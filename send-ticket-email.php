<?php
/**
 * AJAX endpoint: sends the booking confirmation email for a given ticket.
 * Called when the customer clicks "Download" in my-bookings.php.
 */
session_start();
header('Content-Type: application/json');

// Check if user is logged in
if (!isset($_SESSION['logged_in']) || !$_SESSION['logged_in']) {
    echo json_encode(['success' => false, 'message' => 'Not authenticated.']);
    exit();
}

$ticketId = intval($_POST['ticket_id'] ?? 0);
$userId = $_SESSION['user_id'] ?? $_SESSION['acc_id'] ?? null;

if (!$ticketId || !$userId) {
    echo json_encode(['success' => false, 'message' => 'Invalid request.']);
    exit();
}

require_once __DIR__ . '/config.php';
$conn = getDBConnection();

// Verify this ticket belongs to the logged-in user
$stmt = $conn->prepare("
    SELECT t.ticket_id
    FROM TICKET t
    JOIN RESERVE r ON t.reserve_id = r.reservation_id
    WHERE t.ticket_id = ? AND r.acc_id = ?
");
$stmt->bind_param("ii", $ticketId, $userId);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows === 0) {
    $stmt->close();
    $conn->close();
    echo json_encode(['success' => false, 'message' => 'Ticket not found.']);
    exit();
}
$stmt->close();

// Send the booking confirmation email
require_once __DIR__ . '/send-booking-email.php';
$emailSent = sendBookingConfirmationEmail($ticketId, $conn);

$conn->close();

if ($emailSent) {
    echo json_encode(['success' => true, 'message' => 'Your ticket receipt has been sent to your email. Please check your inbox or spam folder.']);
} else {
    echo json_encode(['success' => false, 'message' => 'Failed to send email. Please try again later.']);
}

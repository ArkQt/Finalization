<?php
session_start();
require_once __DIR__ . '/config.php';
$conn = getDBConnection();

// Check if user is logged in
if (!isset($_SESSION['logged_in']) || !$_SESSION['logged_in']) {
    header("Location: login.php");
    exit();
}

// Get booking data from POST first, then SESSION
$rawBookingData = null;

if (!empty($_POST['booking_data'])) {
    $rawBookingData = $_POST['booking_data'];
} elseif (!empty($_SESSION['pending_booking'])) {
    $rawBookingData = $_SESSION['pending_booking'];
}

// Clear from session AFTER reading it
unset($_SESSION['pending_booking']);

if (!$rawBookingData) {
    header("Location: TICKETIX NI CLAIRE.php");
    exit();
}

$bookingData = json_decode($rawBookingData, true);
if (!$bookingData) {
    header("Location: TICKETIX NI CLAIRE.php");
    exit();
}

// Extract booking information
$movieTitle = urldecode($bookingData['movie'] ?? '');
$branchName = urldecode($bookingData['branch'] ?? '');
$showTime = $bookingData['time'] ?? '';
$showDate = $bookingData['date'] ?? date('Y-m-d');
if (!preg_match('/^\d{4}-\d{2}-\d{2}$/', $showDate)) {
    $showDate = date('Y-m-d');
}
$selectedSeats = $bookingData['seats'] ?? [];
$foodItems = $bookingData['food'] ?? [];
$foodTotal = floatval($bookingData['foodTotal'] ?? 0);

// ── 20-Minute Cutoff Validation ───────────────────────────────────────────
// Only check if the booking is for today (future dates are always allowed)
if ($showDate === date('Y-m-d') && !empty($showTime)) {
    // Parse time like "10:30 AM", "08:30 PM" etc.
    $parsedTime = date_parse($showTime);
    if ($parsedTime && isset($parsedTime['hour'])) {
        $showDateTime = mktime($parsedTime['hour'], $parsedTime['minute'] ?? 0, 0);
        $cutoffTime   = $showDateTime - (20 * 60); // 20 minutes before show
        if (time() >= $cutoffTime) {
            // Too late — redirect back with an error
            session_start();
            header("Location: seat-reservation.php?" . http_build_query([
                'movie'  => $_REQUEST['booking_data'] ? ($bookingData['movie'] ?? '') : '',
                'branch' => $bookingData['branch'] ?? '',
                'time'   => $showTime,
                'date'   => $showDate,
                'error'  => 'cutoff'
            ]));
            exit();
        }
    }
}
// ── End Cutoff Validation ─────────────────────────────────────────────────



// Get movie details
$movie = null;
$moviePoster = 'images/default.png';
if ($movieTitle) {
    $stmt = $conn->prepare("SELECT movie_show_id, title, image_poster FROM MOVIE WHERE title = ? LIMIT 1");
    $stmt->bind_param("s", $movieTitle);
    $stmt->execute();
    $result = $stmt->get_result();
    if ($result && $result->num_rows > 0) {
        $movie = $result->fetch_assoc();
        $moviePoster = !empty($movie['image_poster']) ? htmlspecialchars($movie['image_poster']) : 'images/default.png';
    }
    $stmt->close();
}

// Calculate dynamic seat prices
$seatCount = count($selectedSeats);
$seatTotal = 0;
$seatDetails = [];

// Determine max columns per row to find accurate centers
$rowCenters = [];
$globalMaxCol = 0;
foreach ($selectedSeats as $seatId) {
    if (preg_match('/^([A-Z])-?(\d+)$/i', $seatId, $matches)) {
        $r = strtoupper($matches[1]);
        $c = intval($matches[2]);
        if (!isset($rowCenters[$r]) || $c > $rowCenters[$r]['maxCol']) {
            $rowCenters[$r] = ['maxCol' => $c];
        }
        if ($c > $globalMaxCol) $globalMaxCol = $c;
    }
}
// For dynamic calculation, we need to know the width of all rows.
// Since we don't query every seat here, we can use a basic approximation 
// based on standard layout (A-B: 18, C-G: 18), but we will rely centrally on the front-end passed prices if available, 
// or fallback to calculating here.

$frontEndSeatsData = $bookingData['seatsData'] ?? []; 
if (!empty($frontEndSeatsData)) {
    // If seat-reservation passed the exact calculated prices, use them!
    foreach ($frontEndSeatsData as $sd) {
        $price = floatval($sd['price']);
        $seatTotal += $price;
        $seatDetails[] = [
            'id' => $sd['id'],
            'tier' => $sd['tier'],
            'price' => $price
        ];
    }
} else {
    // Fallback if not passed (legacy)
    $seatPrice = 250.00;
    $seatTotal = $seatPrice * $seatCount;
    foreach ($selectedSeats as $s) {
        $seatDetails[] = ['id' => $s, 'tier' => 'Standard', 'price' => 250.00];
    }
}

$grandTotal = $seatTotal + $foodTotal;

// Get user ID
$userId = $_SESSION['user_id'] ?? $_SESSION['acc_id'] ?? null;
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Checkout - Ticketix</title>
    <link rel="icon" type="image/png" href="images/brand x.png" />
    <link rel="stylesheet" href="css/ticketix-main.css">
    <link rel="stylesheet" href="css/checkout.css">
</head>
<body>
    <div class="checkout-container">
        <a href="javascript:history.back()" class="btn-back">← Back</a>
        <h1>Checkout</h1>
        
        <div class="booking-summary">
            <div class="movie-poster-section">
                <img src="<?= htmlspecialchars($moviePoster) ?>" alt="<?= htmlspecialchars($movieTitle) ?>">
                <h3><?= htmlspecialchars($movieTitle) ?></h3>
            </div>
            
            <div class="summary-details">
                <h2>Booking Summary</h2>
                <div class="detail-row">
                    <strong>Branch:</strong>
                    <span><?= htmlspecialchars($branchName ?: 'SM Mall of Asia') ?></span>
                </div>
                <div class="detail-row">
                    <strong>Show Date:</strong>
                    <span><?= date('F d, Y', strtotime($showDate)) ?></span>
                </div>
                <div class="detail-row">
                    <strong>Show Time:</strong>
                    <span><?= htmlspecialchars($showTime) ?></span>
                </div>
                <div class="detail-row">
                    <strong>Seats (<?= $seatCount ?>):</strong>
                    <div class="seats-list">
                        <?php foreach($seatDetails as $sd): ?>
                            <span class="seat-badge <?= strtolower($sd['tier']) ?>" style="background: rgba(255,255,255,0.1); padding: 4px 8px; border-radius: 4px; border: 1px solid rgba(0,191,255,0.3); font-size: 0.85em; display: inline-block; margin: 2px;">
                                <?= htmlspecialchars($sd['id']) ?> (<?= $sd['tier'] ?>)  - ₱<?= number_format($sd['price'], 2) ?>
                            </span>
                        <?php endforeach; ?>
                    </div>
                </div>
                
                <?php if (count($foodItems) > 0): ?>
                <div class="detail-row food-items-row">
                    <strong>Food Items:</strong>
                    <div class="food-items-table-wrapper">
                        <table class="food-items-table">
                            <thead>
                                <tr>
                                    <th>Quantity</th>
                                    <th>Name</th>
                                    <th>Subtotal</th>
                                </tr>
                            </thead>
                            <tbody>
                                <?php foreach ($foodItems as $food): ?>
                                <tr>
                                    <td><?= htmlspecialchars($food['quantity'] ?? 0) ?></td>
                                    <td><?= htmlspecialchars($food['name'] ?? 'N/A') ?></td>
                                    <td>₱<?= number_format($food['subtotal'] ?? 0, 2) ?></td>
                                </tr>
                                <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
                </div>
                <?php endif; ?>
            </div>
        </div>
        
        <div class="price-section">
            <div class="price-row">
                <span>Seat Total (<?= $seatCount ?> seats):</span>
                <span>₱<?= number_format($seatTotal, 2) ?></span>
            </div>
            <?php if ($foodTotal > 0): ?>
            <div class="price-row">
                <span>Food Total:</span>
                <span>₱<?= number_format($foodTotal, 2) ?></span>
            </div>
            <?php endif; ?>
            <div class="price-row total">
                <span>Grand Total:</span>
                <span>₱<?= number_format($grandTotal, 2) ?></span>
            </div>
        </div>
        
        <?php if (isset($_GET['error'])): ?>
        <div class="error-message">
            <strong>Error:</strong> <?= htmlspecialchars($_GET['error']) ?>
        </div>
        <?php endif; ?>
        
        <form method="POST" action="payment.php">
            <input type="hidden" name="booking_data" value="<?= htmlspecialchars($rawBookingData) ?>">
            <input type="hidden" name="seat_total" value="<?= $seatTotal ?>">
            <input type="hidden" name="food_total" value="<?= $foodTotal ?>">
            <input type="hidden" name="grand_total" value="<?= $grandTotal ?>">
            <button type="submit" class="btn-proceed">Proceed to Payment →</button>
        </form>
    </div>
</body>
</html>
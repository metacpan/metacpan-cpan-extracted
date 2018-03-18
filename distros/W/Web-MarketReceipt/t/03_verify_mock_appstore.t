use strict;
use Test::More;
use MIME::Base64 qw/encode_base64/;
use Web::MarketReceipt::Verifier::Mock::AppStore;

my $purchase_info = encode_base64('
{
	"original-purchase-date-pst" = "2000-01-01 00:00:00 America/Los_Angeles";
	"unique-identifier" = "ffffffffffffffffffffffffffffffffffffffff";
	"original-transaction-id" = "9999999999999999";
	"bvrs" = "1.0";
	"transaction-id" = "9999999999999999";
	"quantity" = "1";
	"original-purchase-date-ms" = "946713600000";
	"product-id" = "com.example.001";
	"item-id" = "999999999";
	"bid" = "com.example.001";
	"purchase-date-ms" = "946713600000";
	"purchase-date" = "2000-01-01 17:00:00 Etc/GMT";
	"purchase-date-pst" = "2000-01-01 00:00:00 America/Los_Angeles";
	"original-purchase-date" = "2000-01-01 17:00:00 Etc/GMT";
}', '');
my $receipt_text = encode_base64('
{
	"signature" = "XXXXXX";
	"purchase-info" = "' . $purchase_info . '";
	"environment" = "Sandbox";
	"pod" = "100";
	"signing-status" = "0";
}
', '');

subtest 'verify' => sub {
    my $receipt = Web::MarketReceipt::Verifier::Mock::AppStore->new->verify(
        receipt => $receipt_text,
    );

    ok $receipt->is_success;
    is_deeply $receipt->raw, {
        "original_purchase_date_pst" => "2000-01-01 00:00:00 America/Los_Angeles",
        "unique_identifier"          => "ffffffffffffffffffffffffffffffffffffffff",
        "original_transaction_id"    => "9999999999999999",
        "bvrs"                       => "1.0",
        "transaction_id"             => "9999999999999999",
        "quantity"                   => "1",
        "original_purchase_date_ms"  => "946713600000",
        "product_id"                 => "com.example.001",
        "item_id"                    => "999999999",
        "bid"                        => "com.example.001",
        "purchase_date_ms"           => "946713600000",
        "purchase_date"              => "2000-01-01 17:00:00 Etc/GMT",
        "purchase_date_pst"          => "2000-01-01 00:00:00 America/Los_Angeles",
        "original_purchase_date"     => "2000-01-01 17:00:00 Etc/GMT",
    };

    my $order = $receipt->orders->[0];

    is $order->product_identifier, "com.example.001";
    is $order->unique_identifier, "AppStore:9999999999999999";
    is $order->purchased_epoch, "946713600000";
    is $order->quantity, "1";
    is $order->environment, "Sandbox";
    is $order->state, "purchased";
};

done_testing;

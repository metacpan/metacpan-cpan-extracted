use Test::Spec;
use Test::Exception;
use Digest::SHA qw( sha256_hex sha1_hex );
use URI::Escape qw/uri_escape/;
use Verotel::FlexPay qw(
    get_signature
    get_status_URL
    get_purchase_URL
    get_subscription_URL
    get_upgrade_subscription_URL
    get_cancel_subscription_URL
    validate_signature
);

describe "Verotel::FlexPay" => sub {
    it 'has $VERSION in X.X.X format' => sub {
        like($Verotel::FlexPay::VERSION, qr/^[0-9]+\.[0-9]+\.[0-9]+$/);
    };

    describe "get_signature" => sub {
        it "calculates SHA-256 signature" => sub {
            my %params = (
                    'shopID' => '45',
                    'priceAmount'  => '1a 24',
                    'priceCurrency'  => 'EUR',
                    'custom2' => 'žeřuňěč',
                    'saleID'  => 12,
                    'ignore'  => '835x',
                );
            my $secret = 'abc777X';
            my $encString = "$secret:custom2=žeřuňěč:priceAmount=1a 24:priceCurrency=EUR:saleID=12:shopID=45";
            utf8::encode($encString);

            is( get_signature($secret, %params), lc sha256_hex($encString) );
        };
    };

    describe "validate_signature" => sub {
        my $secret = "k0Xas";
        my $encString  = "$secret:notIgnored=asdf:priceAmount=124:referenceID=:saleID=12:shopID=45";
        my %params = (
                shopID      => '45',
                priceAmount => '124',
                saleID      => 12,
                referenceID => undef,
                notIgnored => 'asdf',
                signature   => sha256_hex($encString),
            );
        my %params_with_old_sig = (
            %params,
            signature => sha1_hex($encString),
        );

        it "returns 1 if new SHA-256 signature is ok" => sub {
            is( validate_signature($secret, %params), 1 );
        };

        it "returns 1 if old SHA-1 signature is ok" => sub {
            is( validate_signature($secret, %params_with_old_sig), 1 );
        };

        it "returns 0 if signature is incorrect" => sub {
            is( validate_signature($secret, %params, abc => 456), 0 );
        };
    };

    describe "URL builder" => sub {
        my $base_url = "https://secure.verotel.com";
        my %test_params = (
            shopID => 123,
            saleID => 345,
            ignored => 'blah',
            backURL => 'http:\\backurl.test',
            declineURL => 'http:\\decline.url',
        );
        my $secret = 'aaB';

        describe "get_purchase_URL" => sub {
            my $signature = get_signature($secret, %test_params, version => 3.5, type => 'purchase');
            my $common_url_portion = "$base_url/startorder"
                ."?backURL=http%3A%5Cbackurl.test"
                ."&declineURL=http%3A%5Cdecline.url"
                ."&ignored=blah"
                ."&saleID=345"
                ."&shopID=123"
                ."&type=purchase"
                ."&version=3.5";

            it "generates valid purchase URL" => sub {
                is(get_purchase_URL($secret, %test_params),
                    "$common_url_portion&signature=$signature"
                );
            };

            it "removes empty values from URL" => sub {
                is( get_purchase_URL($secret, %test_params, custom2 => '', custom3 => undef),
                    "$common_url_portion&signature=$signature"
                );
            };

            it "parameter with zero is not removed from URL" => sub {
                is( get_purchase_URL($secret, %test_params, xxx => 0),
                    "$common_url_portion&xxx=0&signature=$signature"
                );
            };

            it "croaks if called without secret" => sub {
                throws_ok {
                    get_purchase_URL('', bla => 43);
                } qr/no secret given/;
            };

            it "croaks if called without params" => sub {
                throws_ok {
                    get_purchase_URL($secret);
                } qr/no params given/;
            };
        };

        describe "get_subscription_URL" => sub {
            my $signature = get_signature($secret, %test_params, version => 3.5, type => 'subscription');
            my $common_url_portion = "$base_url/startorder"
                ."?backURL=http%3A%5Cbackurl.test"
                ."&declineURL=http%3A%5Cdecline.url"
                ."&ignored=blah"
                ."&saleID=345"
                ."&shopID=123"
                ."&type=subscription"
                ."&version=3.5";

            it "generates valid subscription URL" => sub {
                is(get_subscription_URL($secret, %test_params),
                    "$common_url_portion&signature=$signature"
                );
            };

            it "croaks if called without secret" => sub {
                throws_ok {
                    get_subscription_URL('', bla => 43);
                } qr/no secret given/;
            };

            it "croaks if called without params" => sub {
                throws_ok {
                    get_subscription_URL($secret);
                } qr/no params given/;
            };
        };

        describe "get_upgrade_subscription_URL" => sub {
            my $signature = get_signature($secret, %test_params, version => 3.5, type => 'upgradesubscription', precedingSaleID => 1234);
            my $common_url_portion = "$base_url/startorder"
                ."?backURL=http%3A%5Cbackurl.test"
                ."&declineURL=http%3A%5Cdecline.url"
                ."&ignored=blah"
                ."&precedingSaleID=1234"
                ."&saleID=345"
                ."&shopID=123"
                ."&type=upgradesubscription"
                ."&version=3.5";

            it "generates valid upgrade subscription URL" => sub {
                is(get_upgrade_subscription_URL($secret, %test_params, precedingSaleID => 1234),
                    "$common_url_portion&signature=$signature"
                );
            };
        };

        describe "get_status_URL" => sub {
            my $signature = get_signature($secret, %test_params, version => 3.5);
            my $common_url_portion = "$base_url/salestatus"
                ."?backURL=http%3A%5Cbackurl.test"
                ."&declineURL=http%3A%5Cdecline.url"
                ."&ignored=blah"
                ."&saleID=345"
                ."&shopID=123"
                ."&version=3.5";

            it "generates valid status URL" => sub {
                is(get_status_URL($secret, %test_params),
                    "$common_url_portion&signature=$signature"
                );
            };

            it "croaks if called without secret" => sub {
                throws_ok {
                    get_status_URL('', bla => 43);
                } qr/no secret given/;
            };

            it "croaks if called without params" => sub {
                throws_ok {
                    get_status_URL($secret);
                } qr/no params given/;
            };
        };

        describe "get_cancel_subscription_URL" => sub {
            my $signature = get_signature($secret, %test_params, version => 3.5);
            my $common_url_portion = "$base_url/cancel-subscription"
                ."?backURL=http%3A%5Cbackurl.test"
                ."&declineURL=http%3A%5Cdecline.url"
                ."&ignored=blah"
                ."&saleID=345"
                ."&shopID=123"
                ."&version=3.5";

            it "generates valid status URL" => sub {
                is(get_cancel_subscription_URL($secret, %test_params),
                    "$common_url_portion&signature=$signature"
                );
            };

            it "croaks if called without secret" => sub {
                throws_ok {
                    get_cancel_subscription_URL('', bla => 43);
                } qr/no secret given/;
            };

            it "croaks if called without params" => sub {
                throws_ok {
                    get_cancel_subscription_URL($secret);
                } qr/no params given/;
            };
        };
    };
};

runtests;

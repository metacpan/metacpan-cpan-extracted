use Test2::V0 -no_srand => 1;
use v5.42;
use lib 't/lib';
use Local::FakeSheetsUA;
use Tie::Google::Sheets;
use Crypt::JWT qw( decode_jwt );
use Crypt::PK::RSA;
use URI::Escape qw( uri_unescape );

my $rsa = Crypt::PK::RSA->new->generate_key(256);
my $private_pem = $rsa->export_key_pem('private');
my $public_pem  = $rsa->export_key_pem('public');

my $mock = Local::FakeSheetsUA->new;
tie my %doc, 'Tie::Google::Sheets',
    spreadsheet_id  => 'test-spreadsheet',
    any_ua          => $mock,
    service_account => {
        client_email => 'fake@example.iam.gserviceaccount.com',
        private_key  => $private_pem,
    };

$doc{Sheet1}{A1} = 'hi';

my @calls = $mock->calls;
is scalar(@calls), 3, 'a token request, an existence check, and an API request were made';

my $token_call = $calls[0];
is $token_call->{url}, 'https://oauth2.googleapis.com/token', 'first call is the token endpoint';

my %form = map { my($k, $v) = split /=/, $_, 2; (uri_unescape($k), uri_unescape($v)) } split /&/, $token_call->{opts}{content};
my $claims = decode_jwt(token => $form{assertion}, key => \$public_pem);

is $claims->{iss}, 'fake@example.iam.gserviceaccount.com', 'JWT issuer is the service account email';
is $claims->{scope}, 'https://www.googleapis.com/auth/spreadsheets', 'JWT scope is the spreadsheets scope';
is $claims->{aud}, 'https://oauth2.googleapis.com/token', 'JWT audience is the token endpoint';

my $api_call = $calls[2];
is $api_call->{opts}{headers}{authorization}, 'Bearer fake-service-account-token', 'API request carries the token from the token endpoint';

$doc{Sheet1}{A2} = 'again';
is scalar($mock->calls), 4, 'the cached token and worksheet are reused for a second call, no extra token request or existence check';

done_testing;

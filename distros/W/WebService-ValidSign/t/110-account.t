use Test::Lib;
use Test::WebService::ValidSign;

use WebService::ValidSign;

my $client = WebService::ValidSign->new(
    secret => 'Foo',
);

my $account = $client->account;
isa_ok($account, "WebService::ValidSign::API::Account");

SKIP: {

    use List::Util qw(none);

    if ($ENV{NO_NETWORK_TESTING} || none { $_ =~ /^VALIDSIGN_/ } keys %ENV) {
        my $reason = q{
These tests require internet connectivity and some environment variables:
NO_NETWORK_TESTING set to 0
VALIDSIGN_API_ENDPOINT
VALIDSIGN_API_KEY
};
        skip $reason, 1;
    }

    my $client = WebService::ValidSign->new(
        endpoint => $ENV{VALIDSIGN_API_ENDPOINT},
        secret   => $ENV{VALIDSIGN_API_KEY},
    );

    my $account = $client->account;
    note explain $account->senders;
    note explain $account->senders(search => 'wesley');

}

done_testing;

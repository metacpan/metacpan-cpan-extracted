use strict;
use warnings;
use Test::Lib;
use Test::WebService::ValidSign;

use strict;
use warnings;
use Test::More 0.96;
use Test::Exception;
use Sub::Override;

use WebService::ValidSign;
use HTTP::Response;

my $client = WebService::ValidSign->new(
    endpoint => 'https://try.validsign.nl/api',
    secret => 'Foo',
);

isa_ok($client, "WebService::ValidSign");
isa_ok($client->endpoint, 'URI');
my $lwp = $client->lwp;
isa_ok($lwp, "LWP::UserAgent");

is(
    $lwp->agent,
    "WebService::ValidSign/$WebService::ValidSign::VERSION",
    "UserAgent matches"
);

done_testing;

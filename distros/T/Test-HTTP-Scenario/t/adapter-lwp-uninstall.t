use strict;
use warnings;

use Test::Most;
use Test::Warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use LWP::UserAgent;
use HTTP::Request;
use Test::HTTP::Scenario::Adapter::LWP;

# Capture the real dispatch target for request()
my $orig_request = LWP::UserAgent->can('request');
ok($orig_request, 'captured original LWP::UserAgent->can("request")');

# Dummy scenario that simply delegates to the real request
{
    package Local::Scenario::Dummy;
    use strict;
    use warnings;

    sub new { bless {}, shift }

    sub handle_request {
        my ($self, $req, $code) = @_;
        return $code->();   # delegate to original
    }
}

my $scenario = Local::Scenario::Dummy->new;

my $adapter = Test::HTTP::Scenario::Adapter::LWP->new;
$adapter->set_scenario($scenario);

# Before install: request should be original
is(
    LWP::UserAgent->can('request'),
    $orig_request,
    'before install: request() is original'
);

$adapter->install;

# After install: request should NOT be original
cmp_ok(
    LWP::UserAgent->can('request'),
    'ne',
    $orig_request,
    'after install: request() is overridden'
);

# Make a trivial request to ensure override is active
{
    my $ua  = LWP::UserAgent->new;
    my $req = HTTP::Request->new(GET => 'http://127.0.0.1/');
    my $res = $ua->request($req);
    ok(defined $res, 'request() via overridden method returned a response');
}

$adapter->uninstall;

# After uninstall: request MUST be restored
is(
    LWP::UserAgent->can('request'),
    $orig_request,
    'after uninstall: request() restored to original'
);

done_testing();

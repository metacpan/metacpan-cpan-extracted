#!perl 

# Tests for the authentication sequence. We start from an
# empty config file, get a frob, then a token and a
# timeline.

use strict;
use warnings;
use Test::More tests => 7;

use WebService::RTMAgent;
my $config_file = "config.tmp";
$WebService::RTMAgent::config_file = $config_file;
unlink $WebService::RTMAgent::config_file;

# Overload RTMAgent::request so as to not do any actual requests
# Instead, we use request.* files that contains the tested
# requests, and return the expected responses found in
# response.* files.
package
  RTMTestAgent;
use base 'WebService::RTMAgent';
use HTTP::Response;
use HTTP::Status;
# Load all the requests and expected responses.
my %responses;
foreach my $req_file (glob 't/request.*') {
    local $/; undef $/;
    open my $f, $req_file or die "Unable to open $req_file: $!\n";
    my $req = <$f>;
    my $res_file = $req_file;
    $res_file =~ s/request/response/;
    open $f, $res_file or die "Unable to open $res_file:$!\n";
    my $res = <$f>;
    $responses{$req} = $res;
}
sub request {
    my ($self, $req) = @_;
    my $req_str = $req->as_string;
    die "No such request:\n####\n$req_str####\n" unless exists $responses{$req_str};
    return HTTP::Response->parse($responses{$req_str});
}

package main;

my $ua = new RTMTestAgent;
$ua->api_key("key");
$ua->api_secret("secret");


# check invalid frob works
$WebService::RTMAgent::config->{frob} = 1234;
eval {
    $ua->init;
};
ok($@ =~ "101: Invalid frob", "Invalid frob is caught");

# check invalid token works
$WebService::RTMAgent::config->{token} = 1234;
eval {
    $ua->init;
};
ok($@ =~ /98: Login failed/, "Invalid token is caught");

# Authentication URL tests
ok($ua->get_auth_url eq "https://api.rememberthemilk.com/services/auth/?api_key=key&perms=delete&frob=0c9107b07a7e64fa460af183a6c0f01e7d0e3d54&api_sig=60e3e68636e2319a8977606c05499df5", "Checking authentication URL");
ok($WebService::RTMAgent::config->{frob} eq "0c9107b07a7e64fa460af183a6c0f01e7d0e3d54", "Checking the config file");

# Getting token and timeline
ok($ua->init, "Initialising user agent");
ok($WebService::RTMAgent::config->{token} eq "token", "Checking token");
ok($WebService::RTMAgent::config->{timeline} eq "tl", "Checking timeline");


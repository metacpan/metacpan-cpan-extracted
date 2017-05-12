#!perl 

# Tests for undo feature. We do a couple of undo-able
# functions, then we undo them.

use strict;
use warnings;
use Test::More tests => 7;

use WebService::RTMAgent;
use File::Copy;
copy("t/config","/tmp/config") or die "Could not copy config file to /tmp\n";
$WebService::RTMAgent::config_file = "/tmp/config";

# Overload RTMAgent::request so as to not do any actual requests
# Instead, we use request.* files that contains the tested
# requests, and return the expected responses found in
# response.* files.
package RTMTestAgent;
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

ok($ua->tasks_add("name=\"A new task\""), "Adding a task");
ok($WebService::RTMAgent::config->{undo}->[0]->{op} eq "rtm.tasks.add", "Stored undo info");

ok($ua->tasks_add("name=\"A new task\""), "Adding another task");
ok($WebService::RTMAgent::config->{undo}->[1]->{op} eq "rtm.tasks.add", "Stored undo info");

use Data::Dumper;
my $undoable = $ua->get_undoable;
ok($undoable->[1]->{op} eq "rtm.tasks.add", "get_undoable returns list");

# The actual undo doesn't need to be tested, it's just a
# normal request using what's in the list.

ok($ua->clear_undo(1), "Remove an undoable");
ok(scalar @{$ua->get_undoable} == 1, "remove worked");

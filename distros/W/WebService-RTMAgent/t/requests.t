#!perl 

use strict;
use warnings;
use Test::More tests => 12;

use WebService::RTMAgent;
$WebService::RTMAgent::config_file = "t/config";

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

my $sign = $ua->sign("key=val","cle=valeur","foo=bar");
ok($sign eq "c87afd21be10c9833aa077e248a3d607", "Signing requests");

ok($ua->init, "initialising");

my $lists = $ua->lists_getList;
ok(defined $lists, "request without parameters");

ok(exists $lists->{lists}, " -- checking structure 1");
ok(exists $lists->{lists}->[0]->{list}, " -- checking structure 2");
ok(exists $lists->{lists}->[0]->{list}->[0]->{name}, " -- checking structure 3");
ok($lists->{lists}->[0]->{list}->[0]->{name} eq 'Inbox', " -- checking structure 4");

my $tasks = $ua->tasks_getList("list_id=123");
ok(defined $tasks, "request with parameters");
ok($tasks->{tasks}->[0]->{list}->[0]->{taskseries}->[0]->{id} == 7417459, " -- task id is correct");

# This must kill us
eval {
    $ua->tasks_unknownMethod("param=0");
};
ok($@ =~ "rtm.tasks.unknownMethod does not exist\n", "Carp message");

# Call method with invalid parameters, with verbose (for
# better coverage :-) ).
$ua->verbose('netin netout');
$ua->rtm_tasks_add("nam=adding"); # Also tests method can start with 'rtm'
ok($ua->error eq "4000: Task name provided is invalid.\n", "Error setting");
$ua->verbose('');

# Failing request
eval {
    $ua->tasks_add("name=failing");
};
ok($@ =~ "403 Forbidden", "HTTP request failed");


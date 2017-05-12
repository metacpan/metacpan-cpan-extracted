#!/usr/bin/perl
# vim: set filetype=perl:
# COVER:Server.pm
use strict;
use warnings;
use Term::ReadKey;
use Data::Dumper;

use Test::More qw/no_plan/;

BEGIN {
    use_ok('Tivoli::AccessManager::Admin');
    use_ok('Tivoli::AccessManager::Admin::Server');
}

ReadMode 2;
print "sec_master password: ";
my $pswd = <STDIN>;
ReadMode 0;
chomp $pswd;
print "\n";

print "\nTESTING new\n";
my $pd = Tivoli::AccessManager::Admin->new(password => $pswd);
my $server = Tivoli::AccessManager::Admin::Server->new($pd);
my $resp;

isa_ok($server, "Tivoli::AccessManager::Admin::Server");

print "\nTESTING list\n";
$resp = $server->list;
is($resp->isok, 1, "Got a list of servers");

$resp = Tivoli::AccessManager::Admin::Server->list($pd);
is($resp->isok, 1, "Got another list of servers");

my $wseal;
for ($resp->value) {
    if (/webseal/) {
	$wseal = $_;
	last;
    }
}

my @task_expected = (
'dynurl update',
'jmt load',
'jmt clear',
'cache flush all',
'create <options> <junction-point>',
'add <options> <junction-point>',
'remove <options> <junction-point>',
'delete <junction-point>',
'list',
'show <junction-point>',
'throttle <options> <junction-point>',
'offline <options> <junction-point>',
'online <options> <junction-point>',
'virtualhost create <options> <virtual-host-label>',
'virtualhost add <options> <virtual-host-label>',
'virtualhost remove <options> <virtual-host-label>',
'virtualhost delete <virtual-host-label>',
'virtualhost list',
'virtualhost show <virtual-host-label>',
'virtualhost throttle <options> <virtual-host-label>',
'virtualhost offline <options> <virtual-host-label>',
'virtualhost online <options> <virtual-host-label>',
'reload',
'terminate all_sessions <user_id>',
'refresh all_sessions <user_id>',
'help <command>',
'trace set <component> <level> [file path=<file>|<other-log-agent-config>]',
'trace show [<component>]',
'trace list [<component>]',
'stats show [<component>]',
'stats list',
'stats on <component> [<interval>] [<count>] [file path=<file>|<other-log-agent-config>]',
'stats off [<component>]',
'stats reset [<component>]',
'stats get [<component>]',
);

print "\nTESTING tasklist\n";

$server = Tivoli::AccessManager::Admin::Server->new($pd, name => $wseal);
isa_ok($server, "Tivoli::AccessManager::Admin::Server");

$resp = $server->tasklist;
is($resp->isok, 1, "Got a task list back");
is_deeply($resp->value->{tasks},\@task_expected,"Got the expected list back");

print "\nTESTING tasks\n";

my @help_expected = (
'Command:',
'reload',
'Description:',
'reloads the junction table from the database.',
);

$resp = $server->task('help reload');
is($resp->isok,1,"Asked for help");
is_deeply([$resp->value],\@help_expected,"Got the help I expected");

$resp = $server->task(task => 'help reload');
is($resp->isok,1,"Asked for help again");
is_deeply([$resp->value],\@help_expected,"Got the help I expected again");

print "\nTESTING name\n";
$resp = $server->name;
is($resp->isok, 1, "Requested the server's name");
is($resp->value, $wseal, "And got it");

$resp = $server->name('ivacld-gir');
is($resp->isok, 1, "Set the server's name");
is($resp->value, 'ivacld-gir', "And set it correctly");

$resp = $server->name(name => $wseal);
is($resp->isok, 1, "Set the server's name back to $wseal");
is($resp->value, $wseal, "And got it");

print "\nTESTING broken calls\n";
$server = Tivoli::AccessManager::Admin::Server->new();
is($server,undef,"Could not call new w/o a context");

$server = Tivoli::AccessManager::Admin::Server->new('one');
is($server,undef,"Could not call new with a non-context");

$server = Tivoli::AccessManager::Admin::Server->new($pd,qw/one two three/);
is($server,undef,"Could not call new with an odd number of parameters");

$resp = Tivoli::AccessManager::Admin::Server->list();
is($resp->isok, 0, "Could not call list with an empty parameter list");

$resp = Tivoli::AccessManager::Admin::Server->list(qw/one two three/);
is($resp->isok, 0, "Could not call list with a non-context");

$server = Tivoli::AccessManager::Admin::Server->new($pd);
$resp = $server->tasklist;
is($resp->isok, 0, "Could not get a task list from an unnamed server");

$resp = $server->task('help reload');
is($resp->isok, 0, "Could not perform a task on an unnamed server");

$server = Tivoli::AccessManager::Admin::Server->new($pd,$wseal);
$resp = $server->task('ph34r');
is($resp->isok, 0, "Could not execute an undefined task");

$resp = $server->task(qw/one two three/);
is($resp->isok, 0, "Could not call task with an odd number of parameters");

$resp = $server->task;
is($resp->isok, 0, "Could not call task without a task");

$resp = $server->task(silly => 'bob');
is($resp->isok, 0, "Invalid hash key ignored");

$resp = $server->name(qw/one two three/);
is($resp->isok, 0, "Could not call name with an odd number of parameters");

$resp = $server->name(silly => 'foo');
is($resp->value, $wseal, "Ignored a silly hash key");

$server = Tivoli::AccessManager::Admin::Server->new($pd,'weelah');
$resp = $server->tasklist;
is($resp->isok, 0, "Could not get a task list from a non-existent server");

$server = Tivoli::AccessManager::Admin::Server->new($pd, silly => 'foo');
isa_ok($server, "Tivoli::AccessManager::Admin::Server","Ignored silly hash key");


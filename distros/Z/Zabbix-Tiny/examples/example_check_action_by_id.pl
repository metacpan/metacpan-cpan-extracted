#!/usr/bin/env perl
use strict;
use warnings;
use Zabbix::Tiny;
use Getopt::Long qw(GetOptions);

## Actions in Zabbix can get silently disabled if an entity they reference gets deleted.
## See https://support.zabbix.com/browse/ZBXNEXT-551 for more detail on when that could happen.
## This script allows to check whether an action, specified by ID, is enabled.

my $username     = 'user';
my $password     = 'password';
my $url          = 'http://host/zabbix/api_jsonrpc.php';

my $result;
my $actionid;
my $help;
my $usage = <<"USAGE";
$0 --actionid ACTION_ID

Will check whether action with a given ID is enabled. Returns 0 if it exists and is enabled, 1 if it exists and is disabled, 2 if it does not exist.
Note that all action types are checked - trigger, discovery, auto-registration and internal.
USAGE

GetOptions(
    'actionid|a=s' => \$actionid,
    'help'         => \$help,
) or die "Usage:\n$usage";

if ($help) {
    die "Usage:\n$usage";
}

if (not $actionid) {
    die "specify action ID to check: --actionid";
}

my $zabbix = Zabbix::Tiny->new(
    server   => $url,
    password => $password,
    user     => $username,
);

$result = $zabbix->do(
    'action.get',
    {
        output => [ "actionid", "status" ],
        actionids => $actionid,
    }
);

if (@$result) {
    # action exists, and status 0 is enabled, status 1 is disabled - matches our output, printing as-is
    print "$result->[0]{status}\n";
}
else {
    print "2\n";
}

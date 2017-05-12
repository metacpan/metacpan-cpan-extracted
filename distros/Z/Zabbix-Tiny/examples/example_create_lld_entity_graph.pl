use strict;
use warnings;

use Zabbix::Tiny;
use Getopt::Long qw(GetOptions);
use IO::Socket::SSL;

# This example accepts host name and key with wildcards and creates a graph. This would be useful, for example,
#  to create a graph that includes all items that an LLD rule has created for a specific discovered entity.

my $username = 'Admin';
my $password = 'zabbix';
my $zserver='http://zabbix_server/zabbix';
#my $zserver='https://hs.motive.com/zabbix22Staging';
my @colours = qw(1A7C11 F63100 2774A4 A54F10 FC6EA3 6C59DC AC8C14 611F27 F230E0 5CCD18 BB2A02 5A2B57 89ABF8
     7EC25C 274482 2B5429);

my $itemkey;
my $host;
my $graphname;
my @gitems;
my $result;
my $help;
my $usage = <<"USAGE";
$0 --host "HOST" --key "ITEM_KEY" --graphname "GRAPH_NAME"

Will create a custom graph with items that match the passed key on the specified host

Example:
perl $0 --key "vfs.fs.size[*,free]" --host "A test host" --graphname "Free diskspace"

The above would find items like vfs.fs.size[/,free], vfs.fs.size[/boot,free], vfs.fs.size[/home,free] and so on
USAGE

GetOptions(
    'key|k=s'       => \$itemkey,
    'host|h=s'      => \$host,
    'graphname|n=s' => \$graphname,
    'help'          => \$help,
) or die "Usage:\n$usage";

if ($help) {
    print "Usage:\n$usage";
    exit;
}

if (not $itemkey) {
    die "specify item key : --key";
}

if (not $host) {
    die "specify host name : --host";
}

if (not $graphname) {
    die "specify graph name : --graphname";
}

my $url = $zserver . "/api_jsonrpc.php";
my $zabbix = Zabbix::Tiny->new(
    server   => $url,
    password => $password,
    user     => $username,
    ssl_opts => {
        verify_hostname => 0,
        SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE,
        SSL_verify_mode => SSL_VERIFY_NONE,
    }
);

print "getting host ID of host '$host'\n";
my $hostid = $zabbix->do(
    'host.get',
    {
        output => "hostid",
        filter => { "host" => $host },
    },
);
if (@$hostid) {
    print "... host exists\n";
}
else {
    die "host '$host' does not exist on $zserver";
}

print "gathering item IDs\n";
$result = $zabbix->do(
    'item.get',
    {
        output                 => "itemid",
        hostids               => [ $hostid->[0]->{hostid} ],
        search                 => { key_ => $itemkey },
        searchWildcardsEnabled => 1,
    },
);

my @itemids = map($_->{itemid}, @$result);
# The line above is equivalent to:
#my @itemids;
#foreach (@$result) {
#    push @itemids, $_->{itemid}
#}
my $itemcount = scalar @itemids;

if (!@itemids) {
    die "found no items matching key '$itemkey' on host '$host'";
}
print "... got " . $itemcount . " itemids\n";

foreach my $index (0..$#itemids) {
    push @gitems, { itemid => $itemids[$index], color => $colours[$index] };
};

eval { $result = $zabbix->do(
    'graph.create',
    {
        name   => $graphname,
        width  => '900',
        height => '200',
        gitems => [ @gitems ],
    },
) };
print $@ if ($@);

print "View the created graph: " . $zserver . "/charts.php?graphid=" . $result->{graphids}[0] . "\n";
print "Configure the created graph: " . $zserver . "/graphs.php?form=update&graphid="
    . $result->{graphids}[0] . "\n";

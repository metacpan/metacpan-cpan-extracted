use strict;
use warnings;

use lib "../lib";

## This example allows to create a user on multiple Zabbix servers and accepts username, groups, name and surname on the
##  commandline. Example invocation:
## perl create_user.pl --user rziema --group "Good users" --group "Nice users" --name Roberts --surname Ziema

use Zabbix::Tiny;
use Getopt::Long qw(GetOptions);
use Data::Dumper;

my $username = 'api_user';
my $password = 'api_password';

my %zservers = (
    zabbix_hq        => "http://hq/zabbix",
    zabbix_branch    => "https://branch/zabbix",
    zabbix_somewhere => "https://somewhere/zabbix",
);
my $zserverlist = join(", ", sort {lc $a cmp lc $b} (keys %zservers));

my @usergroups;
my $usertocreate;
my $name;
my $surname;
my $default_password="changemesoon";
my $help;
my $usage = <<"USAGE";
$0 --user USERNAME --group USERGROUP --group "USERGROUP" --name NAME --surname SURNAME

Will create Zabbix user on: $zserverlist
USAGE

GetOptions(
    'group|g=s'   => \@usergroups,
    'user|u=s'    => \$usertocreate,
    'name|n=s'    => \$name,
    'surname|s=s' => \$surname,
    'help'        => \$help,
) or die "Usage:\n$usage";

if ($help) {
    die "Usage:\n$usage";
}

if (not $usertocreate) {
    die "specify user to create : --user";
}

if (not @usergroups) {
    die "at least one usergroup must be specified : --group";
}

foreach my $zserver (keys %zservers) {
    my @usergroupids;
    # log in all servers, see whether all groups we need exist
    print "===== $zserver - $zservers{$zserver} =====\n";
    my $url = $zservers{$zserver} . "/api_jsonrpc.php";
    my $zabbix = Zabbix::Tiny->new(
        server   => $url,
        user     => $username,
        password => $password,
    );
    foreach my $group (@usergroups) {
        print "checking $group";
        my $usergroupid = $zabbix->do(
            'usergroup.get',
            {
                output => "usrgrpid",
                filter => { 
                    "name" => $group 
                },
            }
        );
        if (@$usergroupid) {
            print "... exists\n";
            push @usergroupids, $usergroupid->[0];
        }
        else {
            # error out, allow the usergroup to be created manually
            print "... missing\n";
            die "group $group does not exist on $zserver";
        }
    }

    # all groups there, creating user
    # using eval - if the user already exists, an error message will be printed but we'll proceed
    eval { $zabbix->do(
        'user.create',
        {
            alias   => $usertocreate,
            passwd  => $default_password,
            usrgrps => [ @usergroupids ],
            name    => $name,
            surname => $surname,
            type    => 3,
        }
    ); };
    print $@ if ($@);
}

use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Compile 2.059

use Test::More;

plan tests => 67 + ($ENV{AUTHOR_TESTING} ? 1 : 0);

my @module_files = (
    'WebService/OPNsense.pm',
    'WebService/OPNsense/Backup.pm',
    'WebService/OPNsense/CaptivePortal/Access.pm',
    'WebService/OPNsense/CaptivePortal/Service.pm',
    'WebService/OPNsense/CaptivePortal/Session.pm',
    'WebService/OPNsense/CaptivePortal/Settings.pm',
    'WebService/OPNsense/CaptivePortal/Voucher.pm',
    'WebService/OPNsense/Constants.pm',
    'WebService/OPNsense/Cron/Service.pm',
    'WebService/OPNsense/Cron/Settings.pm',
    'WebService/OPNsense/Diagnostics.pm',
    'WebService/OPNsense/Dnsmasq/Leases.pm',
    'WebService/OPNsense/Dnsmasq/Service.pm',
    'WebService/OPNsense/Dnsmasq/Settings.pm',
    'WebService/OPNsense/Exception.pm',
    'WebService/OPNsense/Firewall.pm',
    'WebService/OPNsense/Firewall/Alias.pm',
    'WebService/OPNsense/Firewall/Category.pm',
    'WebService/OPNsense/Firewall/DNat.pm',
    'WebService/OPNsense/Firewall/Filter.pm',
    'WebService/OPNsense/Firewall/Npt.pm',
    'WebService/OPNsense/Firewall/OneToOne.pm',
    'WebService/OPNsense/Firewall/Role/NAT.pm',
    'WebService/OPNsense/Firewall/SourceNat.pm',
    'WebService/OPNsense/HASync.pm',
    'WebService/OPNsense/IDS/Service.pm',
    'WebService/OPNsense/IDS/Settings.pm',
    'WebService/OPNsense/IPsec/Connections.pm',
    'WebService/OPNsense/IPsec/KeyPairs.pm',
    'WebService/OPNsense/IPsec/Leases.pm',
    'WebService/OPNsense/IPsec/ManualSpd.pm',
    'WebService/OPNsense/IPsec/Pools.pm',
    'WebService/OPNsense/IPsec/PreSharedKeys.pm',
    'WebService/OPNsense/IPsec/Sad.pm',
    'WebService/OPNsense/IPsec/Service.pm',
    'WebService/OPNsense/IPsec/Sessions.pm',
    'WebService/OPNsense/IPsec/Settings.pm',
    'WebService/OPNsense/IPsec/Spd.pm',
    'WebService/OPNsense/IPsec/Tunnel.pm',
    'WebService/OPNsense/IPsec/Vti.pm',
    'WebService/OPNsense/Interfaces.pm',
    'WebService/OPNsense/Kea/CtrlAgent.pm',
    'WebService/OPNsense/Kea/Ddns.pm',
    'WebService/OPNsense/Kea/Dhcpv4.pm',
    'WebService/OPNsense/Kea/Dhcpv6.pm',
    'WebService/OPNsense/Kea/Leases.pm',
    'WebService/OPNsense/Kea/Service.pm',
    'WebService/OPNsense/Normalize.pm',
    'WebService/OPNsense/Object.pm',
    'WebService/OPNsense/OpenVPN/ClientOverwrites.pm',
    'WebService/OPNsense/OpenVPN/Export.pm',
    'WebService/OPNsense/OpenVPN/Instances.pm',
    'WebService/OPNsense/OpenVPN/Service.pm',
    'WebService/OPNsense/Role/APIPath.pm',
    'WebService/OPNsense/Role/Crud.pm',
    'WebService/OPNsense/Role/ItemCrud.pm',
    'WebService/OPNsense/Role/KeaItemCrud.pm',
    'WebService/OPNsense/Role/Service.pm',
    'WebService/OPNsense/Role/Settings.pm',
    'WebService/OPNsense/Routes.pm',
    'WebService/OPNsense/System.pm',
    'WebService/OPNsense/TrafficShaper/Service.pm',
    'WebService/OPNsense/TrafficShaper/Settings.pm',
    'WebService/OPNsense/Unbound/Diagnostics.pm',
    'WebService/OPNsense/Unbound/Overview.pm',
    'WebService/OPNsense/Unbound/Service.pm',
    'WebService/OPNsense/Unbound/Settings.pm'
);



# no fake home requested

my @switches = (
    -d 'blib' ? '-Mblib' : '-Ilib',
);

use File::Spec;
use IPC::Open3;
use IO::Handle;

open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";

my @warnings;
for my $lib (@module_files)
{
    # see L<perlfaq8/How can I capture STDERR from an external command?>
    my $stderr = IO::Handle->new;

    diag('Running: ', join(', ', map { my $str = $_; $str =~ s/'/\\'/g; q{'}.$str.q{'} }
            $^X, @switches, '-e', "require q[$lib]"))
        if $ENV{PERL_COMPILE_TEST_DEBUG};

    my $pid = open3($stdin, '>&STDERR', $stderr, $^X, @switches, '-e', "require q[$lib]");
    binmode $stderr, ':crlf' if $^O eq 'MSWin32';
    my @_warnings = <$stderr>;
    waitpid($pid, 0);
    is($?, 0, "$lib loaded ok");

    shift @_warnings if @_warnings and $_warnings[0] =~ /^Using .*\bblib/
        and not eval { +require blib; blib->VERSION('1.01') };

    if (@_warnings)
    {
        warn @_warnings;
        push @warnings, @_warnings;
    }
}



is(scalar(@warnings), 0, 'no warnings found') or diag 'got warnings: ', ( Test::More->can('explain') ? Test::More::explain(\@warnings) : join("\n", '', @warnings) ) if $ENV{AUTHOR_TESTING};



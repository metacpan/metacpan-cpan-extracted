#!perl
use strictures 2;

use Test2::V1               qw( ok subtest done_testing );
use Test2::Tools::Exception qw( lives );

# Helper: verify a module loads without error
sub load_ok {
    my ($module) = @_;
    ( my $path = $module ) =~ s{::}{/}g;
    ok( lives { require $path . '.pm' }, "$module loads" );
    return;
}

subtest 'all modules compile cleanly' => sub {

    load_ok('WebService::OPNsense');

    load_ok('WebService::OPNsense::Backup');

    load_ok('WebService::OPNsense::CaptivePortal::Access');
    load_ok('WebService::OPNsense::CaptivePortal::Service');
    load_ok('WebService::OPNsense::CaptivePortal::Session');
    load_ok('WebService::OPNsense::CaptivePortal::Settings');
    load_ok('WebService::OPNsense::CaptivePortal::Voucher');

    load_ok('WebService::OPNsense::Constants');

    load_ok('WebService::OPNsense::Cron::Service');
    load_ok('WebService::OPNsense::Cron::Settings');

    load_ok('WebService::OPNsense::Diagnostics');

    load_ok('WebService::OPNsense::Dnsmasq::Leases');
    load_ok('WebService::OPNsense::Dnsmasq::Service');
    load_ok('WebService::OPNsense::Dnsmasq::Settings');

    load_ok('WebService::OPNsense::Exception');

    load_ok('WebService::OPNsense::Firewall');
    load_ok('WebService::OPNsense::Firewall::Alias');
    load_ok('WebService::OPNsense::Firewall::Category');
    load_ok('WebService::OPNsense::Firewall::DNat');
    load_ok('WebService::OPNsense::Firewall::Role::NAT');
    load_ok('WebService::OPNsense::Role::Crud');
    load_ok('WebService::OPNsense::Role::ItemCrud');
    load_ok('WebService::OPNsense::Role::APIPath');
    load_ok('WebService::OPNsense::Role::KeaItemCrud');
    load_ok('WebService::OPNsense::Role::Service');
    load_ok('WebService::OPNsense::Role::Settings');
    load_ok('WebService::OPNsense::Firewall::Filter');
    load_ok('WebService::OPNsense::Firewall::Npt');
    load_ok('WebService::OPNsense::Firewall::OneToOne');
    load_ok('WebService::OPNsense::Firewall::SourceNat');

    load_ok('WebService::OPNsense::HASync');

    load_ok('WebService::OPNsense::IDS::Service');
    load_ok('WebService::OPNsense::IDS::Settings');

    load_ok('WebService::OPNsense::IPsec::Connections');
    load_ok('WebService::OPNsense::IPsec::KeyPairs');
    load_ok('WebService::OPNsense::IPsec::Leases');
    load_ok('WebService::OPNsense::IPsec::ManualSpd');
    load_ok('WebService::OPNsense::IPsec::Pools');
    load_ok('WebService::OPNsense::IPsec::PreSharedKeys');
    load_ok('WebService::OPNsense::IPsec::Sad');
    load_ok('WebService::OPNsense::IPsec::Service');
    load_ok('WebService::OPNsense::IPsec::Sessions');
    load_ok('WebService::OPNsense::IPsec::Settings');
    load_ok('WebService::OPNsense::IPsec::Spd');
    load_ok('WebService::OPNsense::IPsec::Tunnel');
    load_ok('WebService::OPNsense::IPsec::Vti');

    load_ok('WebService::OPNsense::Interfaces');

    load_ok('WebService::OPNsense::Kea::CtrlAgent');
    load_ok('WebService::OPNsense::Kea::Ddns');
    load_ok('WebService::OPNsense::Kea::Dhcpv4');
    load_ok('WebService::OPNsense::Kea::Dhcpv6');
    load_ok('WebService::OPNsense::Kea::Leases');
    load_ok('WebService::OPNsense::Kea::Service');

    load_ok('WebService::OPNsense::Normalize');

    load_ok('WebService::OPNsense::Object');

    load_ok('WebService::OPNsense::OpenVPN::ClientOverwrites');
    load_ok('WebService::OPNsense::OpenVPN::Export');
    load_ok('WebService::OPNsense::OpenVPN::Instances');
    load_ok('WebService::OPNsense::OpenVPN::Service');

    load_ok('WebService::OPNsense::Routes');

    load_ok('WebService::OPNsense::System');

    load_ok('WebService::OPNsense::TrafficShaper::Service');
    load_ok('WebService::OPNsense::TrafficShaper::Settings');

    load_ok('WebService::OPNsense::Unbound::Diagnostics');
    load_ok('WebService::OPNsense::Unbound::Overview');
    load_ok('WebService::OPNsense::Unbound::Service');
    load_ok('WebService::OPNsense::Unbound::Settings');

};

done_testing;

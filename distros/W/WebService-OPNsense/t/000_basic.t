#!perl
use v5.24;
use strictures 2;

use Test2::V1               qw( ok done_testing );
use Test2::Tools::Exception qw( dies lives );

# Load check: all 67 modules compile cleanly
ok( lives { require WebService::OPNsense }, 'WebService::OPNsense loads' );

ok(
    lives { require WebService::OPNsense::Backup },
    'WebService::OPNsense::Backup loads'
);

ok(
    lives { require WebService::OPNsense::CaptivePortal::Access },
    'WebService::OPNsense::CaptivePortal::Access loads'
);

ok(
    lives { require WebService::OPNsense::CaptivePortal::Service },
    'WebService::OPNsense::CaptivePortal::Service loads'
);

ok(
    lives { require WebService::OPNsense::CaptivePortal::Session },
    'WebService::OPNsense::CaptivePortal::Session loads'
);

ok(
    lives { require WebService::OPNsense::CaptivePortal::Settings },
    'WebService::OPNsense::CaptivePortal::Settings loads'
);

ok(
    lives { require WebService::OPNsense::CaptivePortal::Voucher },
    'WebService::OPNsense::CaptivePortal::Voucher loads'
);

ok(
    lives { require WebService::OPNsense::Constants },
    'WebService::OPNsense::Constants loads'
);

ok(
    lives { require WebService::OPNsense::Cron::Service },
    'WebService::OPNsense::Cron::Service loads'
);

ok(
    lives { require WebService::OPNsense::Cron::Settings },
    'WebService::OPNsense::Cron::Settings loads'
);

ok(
    lives { require WebService::OPNsense::Diagnostics },
    'WebService::OPNsense::Diagnostics loads'
);

ok(
    lives { require WebService::OPNsense::Dnsmasq::Leases },
    'WebService::OPNsense::Dnsmasq::Leases loads'
);

ok(
    lives { require WebService::OPNsense::Dnsmasq::Service },
    'WebService::OPNsense::Dnsmasq::Service loads'
);

ok(
    lives { require WebService::OPNsense::Dnsmasq::Settings },
    'WebService::OPNsense::Dnsmasq::Settings loads'
);

ok(
    lives { require WebService::OPNsense::Exception },
    'WebService::OPNsense::Exception loads'
);

ok(
    lives { require WebService::OPNsense::Firewall },
    'WebService::OPNsense::Firewall loads'
);

ok(
    lives { require WebService::OPNsense::Firewall::Alias },
    'WebService::OPNsense::Firewall::Alias loads'
);

ok(
    lives { require WebService::OPNsense::Firewall::Category },
    'WebService::OPNsense::Firewall::Category loads'
);

ok(
    lives { require WebService::OPNsense::Firewall::DNat },
    'WebService::OPNsense::Firewall::DNat loads'
);

ok(
    lives { require WebService::OPNsense::Firewall::Role::NAT },
    'WebService::OPNsense::Firewall::Role::NAT loads'
);

ok(
    lives { require WebService::OPNsense::Role::Crud },
    'WebService::OPNsense::Role::Crud loads'
);

ok(
    lives { require WebService::OPNsense::Role::ItemCrud },
    'WebService::OPNsense::Role::ItemCrud loads'
);

ok(
    lives { require WebService::OPNsense::Role::APIPath },
    'WebService::OPNsense::Role::APIPath loads'
);

ok(
    lives { require WebService::OPNsense::Role::Service },
    'WebService::OPNsense::Role::Service loads'
);

ok(
    lives { require WebService::OPNsense::Role::Settings },
    'WebService::OPNsense::Role::Settings loads'
);

ok(
    lives { require WebService::OPNsense::Firewall::Filter },
    'WebService::OPNsense::Firewall::Filter loads'
);

ok(
    lives { require WebService::OPNsense::Firewall::Npt },
    'WebService::OPNsense::Firewall::Npt loads'
);

ok(
    lives { require WebService::OPNsense::Firewall::OneToOne },
    'WebService::OPNsense::Firewall::OneToOne loads'
);

ok(
    lives { require WebService::OPNsense::Firewall::SourceNat },
    'WebService::OPNsense::Firewall::SourceNat loads'
);

ok(
    lives { require WebService::OPNsense::HASync },
    'WebService::OPNsense::HASync loads'
);

ok(
    lives { require WebService::OPNsense::IDS::Service },
    'WebService::OPNsense::IDS::Service loads'
);

ok(
    lives { require WebService::OPNsense::IDS::Settings },
    'WebService::OPNsense::IDS::Settings loads'
);

ok(
    lives { require WebService::OPNsense::IPsec::Connections },
    'WebService::OPNsense::IPsec::Connections loads'
);

ok(
    lives { require WebService::OPNsense::IPsec::KeyPairs },
    'WebService::OPNsense::IPsec::KeyPairs loads'
);

ok(
    lives { require WebService::OPNsense::IPsec::Leases },
    'WebService::OPNsense::IPsec::Leases loads'
);

ok(
    lives { require WebService::OPNsense::IPsec::ManualSpd },
    'WebService::OPNsense::IPsec::ManualSpd loads'
);

ok(
    lives { require WebService::OPNsense::IPsec::Pools },
    'WebService::OPNsense::IPsec::Pools loads'
);

ok(
    lives { require WebService::OPNsense::IPsec::PreSharedKeys },
    'WebService::OPNsense::IPsec::PreSharedKeys loads'
);

ok(
    lives { require WebService::OPNsense::IPsec::Sad },
    'WebService::OPNsense::IPsec::Sad loads'
);

ok(
    lives { require WebService::OPNsense::IPsec::Service },
    'WebService::OPNsense::IPsec::Service loads'
);

ok(
    lives { require WebService::OPNsense::IPsec::Sessions },
    'WebService::OPNsense::IPsec::Sessions loads'
);

ok(
    lives { require WebService::OPNsense::IPsec::Settings },
    'WebService::OPNsense::IPsec::Settings loads'
);

ok(
    lives { require WebService::OPNsense::IPsec::Spd },
    'WebService::OPNsense::IPsec::Spd loads'
);

ok(
    lives { require WebService::OPNsense::IPsec::Tunnel },
    'WebService::OPNsense::IPsec::Tunnel loads'
);

ok(
    lives { require WebService::OPNsense::IPsec::Vti },
    'WebService::OPNsense::IPsec::Vti loads'
);

ok(
    lives { require WebService::OPNsense::Interfaces },
    'WebService::OPNsense::Interfaces loads'
);

ok(
    lives { require WebService::OPNsense::Kea::CtrlAgent },
    'WebService::OPNsense::Kea::CtrlAgent loads'
);

ok(
    lives { require WebService::OPNsense::Kea::Ddns },
    'WebService::OPNsense::Kea::Ddns loads'
);

ok(
    lives { require WebService::OPNsense::Kea::Dhcpv4 },
    'WebService::OPNsense::Kea::Dhcpv4 loads'
);

ok(
    lives { require WebService::OPNsense::Kea::Dhcpv6 },
    'WebService::OPNsense::Kea::Dhcpv6 loads'
);

ok(
    lives { require WebService::OPNsense::Kea::Leases },
    'WebService::OPNsense::Kea::Leases loads'
);

ok(
    lives { require WebService::OPNsense::Kea::Service },
    'WebService::OPNsense::Kea::Service loads'
);

ok(
    lives { require WebService::OPNsense::Normalize },
    'WebService::OPNsense::Normalize loads'
);

ok(
    lives { require WebService::OPNsense::Object },
    'WebService::OPNsense::Object loads'
);

ok(
    lives { require WebService::OPNsense::OpenVPN::ClientOverwrites },
    'WebService::OPNsense::OpenVPN::ClientOverwrites loads'
);

ok(
    lives { require WebService::OPNsense::OpenVPN::Export },
    'WebService::OPNsense::OpenVPN::Export loads'
);

ok(
    lives { require WebService::OPNsense::OpenVPN::Instances },
    'WebService::OPNsense::OpenVPN::Instances loads'
);

ok(
    lives { require WebService::OPNsense::OpenVPN::Service },
    'WebService::OPNsense::OpenVPN::Service loads'
);

ok(
    lives { require WebService::OPNsense::Routes },
    'WebService::OPNsense::Routes loads'
);

ok(
    lives { require WebService::OPNsense::System },
    'WebService::OPNsense::System loads'
);

ok(
    lives { require WebService::OPNsense::TrafficShaper::Service },
    'WebService::OPNsense::TrafficShaper::Service loads'
);

ok(
    lives { require WebService::OPNsense::TrafficShaper::Settings },
    'WebService::OPNsense::TrafficShaper::Settings loads'
);

ok(
    lives { require WebService::OPNsense::Unbound::Diagnostics },
    'WebService::OPNsense::Unbound::Diagnostics loads'
);

ok(
    lives { require WebService::OPNsense::Unbound::Overview },
    'WebService::OPNsense::Unbound::Overview loads'
);

ok(
    lives { require WebService::OPNsense::Unbound::Service },
    'WebService::OPNsense::Unbound::Service loads'
);

ok(
    lives { require WebService::OPNsense::Unbound::Settings },
    'WebService::OPNsense::Unbound::Settings loads'
);

done_testing;

#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Deep;

use FindBin;
use lib "$FindBin::Bin/../../../../lib";
use Test::WWW::LogicBoxes qw( create_api );
use Test::WWW::LogicBoxes::Domain qw( create_domain );

use WWW::LogicBoxes::PrivateNameServer;

my $logic_boxes = create_api();

subtest 'Rename Private Nameserver For Domain That Does Not Exist' => sub {
    throws_ok {
        $logic_boxes->rename_private_nameserver(
            domain_id => 999999999,
            old_name  => 'ns1.does-not-exist.com',
            new_name  => 'ns3.does-not-exist.com',
        );
    } qr/No such domain/, 'Throws on domain that does not exist';
};

subtest 'Rename Private Nameserver That Does Not Exist' => sub {
    my $domain = create_domain();

    throws_ok {
        $logic_boxes->rename_private_nameserver(
            domain_id => $domain->id,
            old_name  => 'ns1.' . $domain->name,
            new_name  => 'ns3.' . $domain->name,
        );
    } qr/No such existing private nameserver/, 'Throws on private nameserver that does not exist';
};

subtest 'Rename Private Nameserver To Invalid Domain' => sub {
    my $domain = create_domain();
    my $private_nameserver = WWW::LogicBoxes::PrivateNameServer->new(
        domain_id => $domain->id,
        name      => 'ns1.' . $domain->name,
        ips       => [ '4.2.2.1', '8.8.8.8' ],
    );

    lives_ok {
        $logic_boxes->create_private_nameserver( $private_nameserver );
    } 'Lives through creation of private nameserver';

    subtest 'Domain Not Registered With LogicBoxes' => sub {
        throws_ok {
            $logic_boxes->rename_private_nameserver(
                domain_id => $domain->id,
                old_name  => $private_nameserver->name,
                new_name  => 'ns3.does-not-match-domain.com',
            );
        } qr/Invalid domain for private nameserver/, 'Throws on private nameserver that has invalid name';
    };

    subtest 'Registered But Not Matching' => sub {
        my $unmatching_domain = create_domain();
        throws_ok {
            $logic_boxes->rename_private_nameserver(
                domain_id => $domain->id,
                old_name  => $private_nameserver->name,
                new_name  => 'ns1.' . $unmatching_domain->name,
            );
        } qr/Invalid domain for private nameserver/, 'Throws on private nameserver that has invalid name';
    };
};

subtest 'Rename Private Nameserver To Private Nameserver That Already Exists' => sub {
    my $domain = create_domain();
    my $private_nameserver = WWW::LogicBoxes::PrivateNameServer->new(
        domain_id => $domain->id,
        name      => 'ns1.' . $domain->name,
        ips       => [ '4.2.2.1' ],
    );

    lives_ok {
        $logic_boxes->create_private_nameserver( $private_nameserver );
    } 'Lives through creation of private nameserver';

    subtest 'Rename Without Changing Name' => sub {
        throws_ok {
            $logic_boxes->rename_private_nameserver(
                domain_id => $domain->id,
                old_name  => $private_nameserver->name,
                new_name  => $private_nameserver->name,
            );
        } qr/Same value for old and new private nameserver name/, 'Throws on private nameserver that has duplicate name';
    };

    subtest 'Rename To Duplicate Private Nameserver' => sub {
        my $existing_private_nameserver = WWW::LogicBoxes::PrivateNameServer->new(
            domain_id => $domain->id,
            name      => 'ns2.' . $domain->name,
            ips       => [ '8.8.8.8' ],
        );

        lives_ok {
            $logic_boxes->create_private_nameserver( $existing_private_nameserver );
        } 'Lives through creation of private nameserver';

        throws_ok {
            $logic_boxes->rename_private_nameserver(
                domain_id => $domain->id,
                old_name  => $private_nameserver->name,
                new_name  => $existing_private_nameserver->name,
            );
        } qr/A nameserver with that name already exists/, 'Throws on private nameserver that has duplicate name';
    };
};

subtest 'Rename Private Nameserver' => sub {
    my %ips = (
        IPv4 => [ '4.2.2.1', '8.8.8.8' ],
        IPv6 => [ '2001:4860:4860:0:0:0:0:8844', '2001:4860:4860:0:0:0:0:8888' ],
    );

    for my $ip_version ( keys %ips ) {
        subtest $ip_version => sub {
            my $ips = $ips{ $ip_version };

            my $domain = create_domain();
            my $private_nameserver = WWW::LogicBoxes::PrivateNameServer->new(
                domain_id => $domain->id,
                name      => 'ns1.' . $domain->name,
                ips       => $ips,
            );

            lives_ok {
                $logic_boxes->create_private_nameserver( $private_nameserver );
            } 'Lives through creation of private nameserver';

            lives_ok {
                $logic_boxes->rename_private_nameserver(
                    domain_id => $domain->id,
                    old_name  => $private_nameserver->name,
                    new_name  => 'ns3.' . $domain->name,
                );
            }  'Lives through renaming private name server';

            my $retrieved_domain = $logic_boxes->get_domain_by_id( $domain->id );
            if( cmp_ok( scalar @{ $retrieved_domain->private_nameservers }, '==', 1, 'Correct number of private nameservers' ) ) {
                my $retrieved_private_nameserver = $retrieved_domain->private_nameservers->[0];

                cmp_ok( $retrieved_private_nameserver->name, 'eq', 'ns3.' . $domain->name, 'Correct name' );
                cmp_bag( $private_nameserver->ips, $retrieved_private_nameserver->ips, 'Correct ips' );
            }
        };
    }
};

done_testing;

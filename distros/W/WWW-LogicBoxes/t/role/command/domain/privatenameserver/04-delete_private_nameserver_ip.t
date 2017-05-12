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

subtest 'Delete Private Nameserver IP for Domain That Does Not Exist' => sub {
    throws_ok {
        $logic_boxes->delete_private_nameserver_ip(
            domain_id => 999999999,
            name      => 'ns1.does-not-exist.com',
            ip        => '4.2.2.1',
        );
    } qr/No such domain/, 'Throws on domain that does not exist';
};

subtest 'Delete Private Nameserver IP for Nameserver That Does Not Exist' => sub {
    my $domain = create_domain();

    throws_ok {
        $logic_boxes->delete_private_nameserver_ip(
            domain_id => $domain->id,
            name      => 'ns1.' . $domain->name,
            ip        => '4.2.2.1',
        );
    } qr/No such existing private nameserver/, 'Throws on private nameserver that does not exist';
};

subtest 'Delete Private Nameserver IP for Nameserver That Lacks that IP' => sub {
    my $domain = create_domain();

    my $private_nameserver = WWW::LogicBoxes::PrivateNameServer->new(
        domain_id => $domain->id,
        name      => 'ns1.' . $domain->name,
        ips       => [ '4.2.2.1' ],
    );

    lives_ok {
        $logic_boxes->create_private_nameserver( $private_nameserver );
    } 'Lives through creating private nameserver';

    throws_ok {
        $logic_boxes->delete_private_nameserver_ip(
            domain_id => $domain->id,
            name      => $private_nameserver->name,
            ip        => '8.8.8.8',
        );
    } qr/IP address not assigned to private nameserver/, 'Throws on ip address not assigned';
};

subtest 'Delete Private Nameserver IP' => sub {
    my %ips = (
        IPv4 => [ '8.8.4.4', '8.8.8.8' ],
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
            } 'Lives through creating private nameserver';

            subtest 'Delete First IP' => sub {
                lives_ok {
                    $logic_boxes->delete_private_nameserver_ip(
                        domain_id => $domain->id,
                        name      => $private_nameserver->name,
                        ip        => $ips->[0],
                    );
                } 'Lives through deleting ip';

                my $retrieved_domain = $logic_boxes->get_domain_by_id( $domain->id );

                if( cmp_ok( scalar @{ $retrieved_domain->private_nameservers }, '==', 1, 'Correct number of private nameservers' ) ) {
                    my $retrieved_private_nameserver = $retrieved_domain->private_nameservers->[0];

                    cmp_bag( $retrieved_private_nameserver->ips, [ $ips->[1] ], 'Correct ips' );
                }
            };

            subtest 'Delete Last IP' => sub {
                lives_ok {
                    $logic_boxes->delete_private_nameserver_ip(
                        domain_id => $domain->id,
                        name      => $private_nameserver->name,
                        ip        => $ips->[1],
                    );
                } 'Lives through deleting ip';

                my $retrieved_domain = $logic_boxes->get_domain_by_id( $domain->id );

                ok( !$retrieved_domain->has_private_nameservers, 'Correctly lacks private nameservers' );
            };
        };
    }
};

done_testing;

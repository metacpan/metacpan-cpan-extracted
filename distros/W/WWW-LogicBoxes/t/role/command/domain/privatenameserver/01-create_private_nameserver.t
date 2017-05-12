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

subtest 'Create Private Nameserver for Domain That Does Not Exist' => sub {
    my $private_nameserver = WWW::LogicBoxes::PrivateNameServer->new(
        domain_id => 999999999,
        name      => 'ns1.does-not-exist.com',
        ips       => [ '4.2.2.1', '8.8.8.8' ],
    );

    throws_ok {
        $logic_boxes->create_private_nameserver( $private_nameserver );
    } qr/No such domain/, 'Throws on invalid domain';
};

subtest 'Create Private Nameserver That Does Not Match Domain' => sub {
    my $domain = create_domain();

    my $private_nameserver = WWW::LogicBoxes::PrivateNameServer->new(
        domain_id => $domain->id,
        name      => 'ns1.does-not-match.com',
        ips       => [ '4.2.2.1', '8.8.8.8' ],
    );

    throws_ok {
        $logic_boxes->create_private_nameserver( $private_nameserver );
    } qr/A Child Name Servers can only be registered under your Domain Name/, 'Throws on domain not matching';
};

subtest 'Create Private Nameservers For Valid Domain' => sub {
    my %ips = (
        IPv4 => [ '8.8.4.4', '8.8.8.8' ],
        IPv6 => [ '2001:4860:4860:0:0:0:0:8844', '2001:4860:4860:0:0:0:0:8888' ],
    );

    for my $ip_version ( keys %ips ) {
        subtest $ip_version => sub {
            my $ips = $ips{ $ip_version },

            my $domain = create_domain();
            my @private_nameservers;

            subtest 'Create Private Nameservers' => sub {
                subtest 'Create ns1' => sub {
                    push @private_nameservers, WWW::LogicBoxes::PrivateNameServer->new(
                        domain_id => $domain->id,
                        name      => 'ns1.' . $domain->name,
                        ips       => $ips,
                    );

                    lives_ok {
                        $logic_boxes->create_private_nameserver( $private_nameservers[-1] );
                    } 'Lives through private nameserver creation';
                };

                subtest 'Create ns2' => sub {
                    push @private_nameservers, WWW::LogicBoxes::PrivateNameServer->new(
                        domain_id => $domain->id,
                        name      => 'ns2.' . $domain->name,
                        ips       => $ips,
                    );

                    lives_ok {
                        $logic_boxes->create_private_nameserver( $private_nameservers[-1] );
                    } 'Lives through private nameserver creation';
                };

                my $retrieved_domain = $logic_boxes->get_domain_by_id( $domain->id );

                cmp_bag( $retrieved_domain->private_nameservers, \@private_nameservers, 'Correct private_nameservers' );
            };

            subtest 'Assign Domain to Private Nameservers' => sub {
                lives_ok {
                    $logic_boxes->update_domain_nameservers(
                        id          => $domain->id,
                        nameservers => [ map { $_->name } @private_nameservers ],
                    );
                } 'Lives through assigning domain to private nameservers';

                my $retrieved_domain = $logic_boxes->get_domain_by_id( $domain->id );

                cmp_bag( $retrieved_domain->ns, [ map { $_->name } @private_nameservers ], 'Correct domain nameservers' );
            };
        };
    }
};

subtest 'Create Private Nameserver That Already Exist - Adds IP' => sub {
    my $domain = create_domain();

    subtest 'Create ns1' => sub {
        my $private_nameserver = WWW::LogicBoxes::PrivateNameServer->new(
            domain_id => $domain->id,
            name      => 'ns1.' . $domain->name,
            ips       => [ '4.2.2.1' ],
        );

        lives_ok {
            $logic_boxes->create_private_nameserver( $private_nameserver );
        } 'Lives through private nameserver creation';
    };

    subtest 'Add Additional IP to ns1' => sub {
        my $private_nameserver = WWW::LogicBoxes::PrivateNameServer->new(
            domain_id => $domain->id,
            name      => 'ns1.' . $domain->name,
            ips       => [ '8.8.8.8' ],
        );

        lives_ok {
            $logic_boxes->create_private_nameserver( $private_nameserver );
        } 'Lives through private nameserver creation';
    };

    my $retrieved_domain = $logic_boxes->get_domain_by_id( $domain->id );
    ok( ( grep { $_ eq '4.2.2.1' } @{ $retrieved_domain->private_nameservers->[0]->ips } ), 'Contains Initial IP' );
    ok( ( grep { $_ eq '8.8.8.8' } @{ $retrieved_domain->private_nameservers->[0]->ips } ), 'Contains Added IP' );
};

subtest 'Create Private Nameserver That Already Exist - Same IP' => sub {
    my $domain = create_domain();
    my $private_nameserver = WWW::LogicBoxes::PrivateNameServer->new(
        domain_id => $domain->id,
        name      => 'ns1.' . $domain->name,
        ips       => [ '4.2.2.1' ],
    );

    subtest 'Create ns1' => sub {
        lives_ok {
            $logic_boxes->create_private_nameserver( $private_nameserver );
        } 'Lives through private nameserver creation';
    };

    subtest 'Add Additional IP to ns1' => sub {
        throws_ok {
            $logic_boxes->create_private_nameserver( $private_nameserver );
        } qr/Nameserver with this IP Address already exists/, 'Dies with conflicting IP Address';
    };

    my $retrieved_domain = $logic_boxes->get_domain_by_id( $domain->id );
    ok( ( grep { $_ eq '4.2.2.1' } @{ $retrieved_domain->private_nameservers->[0]->ips } ), 'Contains Initial IP' );
};

done_testing;

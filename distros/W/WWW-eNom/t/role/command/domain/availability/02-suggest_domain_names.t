#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Warn;
use String::Random qw(random_string);
use MooseX::Params::Validate;

use FindBin;
use lib "$FindBin::Bin/../../../../lib";
use Test::WWW::eNom qw( create_api mock_response );

use WWW::eNom::Types qw( Bool DomainAvailabilities Int Str Strs );
use WWW::eNom::DomainAvailability;

use List::Util qw(first);

my $eNom = create_api();

subtest 'Suggest Names for Single TLD - With Related - 5 Results' => sub {
    test_suggest_names(
        phrase      => 'fast sports car',
        tlds        => [qw( com )],
        related     => 1,
        num_results => 5,
    );
};

subtest 'Suggest Names for Single TLD - No Related - 5 Results' => sub {
    test_suggest_names(
        phrase      => 'fast sports car',
        tlds        => [qw( com )],
        related     => 0,
        num_results => 5,
    );
};

subtest 'Suggest Names for Multiple TLD - With Related - 5 Results' => sub {
    test_suggest_names(
        phrase      => 'fast sports car',
        tlds        => [qw( com net tv )],
        related     => 1,
        num_results => 5,
    );
};

subtest 'Suggest Names for Multiple TLD - No Related - 5 Results' => sub {
    test_suggest_names(
        phrase      => 'fast sports car',
        tlds        => [qw( com net tv )],
        related     => 0,
        num_results => 5,
    );
};

done_testing;

sub test_suggest_names {
    my (%args) = validated_hash(
        \@_,
        phrase      => { isa => Str  },
        tlds        => { isa => Strs },
        related     => { isa => Bool },
        num_results => { isa => Int },
    );

    my $mocked_api = mock_response(
        method     => 'NameSpinner',
        response   => {
            namespin => {
                domains => {
                    domain => {
                        map {
                            (   $args{related}
                              ? random_string('ccccccccccccccc')
                              : random_string('cccccc') . join( '-', split( ' ', $args{phrase} ) ) )
                            => {
                                map { $_ => 'y' } @{ $args{tlds} }
                            }
                        } 1 .. $args{num_results}
                    }
                }
            }
        }
    );

    my $domain_availabilities;
    warnings_are {
        $domain_availabilities = $eNom->suggest_domain_names({
            phrase      => $args{phrase},
            tlds        => $args{tlds},
            related     => $args{related},
            num_results => $args{num_results},
        });
    } [ ], 'Lives through retrieving domain suggestions';

    $mocked_api->unmock_all;

    inspect_domain_availabilities(
        domain_availabilities => $domain_availabilities,
        phrase                => $args{phrase},
        tlds                  => $args{tlds},
        related               => $args{related},
        num_results           => $args{num_results},
    );

    return;
}

sub inspect_domain_availabilities {
    my (%args) = validated_hash(
        \@_,
        domain_availabilities => { isa => DomainAvailabilities },
        phrase                => { isa => Str },
        tlds                  => { isa => Strs },
        related               => { isa => Bool },
        num_results           => { isa => Int },
    );

    cmp_ok(scalar @{ $args{domain_availabilities} }, '==', $args{num_results} * ( scalar @{ $args{tlds} } ),
        'Correct number of results');

    for my $domain_availability (@{ $args{domain_availabilities} }) {
        subtest 'Inspecting Suggested Domain - ' . $domain_availability->name => sub {
            isa_ok($domain_availability, 'WWW::eNom::DomainAvailability');
            ok(( grep { $_ eq $domain_availability->tld } @{ $args{tlds} } ), 'tld is in list of requested tlds');
        };

        if( !$args{related} ) {
            my @keywords = split( ' ', $args{phrase} );

            ok( grep { $domain_availability->sld =~ m/$_/ } @keywords, 'Keyword appears in exact match' );
        }
    }

    return;
}

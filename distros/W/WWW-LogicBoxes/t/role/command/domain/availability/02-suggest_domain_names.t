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
use Test::WWW::LogicBoxes qw(create_api);

use WWW::LogicBoxes::Types qw( Bool DomainAvailabilities Int Str Strs );
use WWW::LogicBoxes::DomainAvailability;

use List::Util qw(first);

my $logic_boxes = create_api();

subtest 'Legacy Suggest Names for Single TLD - No Hyphen - No Related - 1 Result' => sub {
    legacy_test_suggest_names({
        phrase      => 'fast sports car',
        tlds        => [ 'com' ],
        hyphen      => 0,
        related     => 0,
        num_results => 1,
    });
};

subtest 'Legacy Suggest Names for Single TLD - No Hyphen - No Related - 5 Results' => sub {
    legacy_test_suggest_names({
        phrase      => 'fast sports car',
        tlds        => [ 'com' ],
        hyphen      => 0,
        related     => 0,
        num_results => 5,
    });
};

subtest 'Legacy Suggest Names for Single TLD - With Hyphen - No Related - 5 Results' => sub {
    legacy_test_suggest_names({
        phrase      => 'fast sports car',
        tlds        => [ 'com' ],
        hyphen      => 1,
        related     => 0,
        num_results => 5,
    });
};

subtest 'Legacy Suggest Names for Single TLD - No Hyphen - With Related - 5 Results' => sub {
    legacy_test_suggest_names({
        phrase      => 'fast sports car',
        tlds        => [ 'com' ],
        hyphen      => 0,
        related     => 1,
        num_results => 5,
    });
};

subtest 'Legacy Suggest Names for Single TLD - With Hyphen - With Related - 5 Results' => sub {
    legacy_test_suggest_names({
        phrase      => 'fast sports car',
        tlds        => [ 'com' ],
        hyphen      => 1,
        related     => 1,
        num_results => 5,
    });
};

subtest 'Legacy Suggest Names for Multiple TLD - No Hyphen - No Related - 5 Results' => sub {
    legacy_test_suggest_names({
        phrase      => 'fast sports car',
        tlds        => [ 'com', 'org', 'net' ],
        hyphen      => 0,
        related     => 0,
        num_results => 5,
    });
};

subtest 'Legacy Suggest Names for Multiple TLD - With Hyphen - No Related - 5 Results' => sub {
    legacy_test_suggest_names({
        phrase      => 'fast sports car',
        tlds        => [ 'com', 'org', 'net' ],
        hyphen      => 1,
        related     => 0,
        num_results => 5,
    });
};

subtest 'Legacy Suggest Names for Multiple TLD - No Hyphen - With Related - 5 Results' => sub {
    legacy_test_suggest_names({
        phrase      => 'fast sports car',
        tlds        => [ 'com', 'org', 'net' ],
        hyphen      => 0,
        related     => 1,
        num_results => 5,
    });
};

subtest 'Legacy Suggest Names for Multiple TLD - With Hyphen - With Related - 5 Results' => sub {
    legacy_test_suggest_names({
        phrase      => 'fast sports car',
        tlds        => [ 'com', 'org', 'net' ],
        hyphen      => 1,
        related     => 1,
        num_results => 5,
    });
};

subtest 'V5 Suggest Names for Single TLD - With Related - 5 Results' => sub {
    v5_test_suggest_names(
        phrase      => 'fast sports car',
        tlds        => [qw( com )],
        related     => 1,
        num_results => 5,
    );
};

subtest 'V5 Suggest Names for Single TLD - No Related - 5 Results' => sub {
    v5_test_suggest_names(
        phrase      => 'fast sports car',
        tlds        => [qw( com )],
        related     => 0,
        num_results => 5,
    );
};

subtest 'V5 Suggest Names for Multiple TLD - With Related - 5 Results' => sub {
    v5_test_suggest_names(
        phrase      => 'fast sports car',
        tlds        => [qw( com org net )],
        related     => 1,
        num_results => 5,
    );
};

subtest 'V5 Suggest Names for Multiple TLD - No Related - 5 Results' => sub {
    v5_test_suggest_names(
        phrase      => 'fast sports car',
        tlds        => [qw( com org net )],
        related     => 0,
        num_results => 5,
    );
};

done_testing;

sub legacy_test_suggest_names {
    my (%args) = validated_hash(
        \@_,
        phrase      => { isa => Str  },
        tlds        => { isa => Strs },
        hyphen      => { isa => Bool, optional => 1 },
        related     => { isa => Bool, optional => 1 },
        num_results => { isa => Int },
    );

    my @expected_warnings;
    exists $args{hyphen}  and push @expected_warnings, { carped => 'The hyphen argument is deprecated, please see POD for more information'  };

    my $domain_availabilities;
    warnings_are {
        $domain_availabilities = $logic_boxes->suggest_domain_names({
            phrase      => $args{phrase},
            tlds        => $args{tlds},
            hyphen      => $args{hyphen},
            related     => $args{related},
            num_results => $args{num_results},
        });
    } \@expected_warnings, 'Lives through retrieving domain suggestions';

    inspect_domain_availabilities(
        phrase                => $args{phrase},
        domain_availabilities => $domain_availabilities,
        tlds                  => $args{tlds},
        related               => $args{related},
        num_results           => $args{num_results},
    );

    return;
}

sub v5_test_suggest_names {
    my (%args) = validated_hash(
        \@_,
        phrase      => { isa => Str  },
        tlds        => { isa => Strs },
        related     => { isa => Bool },
        num_results => { isa => Int },
    );

    my $domain_availabilities;
    warnings_are {
        $domain_availabilities = $logic_boxes->suggest_domain_names({
            phrase      => $args{phrase},
            tlds        => $args{tlds},
            related     => $args{related},
            num_results => $args{num_results},
        });
    } [ ], 'Lives through retrieving domain suggestions';

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

    cmp_ok(scalar @{ $args{domain_availabilities} }, '==', $args{num_results} * scalar @{ $args{tlds} },
        'Correct number of results');

    for my $domain_availability (@{ $args{domain_availabilities} }) {
        subtest 'Inspecting Suggested Domain - ' . $domain_availability->name => sub {
            isa_ok($domain_availability, 'WWW::LogicBoxes::DomainAvailability');
            ok(( grep { $_ eq $domain_availability->tld } @{ $args{tlds} } ), 'tld is in list of requested tlds');
        };

        if( !$args{related} ) {
            my @keywords = split( ' ', $args{phrase} );

            push @keywords, 'auto' if( grep { $_ eq 'car' } @keywords );

            ok( grep { $domain_availability->sld =~ m/$_/ } @keywords, 'Keyword appears in exact match' );
        }
    }

    return;
}

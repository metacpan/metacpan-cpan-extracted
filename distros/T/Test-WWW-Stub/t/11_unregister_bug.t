use strict;
use warnings;
use Test::Tester; # Call before any other Test::Builder-based modules
use Test::More;
use Test::Deep qw( cmp_deeply re );
use Test::Warnings qw(:no_end_test warnings);
use parent qw( Test::Class );

use Test::WWW::Stub;
use LWP::UserAgent;

sub ua { LWP::UserAgent->new; }

sub test_pass {
    my ($sub) = shift;
    my ($premature, @results) = run_tests( $sub );
    return $results[0]->{ok};
}

sub issue_19 : Tests {
    my $self = shift;

    my $g1 = Test::WWW::Stub->register('https://example.com/OVERRIDE' => [ 500, [], [] ]);
    {
        my $code;
        my $warnings = [ warnings { $code = $self->ua->get('https://example.com/OVERRIDE')->code; } ];
        cmp_deeply $warnings, [], 'no warnings';
        is $code, 500, 'stub by g1';
    }

    my $g2 = Test::WWW::Stub->register('https://example.com/OVERRIDE' => [ 400, [], [] ]);
    {
        my $code;
        my $warnings = [ warnings { $code = $self->ua->get('https://example.com/OVERRIDE')->code; } ];
        cmp_deeply $warnings, [], 'no warnings';
        is $code, 400, 'stub by g2';
    }

    $g1 = undef;
    {
        my $code;
        my $warnings = [ warnings { $code = $self->ua->get('https://example.com/OVERRIDE')->code; } ];
        cmp_deeply $warnings, [], 'no warnings';
        is $code, 400, 'still stub by g2';
    }

    $g2 = undef;
    {
        my $code;
        my $warnings = [ warnings { $code = $self->ua->get('https://example.com/OVERRIDE')->code; } ];
        cmp_deeply $warnings, [ re('Unexpected external access:') ], 'warnings appeared';
    }
}

__PACKAGE__->runtests;

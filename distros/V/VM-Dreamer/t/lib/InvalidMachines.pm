package InvalidMachines;

use strict;
use warnings;

use VM::Dreamer::Error qw( missing_term invalid_term );

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw( get_invalid_init_tests );

# really, the keys in the hashes below are just 
# to keep track of what I'm testing for

my %missing_args = (

    missing_base => {
        term           => "base",

        op_code_width  => 5,
        operand_width  => 12,

        message        => "Caught absence of base in machine definition"
    },

    missing_op_code_width => {
        term           => "op_code_width",

        base           => 3,
        operand_width  => 15,

        message        => "Caught absense of op_code_width in machine's definition\n",
    },

    missing_operand_width => {
        term           => "operand_width",

        base           => 7,
        op_code_width  => 5,

        message        => "Caught absense of operand_width in machine's definition\n"
    }
);

my %non_numeric = (

    base_is_a_letter => {
        term           => "base",

        base           => 'abcd',
        op_code_width  => 4,
        operand_width  => 17,

        message        => "Caught non-numeric base\n"
    },

    op_code_is_a_float => {
        term           => "op_code_width",

        base           => 10,
        op_code_width  => 1.5,
        operand_width  => 5,

        message        => "Caught op_code_width passed as a float"
    }
);

my %out_of_range = (

    base_too_small => {
        term           => "base",

        base           => 1,
        op_code_width  => 5,
        operand_width  => 7,

        message        => "Caught undersized base"
    },

    base_too_big => {
        term           => "base",

        base           => 12,
        op_code_width  => 3,
        operand_width  => 9,

        message        => "Caught oversized base"
    },

    op_code_too_small => {
        term           => "op_code_width",

        base           => 8,
        op_code_width  => 0,
        operand_width  => 10,

        message        => "Caught undersized op_code"
    },

    op_code_too_big   => {
        term           => "op_code_width",

        base           => 5,
        op_code_width  => 512,
        operand_width  => 128,

        message        => "Caught oversized op_code"
    },

    operand_too_small => {
        term           => "operand_width",

        base           => 6,
        op_code_width  => 3,
        operand_width  => 0,

        message        => "Caught undersized operand"
    },

    operand_too_big => {
        term           => "operand_width",

        base           => 4,
        op_code_width  => 2,
        operand_width  => 1562,

        message        => "Caught oversize operand"
    },

    negative_operand => {
        term           => "operand_width",

        base           =>  7,
        op_code_width  =>  4,
        operand_width  => -5,

        message        => "Caught negative operand"
    }
        
);

sub get_missing_arg_tests {
    my @missing_arg_tests;

    foreach my $test ( keys %missing_args ) {
        push @missing_arg_tests, $missing_args{$test};
    }

    foreach my $test (@missing_arg_tests) {
        $test->{expected_error} = missing_term( $test->{term} );
    }

    return @missing_arg_tests;
}

sub get_non_numeric_tests {
    my @non_numeric_tests;

    foreach my $test ( keys %non_numeric ) {
        push @non_numeric_tests, $non_numeric{$test};
    }

    foreach my $test (@non_numeric_tests) {
        my $term  = $test->{term};
        my $value = $test->{$term};

        $test->{expected_error} = invalid_term( $term, $value ); 
    }

    return @non_numeric_tests;
}

sub get_out_of_range_tests {
    my @out_of_range_tests;

    foreach my $test ( keys %out_of_range ) {
        push @out_of_range_tests, $out_of_range{$test};
    }

    foreach my $test (@out_of_range_tests) {
        my $term  = $test->{term};
        my $value = $test->{$term};

        $test->{expected_error} = invalid_term( $term, $value );
    }

    return @out_of_range_tests;
}

sub get_invalid_init_tests {
    return (
        get_out_of_range_tests(),
        get_non_numeric_tests(),
        get_missing_arg_tests()
    );
}

1;

=pod

=head1 AUTHOR

William Stevenson <dreamer at coders dot coop>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by William Stevenson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)
 
=cut

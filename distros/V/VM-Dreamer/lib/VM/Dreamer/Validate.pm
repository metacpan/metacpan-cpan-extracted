package VM::Dreamer::Validate;

use strict;
use warnings;

our $VERSION = '0.851';

use VM::Dreamer::Environment qw( get_restrictions );
use VM::Dreamer::Error qw( missing_term invalid_term );

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw( validate_definition build_valid_line_regex get_valid_input_regex );

our $restrictions = get_restrictions();

sub validate_definition {
    my $machine_definition = shift;

    foreach my $term ( qw( base op_code_width operand_width ) ) { 
        unless ( defined $machine_definition->{$term} ) {
            die missing_term($term);
        }
        unless ( validate_term( $term, $machine_definition->{$term} ) ) {
            die invalid_term( $term, $machine_definition->{$term} );
        }
    }

    return 1;
}

sub validate_term {
    my( $term, $value ) = @_;

    if( $value !~ /^[1-9]\d*$/ ) {
        return 0;
    }
    elsif( $value < $restrictions->{$term}->{min} ||
           $value > $restrictions->{$term}->{max} ) {
        return 0;
    }
    else {
        return 1;
    }
}

sub build_valid_line_regex {
    my $machine = shift;

    my( $greatest_digit, $operand_width, $instruction_width ) = (
        $machine->{meta}->{greatest}->{digit},
        $machine->{meta}->{width}->{operand},
        $machine->{meta}->{width}->{instruction}
    );

    # consider replacing above with a slice

    if ( ! defined $greatest_digit ) {
        die "Please pass the machine's greatest digit to build_valid_line_regex\n";
    }
    elsif ( ! defined $operand_width ) {
        die "Please pass the machine's op code width to build_valid_line_regex\n";
    }
    elsif( ! defined $instruction_width ) {
        die "Please pass the machine's instruction width to build_valid_line_regex\n";
    }

    return qr/^[0-$greatest_digit]{$operand_width}\t[0-$greatest_digit]{$instruction_width}$/;

}

sub get_valid_input_regex {
    my $machine = shift;

    my $greatest_digit    = $machine->{meta}->{greatest}->{digit};
    my $instruction_width = $machine->{meta}->{width}->{instruction};

    return qr/^[0-$greatest_digit]{$instruction_width}$/;
}
# should be consistent on naming of functions - either call them get_valid
# or build_valid, but not have one build_valid_line_regex and the other
# get_valid_input_regex

# sub validate_program_line {
#     my $line = shift;
#     my $meta = shift;
# 
#     my $greatest_digit  = $meta->{greatest_digit};
#     my $operand_width   = $meta->{operand_width};
#     my $total_width     = $meta->{total_width};
# 
#     my $regex = qr/^[0-$greatest_digit]{$operand_width}\t[0-$greatest_digit]{$total_width}$/; 
# 
#     if ( $line =~ $regex ) {
#         return;
#     }
#     else {
#         die "Line was not properly formatted: $line\n";
#     }
# }

1;

=pod

=head1 NAME

VM::Dreamer::Validate - Quality In / Quality Out

=head1 SYNOPSIS

validate_definition( $machine_definition );

=head1 DESCRIPTION

These functions help make sure that what comes in is what is expected.

=head2 validate_definition

Validates the machine's definition. Returns 1 if the definition is value. Otherwise it raises an exception.

=head2 build_valid_line_regex

Takes the machine's greatest digit, operand_width and instruction_width and returns a regex corresponding to a valid line in an input file to your machine.

my $machine = {
    meta => {
        greatest => {
            digit  => 9,
        },
    },
    width => {
        operand     => 2,
        instruction => 3,
    },
};
my $valid_line = build_valid_line_regex($machine); # qr/^[0-9]{2}\t[0-9]{3}$/

my $machine = {
    meta => {
        greatest => {
            digit  => 8,
        },
    },
    width => {
        operand     => 6,
        instruction => 8,
    },
};
my $valid_line = build_valid_line_regex($machine); # qr/^[0-7]{6}\t[0-7]{8}$/

=head2 get_valid_input_regex

my $machine = {
    meta => {
        greatest => {
            digit => 1,
        },
    },
    width => {
        instruction => 16,
    },
};
my $valid_input = get_valid_input_regex($machine); # qr/^[0-1]{16}$/

=head1 AUTHOR

William Stevenson <william at coders dot coop>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by William Stevenson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)
 
=cut

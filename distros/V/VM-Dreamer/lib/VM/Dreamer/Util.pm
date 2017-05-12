package VM::Dreamer::Util;

use strict;
use warnings;

our $VERSION = '0.851';

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw( stringify_array arrayify_string parse_program_line parse_next_instruction add_two_arrays subtract_two_arrays );

sub stringify_array {
   my $aref = shift;
   return join( '', @$aref );
}

sub arrayify_string {
    my $string = shift;
    return [ split //, $string ];
}

sub parse_program_line {
    my $line = shift;
    return split /\t/, $line;
}

sub parse_next_instruction {
    my $machine = shift;

    my ( $op_code, $operand );

    my $little_endian_instruction = reverse $machine->{next_instruction};

    for ( my $i = 0; $i < $machine->{meta}->{width}->{op_code}; $i++ ) {
        my $digit = chop $little_endian_instruction;
        $op_code .= $digit;
    }
 
    if( length $little_endian_instruction != $machine->{meta}->{width}->{operand} ) {
        die "Operand was not of expected width in instruction: $machine->{next_instruction}"; # want to give programmer better feedback here
    }
    else {
        $operand = reverse $little_endian_instruction;
    }

    return $op_code, $operand;
}

sub add_two_arrays {
    my ( $augend, $addend, $greatest_digit ) = @_;

    my @little_auggie = reverse @$augend;
    my @little_addie  = reverse @$addend;

    if ( @little_addie != @little_auggie ) {
        die "The augend and addend are not of the same length: " . stringify_array( $augend ) . " " . stringify_array( $addend ) . "\n";
    }

    # When I want to store a "stringteger" I think of it from left to
    # right, but when I want to operate on one, it's easier for me to
    # do so on its mirror image 

    for ( my $i = 0; $i <= $#little_auggie; $i++ ) {
        my $k = $i + 1;

        for ( my $j = $little_addie[$i] - 1; $j >= 0; $j-- ) {

            if ( $little_auggie[$i] < $greatest_digit ) {
	        $little_auggie[$i]++;
            }
            else {
		$little_auggie[$i] = $j;

		while ( $k <= $#little_auggie && $little_auggie[$k] == $greatest_digit ) {
		    $little_auggie[$k] = 0;
		    $k++;
                }

	        if ( $k <= $#little_auggie ) {
	            $little_auggie[$k]++;
		}
	
	        last;	
	    }
	}
    }

    return [ reverse @little_auggie ];
}

sub subtract_two_arrays {
    my ( $minuend, $subtrahend, $greatest_digit ) = @_;

    my $n_flag = 0;

    my @little_minnie = reverse @$minuend;
    my @little_subbie = reverse @$subtrahend;

    if ( scalar @little_minnie != scalar @little_subbie ) {
        die "The minuend and subtrahend are not of the same length: " . stringify_array($minuend) . " " . stringify_array($subtrahend) . "\n";
    }

    SUBTR_LOOP:
    for ( my $i = 0; $i <= $#little_minnie; $i++ ) {
	for ( my $j = $little_subbie[$i] - 1; $j >= 0; $j-- ) {
	    if ( $little_minnie[$i] > 0 ) {
	        $little_minnie[$i]--;
	    }
	    else {
	        my $k = $i + 1;

		while ( $k <= $#little_minnie && $little_minnie[$k] == 0 ) {
                    $little_minnie[$k] = $greatest_digit;
		    $k++;
                }

		if ( $k > $#little_minnie ) {
		    $n_flag = 1;
		    last SUBTR_LOOP;
		}
		else {
                    $little_minnie[$k]--;
                    $little_minnie[$i] = $greatest_digit;
		}
	    }
	}
    }

    return [ reverse @little_minnie ], $n_flag ;
}

1;

=pod

=head1 NAME

VM::Dreamer::Util - Utilities for Deamer

=head1 DESCRIPTION

These functions contain some of the core logic in Dreamer and help the higher level functions do their work.

=head2 stringify_array

Takes an array of single digits and turns it into a string;

my $string = stringify_array( [ 5, 3, 2, 1, 0, 8, 7, 5 ] ); # '53210875'

=head2 arrayify_string

Take a string of single digits and turns each one into successive elements of an array. Returns a reference to said array.

my $aref = arrayify_string('53210875'); # [ 5, 3, 2, 1, 0, 7, 7, 5 ]

=head2 parse_program_line

Takes a line of input from a program for your machine and returns the address in which to store the instruction and the instruction itself.

my ( $address, $instruction ) = parse_program_line("15\t342"); ( 15, 342 )

This function really just splits on the separator.

=head2 parse_next_instruction

Splits an instruction into the op_code and the operand.

my $machine = {
    next_instruction => '1101011100111010',
    meta => {
        width => {
            op_code => 4,
            operand => 12,
        },
    },
};
my( $op_code, $operand ) = parse_next_instruction($machine);
# ( 1101, 11100111010 );

=head2 add_two_arrays

Takes two references to arrays whose elements are single digits and the greatest value for any of the digits and adds them together.

my $augend = [ 0, 5, 3, 2 ];
my $addend = [ 3, 9, 4, 8 ];

my $greatest_digit = 9;

my $sum = add_two_arrays( $augend, $addend, $greatest_digit );
# [ 4, 4, 8, 0 ]

Really, this is just adding 532 and 3948, but since the base is arbitrary, I found it easier to implement in this way.

The arrays are almost like old-fashioned adding machines where each element is a "wheel" of digits and the greatest_digit tells you when to carry.

=head2 subtract_two_arrays
 
my $minuend    = [ 1, 0, 1, 1, 0, 0, 1, 0 ];
my $subtrahend = [ 1, 0, 0, 0, 1, 0, 1, 0 ];

my $greatest_digt = 1;

my $difference = subtract_two_arrays( $minuend, $subtrahend, $greatest_digit );
# [ 0, 0, 1, 0, 0, 1, 0, 0 ]

Similarly to carrying in addition, greatest_digit helps us when we need to borrow during subtraction.

=head1 AUTHOR

William Stevenson <william at coders dot coop>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by William Stevenson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)
 
=cut

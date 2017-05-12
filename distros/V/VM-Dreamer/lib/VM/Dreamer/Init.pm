package VM::Dreamer::Init;

use strict;
use warnings;

our $VERSION = '0.851';

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw( init_counter greatest_digit greatest_number total_width );

sub init_counter {
    my $width = shift;

    my @array;

    for ( my $i = 0; $i < $width; $i++ ) {
        push @array, 0;
    }

    return \@array;
}

sub greatest_digit {
    my $base = shift;
    return $base - 1;
}

# should just be able to pass 1 to greatest_number

# also, probably don't need to initialize
# $greatest_number to an empty string

sub greatest_number {
    my ( $base, $width ) = @_;

    unless ( $base && $width ) {
        die "Please pass the machine's base and this number's width\n";
    }

    my $greatest_digit  = greatest_digit($base);
    my $greatest_number = '';

    for ( my $i = 1; $i <= $width; $i++ ) {
        $greatest_number .= $greatest_digit;
    }

    return $greatest_number;
}

sub total_width {
    my @instruction_part_lengths = @_;

    my $total_width = 0;

    foreach my $width (@instruction_part_lengths) {
        unless( $width =~ /^0$/ || $width =~ /^[1-9]\d*$/ ) {
            die "The widths may only be zero or a positive interger";
        }
        else {
            $total_width += $width;
        }
    }

    return $total_width;
}

1;

# init_counter takes an integer n and return a reference to an array which has n elements, each of which are 0

# greatest digit takes a number n (the base) and returns n - 1

# greatest_number takes two numbers n and r and returns a number p which has r digits, each of which are n

# total width taks two numbers n and r and returns n + r

=pod

=head1 NAME

VM::Dreamer::Init - Functions to help with Initialization

=head1 SYNOPSIS

my $counter         = init_counter(8);         # [ 0, 0, 0, 0, 0, 0, 0, 0 ]
my $greatest_digit  = greatest_digit(8);       # 7
my $greatest_number = greatest_number( 10, 4); # '9999'
my $total_width     = total_width( 1, 2 );     # 3

=head1 DESCRIPTION

=head2 init_counter

Takes a positive integer n and returns a reference to an an array of n elements, each of which is 0.

In Dreamer, counters are machine parts like the counter and the accumulator.

=head2 greatest_digit

Takes a positive integer n and returns n - 1. Really only meant to be used for n from 2 to 10 inclusive, though no validation is performed here. The idea is that if the base is 8, the greatest digit would be 7.

=head2 greatest_number

Given a base and a width, returns a string of n digits, each of which is one less then the base.

For example, if the base is 2 and the width is 9, the greatest_number would be 111111111.

=head2 total_width

Just adds up the elements in an array, but also performes validation checking to make sure that each element is zero or a positive integer.

For example, if the op_code_width is 4 and the operand width is 12, the total_width would be 16. This is useful for figuring out how long an instruction is given the widths of its parts.

As Dreamer only operates on one operand machines right now, this will really only be passed 2 elements in the array - the op_code_width and the operand_width. But, I decided to generalize it for use later.

=head1 AUTHOR

William Stevenson <william at coders dot coop>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by William Stevenson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)
 
=cut

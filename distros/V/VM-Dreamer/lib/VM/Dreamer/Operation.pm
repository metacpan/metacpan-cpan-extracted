package VM::Dreamer::Operation;

use strict;
use warnings;

our $VERSION = '0.851';

use VM::Dreamer::Init qw( total_width greatest_digit greatest_number init_counter );

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw( get_new_machine add_one_to_counter );

sub get_new_machine {
    my ( $base, $op_code_width, $operand_width, $instruction_set ) = @_;

    my $total_width    = total_width( $op_code_width, $operand_width ); 
    my $greatest_digit = greatest_digit($base);

    my %machine = (
        memory      => {},

        inbox       => [],
        outbox      => [],

        n_flag      => 0,
        halt        => 0,

        next_instr  => '',

        instruction_set => $instruction_set,
    );

    @machine{ 'counter', 'accumulator' } = (
        init_counter($operand_width),
        init_counter($total_width)
    );

    $machine{meta} = {
        base  => $base,
        width => {
            op_code     => $op_code_width,
            operand     => $operand_width,
            instruction => $total_width
        },
        greatest => {
            digit       => $greatest_digit,
            op_code     => greatest_number( $base, $op_code_width ),
            operand     => greatest_number( $base, $operand_width),
            instruction => greatest_number( $base, $total_width )
        }
    };

    return \%machine;
}

sub add_one_to_counter {
    my ( $counter, $greatest_digit ) = @_;

    my $i          = 0;
    my $carry_flag = 0;

    my @little_endian_counter = reverse @$counter;

    if ( $little_endian_counter[0] < $greatest_digit ) {
        $little_endian_counter[0]++;
    }
    else {
        while ( $i <= $#little_endian_counter && $little_endian_counter[$i] == $greatest_digit ) {
           $little_endian_counter[$i] = 0;
           $i++;
        }
        if ( $i <= $#little_endian_counter ) {
            $little_endian_counter[$i]++;
        }
    }

    return [ reverse @little_endian_counter ];
}

1;

=pod

=head1 NAME

VM::Dreamer::Operations - Help with the machine's operation 

=head1 SYNOPSIS

my $machine = get_new_machine( $base, $op_code_width, $operand_width, $instruction_set );
add_one_to_counter( $counter, $greatest_digit );

=head1 DESCRIPTION

=head2 get_new_machine

This function is called by VM::Dreamer::initialize_machine after it has validated the machine's definition.

It sets the initial values for the machine's components as based on the machine's definition.

It returns a reference to the newly initialized machine.

=head2 add_one_to_counter

Used by VM::Dreamer::increment_counter.

Does just what it says - increments the counter by 1. It uses greatest_digit to know when to carry from one column to the next.

For example, if the machine's greatest digit was 7 and the counter was set to 5473777, this function would return 5474000.

Or, if the machine's greatest digit was 9 and the counter was set to 10259, this fuction would return 10260.

It should be undefined what happens when the maximum value of the counter is passed to this function (but it just returns all zero's).

=head1 SEE ALSO

VM::Dreamer::initialize_machine
VM::Dreamer::increment_counter

=head1 AUTHOR

William Stevenson <william at coders dot coop>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by William Stevenson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)
 
=cut

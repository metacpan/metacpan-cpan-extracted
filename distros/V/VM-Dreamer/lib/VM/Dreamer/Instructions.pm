package VM::Dreamer::Instructions;

use strict;
use warnings;

our $VERSION = '0.851';

use VM::Dreamer::IO qw( get_valid_input_from_user add_input_to_inbox shift_inbox_to_memory add_to_outbox shift_outbox_to_user );
use VM::Dreamer::Util qw( arrayify_string stringify_array add_two_arrays subtract_two_arrays );

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw( input_to_mb output_from_mb store load add subtract branch_always branch_if_zero branch_if_positive halt );

sub input_to_mb {
    my ( $machine, $operand ) = @_;

    my $input = get_valid_input_from_user($machine);

    add_input_to_inbox( $machine, $input );

    shift_inbox_to_memory( $machine, $operand );

    return 0;
}

sub output_from_mb {
    my ( $machine, $operand ) = @_;

    add_to_outbox( $machine, $operand );

    shift_outbox_to_user($machine);

    return 0;
}

sub store {
    my ( $machine, $operand ) = @_;

    $machine->{memory}->{$operand} = stringify_array( $machine->{accumulator} );

    return 0;

    # Assuming that operand is a valid mailbox value
}

sub load {
    my ( $machine, $operand ) = @_;

    if ( $machine->{memory}->{$operand} ) {
        $machine->{accumulator} = arrayify_string( $machine->{memory}->{$operand} );
        $machine->{n_flag}      = 0;
    }
    else {
        die "No value stored at address $operand to load onto the accumulator\n";
    }

    return 0;
}

sub add {
    my ( $machine, $operand ) = @_;

    my $augend = $machine->{accumulator};
    my $addend = arrayify_string( $machine->{memory}->{$operand} );

    $machine->{accumulator} = add_two_arrays( $augend, $addend, $machine->{meta}->{greatest}->{digit} );

    return 0;
}

sub subtract {
    my ( $machine, $operand ) = @_;

    my $minuend    = $machine->{accumulator};
    my $subtrahend = arrayify_string( $machine->{memory}->{$operand} );

    ( $machine->{accumulator}, $machine->{n_flag} ) = subtract_two_arrays( $minuend, $subtrahend, $machine->{meta}->{greatest}->{digit} );

    return 0;
}

sub branch_always {
    my ( $machine, $operand ) = @_;

    $machine->{counter} = arrayify_string($operand);

    return 0;
}

sub branch_if_zero {
    my ( $machine, $operand ) = @_;

    my $accumulator = stringify_array( $machine->{accumulator} );

    if ( $accumulator == 0 ) {
        $machine->{counter} = arrayify_string($operand);
    }

    # in Perl, a string of zeros is treated as the number 0 when used
    # in numeric context, e.g. '000' == 0 would be true

    return 0;
}

sub branch_if_negative {
    my ( $machine, $operand ) = @_;

    if ( $machine->{n_flag} == 1 ) {
        $machine->{counter} = arrayify_string($operand);
    }

    return 0;
}

sub branch_if_positive {
    my ( $machine, $operand ) = @_;

    my $accumulator = stringify_array( $machine->{counter} );

    if ( $accumulator > 0 && $machine->{n_flag} == 0 ) {
        $machine->{counter} = arrayify_string($operand);
    }

    # just like above, in Perl, a sting of numbers is treated like
    # the number itself and padded zeros are ignored when used
    # in numeric context

    # e.g. '0050' > 0 would be true, so there is no need, in this
    # language, to strip them

    return 0;
}

sub halt {
    my $machine = shift;

    $machine->{halt} = 1;

    return 0;
}

1;

=pod

=head1 NAME

VM::Dreamer::Instructions - The heavy lifting

=head1 SYNOPSIS

input_to_mb( $machine, '72' );
output_from_my( $machine, $operand );
store( $machine, $operand );
load( $machine, $operand );
add( $machine, $operand );
subtract( $machine, $operand );
branch_always( $machine, $operand );
branch_if_zero( $machine, $operand );
branch_if_negative( $machine, $operand );
branch_if_positive( $machine, $operand );
halt($machine);

=head1 DESCRIPTION

These functions will be used in a dispatch table in VM::Dreamer::Languages::YourMachine where you map your operation codes to these functions.

A base 10 machine with an op code width of 1 might map op code 7 to branch_always. A base 2 machine with an opcode width of 4 might map 0101 to subtract.

For an example, see VM::Dreamer::Languages::Grasshopper

If you'd like to add more instructions, you can do so here in VM::Dreamer::Instructions and send me a pull request. You can also use VM::Dreamer::Local for your own code.

=head2 input_to_mb

input_to_mb( $machine, '72' );

Prompts the user for input and, if valid, stores their input in memory at address '72'.

=head2 output_from_mb 

output_from_mb( $machine, '72' );

Outputs the value stored in memory at address '72' to the user.

=head2 store

store( $machine, '1011101' );

Stores the value on the accumulator at address '1011101' in memory.

=head2 load

load( $machine, '271104523210' );

Loads the value stored in memory at address '271104523210' onto the accumulator.

=head2 add

add( $machine, '10011100101001' );

Adds the value stored in memory at address '10011100101001' to the current value on the accumulator.

=head2 subtract( $machine, '9744321229' );

Subtracts the value stored in memory at address '9744321229' from the current value on the accumulator.

If the resulting value is negative, the negative flag is set and the remaining value on the accumulator is undefined.

=head2 branch_always

branch_always( $machine, '432' );

Sets the value of the counter to 432, always.

This means that the next instruction executed will be fetched from address 432 in memory.

=head2 branch_if_zero

branch_if_zero( $machine, '34221023' );

Sets the value of the counter to 34221023 if the value on the accumulator is zero.

In other words, if the accumulator is zero, fetch the next instruction from address 34221023 in memory.

=head2 branch_if_negative

branch_if_negative( $machine, '1521532' );

Sets the value of the counter to 1521532 if the negative flag is set.

In other words, if the negative flag is set, fetch the next instruction from address 1521532 in memory.

=head2 branch_if_positive

branch_if_positive( $machine, '92345' );

Sets the value of the counter to 92345 if the value on the accumulator is greater than zero and the negative flag is not set.

In other words, if the negative flag is unset and the accumulator is greater than 0, fetch the next instruction from address 92345 in memory.

=head2 halt

halt($machine);

Sets the halt flag to 1. This means that the machine should cease operation.

=head1 SEE ALSO

VM::Dreamer::execute_next_instruction
VM::Dreamer::Languages::Grasshopper

=head1 AUTHOR

William Stevenson <william at coders dot coop>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by William Stevenson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)
 
=cut

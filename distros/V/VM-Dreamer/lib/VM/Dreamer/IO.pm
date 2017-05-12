package VM::Dreamer::IO;

use strict;
use warnings;

our $VERSION = '0.851';

use VM::Dreamer::Validate qw{ get_valid_input_regex };

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw( get_valid_input_from_user add_input_to_inbox shift_inbox_to_memory add_to_outbox shift_outbox_to_user );

sub get_valid_input_from_user {
    my $machine = shift;
    my $max_tries = 5;

    unless ($machine) {
        die "Please pass the machine href to get_input_from_user";
    }

    my $input;
    my $valid_input = get_valid_input_regex($machine);

    my $greatest_instruction = $machine->{meta}->{greatest}->{instruction};
    my $base                 = $machine->{meta}->{base};
    my $instruction_width    = $machine->{meta}->{width}->{instruction};

    my $tries;
    for ( $tries = 1; $tries <= $max_tries; $tries++ ) {
        print "Please enter a number from 0 to $greatest_instruction in base $base\n";

        $input = readline(*STDIN);
        chomp $input;
        my $length = length($input);

        if (!$length) {
            print "It doesn't look like you entered any characters. ";
            next;
        }
        elsif ( $length > $instruction_width ) {
            print "It looks like you entered too many characters. ";
            next;
        }
        elsif ( $length < $instruction_width ) {
            $input = sprintf "%03s", $input;
        }

        if ( $input !~ $valid_input ) {
            print "Your input doesn't look valid. ";
            next;
        }
        else {
            last;
        }
    }

    if ( $tries > $max_tries ) {
        die "Did not receive valid input after $max_tries attempts. Please restart your program\n";
    }
    else {
        return $input;
    }
}

sub add_input_to_inbox {
    my ( $machine, $input ) = @_;

    push @{$machine->{inbox}}, $input;

    return 0;

    # maybe make this more generic and just call it add_to_inbox

    # how would I abstract the keyboard / display? what would they
    # look like? how would I represent them in this code?
}

sub shift_inbox_to_memory {
    my ( $machine, $address ) = @_;

    $machine->{memory}->{$address} = shift @{$machine->{inbox}};

    return 0;

    # like shift_outbox, maybe make this more generic
    # at some point and have a target of where to shift
    # it
}

sub add_to_outbox {
    my ( $machine, $operand ) = @_;

    push @{$machine->{outbox}}, $machine->{memory}->{$operand};

    return 0;
}

sub shift_outbox_to_user { 
    my $machine = shift;

    print shift ( @{$machine->{outbox}} ) . "\n";

    return 0;

    # maybe, at some point, make this more generic
    # where it is just called shift_outbox and there
    # is a target of where to shift it to...

    # consider stripping leading 0's when outputting
    # to user
}

1;

=pod

=head1 NAME

VM::Dreamer::IO - IO functionality for Dreamer

=head1 SYNOPSIS

    get_valid_input_from_user($machine)
    add_input_to_inbox( $machine, $input )
    shift_inbox_to_memory( $machine, $address )

    add_to_outbox( $machine, $operand )
    shift_outbox_to_user($machine)

=head1 DESCRIPTION

This module handles IO functions for Dreamer. This just means that it can:

=over 12

=item get input and validate it
=item add the input to the Inbox stack
=item shift the "oldest" entry in the inbox to an address in memory

=item add an item in memory to the Outbox stack
=item output the "oldest" entry in the outbox to the user

=back

=head1 SUBROUTINES

=head2 get_valid_input_from_user

Prompts the user for input. Valid input is returned otherwise the user is told what they did wrong and asked to try again. Raises an exception if max_tries is exceeded by the user.

Note: The user doesn't need to zero-pad their input. They can do so if they like, but the input can't have more digits than the largest number they can enter.

I.e. if the largest number they can enter is 999, 15 and 015 are acceptable, but 0015 would be rejected.

=head2 add_input_to_inbox

Pushes input to the "top" of the Inbox. 

=head2 shift_inbox_to_memory

Shifts the "bottom" of the inbox to an address in memory.

=head2 add_to_outbox

Adds the information stored at an address in memory to the "top" of the Outbox.

=head2 shift_outbox_to_user

Putputs the value at the "bottom" of the Outbox to the user. Note all output is zero-padded to have the same number of digits as the "width" of each address in memory.

This means that if your memory is 8 digits wide and each digit can be between 0 and 7, the number 715 would be output as 00000715.

This may change in a future release.

=head1 CONSUMPTION

Together, the first three methods are used to implement VM::Dreamer::Instructions::input_to_mb and the last two are used to implemtn VM::Dreamer::Instructions::output_from_mb. These in turn are the INP and OUT operations for Grasshopper.

=head1 CAVEATS

I've tried to follow the FIFO concept of First In, First Out; however, I don't know how well I understand the underlying concepts. If you know better and see any conceptual issues with the implementation, please let me know.

=head1 AUTHOR

William Stevenson <william at coders dot coop>

=head1 SEE ALSO

VM::Dreamer::Instructions

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by William Stevenson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)
 
=cut

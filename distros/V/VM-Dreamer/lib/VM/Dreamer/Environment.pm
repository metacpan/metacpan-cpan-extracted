package VM::Dreamer::Environment;

use strict;
use warnings;

our $VERSION = '0.851';

require Exporter;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw( get_restrictions get_say_normal );

my $restrictions = {
    base => {
        min => 2,
        max => 10
    },

    op_code_width => {
        min => 1,
        max => 8
    },

    operand_width => {
        min => 1,
        max => 248
    }
};

our $say_normal = {
    base          => "base",
    op_code_width => "op-code's width",
    operand_width => "operand's width"
};

sub get_restrictions {
    return $restrictions;
}

sub get_say_normal {
    return $say_normal;
}

1;

=pod

=head1 NAME

Vm::Dreamer::Environment

=head1 SYNOPSIS

get_restrictions();
get_say_normal();

=head1 DESCRIPTION

Provides a place for environmental variables. Currently lets you set boundaries on the base, the op_code_width and the operand_width. Used for validation during initialization. 

=head1 SUBROUTINES

=head2 get_restrictions

Doesn't take any arguments and returns a hash ref with three keys - base, op_code_width and operand_width. Each in turn is a reference to a hash which has a key called min and another called max.

Used by VM::Dreamer::Validate to validate the machine definition during initialization and by VM::Dreamer::Error to populate an error string with the min/max values for a more robust error message to the user.

=head2 get_say_normal

Returns a analog of base, op_code_width and operand_width suitable for use in strings when presented to a human. Used by vM::Dreamer::Error.

=head1 AUTHOR

William Stevenson <william at coders dot coop>

=head1 SEE ALSO

VM::Dreamer
VM::Dreamer::Error
VM::Dreamer::Validate

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by William Stevenson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)
 
=cut

package VM::Dreamer::Error;

use strict;
use warnings;

our $VERSION = '0.851';

use VM::Dreamer::Environment qw( get_restrictions get_say_normal );

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw( missing_term invalid_term );

my $restrictions = get_restrictions();
my $say_normal   = get_say_normal();

sub missing_term {
    my $missing_term = shift;

    return "Please include the $say_normal->{$missing_term} in the machine's definition\n";
}

sub invalid_term {
    my ( $term, $value ) = @_;

    my $min = $restrictions->{$term}->{min};
    my $max = $restrictions->{$term}->{max};

    return "The $say_normal->{$term} can only be an integer between $min and $max, but you gave it a value of $value\n";
}

1;

=pod

=head1 NAME

VM::Dreamer::Error

=head1 SYNOPSIS

missing_term($term)
invalid_term( $term, $value );

=head1 DESCRIPTION

Provides robust error messages to the user

=head1 SUBROUTINES

=head2 missing_term

Takes a key which wasn't included in the machine definition and returns a string indicating this. Consumed by VM::Dreamer::Validate.

=head2 invalid_term

Used to return an error message when a definition term has a value which is outside the acceptable range. Takes the term (e.g. base, op_code_width or operand_width) and the offending value. Returns an error message saying what the offendng term was, what the boundaries are for the term adn what the actual value was.

=head1 AUTHOR

William Stevenson <william at coders dot coop>

=head1 SEE ALSO

VM::Dreamer::Validate

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by William Stevenson.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)
 
=cut

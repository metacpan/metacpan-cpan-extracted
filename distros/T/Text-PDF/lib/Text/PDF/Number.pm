package Text::PDF::Number;

=head1 NAME

Text::PDF::Number - Numbers in PDF. Inherits from L<Text::PDF::String>

=head1 METHODS

=cut

use strict;
use vars qw(@ISA);
# no warnings qw(uninitialized);

use Text::PDF::String;
@ISA = qw(Text::PDF::String);


=head2 $n->convert($str)

Converts a string from PDF to internal, by doing nothing

=cut

sub convert
{ return $_[1]; }


=head2 $n->as_pdf

Converts a number to PDF format

=cut

sub as_pdf
{ $_[0]->{'val'}; }



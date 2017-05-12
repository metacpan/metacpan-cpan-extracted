package Text::PDF::Name;

use strict;
use vars qw(@ISA);
# no warnings qw(uninitialized);

use Text::PDF::String;
@ISA = qw(Text::PDF::String);

=head1 NAME

Text::PDF::Name - Inherits from L<Text::PDF::String> and stores PDF names (things
beginning with /)

=head1 METHODS

=head2 Text::PDF::Name->from_pdf($string)

Creates a new string object (not a full object yet) from a given string.
The string is parsed according to input criteria with escaping working, particular
to Names.

=cut


sub from_pdf
{
    my ($class, $str, $pdf) = @_;
    my ($self) = $class->SUPER::from_pdf($str);

    $self->{'val'} = name_to_string ($self->{'val'}, $pdf);
    $self;
}

=head2 $n->convert ($str, $pdf)

Converts a name into a string by removing the / and converting any hex
munging unless $pdf is supplied and its version is less than 1.2.

=cut

sub convert
{
    my ($self, $str, $pdf) = @_;

    $str = name_to_string ($str, $pdf);
    return $str;
}


=head2 $s->as_pdf ($pdf)

Returns a name formatted as PDF.  $pdf is optional but should be the
PDF File object for which the name is intended if supplied.

=cut

sub as_pdf
{
    my ($self, $pdf) = @_;
    my ($str) = $self->{'val'};

    $str = string_to_name ($str, $pdf);
    return ("/" . $str);
}


# Prior to PDF version 1.2, `#' was a literal character.  Embedded
# spaces were implicitly allowed in names as well but it would be best
# to ignore that (PDF reference 2nd edition, Appendix H, section 3.2.4.3).

=head2 Text::PDF::Name->string_to_name ($str, $pdf)

Suitably encode the string $str for output in the File object $pdf
(the exact format may depend on the version of $pdf).  Prinicipally,
encode certain characters in hex if the version is greater than 1.1.

=cut

sub string_to_name ($;$)
{
    my ($str, $pdf) = @_;
    if (!defined($pdf) || (defined $pdf->{' version'} && $pdf->{' version'} >= 2))
    { $str =~ s|([\001-\040\177-\377%()\[\]{}<>#/])|"#".sprintf("%02X", ord($1))|oge; }
    return $str;
}

=head2 Text::PDF::Name->name_to_string ($str, $pdf)

Suitably decode the string $str as read from the File object $pdf (the
exact decoding may depend on the version of $pdf).  Principally, undo
the hex encoding for PDF versions > 1.1.

=cut
  
sub name_to_string ($;$)
{
    my ($str, $pdf) = @_;
    $str =~ s|^/||o;

    if (!defined($pdf) || (defined $pdf->{' version'} && $pdf->{' version'} >= 2))
    { $str =~ s/#([0-9a-f]{2})/chr(hex($1))/oige; }
    return $str;
}


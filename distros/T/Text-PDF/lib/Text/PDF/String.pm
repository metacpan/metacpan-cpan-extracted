package Text::PDF::String;

=head1 NAME

Text::PDF::String - PDF String type objects and superclass for simple objects
that are basically stringlike (Number, Name, etc.)

=head1 METHODS

=cut

use strict;
use vars qw(@ISA %trans %out_trans);
# no warnings qw(uninitialized);

use Text::PDF::Objind;
@ISA = qw(Text::PDF::Objind);

%trans = (
    "n" => "\n",
    "r" => "\r",
    "t" => "\t",
    "b" => "\b",
    "f" => "\f",
    "\\" => "\\",
    "(" => "(",
    ")" => ")"
        );

%out_trans = (
    "\n" => "n",
    "\r" => "r",
    "\t" => "t",
    "\b" => "b",
    "\f" => "f",
    "\\" => "\\",
    "(" => "(",
    ")" => ")"
             );


=head2 Text::PDF::String->from_pdf($string)

Creates a new string object (not a full object yet) from a given string.
The string is parsed according to input criteria with escaping working.

=cut

sub from_pdf
{
    my ($class, $str) = @_;
    my ($self) = {};

    bless $self, $class;
    $self->{'val'} = $self->convert($str);
    $self->{' realised'} = 1;
    return $self;
}


=head2 Text::PDF::String->new($string)

Creates a new string object (not a full object yet) from a given string.
The string is parsed according to input criteria with escaping working.

=cut

sub new
{
    my ($class, $str) = @_;
    my ($self) = {};

    bless $self, $class;
    $self->{'val'} = $str;
    $self->{' realised'} = 1;
    return $self;
}


=head2 $s->convert($str)

Returns $str converted as per criteria for input from PDF file

=cut

sub convert
{
    my ($self, $str) = @_;

    $str =~ s/\\([nrtbf\\()]|[0-7]+)/defined $trans{$1} ? $trans{$1} : chr(oct($1))/oegi;
#    $str =~ s/\\([0-7]+)/chr(oct($1))/oeg;              # thanks to kundrat@kundrat.sk
    1 while $str =~ s/\<([0-9a-f]{2})[\r\n]*/chr(hex($1))."\<"/oige;
    $str =~ s/\<([0-9a-f]?)\>/chr(hex($1."0"))/oige;
    $str =~ s/\<\>//og;
    return $str;
}


=head2 $s->val

Returns the value of this string (the string itself).

=cut

sub val
{ $_[0]->{'val'}; }


=head2 $->as_pdf

Returns the string formatted for output as PDF for PDF File object $pdf.

=cut

sub as_pdf
{
    my ($self) = @_;
    my ($str) = $self->{'val'};

    if ($str =~ m/[^\n\r\t\b\f\040-\176\200-\377]/oi)
    {
        $str =~ s/(.)/sprintf("%02X", ord($1))/oge;
        return "<$str>";
    } else
    {
        $str =~ s/([\n\r\t\b\f\\()])/\\$out_trans{$1}/ogi;
        return "($str)";
    }
}

=head2 $s->outobjdeep

Outputs the string in PDF format, complete with necessary conversions

=cut

sub outobjdeep
{
    my ($self, $fh, $pdf, %opts) = @_;

    $fh->print($self->as_pdf ($pdf));
}


=head2 $s->copy($inpdf, $res, $unique, $outpdf, %opts)

Copies an object. See Text::PDF::Objind::Copy() for details

=cut

sub copy
{
    my ($self, $inpdf, $res, $unique, $outpdf, %opts) = @_;
    my ($i);

    $res = $self->SUPER::copy($inpdf, $res, $unique, $outpdf, %opts);
    $res->{'val'} = $self->{'val'};
    $res->{' realised'} = 1;
    $res;
}

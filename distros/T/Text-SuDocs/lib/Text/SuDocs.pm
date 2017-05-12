package Text::SuDocs;
{
  $Text::SuDocs::VERSION = '0.014';
}

# ABSTRACT: parse and normalize SuDocs numbers

use 5.10.0;

use Any::Moose;
use namespace::autoclean;
use Carp;

our @subfields = qw{agency subagency committee series relatedseries document};

has [qw(original), @subfields] => (
    is => 'rw',
    isa => 'Maybe[Str]',
    );

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    if (@_ == 1 && !ref $_[0]) {
        return $class->$orig(original => $_[0]);
    }
    else {
        return $class->$orig(@_);
    }
};

sub BUILD {
    my $self = shift;
    if($self->original) {
        $self->parse;
    }
}

around 'original' => sub {
    my $orig = shift;
    my $self = shift;

    if (scalar @_) {
        $self->$orig(@_);
        $self->parse();
    }

    return $self->$orig();
};

sub parse {
    my $self = shift;
    my $original = shift // $self->original;
    return if ! defined $original;

    chomp($original);
    croak 'Invalid characters' if $original =~ qr{[^\p{IsAlnum}\s:/\-.<>()]};
    $original = uc $original;
    $original =~ s{^\s+|\s+$}{}g;
    $original =~ s{\s+}{ }g;
    $original =~ s{:$}{};

    if ($original =~ /^(XJH|XJS)$/) {
      $self->agency($1);
      return $self;
    }

    $original =~ qr{
        ^(\p{IsAlpha}+)\s*                        #Agency
        (\p{IsDigit}+)\s*\.\s*                    #Subagency
        (?:(\p{IsAlpha}+)\s+)?                    #Committee
        (\p{IsDigit}+)                            #Series
        (?:/(\p{IsAlnum}+)(-\p{IsAlnum}+)?)?\s*   #RelSeries
        (?::\s*(.*))?$                            #Document
        }x;
    croak 'Unable to determine stem' if (!($1 && $2 && $4));

    $self->agency($1);
    $self->subagency($2);
    $self->committee($3);
    $self->series($4);
    my $relseries =
        (!$5) ? undef :
        ($6) ? $5.$6 : $5;
    $self->relatedseries($relseries);
    $self->document($7);

    return $self;
}

sub normal_string {
    my $self = shift;
    my %args = (ref $_[0]) ? %{$_[0]} : @_;

    return $self->agency if ($self->agency =~ /^(?:XJH|XJS)$/);

    my $sudocs = sprintf(
        '%s %d.%s%s%s',
        $self->agency,
        $self->subagency,
        ($self->committee) ? $self->committee . q{ } : '',
        $self->series,
        ($self->relatedseries) ? '/'.$self->relatedseries : '',
        );

    unless ($args{class_stem} || !$self->document) {
        $sudocs .= ':'.$self->document;
    }
    return $sudocs;
}

sub sortable_string {
    my $self = shift;
    my $pad = shift // 8;

    my $s = $self->normal_string;
    my $format = sprintf '%%0%dd', $pad;
    $s =~ s/\b(\d+)\b/sprintf $format, $1/xge;
    $s =~ s/\s/_/g;

    return $s;
}

__PACKAGE__->meta()->make_immutable();
1;

__END__

=head1 NAME

Text::SuDocs - Parse and normalize SuDocs numbers

=head1 DESCRIPTION

The United States Government Printing Office uses a "Superintendent
of Documents (SuDocs)" classification system to uniquely identify,
categorize, and sort documents it tracks. This package is used for
parsing and normalizing these identifiers.

=head1 METHODS

=head2 my $sudocs = Text::SuDocs->new($string)

Creates a new Text::SuDocs object. Its sole argument is a
scalar containing a SuDocs string.

=head2 my $string = $sudocs->agency()

=head2 my $string = $sudocs->subagency()

=head2 my $string = $sudocs->committee()

=head2 my $string = $sudocs->series()

=head2 my $string = $sudocs->relatedseries()

=head2 my $string = $sudocs->document()

These accessor methods are available to retrieve individual
components of the SuDocs identifier.

=head2 my $string = $sudocs->original()

Accessor method for retrieving the original identifier.

=head2 my $string = $sudocs->normal_string()

This method returns the normalized expression of the SuDocs string.
Normalization trims off whitespace, uppercases all alphas, and
removes unneeded whitespace.

=head2 my $string = $sudocs->sortable_string(6)

This method returns the sortable expression of the SuDocs string.
A sortable string is a normalized one with all the whitespace
converted to underscores and all the numbers padded out with zeros.
The default pad is eight digits, but this can be altered by passing
in a single scalar for the pad length.

=head1 BUGS

Please submit bug reports to https://github.com/ctfliblime/Text-SuDocs/issues. Pull requests with fixes and enhancements are also welcome.

=head1 SEE ALSO

http://www.access.gpo.gov/su_docs/fdlp/pubs/explain.html

=head1 LICENSE

This code may be distributed under the same terms as Perl itself.

Please note that these modules are not products of or supported by the
employers of the various contributors to the code.

=head1 COPYRIGHT

Copyright 2011 LibLime, a Division of PTFS, Inc.

=head1 AUTHORS

=over 4

=item * Clay Fouts (cfouts@liblime.com)

=cut

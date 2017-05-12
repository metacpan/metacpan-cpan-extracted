#-*- perl -*-
#-*- coding: utf-8 -*-

package Unicode::Precis;

use 5.008007;    # Use Unicode 4.1.0 or later.
use strict;
use warnings;

use Encode qw(is_utf8 _utf8_on _utf8_off);
use Unicode::BiDiRule qw(check);
use Unicode::Normalize qw(normalize);
use Unicode::Precis::Preparation qw(prepare FreeFormClass IdentifierClass);
use Unicode::Precis::Utils
    qw(compareExactly decomposeWidth foldCase mapSpace);

our $VERSION = '1.100';
$VERSION = eval $VERSION;    # see L<perlmodstyle>

sub new {
    my $class   = shift;
    my %options = @_;

    bless {%options} => $class;
}

sub compare {
    my $self    = shift;
    my $stringA = $self->enforce(shift);
    my $stringB = $self->enforce(shift);

    return compareExactly($stringA, $stringB);
}

sub enforce {
    my ($self, $string) = @_;

    return undef unless defined $string;

    if (lc($self->{WidthMappingRule} || '') eq 'decomposition') {
        decomposeWidth($string);
    }
    my $mappingrule = lc($self->{AdditionalMappingRule} || '');
    if ($mappingrule =~ /\bmapspace/) {
        mapSpace($string);
    }
    if ($mappingrule =~ /\bstripspace/) {
        $string =~ s/\A\x20+//;
        $string =~ s/\x20+\z//;
    }
    if ($mappingrule =~ /\bunifyspace/) {
        $string =~ s/\x20\x20+/\x20/g;
    }
    if (lc($self->{CaseMappingRule} || '') eq 'fold') {
        foldCase($string);
    }
    if ($self->{NormalizationRule}) {
        if (is_utf8($string)) {
            $string =
                eval { normalize(uc $self->{NormalizationRule}, $string) };
        } elsif ("\t" eq "\005") {    # EBCDIC
            $string = Encode::decode('UTF-8', $string);
            $string =
                eval { normalize(uc $self->{NormalizationRule}, $string) };
            $string = Encode::encode('UTF-8', $string) if defined $string;
        } else {
            _utf8_on($string);
            $string =
                eval { normalize(uc $self->{NormalizationRule}, $string) };
            _utf8_off($string);
        }
        return undef unless defined $string;
    }
    if (lc($self->{DirectionalityRule} || '') eq 'bidi') {
        return undef unless defined check($string, 0);
    }
    my $stringclass = {
        freeformclass   => FreeFormClass,
        identifierclass => IdentifierClass,
        }->{lc($self->{StringClass} || '')}
        || 0;
    return undef
        unless defined prepare($string, $stringclass);
    if (ref $self->{OtherRule} eq 'CODE') {
        return undef
            unless defined($string = $self->{OtherRule}->($string));
    }

    eval { $_[1] = $string };
    $string;
}

1;
__END__

=encoding utf-8

=head1 NAME

Unicode::Precis - RFC 7564 PRECIS Framework - Enforcement and Comparison

=head1 SYNOPSIS

  use Unicode::Precis;
  $precis = Unicode::Precis->new(options...);
  $string = $precis->enforce($input);
  $equals = $precis->compare($inputA, $inputB);
  
=head1 DESCRIPTION

L<Unicode::Precis> performs enforcement and comparison of
UTF-8 bytestring or Unicode string according to PRECIS Framework.

Note that bytestring will not be upgraded but treated as UTF-8 sequence
by this module.

=head2 Methods

=over

=item new ( options ... )

I<Constructor>.
Creates new instance of L<Unicode::Precis> class.
Following options may be specified.

=over

=item WidthMappingRule =E<gt> 'Decomposition'

If specified, maps fullwidth and halfwidth characters to their decomposition
mappings
using decomposeWidth().

=item AdditionalMappingRule =E<gt> 'I<options...>'

If specified, maps spaces.
I<options...> may include any of following words:

=over

=item C<MapSpace>

Maps non-ASCII space characters to ASCII space
using mapSpace().

=item C<StripSpace>

Removes ASCII space character(s) at the beginning and/or ending of the string.

=item C<UnifySpace>

Maps sequences of more than one ASCII space character to a single ASCII space
character.

=back

=item CaseMappingRule =E<gt> 'Fold'

If specified, maps uppercase and titlecase characters to lowercase
using foldCase().

=item NormalizationRule =E<gt> 'NFC' | 'NFKC' | 'NFD' | 'NFKD'

If specified, normalizes string using given normalization form.

=item DirectionalityRule =E<gt> 'BiDi'

If specifiled and the string contains right-to-left character,
checks string against BiDi Rule.

=item StringClass =E<gt> 'FreeFormClass' | 'IdentifierClass'

If specified, checks string according to given string class.

=item OtherRule =E<gt> $subref

If specified, replaces and/or checks string with the result of subroutine
referred by $subref.

=back

=item compare ( $stringA, $stringB )

I<Instance method>.
Compares strings.
If enforcement on both strings succeeds,
compares them using compareExactly() and returns C<1> or C<0>.
Otherwise returns C<undef>.

Arguments $stringA and $stringB are not modified.

=item enforce ( $string )

I<Instance method>.
Performs enforcement on the string.
If processing succeeded, modifys argument $string and returns it.
Otherwise returns C<undef>.

=back

=head2 Exports

None are exported.

=head1 CAVEATS

The repertoire this module can handle is restricted by Unicode database
of Perl core: Characters beyond it are considered to be "unassigned"
and are disallowed, even if they are available by recent version of
Unicode.  Table below lists implemented Unicode version by each Perl version.

  Perl's version     Implemented Unicode version
  ------------------ ---------------------------
  5.8.7, 5.8.8       4.1.0
  5.10.0             5.0.0
  5.8.9, 5.10.1      5.1.0
  5.12.x             5.2.0
  5.14.x             6.0.0
  5.16.x             6.1.0
  5.18.x             6.2.0
  5.20.x             6.3.0

=head1 RESTRICTIONS

This module can not handle Unicode string on EBCDIC platforms.

=head1 SEE ALSO

RFC 7564 I<PRECIS Framework: Preparation, Enforcement, and Comparison of
Internationalized Strings in Application Protocols>.
L<https://tools.ietf.org/html/rfc7564>.

L<Unicode::BiDiRule>, L<Unicode::Normalize>, L<Unicode::Precis::Preparation>,
L<Unicode::Precis::Utils>.

=head1 AUTHOR

Hatuka*nezumi - IKEDA Soji, E<lt>hatuka@nezumi.nuE<gt>

=head1 COPYRIGHT AND LICENSE

(C) 2015, 2016 Hatuka*nezumi - IKEDA Soji

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. For more details, see the full text of
the licenses at <http://dev.perl.org/licenses/>.

This program is distributed in the hope that it will be
useful, but without any warranty; without even the implied
warranty of merchantability or fitness for a particular purpose.

=cut

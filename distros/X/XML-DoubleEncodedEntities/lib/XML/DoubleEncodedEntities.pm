package XML::DoubleEncodedEntities;

use strict;

require Exporter;

use vars qw($VERSION @EXPORT_OK @ISA);

$VERSION = '1.1';
@EXPORT_OK = qw(decode);
@ISA = qw(Exporter);

# localising prevents the warningness leaking out of this module
local $^W = 1;    # can't use warnings as that's a 5.6-ism

=encoding ISO8859-1

=head1 NAME

XML::DoubleEncodedEntities - unbreak XML with doubly-encoded entities

=head1 DESCRIPTION

Occasionally, XML files escape into the wild with their entities encoded
twice so instead of this:

    <chocolate>Green &amp; Blacks</chocolate>

you get:

    &lt;chocolate&gt;Green &amp;amp; Blacks&lt;/chocolate&gt;

A real-world example of this problem can be seen in this failing test
for a module which queries an online XML datasource:

    http://www.nntp.perl.org/group/perl.cpan.testers/2007/02/msg414642.html

(search for the text 'Arcturus' in that page).

This module tries to fix that.

=head1 SYNOPSIS

    use XML::DoubleEncodedEntities;
    
    my $xmlfile = XML::DoubleEncodedEntities::decode($xmlfile);

=head1 Functions

=head2 decode

This function is not exported, but can be if you wish.  It takes one
scalar parameter and returns a corresponding scalar, decoded if necessary.

The parameter is assumed to be a string.  If its first non-whitespace
characters are C<&lt;>, or if it contains the sequence C<&amp;amp;> the
string is assumed to be a doubly-encoded XML document, in which case the
following entities, if present, are decoded:
    &amp;
    &lt;
    &gt;
    &quot;
    &apos;

No other parameters are decoded.  After all, if the input document has been
*doubly* encoded then something like C<æ>, which should be the entity C<&aelig;>
will be represented by the character sequence C<&amp;aelig;>.  Once the
C<&amp;> has been corrected by this module, you'll be able to decode the
resulting C<&aelig;> in the normal way.

=cut

# ripped off (and simplified) from XML::Tiny
sub decode {
    my $thingy = shift;
    return $thingy unless($thingy =~ /(^\s*&lt;|&amp;amp;)/);

    $thingy =~ s/&(lt;|gt;|quot;|apos;|amp;|.*)/
        $1 eq 'lt;'   ? '<' :
        $1 eq 'gt;'   ? '>' :
        $1 eq 'apos;' ? "'" :
        $1 eq 'quot;' ? '"' :
        $1 eq 'amp;'  ? '&' :
        die("Illegal ampersand or entity\n\tat &$1\n")
    /ge;
    $thingy;
}

=head1 BUGS and FEEDBACK

I welcome feedback about my code, including constructive criticism.
Bug reports should be made using L<http://rt.cpan.org/> or by email,
and should include the smallest possible chunk of code, along with
any necessary data, which demonstrates the bug.  Ideally, this
will be in the form of a file which I can drop in to the module's
test suite.  Ideally such files will work in perl 5.004.

If you are feeling particularly generous you can encourage me in my
open source endeavours by buying me something from my wishlist:
  L<http://www.cantrell.org.uk/david/wishlist/>

=head1 SEE ALSO

L<Encode::DoubleEncodedUTF8>, which does the same job for broken UTF-8.

L<Test::DoubleEncodedEntities>, which is HTMLish.

=head1 AUTHOR

David Cantrell E<lt>F<david@cantrell.org.uk>E<gt>

=head1 COPYRIGHT and LICENCE

Copyright 2007 David Cantrell

This module is free-as-in-speech software, and may be used, distributed,
and modified under the same terms as Perl itself.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

'&amp;amp;#49'

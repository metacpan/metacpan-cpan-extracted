package X500::DN::Marpa::DN;

use parent 'X500::DN::Marpa';
use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Moo;

use X500::DN::Marpa::RDN;

our $VERSION = '1.00';

# ------------------------------------------------

sub getRFC2253String
{
	my($self) = @_;

	return $self -> dn;

} # End of getRFC2253String.

# ------------------------------------------------

sub getRDN
{
	my($self, $n) = @_;
	my($temp)     = $self -> rdn($n + 1);

	return $temp if (length($temp) == 0);

	my($rdn) = X500::DN::Marpa::RDN -> new;

	$rdn -> parse($temp);

	return $rdn;

} # End of getRDN.

# ------------------------------------------------

sub getRDNs
{
	my($self) = @_;

	return $self -> rdn_number;

} # End of getRDNs.

# ------------------------------------------------

sub getX500String
{
	my($self) = @_;

	return '{' . $self -> openssl_dn . '}';

} # End of getX500String.

# ------------------------------------------------

sub hasMultivaluedRDNs
{
	my($self)   = @_;
	my($result) = 0;

	for my $rdn ($self -> stack -> print)
	{
		$result = 1 if ($$rdn{count} > 1);
	}

	return $result;

} # End of hasMultivaluedRDNs.

# ------------------------------------------------

sub ParseRFC2253
{
	my($self, $dn) = @_;

	$self -> parse($dn);

	return $self; # Sic. See docs.

} # End of ParseRFC2253.

# ------------------------------------------------

1;

=pod

=encoding utf8

=head1 NAME

C<X500::DN::Marpa::DN> - Backcompat module to emulate the DN part of C<X500::DN>

=head1 Synopsis

This is scripts/back.compat.pl:

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use X500::DN::Marpa::DN;
	use X500::DN::Marpa::RDN;

	# -----------------------

	print "Part 1:\n";

	my($dn)   = X500::DN::Marpa::DN -> new;
	my($text) = 'foo=FOO + bar=BAR + frob=FROB, baz=BAZ';

	$dn -> ParseRFC2253($text);

	print "Parsing:     $text\n";
	print 'RDN count:   ', $dn -> getRDNs, " (Expected: 2)\n";
	print 'DN:          ', $dn -> getRFC2253String, " (Expected: baz=BAZ,foo=FOO+bar=BAR+frob=FROB)\n";
	print 'X500 string: ', $dn -> getX500String, " (Expected: {foo=FOO+bar=BAR+frob=FROB+baz=BAZ})\n";
	print '-' x 50, "\n";
	print "Part 2:\n";

	my($rdn)       = $dn -> getRDN(0);
	my $type_count = $rdn -> getAttributeTypes;
	my(@types)     = $rdn -> getAttributeTypes;

	print 'RDN(0):      ', $rdn -> dn, "\n";
	print "Type count:  $type_count (Expected: 3)\n";
	print "Type [0]:    $types[0] (Expected: foo)\n";
	print "Type [1]:    $types[1] (Expected: bar)\n";

	my(@values) = $rdn -> getAttributeValue('foo');

	print "Value [0]:   $values[0] (Expected: FOO+bar=BAR+frob=FROB)\n";

	my($has_multi) = $dn -> hasMultivaluedRDNs;

	print "hasMulti:    $has_multi (Expected: 1)\n";
	print '-' x 50, "\n";
	print "Part 2:\n";

	$rdn = $dn -> getRDN(1);

	@values = $rdn -> getAttributeValue('baz');

	print 'RDN(1):      ', $rdn -> dn, "\n";
	print "Value [0]:   $values[0] (Expected: BAZ)\n";
	print '-' x 50, "\n";

Output of scripts/back.compat.pl:

	Part 1:
	Parsing:     foo=FOO + bar=BAR + frob=FROB, baz=BAZ
	RDN count:   2 (Expected: 2)
	DN:          baz=BAZ,foo=FOO+bar=BAR+frob=FROB (Expected: baz=BAZ,foo=FOO+bar=BAR+frob=FROB)
	X500 string: {foo=FOO+bar=BAR+frob=FROB+baz=BAZ} (Expected: {foo=FOO+bar=BAR+frob=FROB+baz=BAZ})
	--------------------------------------------------
	Part 2:
	RDN(0):      foo=FOO+bar=BAR+frob=FROB
	Type count:  3 (Expected: 3)
	Type [0]:    foo (Expected: foo)
	Type [1]:    bar (Expected: bar)
	Value [0]:   FOO+bar=BAR+frob=FROB (Expected: FOO+bar=BAR+frob=FROB)
	hasMulti:    1 (Expected: 1)
	--------------------------------------------------
	Part 2:
	RDN(1):      baz=BAZ
	Value [0]:   BAZ (Expected: BAZ)
	--------------------------------------------------

=head1 Description

C<X500::DN::Marpa::DN> provides a L<Marpa::R2>-based parser for parsing X.500 Distinguished Names.

This module emulates the DN parts of L<X500::DN>.

Notes:

=over 4

=item o C<X500::DN>

This module was based on the obsolete L<RFC2253|https://www.ietf.org/rfc/rfc2253.txt>:
Lightweight Directory Access Protocol (v3): UTF-8 String Representation of Distinguished Names.

=item o C<X500::DN::Marpa> and C<X500::DN::Marpa::DN>

These modules are based on L<RFC4514|https://www.ietf.org/rfc/rfc4514.txt>:
Lightweight Directory Access Protocol (LDAP): String Representation of Distinguished Names.

=back

See also L<X500::DN::Marpa> and L<X500::DN::Marpa::RDN>.

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install C<X500::DN::Marpa> as you would any C<Perl> module:

Run:

	cpanm X500::DN::Marpa

or run:

	sudo cpan X500::DN::Marpa

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

C<new()> is called as C<< my($parser) = X500::DN::Marpa::DN -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<X500::DN::Marpa::DN>.

Key-value pairs accepted in the parameter list (see corresponding methods for details:

=over 4

=item o (None)

=back

=head1 Methods

This module is a subclass of L<X500::DN::Marpa> and shares all its options to new(), and all its
methods. See L<X500::DN::Marpa/Constructor and Initialization> and L<X500::DN::Marpa/Methods>.

Further, it has these methods:

=head2 getRFC2253String()

Returns the DN as a string.

And yes, it's really based on RFC4514, as it says in the L</Description>.

The DN is what was passed to L</ParseRFC2253($dn)>.

=head2 getRDN($n)

Returns an object of type L<X500::DN::Marpa::RDN>, containing the $n-th RDN, or returns '' if $n
is out of range.

$n counts from 0.

The returned object has already parsed the RDN, so you use that object via the methods documented in
L<X500::DN::Marpa::RDN>.

If the input is 'UID=nobody@example.com,DC=example,DC=com', C<rdn(0)> returns an object which has
parsed 'uid=nobody@example.com'. Note the lower-case 'uid'.

Warning: The parent class L<X500::DN::Marpa> counts RDNs from 1.

=head2 getRDNs()

Returns the number of RDNs in the DN parsed.

=head2 getX500String()

Returns what L<X500::DN> calls an X500 version of the DN.

=head2 hasMultivaluedRDNs()

Returns a Boolean, 0 meaning there are no multvalued RDNs, and 1 meaning there is at least 1 such
RDN.

=head2 new()

See L</Constructor and Initialization> for details on the parameters accepted by L</new()>.

=head2 ParseRFC2253($dn)

Parses $dn and returns $self (sic).

This has to be the first method (after L</new()> of course) which you call on an object of type
C<X500::DN::Marpa::DN>.

So, you are expected to do this:

	my($parser) = X500::DN::Marpa::DN -> new;

	$parser -> ParseRFC2253($a_dn);

And to just ignore the return value. After this, you call methods on $parser.

If you do this:

	my($parser) = X500::DN::Marpa::DN -> new;
	my($dn)     = $parse -> ParseRFC2253($a_dn);

It will work of course, but you have 2 copies of $parser, and you (probably) call methods on $dn.

So, you could do this:

	my($dn) = X500::DN::Marpa::DN -> new -> ParseRFC2253($a_dn);

And just ignore the intermediary copy, which has been discarded. After this, you call methods on
$dn.

This means that to patch old code, just convert:

	my($dn) = X500::DN -> ParseRFC2253

Into:

	my($dn) = X500::DN::Marpa::DN -> new -> ParseRFC2253

=head1 FAQ

See L<X500::DN::Marpa/FAQ>.

=head2 How to I transition to C<X500::DN::Marpa::DN> before switching to C<X500::DN::Marpa>?

See scripts/back.compat.pl.

=head2 How do I upgrade code from C<X500::DN> to C<X500::DN::Marpa>?

See scripts/synopsis.pl.

You can think of scripts/synopsis.pl as scripts/forward.compat.pl!

=head2 How do you handle attribute values in double-quotes?

RFC4514 does not discuss this topic.

So, I ignore the quotes, because I assume none of your other software accepts them anyway, since
you're not using them any more, right?

=head1 References

See L<X500::DN::Marpa/References>.

=head1 See Also

L<X500::DN>.

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/X500-DN-Marpa>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=X500::DN::Marpa>.

=head1 Author

L<X500::DN::Marpa> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2015.

Marpa's homepage: L<http://savage.net.au/Marpa.html>.

My homepage: L<http://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2015, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License 2.0, a copy of which is available at:
	http://opensource.org/licenses/alphabetical.

=cut

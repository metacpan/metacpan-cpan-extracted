package X500::DN::Marpa::RDN;

use parent 'X500::DN::Marpa';
use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.

use Moo;

use Want;

our $VERSION = '1.00';

# ------------------------------------------------

sub getAttributeTypes
{
	my($self) = @_;
	my(@type) = $self -> rdn_types(1);

	return want('LIST') ? @type : scalar @type;

} # End of getAttributeTypes.

# ------------------------------------------------

sub getAttributeValue
{
	my($self, $type) = @_;
	my(@value) = $self -> rdn_values($type);

	return want('LIST') ? @value : $value[0];

} # End of getAttributeValue.

# ------------------------------------------------

1;

=pod

=encoding utf8

=head1 NAME

C<X500::DN::Marpa::RDN> - Backcompat module to emulate the RDN part of C<X500::DN>

=head1 Synopsis

See L<X500::DN::Marpa::DN/Synopsis>.

=head1 Description

C<X500::DN::Marpa::RDN> provides a L<Marpa::R2>-based parser for parsing X.500 Relative
Distinguished Names.

This module emulates the RDN parts of L<X500::DN>.

Actually, objects of type C<X500::DN::Marpa::RDN> are returned by
L<X500::DN::Marpa::DN/getRDN($n)>, so you may not need to use this module directly at all.

But if you do create such an object directly, you I<must> call C<< $rdn -> parse($an_rdn) >>
before calling any other methods.

See also L<X500::DN::Marpa> and L<X500::DN::Marpa::DN>.

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

C<new()> is called as C<< my($parser) = X500::DN::Marpa::RDN -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<X500::DN::Marpa::RDN>.

Key-value pairs accepted in the parameter list (see corresponding methods for details:

=over 4

=item o (None)

=back

=head1 Methods

This module is a subclass of L<X500::DN::Marpa> and shares all its options to new(), and all its
methods. See L<X500::DN::Marpa/Constructor and Initialization> and L<X500::DN::Marpa/Methods>.

Further, it has these methods:

=head2 getAttributeTypes()

In scalar context, returns the number of types in the RDN passed in to
L<X500::DN::Marpa/parse([$string])>.

In list context, returns all those types.

=head2 getAttributeValue($key)

In scalar context, returns the number of values in the RDN passed in to
L<X500::DN::Marpa/parse([$string])>, whose type matches $key.

In list context, returns all those values.

=head2 new()

See L</Constructor and Initialization> for details on the parameters accepted by L</new()>.

=head1 FAQ

See L<X500::DN::Marpa::DN/FAQ> and L<X500::DN::Marpa/FAQ>.

=head1 References

See L<X500::DN::Marpa/References>.

=head1 See Also

L<X500::DN::Marpa>.

L<X500::DN::Marpa::DN>.

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

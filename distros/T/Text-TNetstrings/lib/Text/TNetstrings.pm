package Text::TNetstrings;
use strict;
use warnings;
use base qw(Exporter);

=head1 NAME

Text::TNetstrings - Data serialization using typed netstrings.

=head1 VERSION

Version 1.2.0

=cut

use version 0.77; our $VERSION = version->declare("v1.2.0");

=head1 SYNOPSIS

An implementation of the tagged netstring specification, a simple data
interchange format better suited to low-level network communication than
JSON. See http://tnetstrings.org/ for more details.

	use Text::TNetstrings qw(:all);

	my $data = encode_tnetstrings({"foo" => "bar"}) # => "12:3:foo,3:bar,}"
	my $hash = decode_tnetstrings($data)            # => {"foo" => "bar"}

=head1 EXPORT

=over

=item C<encode_tnetstrings($data)>

=item C<decode_tnetstrings($data)>

=item C<:all>

The "all" tag exports all the above subroutines.

=back

=cut

our @EXPORT_OK = qw(encode_tnetstrings decode_tnetstrings $Useperl);
our %EXPORT_TAGS = (
	"all" => \@EXPORT_OK,
);

=head1 ENVIRONMENT

=over

=item C<PERL_ONLY>

=item C<TNETSTRINGS_PUREPERL>

Can be set to a boolean value which controls whether the pure Perl
implementation of C<Text::TNetstrings> is used. The C<Text::TNetstrings>
module is a dual implementation, with all functionality written in both
pure Perl and also in XS ('C'). By default, The XS version will be used
whenever possible, as it is much faster. This option allows you to
override the default behaviour.

=item C<TNETSTRINGS_XS>

Unless C<TNETSTRINGS_PUREPERL> or C<PERL_ONLY> is set, an attempt will
be made to load the XS module. If it can not be loaded it will fail
quietly and fall back to the pure Perl module. If C<TNETSTRINGS_XS> is
set a warning will be issued if loading the XS module fails.

=back

=cut

BEGIN {
	my $xs = $ENV{"TNETSTRINGS_XS"} || !($ENV{"TNETSTRINGS_PUREPERL"} || $ENV{"PERL_ONLY"});
	if($xs) {
		if($ENV{"TNETSTRINGS_XS"}) {
			require Text::TNetstrings::XS;
			*encode_tnetstrings = \&Text::TNetstrings::XS::encode_tnetstrings;
			*decode_tnetstrings = \&Text::TNetstrings::XS::decode_tnetstrings;
		} else {
			eval {
				require Text::TNetstrings::XS;
				*encode_tnetstrings = \&Text::TNetstrings::XS::encode_tnetstrings;
				*decode_tnetstrings = \&Text::TNetstrings::XS::decode_tnetstrings;
			};
			$xs = 0 if $@;
		}
	}
	if(!$xs) {
		require Text::TNetstrings::PP;
		*encode_tnetstrings = \&Text::TNetstrings::PP::encode_tnetstrings;
		*decode_tnetstrings = \&Text::TNetstrings::PP::decode_tnetstrings;
	}
};

=head1 SUBROUTINES/METHODS

=head2 encode_tnetstrings($data)

Encode a scalar, hash or array into TNetstring format.

=head2 decode_tnetstrings($string)

Decode TNetstring data into the appropriate scalar, hash or array. In
array context the remainder of the string will also be returned, e.g.:

	my ($data, $rest) = decode_tnetstrings("0:~foo"); #=> (undef, "foo")

=head1 MAPPING

=head2 Perl -> TNetstrings

=over

=item ARRAY

Perl array references become TNetstring lists.

=item HASH

Perl hash references become TNetstring dictionaries. The TNetstring
specification does not dictate an ordering, thus Perl's pseudo-random
ordering is used.

=item Unblessed

Other unblessed references are not allowed, and an exception will be
thrown. This uncludes C<CODE>s, C<GLOB>s, etc.

=item boolean::true, boolean::false

These special values become TNetstring true and false values,
respectively.

=item Blessed Objects

Blessed objects are not representable in TNetstrings, and thus an
exception will be thrown.

=item Scalars

Due to Perl not having distinct string, floating point or fixed point
integers, the encoded type is a best guest. Undefined scalars will be
encoded as TNetstring nulls (c<0:~>), values which look like a floating
point number are encoded as floats, values which look like a fixed point
integer are encoded as integers, and everything else is encoded as
a string (using stringification).

=back

=cut

=head1 AUTHOR

Sebastian Nowicki

=head1 SEE ALSO

L<http://tnetstrings.org/> for the TNetstrings specification.

L<Text::TNetStrings::XS|Text::TNetstrings::XS> for better performance.

L<Text::TNetStrings::PP|Text::TNetstrings::PP> if XS is not supported.

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-tnetstrings at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-TNetstrings>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::TNetstrings


You can also look for information at:

=over

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-TNetstrings>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-TNetstrings>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-TNetstrings>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-TNetstrings>

=item * GitHub

L<http://www.github.com/sebnow/text-tnetstrings-perl>

=back

=head1 CHANGES

=head2 v1.2.0

=over

=item Support for encoding L<boolean> objects.

=back

=head2 v1.1.1

=over

=item Performance improvements

=item Bug fixes for strings containing C<NULL> bytes

=back

=head2 v1.1.0

=over

=item XS module for improved performance

=back

=head2 v1.0.1

=over

=item Performance improvements

=back

=head2 v1.0.0

=over

=item Initial release

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Sebastian Nowicki.

This program is distributed under the MIT (X11) License:
L<http://www.opensource.org/licenses/mit-license.php>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

=cut

1;


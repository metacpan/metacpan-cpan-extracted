package Text::TransMetaphone;
use base qw(Exporter);
use utf8;

BEGIN
{
	use strict;
	use warnings;
	use vars qw($VERSION @EXPORT_OK %LocaleRanges);

	$VERSION = "0.08";

	@EXPORT_OK = qw( trans_metaphone reverse_key );

	%LocaleRanges = ();
}


sub guess_locale
{
my ($word) = @_;

	my $locale;
	$word =~ /(\p{IsLetter})/;	
	my $char =  $1;  # grab first letter

	#
	# check ranges of registered locales
	#
	foreach (keys %LocaleRanges) {
		$locale = $_  if ( $char =~ /$LocaleRanges{$_}/ );
	}
	unless ( $locale ) {
		$locale = "am"    if ( $char =~ /\p{InEthiopic}/   );
		$locale = "ar"    if ( $char =~ /\p{InArabic}/     );
		$locale = "ch"    if ( $char =~ /\p{InCherokee}/   );
		$locale = "el"    if ( $char =~ /\p{InGreekAndCoptic}/ );
		$locale = "en_US" if ( $char =~ /\p{InBasicLatin}/ );
		$locale = "gu"    if ( $char =~ /\p{InGujarati}/   );
		$locale = "he"    if ( $char =~ /\p{InHebrew}/     );
		$locale = "ja_hiragana" if ( $char =~ /\p{InHiragana}/ );
		$locale = "ja_katakana" if ( $char =~ /\p{InKatakana}/ );
		$locale = "ru"    if ( $char =~ /\p{InCyrillic}/   );
	}

$locale;

}


sub list_locales
{
	keys %LocaleRanges;
}


sub trans_metaphone
{
my $word = shift;
my $locale = (@_) ? shift : guess_locale ( $word );


	die "No locale identified for $word.  Locale must be specified." unless ( $locale );

	unless ( exists($LocaleRanges{$locale}) ) {
		my $module = "Text::TransMetaphone::$locale";
		eval "require $module;"
		|| die "Unable to load Text::TransMetaphone::$locale : $@";

		$LocaleRanges{$locale} = ${"Text::TransMetaphone::${locale}::LocaleRange"};
	}

	my @keys = &{"Text::TransMetaphone::${locale}::trans_metaphone"} ( $word );

	( wantarray ) ? @keys : $kesy[0];
}


sub reverse_key
{
my ($word, $locale) = @_;

	die "No locale identified for $word.  Locale must be specified." unless ( $locale );

	unless ( exists($LocaleRanges{$locale}) ) {
		my $module = "Text::TransMetaphone::$locale";
		eval "require $module;"
		|| die "Unable to load Text::TransMetaphone::$locale : $@";

		$LocaleRanges{$locale} = ${"Text::TransMetaphone::${locale}::LocaleRange"};
	}

	&{"Text::TransMetaphone::${locale}::reverse_key"} ( $word );

}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__


=encoding utf8


=head1 NAME

Text::TransMetaphone – Translingual phonetic encoding of words. 

=head1 SYNOPSIS

use Text::TransMetaphone qw( trans_metaphone reverse_key );

my @keys = trans_metaphone ( "Waldo" );  # convert to IPA symbols 

print reverse_key ( $key[0], "chr" );    # print in Cherokee

=head1 DESCRIPTION

This module implements a "sounds like" algorithm developed
by Lawrence Philips which he published in the June, 2000 issue
of I<C/C++ Users Journal>.  Trans-Metaphone is a variation
of Philips' original Metaphone algorithm. 

The TransMetaphone package implements an "N-Metaphone" algorithm
for supported languages where keys are generated in IPA symbols.
There are no restrictions on the number of encoded keys that may be
returned.  The number of encoded keys returned is left to the
discretion of implementer and what s/he finds practical for the
writing system of concern.

IPA encoding is applied to normalize language and script boundaries.
IPA encoded words can then be readily compared between different
languages and writing systems.  Applied to text retrieval, you can
generate a key in one language and then search for it any other
supported language.

For additional details, see the C<doc/index.html> file provided
with this package and the demonstration scripts found under the
C<examples/> directory.

=head1 FUNCTIONS

=over 4

=item trans_metaphone ( STRING [, ISO639_LANGUAGE_CODE] )

Takes a word and returns a phonetic encoding with IPA symbols.  Optionally,
an ISO-639 language code can be set to specify the locale applicable to
the passed string.  When not passed, the locale will be guessed based on
the character range of the string.

In an array context, the function returns all logical phonetic encodings
for the word.  The first encoding in the array will be the most literal,
later encodings will be the less probable, the final encoding will be
a regular expression suitable for matching all returned encodings.

In a scalar context, the function returns only the first encoding.

=item reverse_key ( IPA-STRING, ISO639_LANGUAGE_CODE )

The reverse_key function takes an IPA encoded string (such as one
returned by the trans_metaphone function) and returns a regular
expression to match the sequence under the orthography conventions
of the locale specified.

This function is experimental, it offers an aid for transliterating
a normalized IPA sequence into a supported writing convention.  It
may also be helpful for debugging.

=back

=head1 BUGS

View the documentation of individual locale modules for limitations.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2003-2025, Daniel Yacob C<< <dyacob@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 SEE ALSO

Philips, Lawrence. I<C/C++ Users Journal>, June, 2000.
L<http://www.cuj.com/articles/2000/0006/0006d/0006d.htm?topic=articles>

Philips, Lawrence. I<Computer Language>, Vol. 7, No. 12 (December), 1990.

L<Text::DoubleMetaphone> by Maurice Aubrey E<lt>maurice@hevanet.comE<gt>.

Kevin Atkinson (author of the Aspell spell checker) maintains
a page dedicated to the Metaphone and Double Metaphone algorithms at 
L<http://aspell.sourceforge.net/metaphone/>

=cut

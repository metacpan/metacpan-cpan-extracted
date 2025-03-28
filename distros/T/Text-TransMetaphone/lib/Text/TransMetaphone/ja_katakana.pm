package Text::TransMetaphone::ja_katakana;
use utf8;

BEGIN
{
	use strict;
	use warnings;
	use vars qw( $VERSION $LocaleRange );

	$VERSION = '0.10';

	$LocaleRange = qr/\p{InKatakana}/;

}


sub trans_metaphone
{

	#
	# since I know nothing about greek orthography,
	# this just blindly strips vowels and transliterates
	# text onto IPA.  we don't worry about key length for now
	#

	$_ = $_[0];

	#
	# strip out all but first vowel:
	#
	s/^[ァアィイゥウェエォオー]/a/;
	s/[ァアィイゥウェエォオー]//g;

	s/[バビブベボ]/b/g;
	s/[ダデド]/d/g;
	s/[ガギグゲゴ]/g/g;
	s/[ハヒヘホ]/h/g;
	s/[ヂヅ]/ʣ/g;
	s/フ/f/g;
	s/[ャヤュユョヨ]/j/g;
	s/[カヵキクケヶコ]/k/g;
	s/[マミムメモ]/m/g;
	s/[ンナニヌネノ]/n/g;
	s/[パピプペポ]/p/g;
	s/[ラリルレロ]/r/g;
	s/[サシスセソ]/s/g;
	s/[ッタテト]/t/g;
	s/[ヷヸヴヹヺ]/v/g;
	s/[ヮワヰヱヲ]/w/g;
	s/[ザジズゼゾ]/z/g;

	($_, $_);  # no regex key at this time
}


sub reverse_key
{

	$_ = $_[0];

	s/a/[ァアィイゥウェエォオー]/;

	s/b/[バビブベボ]/g;
	s/d/[ダデド]/g;
	s/g/[ガギグゲゴ]/g;
	s/h/[ハヒヘホ]/g;
	s/ʣ/[ヂヅ]/g;
	s/f/フ/g;
	s/j/[ャヤュユョヨ]/g;
	s/k/[カヵキクケヶコ]/g;
	s/m/[マミムメモ]/g;
	s/n/[ンナニヌネノ]/g;
	s/p/[パピプペポ]/g;
	s/r/[ラリルレロ]/g;
	s/s/[サシスセソ]/g;
	s/t/[ッタテト]/g;
	s/v/[ヷヸヴヹヺ]/g;
	s/w/[ヮワヰヱヲ]/g;
	s/z/[ザジズゼゾ]/g;

	$_;
}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__


=encoding utf8


=head1 NAME

Text::TransMetaphone::ja_katakana - Transcribe Katakana words into IPA symbols.

=head1 SYNOPSIS

This module is used by L<Text::TransMetaphone> and need not be used
directly.

=head1 DESCRIPTION

The Text::TransMetaphone::ja_katakana module implements the TransMetaphone algorithm
for Katakana.  The module provides a C<trans_metaphone> function that accepts
a Katakana word as an argument and returns a list of keys transcribed into
IPA symbols under Katakana orthography rules.  The last key of the list is
a regular expression that matching all previously returned keys.

A C<reverse_key> function is also provided to convert an IPA symbol key into  
a regular expression that would phonological sequence under Katakana orthography.

=head1 STATUS

The Katakana module has limited awareness of Katakana orthography, no alternative
keys are generated at this time.   The module will be updated as more rules
of Katakana orthography are learnt.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2003-2025, Daniel Yacob C<< <dyacob@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 BUGS

None presently known.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 SEE ALSO

L<Text::TransMetaphone>

=cut

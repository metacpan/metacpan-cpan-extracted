package Text::TransMetaphone::ja_hiragana;

use utf8;
BEGIN
{
	use strict;
	use vars qw( $VERSION $LocaleRange );

	$VERSION = '0.01';

	$LocaleRange = qr/\p{InHiragana}/;

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
	s/^[ぁあぃいぅうぇえぉおー]/a/;
	s/[ぁあぃいぅうぇえぉおー]//g;

	s/[ばびぶべぼ]/b/g;
	s/[だでど]/d/g;
	s/[がぎぐげご]/g/g;
	s/[はひへほ]/h/g;
	s/[ぢづ]/ʣ/g;
	s/ふ/f/g;
	s/[やゆよ]/j/g;
	s/[かきくけこ]/k/g;
	s/[まみむめも]/m/g;
	s/[んなにぬねの]/n/g;
	s/[ぱぴぷぺぽ]/p/g;
	s/[らりるれろ]/r/g;
	s/[さしすせそ]/s/g;
	s/[ったてと]/t/g;
	s/[ちつ]/ʦ/g;
	s/ゔ/v/g;
	s/[ゎわゐゑを]/w/g;
	s/[ざじずぜぞ]/z/g;

	($_, $_);  # no regex key at this time
}


sub reverse_key
{

	$_ = $_[0];

	s/a/[ぁあぃいぅうぇえぉおー]/;

	s/b/[ばびぶべぼ]/g;
	s/d/[だでど]/g;
	s/g/[がぎぐげご]/g;
	s/h/[はひへほ]/g;
	s/ʣ/[ぢづ]/g;
	s/f/ふ/g;
	s/j/[やゆよ]/g;
	s/k/[かきくけこ]/g;
	s/m/[まみむめも]/g;
	s/n/[んなにぬねの]/g;
	s/p/[ぱぴぷぺぽ]/g;
	s/r/[らりるれろ]/g;
	s/s/[さしすせそ]/g;
	s/t/[ったてと]/g;
	s/ʦ/[ちつ]/g;
	s/v/ゔ/g;
	s/w/[ゎわゐゑを]/g;
	s/z/[ざじずぜぞ]/g;

	$_;
}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__



=head1 NAME

Text::TransMetaphone::ja_hiragana - Transcribe Hiragana words into IPA symbols.

=head1 SYNOPSIS

This module is used by L<Text::TransMetaphone> and need not be used
directly.

=head1 DESCRIPTION

The Text::TransMetaphone::ja_hiragana module implements the TransMetaphone algorithm
for Hiragana.  The module provides a C<trans_metaphone> function that accepts
an Hiragana word as an argument and returns a list of keys transcribed into
IPA symbols under Hiragana orthography rules.  The last key of the list is
a regular expression that matching all previously returned keys.

A C<reverse_key> function is also provided to convert an IPA symbol key into  
a regular expression that would phonological sequence under Hiragana orthography.

=head1 STATUS

The Hiragana module has limited awareness of Hiragana orthography, no alternative
keys are generated at this time.   The module will be updated as more rules
of Hiragana orthography are learnt.

=head1 COPYRIGHT

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 BUGS

None presently known.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 SEE ALSO

L<Text::TransMetaphone>

=cut

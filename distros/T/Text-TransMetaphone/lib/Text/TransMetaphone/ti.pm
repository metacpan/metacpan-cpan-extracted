package Text::TransMetaphone::ti;

use utf8;
BEGIN
{
	use strict;
	use vars qw( $VERSION $LocaleRange );

	$VERSION = '0.01';

	$LocaleRange = qr/\p{Inxyz}/;

}


sub trans_metaphone
{

	#
	# since I know nothing about tigrigna orthography,
	# this just blindly strips vowels and transliterates
	# text onto IPA.  we don't worry about key length for now
	#

	$_ = $_[0];

	#
	# strip out all but first vowel:
	#
	s/^[አ-ኧዐ-ዖ]+/a/g;
	s/[አ-ኧዐ-ዖ]//g;

	s/[በ-ቦ]/b/g;
	s/[ደ-ዶ]/d/g;
	s/[ዸ-ዾ]/ɗ/g;
	s/[ገ-ጎ]/g/g;
	s/[ሀ-ሆኀ-ኆ]/h/g;
	s/[ሐ-ሖ]/ħ/g;
	s/[ጀ-ጆ]/ʤ/g;
	s/[ፈ-ፎ]/f/g;
	s/[የ-ዮ]/j/g;
	s/[ከ-ኮ]/k/g;
	s/[ቀ-ቆ]/k'/g;
	s/[ኰ-ኵ]/kʷ/g;
	s/[ቐ-ቖ]/q/g;
	s/[ለ-ሎ]/l/g;
	s/[መ-ሞ]/m/g;
	s/[ነ-ኖ]/n/g;
	s/[ኘ-ኞ]/ɲ/g;
	s/[ጘ-ጞ]/ŋ/g;
	s/[ፐ-ፖ]/p/g;
	s/[ጰ-ጶ]/p'/g;
	s/[ረ-ሮ]/r/g;
	s/[ሠ-ሦሰ-ሶ]/s/g;
	s/[ጸ-ጾፀ-ፆ]/s'/g;
	s/[ሸ-ሾ]/ʃ/g;
	s/[ተ-ቶ]/t/g;
	s/[ጠ-ጦ]/t'/g;
	s/[ቸ-ቾ]/ʧ/g;
	s/[ጨ-ጮ]/ʧ'/g;
	s/[ቨ-ቮ]/v/g;
	s/[ወ-ዎ]/w/g;
	s/[ኸ-ኾ]/x/g;
	s/[ዘ-ዞ]/z/g;
	s/[ዠ-ዦ]/ʒ/g;

	($_, $_);  # no regex key at this time
}


sub reverse_key
{
	s/a/[አ-ኧዐ-ዖ]/;

	s/k'/[ቀ-ቆ]/g;
	s/kʷ/[ኰ-ኵ]/g;
	s/p'/[ጰ-ጶ]/g;
	s/s'/[ጸ-ጾፀ-ፆ]/g;
	s/t'/[ጠ-ጦ]/g;
	s/ʧ'/[ጨ-ጮ]/g;

	s/b/[በ-ቦ]/g;
	s/d/[ደ-ዶ]/g;
	s/ɗ/[ዸ-ዾ]/g;
	s/g/[ገ-ጎ]/g;
	s/h/[ሀ-ሆኀ-ኆ]/g;
	s/ħ/[ሐ-ሖ]/g;
	s/ʤ/[ጀ-ጆ]/g;
	s/f/[ፈ-ፎ]/g;
	s/j/[የ-ዮ]/g;
	s/k/[ከ-ኮ]/g;
	s/q/[ቐ-ቖ]/g;
	s/l/[ለ-ሎ]/g;
	s/m/[መ-ሞ]/g;
	s/n/[ነ-ኖ]/g;
	s/ɲ/[ኘ-ኞ]/g;
	s/ŋ/[ጘ-ጞ]/g;
	s/p/[ፐ-ፖ]/g;
	s/r/[ረ-ሮ]/g;
	s/s/[ሠ-ሦሰ-ሶ]/g;
	s/ʃ/[ሸ-ሾ]/g;
	s/t/[ተ-ቶ]/g;
	s/ʧ/[ቸ-ቾ]/g;
	s/v/[ቨ-ቮ]/g;
	s/w/[ወ-ዎ]/g;
	s/x/[ኸ-ኾ]/g;
	s/z/[ዘ-ዞ]/g;
	s/ʒ/[ዠ-ዦ]/g;

	$_;
}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__



=head1 NAME

Text::TransMetaphone::ti - Transcribe Tigrinya words into IPA symbols.

=head1 SYNOPSIS

This module is used by L<Text::TransMetaphone> and need not be used
directly.

=head1 DESCRIPTION

The Text::TransMetaphone::ti module implements the TransMetaphone algorithm
for Tigrinya.  The module provides a C<trans_metaphone> function that accepts
an Tigrinya word as an argument and returns a list of keys transcribed into
IPA symbols under Tigrinya orthography rules.  The last key of the list is
a regular expression that matching all previously returned keys.

A C<reverse_key> function is also provided to convert an IPA symbol key into  
a regular expression that would phonological sequence under Tigrinya orthography.

=head1 STATUS

The Tigrinya module has limited awareness of Tigrinya orthography, no alternative
keys are generated at this time.   The module will be updated as more rules
of Tigrinya orthography are learnt.

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

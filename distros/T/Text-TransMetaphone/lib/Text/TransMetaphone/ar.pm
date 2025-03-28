package Text::TransMetaphone::ar;
use utf8;

BEGIN
{
	use strict;
	use warnings;
	use vars qw( $VERSION $LocaleRange );

	$VERSION = '0.10';

	$LocaleRange = qr/(\p{InArabic}|\p{InArabicPresentationFormsA}|\p{InArabicPresentationFormsB})/;

}


sub trans_metaphone
{
	#
	# since I know nothing about arabic orthography,
	# this just blindly strips vowels and transliterates
	# text onto IPA.  we don't worry about key length for now
	#

	$_ = $_[0];

	#
	# strip out all but first vowel:
	#
	s/^[اﺎﻋﻌﻊع]/a/g;
	s/[اﺎﻋﻌﻊع]//g;

	#
	# strip vowel markers
	#
	s/[\x{064b}-\x{0655}\x{fe70}-\x{fe7f}]//g;

	s/[ﺑﺒﺐب]/b/g;
	s/[دﺪ]/d/g;
	s/[ﺿﻀﺾض]/ɗ/g;
	s/[ﻏﻐﻎغگﮒﮓﮔﮕ]/g/g;
	s/[ﻫﻬﻪه]/h/g;
	s/[ﺣﺤﺢح]/ħ/g;
	s/[ﺟﺠﺞج]/ʤ/g;
	s/[ﻓﻔﻒف]/f/g;
	s/[ﻳﻴﻲي]/j/g;
	s/[ﻛﻜﻚك]/k/g;
	s/[ﻗﻘﻖق]/k'/g;
	s/[ﻟﻠﻞل]/l/g;
	s/[ﻣﻤﻢم]/m/g;
	s/[ﻧﻨﻦن]/n/g;
	s/[ﭶﭷﭸﭹ]/ɲ/g;
	s/[ﭖﭗﭘﭙ]/p/g;
	s/[ﭢﭣﭤﭥ]/p'/g;
	s/[رﺮ]/r/g;
	s/[ﺳﺴﺲس]/s/g;
	s/[ﺻﺼﺺص]/s'/g;
	s/[ﺷﺸﺶش]/ʃ/g;
	s/[ﺗﺘﺖت]/t/g;
	s/[ﻃﻄﻂط]/t'/g;
	s/[ﺛﺜﺚث]/Θ/g;
	s/[ﭺﭻﭼﭽ]/ʧ/g;
	s/[ﭾﭿﮀﮁ]/ʧ'/g;
	s/[ﭪﭫﭬﭭ]/v/g;
	s/[وﻮ]/w/g;
	s/[ﺧﺨﺦخ]/x/g;
	s/[زﺰﻇﻈﻆظ]/z/g;
	s/[ﮊﮋﮌﮍ]/ʒ/g;

	my @keys   = ($_);
	my $re     =  $_;
	my $second =  $_;

	$second = s/(.)w/$1/g;
	$re = s/(.)w/$1w?/g;

	push ( @keys, $second ) if ( $second ne $_ );
	push ( @keys, qr/$re/ );

	@keys;
}


sub reverse_key
{
	$_ = $_[0];

	s/a/[اﺎﻋﻌﻊع]/;

	s/s'/[ﺻﺼﺺص]/g;
	s/t'/[ﻃﻄﻂط]/g;
	s/ʧ'/[ﭾﭿﮀﮁ]/g;
	s/k'/[ﻗﻘﻖق]/g;
	s/p'/[ﭢﭣﭤﭥ]/g;

	s/b/[ﺑﺒﺐب]/g;
	s/d/[دﺪ]/g;
	s/ɗ/[ﺿﻀﺾض]/g;
	s/g/[ﻏﻐﻎغگﮒﮓﮔﮕ]/g;
	s/h/[ﻫﻬﻪه]/g;
	s/ħ/[ﺣﺤﺢح]/g;
	s/ʤ/[ﺟﺠﺞج]/g;
	s/f/[ﻓﻔﻒف]/g;
	s/j/[ﻳﻴﻲي]/g;
	s/k/[ﻛﻜﻚك]/g;
	s/l/[ﻟﻠﻞل]/g;
	s/m/[ﻣﻤﻢم]/g;
	s/n/[ﻧﻨﻦن]/g;
	s/ɲ/[ﭶﭷﭸﭹ]/g;
	s/p/[ﭖﭗﭘﭙ]/g;
	s/r/[رﺮ]/g;
	s/s/[ﺳﺴﺲس]/g;
	s/ʃ/[ﺷﺸﺶش]/g;
	s/t/[ﺗﺘﺖت]/g;
	s/Θ/[ﺛﺜﺚث]/g;
	s/ʧ/[ﭺﭻﭼﭽ]/g;
	s/v/[ﭪﭫﭬﭭ]/g;
	s/w/[وﻮ]/g;
	s/x/[ﺧﺨﺦخ]/g;
	s/z/[زﺰﻇﻈﻆظ]/g;
	s/ʒ/[ﮊﮋﮌﮍ]/g;

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

Text::TransMetaphone::ar - Transcribe Arabic words into IPA symbols.

=head1 SYNOPSIS

This module is used by L<Text::TransMetaphone> and need not be used
directly.

=head1 DESCRIPTION

The Text::TransMetaphone::ar module implements the TransMetaphone algorithm
for Arabic.  The module provides a C<trans_metaphone> function that accepts
an Arabic word as an argument and returns a list of keys transcribed into
IPA symbols under Arabic orthography rules.  The last key of the list is
a regular expression that matching all previously returned keys.

A C<reverse_key> function is also provided to convert an IPA symbol key into  
a regular expression that would phonological sequence under Arabic orthography.

=head1 STATUS

The Arabic module applies basic phonetic mappings to generate keys.  No more
than three keys (including the regex key) are returned at this time.  The
second key strips the "w" IPA symbol under vowel rules.  One key *should* be
created for each "w" substitution, this will be fixed in a future release.
The module will be updated as more rules of Arabic orthography are learnt.

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

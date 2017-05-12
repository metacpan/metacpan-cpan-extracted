package Text::TransMetaphone::chr;

use utf8;
BEGIN
{
	use strict;
	use vars qw( $VERSION $LocaleRange );

	$VERSION = '0.01';

	$LocaleRange = qr/\p{InCherokee}/;

}


sub trans_metaphone
{
	#
	# since I know nothing about cherokee orthography,
	# this just blindly strips vowels and transliterates
	# text onto IPA.  we don't worry about key length for now
	#

	$_ = $_[0];

	#
	# strip out all but first vowel:
	#
	s/^[Ꭰ-Ꭵ]/a/;
	s/[Ꭰ-Ꭵ]//g;

	#                ᎦᎧ                      ᎾᏀ   ᏅᏌ              ᏛᏣ                Ᏼ
	tr/ᎦᎧᎭ-ᎾᏀ-ᏅᏌ-ᏛᏣ-Ᏼ/gkhhhhhhllllllmmmmmnnnnnnnsssssssdtdtdtdddʦʦʦʦʦʦwwwwwwjjjjjj/;
	s/Ꮏ/hn/g;
	s/[Ꮖ-Ꮛ]/kʷ/g;
	s/Ꮬ/dl/g;
	s/[Ꮭ-Ꮲ]/tl/g;

	my @keys = ( $_ );
	my $re = $_;

	while ( $keys[0] =~ /[ᎨᎩᎪᎫᎬ]/ ) {
		my @newKeys;
		for (my $i=0; $i < @keys; $i++) {
			$newKeys[$i] = $keys[$i];     # copy old keys
			$keys[$i]    =~ s/[ᎨᎩᎪᎫᎬ]/g/; # update old keys for primary mapping
			$newKeys[$i] =~ s/[ᎨᎩᎪᎫᎬ]/k/; # update new keys for primary mapping
		}
		push (@keys,@newKeys);  # add new keys to old keys
	}
	$re =~ s/[ᎨᎩᎪᎫᎬ]/[gk]/g; 

	push ( @keys, qr/$re/ );

	@keys;
}


sub reverse_key
{
	$_ = $_[0];

	s/a/[Ꭰ-Ꭵ]/g;

	tr/gkggggghhhhhhllllllmmmmmnnnnnnnsssssssdtdtdtdddʦʦʦʦʦʦwwwwwwjjjjjj/Ꭶ-ᎾᏀ-ᏅᏌ-ᏛᏣ-Ᏼ/;

	s/k/Ꭺ/g;

	s/hn/Ꮏ/g;
	s/kʷ/[Ꮖ-Ꮛ]/g;
	s/dl/Ꮬ/g;
	s/tl/[Ꮭ-Ꮲ]/g;

	$_;
}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__



=head1 NAME

Text::TransMetaphone::chr - Transcribe Cherokee words into IPA symbols.

=head1 SYNOPSIS

This module is used by L<Text::TransMetaphone> and need not be used
directly.

=head1 DESCRIPTION

The Text::TransMetaphone::chr module implements the TransMetaphone algorithm
for Cherokee.  The module provides a C<trans_metaphone> function that accepts
an Cherokee word as an argument and returns a list of keys transcribed into
IPA symbols under Cherokee orthography rules.  The last key of the list is
a regular expression that matching all previously returned keys.

A C<reverse_key> function is also provided to convert an IPA symbol key into  
a regular expression that would phonological sequence under Cherokee orthography.

=head1 STATUS

The Cherokee module applies basic phonetic mappings to generate keys.  Alternative
keys substittue "g" with "k".  The module will be updated as more rules of
Cherokee orthography are learnt.


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

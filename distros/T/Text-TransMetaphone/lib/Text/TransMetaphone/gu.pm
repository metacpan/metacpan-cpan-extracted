package Text::TransMetaphone::gu;
use utf8;

BEGIN
{
	use strict;
	use warnings;
	use vars qw( $VERSION $LocaleRange );

	$VERSION = '0.08';

	$LocaleRange = qr/\p{InGujarti}/;

}


sub trans_metaphone
{


	#
	# since I know nothing about gujarti orthography,
	# this just blindly strips vowels and transliterates
	# text onto IPA.  we don't worry about key length for now
	#

	$_ = $_[0];

	#
	# strip out all but first vowel:
	#
	s/^[અઆઇઈઉઊઋઍએઐઑઓઔાિીુૂૃૄૅેૈૉોૌૠ]/a/;
	s/[અઆઇઈઉઊઋઍએઐઑઓઔાિીુૂૃૄૅેૈૉોૌૠ]//g;

	s/[બભ]/b/g;
	s/[ડદ]/d/g;
	s/[ઢધ]/ɗ/g;
	s/[ગઘ]/g/g;
	s/હ/h/g;
	s/[જઝ]/ʤ/g;
	s/ય/j/g;
	s/ક/k/g;
	s/ખ/k'/g;
	s/[લળ]/l/g;
	s/મ/m/g;
	s/ન/n/g;
	s/[ણઞ]/ɲ/g;
	s/ઙ/ŋ/g;
	s/પ/p/g;
	s/ફ/p'/g;
	s/ર/r/g;
	s/સ/s/g;
	s/[ષશ]/ʃ/g;
	s/[ટત]/t/g;
	s/[ઠથ]/t'/g;
	s/ચ/ʧ/g;
	s/છ/ʧ'/g;
	s/વ/w/g;

	($_, $_);  # no regex key at this time
}


sub reverse_key
{

	$_ = $_[0];

	s/a/[અઆઇઈઉઊઋઍએઐઑઓઔાિીુૂૃૄૅેૈૉોૌૠ]/;

	s/k'/ખ/g;
	s/p'/ફ/g;
	s/t'/[ઠથ]/g;
	s/ʧ'/છ/g;

	s/b/[બભ]/g;
	s/d/[ડદ]/g;
	s/ɗ/[ઢધ]/g;
	s/g/[ગઘ]/g;
	s/h/હ/g;
	s/ʤ/[જઝ]/g;
	s/j/ય/g;
	s/k/ક/g;
	s/l/[લળ]/g;
	s/m/મ/g;
	s/n/ન/g;
	s/ɲ/[ણઞ]/g;
	s/ŋ/ઙ/g;
	s/p/પ/g;
	s/r/ર/g;
	s/s/સ/g;
	s/ʃ/[ષશ]/g;
	s/t/[ટત]/g;
	s/ʧ/ચ/g;
	s/w/વ/g;

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

Text::TransMetaphone::gu – Transcribe Gujarti words into IPA symbols.

=head1 SYNOPSIS

This module is used by L<Text::TransMetaphone> and need not be used
directly.

=head1 DESCRIPTION

The Text::TransMetaphone::gu module implements the TransMetaphone algorithm
for Gujarti.  The module provides a C<trans_metaphone> function that accepts
an Gujarti word as an argument and returns a list of keys transcribed into
IPA symbols under Gujarti orthography rules.  The last key of the list is
a regular expression that matching all previously returned keys.

A C<reverse_key> function is also provided to convert an IPA symbol key into  
a regular expression that would phonological sequence under Gujarti orthography.

=head1 STATUS

The Gujarti module is the most developed in the TransMetaphone package.
The Gujarti module applies basic phonetic mappings to generate keys.  No
alternative keys are generated at this time.   The module will be updated as
more rules of Gujarti orthography are learnt.

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

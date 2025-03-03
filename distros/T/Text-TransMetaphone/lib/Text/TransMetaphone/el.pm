package Text::TransMetaphone::el;
use utf8;

BEGIN
{
	use strict;
	use warnings;
	use vars qw( $VERSION $LocaleRange );

	$VERSION = '0.08';

	$LocaleRange = qr/\p{InGreekAndCoptic}/;

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
	s/^[ΑΕΗΙΟΥΩ]/a/ig;
	s/[ΑΕΗΙΟΥΩ]//ig;

	s/ύ//ig;   # is this greek?  it appears in the "unicode" example

	s/ΜΠ/b/ig;
	s/ΝΤ/d/ig;
	s/ντ/d/g;   # uppercase match didn't work
	s/ΓΚ/g/ig;
	s/ΤΖ/ʣ/ig;

	s/Φ/f/ig;
	s/Γ/j/ig;
	s/Κ/k/ig;
	s/Ξ/ks/ig;
	s/Λ/l/ig;
	s/Μ/m/ig;
	s/Ν/n/ig;
	s/Γ[ΚΓΞΧ]/ŋ/ig;
	s/Π/p/ig;
	s/Ρ/r/ig;
	s/Σ/s/ig;
	s/Τ/t/ig;
	s/[ΔΘ]/Θ/ig;
	s/Β/v/ig;
	s/Ψ/ps/ig;
	s/Χ/x/ig;
	s/Ζ|(Σ[ΒΓΔΜ])/z/ig;

	($_, $_);  # no regex key at this time
}


sub reverse_key
{
	$_ = $_[0];

	s/b/ΜΠ/g;
	s/d/ΝΤ/g;
	s/g/ΓΚ/g;
	s/ʣ/ΤΖ/g;
	s/f/Φ/g;
	s/j/Γ/g;
	s/k/Κ/g;
	s/l/Λ/g;
	s/m/Μ/g;
	s/n/Ν/g;
	s/p/Π/g;
	s/r/Ρ/g;
	s/t/Τ/g;
	s/v/Β/g;
	s/ks/Ξ/g;
	s/ps/Ψ/g;
	s/s/Σ/g;
	s/x/Χ/g;

	s/ŋ/Γ[ΚΓΞΧ]/g;
	s/Θ/[ΔΘ]/g;
	s/z/Ζ|(Σ[ΒΓΔΜ])/g;

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

Text::TransMetaphone::el – Transcribe Greek words into IPA symbols.

=head1 SYNOPSIS

This module is used by L<Text::TransMetaphone> and need not be used
directly.

=head1 DESCRIPTION

The Text::TransMetaphone::el module implements the TransMetaphone algorithm
for Greek.  The module provides a C<trans_metaphone> function that accepts
a Greek word as an argument and returns a list of keys transcribed into
IPA symbols under Greek orthography rules.  The last key of the list is
a regular expression that matching all previously returned keys.

A C<reverse_key> function is also provided to convert an IPA symbol key into  
a regular expression that would phonological sequence under Greek orthography.

=head1 STATUS

The Greek module has limited awareness of Greek orthography, no alternative
keys are generated at this time.   The module will be updated as more rules
of Greek orthography are learnt.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2003-2025, Daniel Yacob C<< <dyacob@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 BUGS

The /i regex substitution switch isn't working for Greek in some cases.
Some vowels used in Greek also are not being stripped out.  Fixes will be
provided in a future release.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 SEE ALSO

L<Text::TransMetaphone>

=cut

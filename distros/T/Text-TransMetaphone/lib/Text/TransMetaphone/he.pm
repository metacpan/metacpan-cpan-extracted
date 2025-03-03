package Text::TransMetaphone::he;
use utf8;

BEGIN
{
	use strict;
	use warnings;
	use vars qw( $VERSION $LocaleRange );

	$VERSION = '0.08';

	$LocaleRange = qr/\p{InHebrew}/;

}


sub trans_metaphone
{

	#
	# since I know nothing about hebrew orthography,
	# this just blindly strips vowels and transliterates
	# text onto IPA.  we don't worry about key length for now
	#

	$_ = $_[0];

	#
	# strip out all but first vowel:
	#
	s/^[אע]+/a/;
	s/[אע]//g;

	s/ד/d/g;
	s/ג/g/g;
	s/ח/ħ/g;
	s/י/j/g;
	# s/ק/k'/g;
	s/ל/l/g;
	s/[מם]/m/g;
	s/[נן]/n/g;
	s/ר/r/g;
	s/ס/s/g;
	s/[צץ]/s'/g;
	s/[טת]/t/g;
	# s/ו/v/g;
	s/ז/z/g;

	my @keys = ( $_ );
	my $re = $_;

	#
	#  since /g for secondaries below this is somewhat
	#  broken, we should generate one key per alterative
	#  substitution, fix this next time.
	#
	if ( /ב/ ) {
		$keys[1] = $keys[0];  # copy old key
		$keys[0] =~ s/ב/b/g;  # primary mapping
		$keys[1] =~ s/ב/v/g;  # alternative
		$re =~ s/ב/\[bv\]/g;
	}
	if ( /ש/ ) {
		my @newKeys;
		for (my $i=0; $i < @keys; $i++) {
			$newKeys[$i] = $keys[$i];  # copy old keys
			$keys[$i] =~ s/ש/ʃ/g;      # update old keys for primary mapping
		}
		for (my $i=0; $i < @newKeys; $i++) {
			$newKeys[$i] =~ s/ש/s/g;  # update new keys for alternative
		}
		push (@keys,@newKeys);  # add new keys to old keys

		$re =~ s/ש/\[ʃs\]/g;
	}
	if ( /ק/ ) {
		my @newKeys;
		for (my $i=0; $i < @keys; $i++) {
			$newKeys[$i] = $keys[$i];  # copy old keys
			$keys[$i] =~ s/ק/k'/g;     # update old keys for primary mapping
		}
		for (my $i=0; $i < @newKeys; $i++) {
			$newKeys[$i] =~ s/ק/k/g;   # update old keys for primary mapping
		}
		push (@keys,@newKeys);  # add new keys to old keys

		$re =~ s/ק/k'?/g;
	}
	if ( /ו/ ) {
		my @newKeys;
		for (my $i=0; $i < @keys; $i++) {
			$newKeys[$i] = $keys[$i];  # copy old keys
			$keys[$i] =~ s/ו/v/g;      # update old keys for primary mapping
		}
		for (my $i=0; $i < @newKeys; $i++) {
			$newKeys[$i] =~ s/ו//g;    # update old keys for primary mapping
		}
		push (@keys,@newKeys);  # add new keys to old keys

		$re =~ s/ו/v?/g;
	}
	if ( /[פף]/ ) {
		my @newKeys;
		for (my $i=0; $i < @keys; $i++) {
			$newKeys[$i] = $keys[$i];  # copy old keys
			$keys[$i] =~ s/[פף]/p/g;   # update old keys for primary mapping
		}
		for (my $i=0; $i < @newKeys; $i++) {
			$newKeys[$i] =~ s/[פף]/f/g;  # update old keys for primary mapping
		}
		push (@keys,@newKeys);  # add new keys to old keys

		$re =~ s/[פף]/\[pf\]/g;
	}
	if ( /[כך]/ ) {
		my @newKeys;
		for (my $i=0; $i < @keys; $i++) {
			$newKeys[$i] = $keys[$i];  # copy old keys
			$keys[$i] =~ s/[כך]/k/g;   # update old keys for primary mapping
		}
		for (my $i=0; $i < @newKeys; $i++) {
			$newKeys[$i] =~ s/[כך]/x/g;  # update old keys for primary mapping
		}
		push (@keys,@newKeys);  # add new keys to old keys

		$re =~ s/[כך]/\[kx\]/g;
	}

	if ( $#keys ) {
		push ( @keys, qr/$re/ );	
	}


	# check how perl works with ltr scripts,
	# do keys need to be reversed at this stage?
	@keys;
}



#########################################################
# Do not change this, Do not put anything below this.
# File must return "true" value at termination
1;
##########################################################

__END__


=encoding utf8


=head1 NAME

Text::TransMetaphone::he – Transcribe Hebrew words into IPA symbols.

=head1 SYNOPSIS

This module is used by L<Text::TransMetaphone> and need not be used
directly.

=head1 DESCRIPTION

The Text::TransMetaphone::he module implements the TransMetaphone algorithm
for Hebrew.  The module provides a C<trans_metaphone> function that accepts
an Hebrew word as an argument and returns a list of keys transcribed into
IPA symbols under Hebrew orthography rules.  The last key of the list is
a regular expression that matching all previously returned keys.

A C<reverse_key> function is also provided to convert an IPA symbol key into  
a regular expression that would phonological sequence under Hebrew orthography.

=head1 STATUS

The Hebrew module applies basic phonetic mappings to generate keys. 
Presently one new key is created per substitution set.  However, one key
*should* be created for each individual substitution.  This will be fixed
in a future release.  The module will be updated as more rules of Hebrew
orthography are learnt.

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

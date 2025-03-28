package Text::TransMetaphone::am;

# If either of these next two lines are inside
# the BEGIN block the package will break.
#
use utf8;
use Regexp::Ethiopic::Amharic qw(:forms setForm overload);

BEGIN
{
	use strict;
	use warnings;
	use vars qw( $VERSION $LocaleRange %IMExpected %IMError %plosives );

	$VERSION = '0.10';

	$LocaleRange = qr/[ሀ-ቍበ-ኾዐ-ዷጀ-ጕጠ-፼]/;

	%plosives = (
		k => 'ቀ',
		t => 'ጠ',
		ʧ => 'ጨ',
		s => 'ጸ',
		p => 'ጰ',
	);
	%IMExpected =(
		ስ => "s",
		ጽ => "s'",
		ቅ => "k'",
		ቕ => "q",
		ት => "t",
		ጥ => "t'",
		ች => "ʧ",
		ጭ => "ʧ",
		ን => "n",
		ክ => "k",
		ዝ => "z",
		ዥ => "ʒ",
		ጵ => "p'",
		ፕ => "p"
	);
	%IMError  =(
		ስ => "s'",
		ጽ => "s",
		ቅ => "q",
		ቕ => "k'",
		ት => "t'",
		ጥ => "t",
		ች => "ʧ'",
		ጭ => "ʧ'",
		ን => "ɲ",
		ክ => "x",
		ዝ => "ʒ",
		ዥ => "z",
		ጵ => "p",
		ፕ => "p'"
	);
}


sub trans_metaphone
{

	$_ = $_[0];

	#
	#  strip out all but first vowel:
	#
	s/^[=#አ#=]/a/;
	s/[=#አ#=]//g;

	s/([#11#])/setForm($1,$ሳድስ)."ዋ"/eg;
	s/[=#ሀ#=]/h/g;
	s/[=#ሰ#=]/ሰ/g;
	s/[=#ጸ#=]/ጸ/g;
	# s/(.)[=#ጸ#=]/s'/g;  # compare this to ts in english, it should be a 2nd key

	#
	#  now strip vowels, this simplies later code:
	#
	s/(\p{InEthiopic})/ ($1 eq 'ኘ') ? $1 : setForm($1,$ሳድስ)/eg;

	tr/ልምርሽብቭውይድጅግፍ/lmrʃbvwjdʤgf/;


	my @keys = ( $_ );
	my $re = $_;


	#
	#  mixed glyphs: ዽ for ጵ or ዽ is shift stick for ድ
	#
	if ( $keys[0] =~ /ዽ/ ) {
		$keys[2] = $keys[1] = $keys[0];
		$keys[0] =~ s/ዽ/ɗ/;    # caps problem
		$keys[1] =~ s/ዽ/d/;    # literal
		$keys[2] =~ s/ዽ/p'/;   # mistaken glyph
		$re =~ s/ዽ/([dɗ]|p')/g;
	}
	#
	#  mixed glyphs: ኘ for ፕ or ኘ is shift stick for ነ
	#
	if ( $keys[0] =~ /ኘ/ ) {
		my (@newKeysA, @newKeysB);
		for (my $i=0; $i < @keys; $i++) {
			$newKeysA[$i] = $newKeysB[$i] = $keys[$i];  # copy old keys
			$keys[$i]     =~ s/ኘ/ɲ/;    # literal
			$newKeysA[$i] =~ s/ኘ/n/;    # caps problem
			$newKeysB[$i] =~ s/ኘ/p/;    # mistaken glyph
		}
		push (@keys,@newKeysA);  # add new keys to old keys
		push (@keys,@newKeysB);  # add new keys to old keys
		$re =~ s/ኘ/[nɲp]/g;
	}
	#
	#  handle phonological problems
	#
	if ( $keys[0] =~ /mb/ ) {
		my @newKeys;
		for (my $i=0; $i < @keys; $i++) {
			$newKeys[$i] = $keys[$i];  # copy old keys
			$newKeys[$i] =~ s/mb/nb/;  # update old keys for primary mapping
		}
		push (@keys,@newKeys);  # add new keys to old keys
		$re =~ s/mb/[mn]b/g;
	}

#
# try to keep least probable keys last:
#
	#
	#  Handle IM problems
	#
	while ( $keys[0] =~ /([ስቅቕትችንክዝዥጥጭጽጵፕ])/ ) {
		my $a = $1;
		my @newKeys;
		for (my $i=0; $i < @keys; $i++) {
			$newKeys[$i] = $keys[$i];  # copy old keys
			$keys[$i] =~ s/$a/$IMExpected{$a}/;  # update old keys for primary mapping
		}
		for (my $i=0; $i < @newKeys; $i++) {
			$newKeys[$i] =~ s/$a/$IMError{$a}/;  # update new keys for alternative
		}
		push (@keys,@newKeys);  # add new keys to old keys

		# print "$a => $IMExpected{$a} / $IMError{$a}\n";
		if ( $plosives{$IMExpected{$a}} || $plosives{$IMError{$a}} ) {
			$re =~ s/$a/($IMExpected{$a}|$IMError{$a})/g;
		}
		else {
			$re =~ s/$a/[$IMExpected{$a}$IMError{$a}]/g;
		}
	}

	if ( $#keys ) {
		push ( @keys, qr/$re/ );	
	}

@keys;
}


sub reverse_key
{
	$_ = $_[0];
	
	s/([stʧkp])'/$plosives{$1}/g;
	tr/hlmrsʃqbvtʧnɲakwjdɗʤzʒgɲfp/ሀለመረሰሸቐበቨተቸነኘአከወየደዸጀዘዠገጘፈፐ/;
	s/(\p{InEthiopic})/[#$1#]/g;
	s/ዸ/ደዸ/g;
	s/ጘ/ገጘ/g;

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

Text::TransMetaphone::am - Transcribe Amharic words into IPA symbols.

=head1 SYNOPSIS

This module is used by L<Text::TransMetaphone> and need not be used
directly.

=head1 DESCRIPTION

The Text::TransMetaphone::am module implements the TransMetaphone algorithm
for Amharic.  The module provides a C<trans_metaphone> function that accepts
an Amharic word as an argument and returns a list of keys transcribed into
IPA symbols under Amharic orthography rules.  The last key of the list is
a regular expression that matching all previously returned keys.

A C<reverse_key> function is also provided to convert an IPA symbol key into  
a regular expression that would phonological sequence under Amharic orthography.

=head1 STATUS

The Amharic module is the most developed in the TransMetaphone package.
It has awareness of common misspelling in Amharic, perhaps too much, the
module will produce a high number of keys.

=head1 REQUIRES

Regexp::Ethiopic.

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

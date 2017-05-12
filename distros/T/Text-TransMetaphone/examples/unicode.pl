#!/usr/bin/perl -w

use strict;
use utf8;
use Text::TransMetaphone qw( trans_metaphone );
binmode(STDOUT, ":utf8");  # works fine w/o this on linux

my %unicode =(
	en_US => "Unicode",
	am => "ዩኒኮድ",
	ar => "يونِكود",
	'chr' => "ᏳᏂᎪᏛ",
	he  => "יוניקוד",
	el => "Γιούνικοντ",
	gu => "યૂનિકોડ",
	ru => "Юникод",
	'ja_katakana' => "ユニコード",
	'ja_hiragana' => "ゆにこーど",
	ti => "ዩኒኮድ"
);

my $ipaKey = "jnkd";

foreach my $lang ( sort keys %unicode ) {
	my @keys = trans_metaphone ( $unicode{$lang}, $lang );
	print "$lang => $unicode{$lang}";
	foreach (@keys) {
		last if (ref($_));  # don't print the regex
		print " => $_";
		last if ($_ eq $ipaKey);
	}
	print "\n";
}


__END__

=head1 NAME

unicode.pl - Phonetic encoding demonstrations with the word "Unicode".

=head1 SYNOPSIS

./unicode.pl

=head1 DESCRIPTION

This is a simple demonstration script that generates keys for
the word "unicode" under the 10 supported languages.  This is
simply the only (non-political) example word I could find written
in all 10 languages.

Thanks to Mark Davis and his wonderful file:

http://www.macchiato.com/unicode/Unicode_transcriptions.html

"Unicode" may not be the ideal example word because of the way
the "U" sound is treated in English.  "Y" is not treated as a
vowel in the non-English modules, but this may have to be
changed.

=head1 AUTHOR

Daniel Yacob,  L<dyacob@cpan.org|mailto:dyacob@cpan.org>

=head1 SEE ALSO

L<Text::TransMetaphone>

=cut

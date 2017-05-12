# Package Lingua::DetectCharset
# Version 1.02
# Part of "WWW Cyrillic Encoding Suite"
# Get docs and newest version from
#	http://www.neystadt.org/cyrillic/
#
# Copyright (c) 1997-98, John Neystadt <http://www.neystadt.org/john/>
# You may install this script on your web site for free
# To obtain permision for redistribution or any other usage
#	contact john@neystadt.org.
#
# Portions copyright by 
#
# Drop me a line if you deploy this script on tyour site.

package Lingua::DetectCharset;

$VERSION = "1.02";

use Convert::Cyrillic;
use Lingua::DetectCharset::StatKoi;
use Lingua::DetectCharset::StatWin;
use Lingua::DetectCharset::StatUtf8;

$PairSize = 2;
$MinRatio = 1.5; # Mark must be in $MinRatio times larger of 
			# one encoding than another to decide upon, or ENG.
$DoubtRatio = 1;
$DoubtLog = 'DetectCharsetDoubt.txt';

sub Detect {
	my (@Data) = @_;
	my ($KoiMark) = GetCodeScore ('Koi', @Data);
	my ($WinMark) = GetCodeScore ('Win', @Data);
	my ($Utf8Mark) = GetCodeScore ('Utf8', @Data);

	# print STDERR "GetEncoding: Koi8 - $KoiMark, Win - $WinMark, Utf8 - $Utf8Mark\n";

	$KoiRatio =  $KoiMark/($WinMark+$Utf8Mark+1);
	$WinRatio =  $WinMark/($KoiMark+$Utf8Mark+1);
	$Utf8Ratio = $Utf8Mark/($KoiMark+$WinMark+1);

	if ($DoubtLog) {
		if (($KoiRatio < $MinRatio && $KoiRatio > $DoubtRatio) ||
			($WinRatio < $MinRatio && $WinRatio > $DoubtRatio) ||
			($Utf8Ratio < $MinRatio && $Utf8Ratio > $DoubtRatio)) {
				open Log, ">>$DoubtLog";
				print Log " Koi8 - $KoiMark, Win - $WinMark, Utf8 - $Utf8Mark\n", 
					join ("\n", @Data), "\n\n";
				close Log;
		}
	}

	return 'KOI8' if $KoiRatio > $WinRatio && $KoiRatio > $Utf8Ratio;	# $MinRatio;
	return 'WIN' if $WinRatio > $Utf8Ratio;

	# We do english, only if no single cyrillic character were detected
	return 'UTF8' if $WinRatio + $KoiRatio + $Utf8Ratio > 0;
	return 'ENG';
}

sub GetCodeScore {
	my ($Code, @Data) = @_;
	my ($Table);

	if ($Code eq 'Koi') {
		$Table = \%Lingua::DetectCharset::StatKoi::StatsTableKoi;
	} elsif ($Code eq 'Win') {
		$Table = \%Lingua::DetectCharset::StatWin::StatsTableWin;
	} elsif ($Code eq 'Utf8') {
		$Table = \%Lingua::DetectCharset::StatUtf8::StatsTableUtf8Long;
	} else {
		die "Don't know $Code!\n";
	}

	$PairSize = 4 if $Code eq 'Utf8';
	$PairSize = 2 if $Code ne 'Utf8';

	my ($Mark, $i);
	for (@Data) {
		s/[\n\r]//go;
		$_ = Convert::Cyrillic::toLower ($_, $Code);
		for (split (/[\.\,\-\s\:\;\?\!\'\"\(\)\d<>]+/o)) {
			for $i (0..length ()-$PairSize) {
				$Mark += ${$Table} {substr ($_, $i, $PairSize)};
			}
		}
	}

	$Mark;
}
1;

__END__

=head1 NAME

Lingua::DetectCharset - Routine for automatically detecting cyrillic charset.

=head1 SYNOPSIS

use Lingua::DetectCharset;

$Charset = Lingua::DetectCharset::Detect ($Buffer); 

The returned $Charset is either 'WIN', 'KOI8', 'UTF8' or 'ENG'. The last is return when 
no single cyrillic token are found in buffer.

=head1 DESCRIPTION

This package implements routine for detection charset of the given text snippet. 
Snippet may contain anything from few words to many kilobytes of text, and may 
have line breaks, English text and html tags embedded. 

This routine is implemented using algorithm of statistical analysis of text, 
which was proved to be very efficient and showed around B<99.98% acccuracy> in 
tests.

=head1 AUTHOR

John Neystadt <john@neystadt.org>
Portions by M@kr <http://pub.kem.ru/dev>

=head1 SEE ALSO

perl(1), Convert::Cyrillic(3).

=head1 NOTES

Part of "WWW Cyrillic Encoding Suite"
Get docs and newest version from
	http://www.neystadt.org/cyrillic/

Copyright (c) 1997-98, John Neystadt <http://www.neystadt.org/john/>
You may install this script on your web site for free
To obtain permision for redistribution or any other usage
contact john@neystadt.org.

Drop me a line if you deploy this script on your site.

=cut

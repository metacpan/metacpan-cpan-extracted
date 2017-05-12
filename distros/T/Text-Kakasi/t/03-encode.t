#!/usr/bin/perl
# $Id: 03-encode.t,v 2.0 2003/05/22 18:19:11 dankogai Exp $
# 
# by Dan Kogai <dankogai@dan.co.jp>
#
# This document is written in UTF-8
#


BEGIN{
    use strict;
    unshift @INC, 't';		# for MyTestUtils.pm
    require MyTestUtils;
    eval { require Text::Kakasi };
    unless ($Text::Kakasi::HAS_ENCODE){
	print "1..0 # Encode not supported.\n"; exit;
    } else {
	binmode STDOUT => ':utf8';
    }
	
}

$seq = 1; 
$test = 65;
$| = 1;

print "1..$test\n";
ok($Text::Kakasi::HAS_ENCODE, "encode support");


eval { Encode->import(qw/encode decode decode_utf8/) };

my $src_utf8 =
    decode_utf8("漢字カタカナひらがなの混じったtext.");
my $dst_utf8 = 
    decode_utf8("漢字[kanji]カタカナひらがなの混じ[maji]ったtext.");
my $k = Text::Kakasi->new;

my @enc = qw(utf8 shiftjis euc-jp 7bit-jis
	     UTF-16BE UTF-16LE UTF-32BE UTF-32LE );

for my $in (@enc) {
    my $in_src = $in eq 'utf8' ? $src_utf8 : encode($in, $src_utf8);
    for my $out (@enc) {
	my $out_dst = $out eq 'utf8' ? $dst_utf8 : encode($out, $dst_utf8);
	my $result = $k->set("-i$in", "-o$out", qw/-Ja -f/)->get($in_src);
	ok(($result eq $out_dst), "-i$in -o$out");
    }
}

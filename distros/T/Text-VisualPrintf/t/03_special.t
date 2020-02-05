use strict;
use warnings;
use utf8;
use open IO => ':utf8', ':std';
use Text::VisualPrintf;

use Test::More;

is( Text::VisualPrintf::sprintf( "%5s", '%s'),     '   %s', '%s in %s' );
is( Text::VisualPrintf::sprintf( "%5s", '$^X'),    '  $^X', 'VAR' );
is( Text::VisualPrintf::sprintf( "%5s", '@ARGV'),  '@ARGV', 'ARRAY' );

is( Text::VisualPrintf::sprintf( "(%s, %s, %s)",
				 "\001\001", "日本語", "\001\002" ),
    "(\001\001, 日本語, \001\002)", 'ARRAY' );

is( Text::VisualPrintf::sprintf( "(%s, %s, %s)",
				 "日本語", "\001\001", "\001\002" ),
    "(日本語, \001\001, \001\002)", 'ARRAY' );

is( Text::VisualPrintf::sprintf( "\001\001(%s, %s, %s)",
				 "壱", "日本語", "\001\002" ),
    "\001\001(壱, 日本語, \001\002)", 'ARRAY' );

sub ctrls {
    my($i, $j) = @_;
    my @seq;
    for my $i (1 .. $i) {
	for my $j (1 .. $j//$i) {
	    push @seq, pack "CC", $i, $j;
	}
    }
    join '', @seq;
};

my $longseq = ctrls(5, 3);
is( Text::VisualPrintf::sprintf("$longseq(%5s)", "壱"),
    "$longseq(   壱)",
    'Long binary format.');

 TODO:
{
    local $TODO = "Outlimit";
    my $allseq = ctrls(5, 5);
    is( Text::VisualPrintf::sprintf("$allseq(%5s)", "壱"),
	"$allseq(   壱)",
	'All binary pattern format.');
}

{
    is( Text::VisualPrintf::sprintf("%.4s", "112233"),
	"1122",
	'truncation. (ASCII)');
}

{
    is( Text::VisualPrintf::sprintf("%.3s", "ｱｲｳｴｵ"),
	"ｱｲｳ",
	'truncation. (Half-width KANA)');
}

{
    is( Text::VisualPrintf::sprintf("%.4s", "一二三"),
	"一二",
	'truncation. (Kanji)');
}

{
    is( Text::VisualPrintf::sprintf("%.3s", "一二三"),
	"一 ",
	'truncation. (Kanji with padding)');
}

{
    is( Text::VisualPrintf::sprintf("%.3s", "一23"),
	"一2",
	'truncation. (Kanji + ASCII)');
}

 TODO:
{
    local $TODO = "Truncation to 1 (Half-width KANA)";
    is( Text::VisualPrintf::sprintf("%.1s", "ｱｲｳ"),
	"ｱ",
	'truncation. (1 byte)');
}

{
    is( Text::VisualPrintf::sprintf("%.2s", "ｱイウ"),
	"ｱ ",
	'truncation. (Half-width with padding)');
}

 TODO:
{
    local $TODO = "Truncation to 1";
    is( Text::VisualPrintf::sprintf("%.1s", "一二三"),
	"一",
	'truncation. (1 byte)');
}

done_testing;

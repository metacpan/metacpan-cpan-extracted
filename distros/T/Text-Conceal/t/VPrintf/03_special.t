use strict;
use warnings;
use utf8;
use open IO => ':utf8', ':std';
use lib 't/lib'; use Text::VPrintf;

use Test::More;

is( Text::VPrintf::sprintf( "%5s", '%s'),     '   %s', '%s in %s' );
is( Text::VPrintf::sprintf( "%5s", '$^X'),    '  $^X', 'VAR' );
is( Text::VPrintf::sprintf( "%5s", '@ARGV'),  '@ARGV', 'ARRAY' );

is( Text::VPrintf::sprintf( "(%s, %s, %s)",
				 "\001\001", "日本語", "\001\002" ),
    "(\001\001, 日本語, \001\002)", 'ARRAY' );

is( Text::VPrintf::sprintf( "(%s, %s, %s)",
				 "日本語", "\001\001", "\001\002" ),
    "(日本語, \001\001, \001\002)", 'ARRAY' );

is( Text::VPrintf::sprintf( "\001\001(%s, %s, %s)",
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
    local $" = '';
    wantarray ? @seq : "@seq";
};

my $longseq = ctrls(5, 3);
is( Text::VPrintf::sprintf("$longseq(%5s)", "壱"),
    "$longseq(   壱)",
    'Long binary format.');

# TODO:
{
#    local $TODO = "Outlimit";
    my $allseq = ctrls(5, 5);
    is( Text::VPrintf::sprintf("$allseq(%5s)", "壱"),
	"$allseq(   壱)",
	'5x5 binary pattern format.');
}

for my $i (1..252) {
    my $allseq = join '', (map { pack("C", $_) } 1 .. $i);
    $allseq =~ s///g;
    is( Text::VPrintf::sprintf($allseq =~ s/%/%%/gr . "(%5s)", "壱"),
	"$allseq(   壱)",
	"Many ASCII format ($i)");
}

 TODO:
for my $i (253..255) {
    local $TODO = "Too many ASCII ($i)";
    my $allseq = join '', (map { pack("C", $_) } 1 .. $i);
    is( Text::VPrintf::sprintf($allseq =~ s/%/%%/gr . "(%5s)", "壱"),
	"$allseq(   壱)",
	"Too many ASCII format ($i)");
}

for my $i (1..251) {
    my $allseq = join '', (map { pack("C", $_) } 1 .. $i);
    is( Text::VPrintf::sprintf($allseq =~ s/%/%%/gr . "(%.0s)(%5s)", "壱", "弐"),
	"$allseq()(   弐)",
	"Many ASCII format ($i) with 0-width");
}

 TODO:
# At least 3 uniq characters are necessary to process 0-width result.
# Wrong parameter is used if only 2-characters are available.
# Give up the process if < 2.
for my $i (252..255) {
    local $TODO = "Too many ASCII ($i)";
    my $allseq = join '', (map { pack("C", $_) } 1 .. $i);
    is( Text::VPrintf::sprintf($allseq =~ s/%/%%/gr . "(%.0s)(%5s)", "壱", "弐"),
	"$allseq()(   弐)",
	"Too many ASCII format ($i) with 0-width");
}

# TODO:
{
#    local $TODO = "Outlimit param";
    my @allseq = ctrls(5, 5);
    my $format = "%s" x @allseq . "(%5s)";
    my $expect = join '', @allseq, "(   壱)";
    is( Text::VPrintf::sprintf($format, @allseq, "壱"),
	$expect,
	'All binary pattern paramater.');
}

{
    is( Text::VPrintf::sprintf("%.4s", "112233"),
	"1122",
	'truncation. (ASCII)');
}

{
    is( Text::VPrintf::sprintf("%.3s", "ｱｲｳｴｵ"),
	"ｱｲｳ",
	'truncation. (Half-width KANA)');
}

{
    is( Text::VPrintf::sprintf("%.4s", "一二三"),
	"一二",
	'truncation. (Kanji)');
}

{
    is( Text::VPrintf::sprintf("%.3s", "一二三"),
	"一 ",
	'truncation. (Kanji with padding)');
}

{
    is( Text::VPrintf::sprintf("%.3s", "一23"),
	"一2",
	'truncation. (Kanji + ASCII)');
}

# TODO:
{
#    local $TODO = "Truncation to 1 (Half-width KANA)";
    is( Text::VPrintf::sprintf("%.1s", "ｱｲｳ"),
	"ｱ",
	'truncation. (1 column)');
}

{
    is( Text::VPrintf::sprintf("%.2s", "ｱイウ"),
	"ｱ ",
	'truncation. (Half-width with padding)');
}

# TODO:
{
#    local $TODO = "Truncation to 1";
    # This behavior seems to be consistent.
    is( Text::VPrintf::sprintf("%.1s", "一二三"),
	" ",
	'truncation. (1 column)');
}

# TODO:
{
#     local $TODO = "Impossible...";
# wow! i could do it.
    is( Text::VPrintf::sprintf("%.0s%.2s", qw(一 二)),
	"二",
	'0-width truncation. (two iterms)');
    is( Text::VPrintf::sprintf("%.0s%.0s%.2s", qw(一 二 三)),
	"三",
	'0-width truncation. (three iterms)');
}

done_testing;

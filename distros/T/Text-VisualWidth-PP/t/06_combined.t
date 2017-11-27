use strict;
use warnings;
use utf8;
use Test::More tests => 1+4+3+3+6;
BEGIN { use_ok('Text::VisualWidth::PP') };

binmode STDOUT, ":encoding(utf8)";

ok( Text::VisualWidth::PP::width("123abcﾊﾟﾋﾟﾌﾟパピプ") == 18, 'Normal width');
is( Text::VisualWidth::PP::trim("123ﾊﾟﾋﾟﾌﾟパピプ",7), '123ﾊﾟﾋﾟ', 'Halfwidth Kana trim');
is( Text::VisualWidth::PP::trim("123ﾊﾟﾋﾟﾌﾟパピプ",8), '123ﾊﾟﾋﾟ', 'Halfwidth Kana trim');
is( Text::VisualWidth::PP::trim("123ﾊﾟﾋﾟﾌﾟパピプ",9), '123ﾊﾟﾋﾟﾌﾟ', 'Halfwidth Kana trim');

sub kana {
    my $X_KANA = shift;
    map  { @$_ }
    grep { defined $_->[1] }
    map  { [ $_->[0], eval "\"$_->[1]\"" ] }	# "\N{NAME}"
    map  { [ $_->[0], "\\N{$_->[1]}" ] }	# \N{NAME}
    map  {					# UNICODE NAME
	( [ $_,    "$X_KANA LETTER $_" ],
	  [ "x$_", "$X_KANA LETTER SMALL $_" ] )
    }
    map  {					# KA KI KU KE KO SA ...
	my $c = $_;
	map { "$c$_" } qw(A I U E O);
    }
    'KSTNHMYRW GZDBP' =~ /\A|\w/g;
}
my %k = kana "KATAKANA";
my %h = kana "HIRAGANA";
my %m = (
    'CT' => "\N{COMBINING KATAKANA-HIRAGANA VOICED SOUND MARK}",
    'CM' => "\N{COMBINING KATAKANA-HIRAGANA SEMI-VOICED SOUND MARK}",
    'T'  => "\N{KATAKANA-HIRAGANA VOICED SOUND MARK}",
    'M'  => "\N{KATAKANA-HIRAGANA SEMI-VOICED SOUND MARK}",
    );

# ハ゜ヒ゜フ゜
my $c_papipu = "$k{HA}$m{CM}$k{HI}$m{CM}$k{HU}$m{CM}";
ok( Text::VisualWidth::PP::width("123abc${c_papipu}ﾊﾟﾋﾟﾌﾟ") == 18, 'Combined width');
is( Text::VisualWidth::PP::trim("123${c_papipu}ﾊﾟﾋﾟﾌﾟ",11),
    "123${c_papipu}ﾊﾟ",
    'Combined trim');
is( Text::VisualWidth::PP::trim("123${c_papipu}ﾊﾟﾋﾟﾌﾟ",8),
    "123\x{30cf}\x{309a}\x{30d2}\x{309a}",
    'Combined trim');

# マ゛ミ゛
my $c_mami = "$k{MA}$m{CT}$k{MI}$m{CT}";
is( Text::VisualWidth::PP::trim("${c_mami}",4),
    "${c_mami}",
    'Combined trim');
is( Text::VisualWidth::PP::trim("${c_mami}",3),
    "$k{MA}$m{CT}",
    'Combined trim');
is( Text::VisualWidth::PP::trim("${c_mami}",2),
    "$k{MA}$m{CT}",
    'Combined trim');

# Vietnamese
ok( Text::VisualWidth::PP::width("Mọi người") == 9, 'VI width');
is( Text::VisualWidth::PP::trim("Mọi người",2), "Mọ", 'VI trim');
is( Text::VisualWidth::PP::trim("Mọi người",8), "Mọi ngườ", 'VI trim');

ok( Text::VisualWidth::PP::width("Mọi người") == 9, 'VI combined width');
is( Text::VisualWidth::PP::trim("Mọi người",2), "Mọ", 'VI combined trim');
is( Text::VisualWidth::PP::trim("Mọi người",8), "Mọi ngườ", 'VI decomp trim');

done_testing;

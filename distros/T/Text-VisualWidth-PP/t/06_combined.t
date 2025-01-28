use strict;
use warnings;
use utf8;
use Test::More;
BEGIN { use_ok('Text::VisualWidth::PP') };

binmode STDOUT, ":encoding(utf8)";
binmode STDERR, ":encoding(utf8)";

ok( Text::VisualWidth::PP::width("0123abcﾊﾟﾋﾟﾌﾟパピプ") == 19, 'Normal width');
is( Text::VisualWidth::PP::trim("0123ﾊﾟﾋﾟﾌﾟパピプ",8), '0123ﾊﾟﾋﾟ', 'Halfwidth Kana trim 1');
# \X behave different in perl < 5.12
if ($] < 5.011) {
    is( Text::VisualWidth::PP::trim("0123ﾊﾟﾋﾟﾌﾟパピプ",9), '0123ﾊﾟﾋﾟﾌ', 'Halfwidth Kana trim 2-1');
} else {
    is( Text::VisualWidth::PP::trim("0123ﾊﾟﾋﾟﾌﾟパピプ",9), '0123ﾊﾟﾋﾟ', 'Halfwidth Kana trim 2-2');
}
is( Text::VisualWidth::PP::trim("0123ﾊﾟﾋﾟﾌﾟパピプ",10), '0123ﾊﾟﾋﾟﾌﾟ', 'Halfwidth Kana trim 3');

my %m = (
    'CT' => "\x{3099}", # COMBINING KATAKANA-HIRAGANA VOICED SOUND MARK
    'CM' => "\x{309a}", # COMBINING KATAKANA-HIRAGANA SEMI-VOICED SOUND MARK
    'T'  => "\x{309b}", # KATAKANA-HIRAGANA VOICED SOUND MARK
    'M'  => "\x{309c}", # KATAKANA-HIRAGANA SEMI-VOICED SOUND MARK
    );

# ハ゜ヒ゜フ゜
my $c_papipu = "ハ$m{CM}ヒ$m{CM}フ$m{CM}";
ok( Text::VisualWidth::PP::width("123abc${c_papipu}ﾊﾟﾋﾟﾌﾟ") == 18, 'Combined width');
is( Text::VisualWidth::PP::trim("123${c_papipu}ﾊﾟﾋﾟﾌﾟ",11),
    "123${c_papipu}ﾊﾟ",
    'Combined trim 1');
is( Text::VisualWidth::PP::trim("123${c_papipu}ﾊﾟﾋﾟﾌﾟ",8),
    "123\x{30cf}\x{309a}\x{30d2}\x{309a}",
    'Combined trim 2');

# マ゛ミ゛
my $c_mami = "マ$m{CT}ミ$m{CT}";
is( Text::VisualWidth::PP::trim("${c_mami}",4),
    "${c_mami}",
    'Combined trim 3');
is( Text::VisualWidth::PP::trim("${c_mami}",3),
    "マ$m{CT}",
    'Combined trim 4');
is( Text::VisualWidth::PP::trim("${c_mami}",2),
    "マ$m{CT}",
    'Combined trim 5');

# Vietnamese
ok( Text::VisualWidth::PP::width("Mọi người") == 9, 'VI width');
is( Text::VisualWidth::PP::trim("Mọi người",2), "Mọ", 'VI trim 1');
is( Text::VisualWidth::PP::trim("Mọi người",8), "Mọi ngườ", 'VI trim 2');

ok( Text::VisualWidth::PP::width("Mọi người") == 9, 'VI combined width');
is( Text::VisualWidth::PP::trim("Mọi người",2), "Mọ", 'VI combined trim');
is( Text::VisualWidth::PP::trim("Mọi người",8), "Mọi ngườ", 'VI decomp trim');

done_testing;

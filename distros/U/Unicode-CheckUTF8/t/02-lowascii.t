use Test::More tests => 128;
use Unicode::CheckUTF8 qw(is_utf8);

for (0..127) {
    my $chr = chr $_;
    my $res = is_utf8("A$chr");
    my $exp = 0;
    if ($_ >= 32) { $exp = 1; }
    if ($chr eq "\t") { $exp = 1; }
    if ($chr eq "\n") { $exp = 1; }
    if ($chr eq "\r") { $exp = 1; }
    is($res, $exp, "char: $_");
}


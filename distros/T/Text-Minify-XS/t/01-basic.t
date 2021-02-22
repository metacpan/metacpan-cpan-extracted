use utf8;

use Test::More;
use Test::Warnings qw/ warning /;

use Encode qw/ encode_utf8 /;

use_ok "Text::Minify::XS", "minify";

is minify("") => "", "empty";

is minify(" ") => "", "empty";

is minify("\t\t \n") => "", "empty";

is minify("simple") => "simple";

is minify("\n  simple") => "simple";

is minify("\n  simple\n") => "simple\n";

is minify("\n\n  simple\r\n test\n\r") => "simple\ntest\n";

is minify("simple  \n") => "simple\n";

is minify("simple  \nstuff  ") => "simple\nstuff";

is minify("\r\n\r\n\t0\r\n\t\t1\r\n") => "0\n1\n";

is minify(" £ simple") => "£ simple";

{
    my $str = chr(0x2020) . "x";
    is minify(" " . $str) => $str;
}

{
    my $str = chr(0x4e20) . "x";
    is minify(" " . $str) => $str;
}

{
    my $n = chr(0x2028);
    is minify("${n}x   ${n}") => "${n}x${n}";
}

{
    is minify(" \0 x") => "\0 x";

    is minify("\0") => "\0", "null";

    is minify(" \0 ") => "\0", "null";

}

my $warning = warning {
    my $n = chr(160);
    my $r = minify($n);
};
like $warning, qr/Malformed UTF-8 character/;

{
    my $n = encode_utf8(chr(160));
    is minify($n) => $n;
}

done_testing;

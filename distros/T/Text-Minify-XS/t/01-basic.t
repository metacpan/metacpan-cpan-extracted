use utf8;

use Test::More;

use_ok "Text::Minify::XS", "minify";

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
}

done_testing;

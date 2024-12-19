use utf8;

use v5.14;
use warnings;

use Test2::V0;
use Test2::Tools::Exception qw( lives );
use Test2::Tools::Warnings qw( warning );

use Encode 2.85 qw/ encode_utf8 /;

use Text::Minify::XS "minify";

is minify("") => "", "empty";

is minify(" ") => "", "empty";

is minify("\t\t \n") => "", "empty";

is minify("simple") => "simple";

is minify("\nsimple") => "simple";

is minify("\n  simple") => "simple";

is minify("\n  simple\n") => "simple\n";

is minify("\r  simple \r ") => "simple\n";

is minify("\n\n  simple\r\n test\n\r") => "simple\ntest\n";

is minify("simple  \n") => "simple\n";

is minify("simple  \r") => "simple\n";

is minify("simple  \nstuff  ") => "simple\nstuff";

is minify("\r\n\r\n\t0\r\n\t\t1\r\n") => "0\n1\n";

is minify(" £ ") => "£";

is minify(" £ simple") => "£ simple";

{
    my $str = encode_utf8( chr(0x2020) . "x" );
    is minify(" " . $str) => $str;
}

{
    my $str = encode_utf8( chr(0x4e20) . "x" );
    is minify(" " . $str) => $str;
}

{
    my $n = encode_utf8( chr(0x2028) );
    is minify("${n}x   ${n}${n}") => "${n}x${n}";
}

{
    my $n = encode_utf8( chr(0x2028) );
    is minify("${n}x   ${n}${n} ") => "${n}x${n}";
}

{
    is minify(" \0 x") => "\0 x";

    is minify("\0") => "\0", "null";

    is minify(" \0 ") => "\0", "null";

}

ok lives {

    my $warning = warning {
        my $n = chr(160);
        my $r = eval { minify($n) };
    };
    like $warning, qr/Malformed UTF-8 character/;

};

ok lives {

    my $warning = warning {
        my $n = chr(160);
        my $r = eval { minify("  $n  \n  \n") };
    };
    like $warning, qr/Malformed UTF-8 character/;
};

ok lives {

    my $n = eval { encode_utf8( chr(160) ) };
    is minify($n) => $n;

};

done_testing;

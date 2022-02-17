use utf8;

use Test::More 1.302183;

use_ok "Text::Minify::XS", "minify_utf8";

is minify_utf8("") => "", "empty";

is minify_utf8(" ") => "", "empty";

is minify_utf8("\t\t \n") => "", "empty";

is minify_utf8("simple") => "simple";

is minify_utf8("\nsimple") => "simple";

is minify_utf8("\n  simple") => "simple";

is minify_utf8("\n  simple\n") => "simple\n";

is minify_utf8("\r  simple \r ") => "simple\n";

is minify_utf8("\n\n  simple\r\n test\n\r") => "simple\ntest\n";

is minify_utf8("simple  \n") => "simple\n";

is minify_utf8("simple  \r") => "simple\n";

is minify_utf8("simple  \nstuff  ") => "simple\nstuff";

is minify_utf8("\r\n\r\n\t0\r\n\t\t1\r\n") => "0\n1\n";

done_testing;

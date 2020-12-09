use Test::More;

use_ok "Text::Minify::XS", "minify";

is minify("simple") => "simple";

is minify("\n  simple") => "simple";

is minify("\n  simple\n") => "simple\n";

is minify("\n\n  simple\r\n test\n\r") => "simple\ntest\n";

is minify("simple  \n") => "simple\n";

is minify("simple  \nstuff  ") => "simple\nstuff";

is minify("\r\n\r\n\t0\r\n\t\t1\r\n") => "0\n1\n";

done_testing;

use warnings;
use strict;
use Test::More;
use Test::Exception;

plan tests => 5;

use Text::MiniTmpl qw( render );


throws_ok { render('t/tmpl/bad_syntax.txt') }
    qr{\./t/tmpl/bad_syntax.txt line 2, near "for @"};
throws_ok { render('t/tmpl/subdir/include_bad_syntax.txt') }
    qr{\./t/tmpl/bad_syntax.txt line 2, near "for @"};
throws_ok { render('./t/tmpl/bad_strict.txt') }
    qr{"\$user".*at \./t/tmpl/bad_strict.txt line 3};
my $warn; local $SIG{__WARN__} = sub { $warn = $_[0] };
lives_ok { render('./t/tmpl/bad_warning.txt') };
like $warn, qr{Useless.*at \./t/tmpl/bad_warning.txt line 2}, 'warning';


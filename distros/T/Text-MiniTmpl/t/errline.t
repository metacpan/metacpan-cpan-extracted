use warnings;
use strict;
use Test::More;
use Test::Exception;

use Text::MiniTmpl qw( render );

my @line = (4,1,2,2,2,3,3,7,7,8);

plan tests => 0+@line;

local $SIG{__WARN__} = sub{};
for my $i (0 .. $#line) {
    throws_ok { render("t/tmpl/errline/$i.txt") }
        qr{Died at \./t/tmpl/errline/$i\.txt line $line[$i]\.};
}


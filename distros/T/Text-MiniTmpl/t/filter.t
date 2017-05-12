use warnings;
use strict;
use Test::More;

plan tests => 1;

use Text::MiniTmpl qw( render );

is render('t/tmpl/filter.txt', users=>['powerman','someone']),
    "\n"
  . "\n"
  . "Hello, powerman!\n"
  . "Hello, someone!\n"
  . "Hello, GHOST!\n"
  . "\n"
    ;


use strict;
use warnings;

use Test::More tests => 5;

use_ok("WWW::Metalgate::Column");
my $column = WWW::Metalgate::Column->new;
is($column->uri, "http://www.metalgate.jp/column.htm");
isa_ok($column->uri, "URI");
can_ok($column, "years");
my @years = $column->years;
is(0+@years, @{[1992 .. 2007]}, 'number of years');

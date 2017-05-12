#
# $Id: 06_indent_level_increase.t 4552 2010-09-23 10:40:29Z james $
#

use strict;
use warnings;

use Test::More;
plan tests => 4;

use_ok('Text::Indent');

my $i = Text::Indent->new;
is( $i->level, 0, "level initialized to 0");
$i->increase;
is( $i->level, 1, "level increased to 1");
$i->increase(2);
is( $i->level, 3, "level increased to 3");

#
# EOF

#
# $Id$
#

use strict;
use warnings;

use Test::More;
plan tests => 3;

use_ok('Text::Indent');

my $i = Text::Indent->new( Level => 5 );
is( $i->level, 5, "level initialized to 5");
$i->reset;
is( $i->level, 0, "level reset to 0");

#
# EOF

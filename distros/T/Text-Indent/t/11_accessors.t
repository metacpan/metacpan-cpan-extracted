#
# $Id: 11_accessors.t 4552 2010-09-23 10:40:29Z james $
#

use strict;
use warnings;

use Test::More;
plan tests => 5;

use_ok('Text::Indent');

my @accessors = qw|
    spaces
    spacechar
    level
    add_newline
|;
for( @accessors ) {
    can_ok('Text::Indent', $_);
}

#
# EOF

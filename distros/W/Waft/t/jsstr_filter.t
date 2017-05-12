
use Test;
BEGIN { plan tests => 2 };

use strict;
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

require Waft;

my $text = qq{\x0A\x0D"'/<>\\};
my $filtered = q{\n\r\"\'\/\x3C\x3E\\\\};

ok( Waft->jsstr_filter($text) eq $filtered );
ok( Waft->jsstr_filter("$text$text") eq "$filtered$filtered" );

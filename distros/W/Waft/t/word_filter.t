
use Test;
BEGIN { plan tests => 2 };

use strict;
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

require Waft;

my $text = qq{"&'45678\t<br />\n};
my $filtered
    = "&quot;&amp;&#39;45678\t&lt;br /&gt;\n";

ok( Waft->word_filter($text) eq $filtered );
ok( Waft->word_filter("$text$text") eq "$filtered$filtered" );

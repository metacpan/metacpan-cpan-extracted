
use Test;
BEGIN { plan tests => 2 };

use strict;
BEGIN { eval { require warnings } ? 'warnings'->import : ( $^W = 1 ) }

require Waft;

my $text = qq{ "&'5678\t<br />\n};
my $filtered = q{&nbsp;&quot;&amp;&#39;5678}
               . qq{ &nbsp; &nbsp; &nbsp; &nbsp;&lt;br /&gt;<br />\n};

ok( Waft->text_filter($text) eq $filtered );
ok( Waft->text_filter("$text$text") eq "$filtered$filtered" );

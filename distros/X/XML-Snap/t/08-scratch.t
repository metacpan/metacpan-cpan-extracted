#!perl -T

use Test::More tests => 6;
use XML::Snap;
use Data::Dumper;

my $xml = XML::Snap->new('scratch');
is ($xml->string, "<scratch/>");
$xml->add_pretty (XML::Snap->parse('<middle test="test"/>'));
is ($xml->string."\n", <<'EOF');
<scratch>
<middle test="test"/>
</scratch>
EOF

$text = "test text";
$xml->add_pretty (\$text);
is ($xml->string."\n", <<'EOF');
<scratch>
<middle test="test"/>
test text
</scratch>
EOF

$xml->prepend_pretty(XML::Snap->new('top'));
is ($xml->string."\n", <<'EOF');
<scratch>
<top/>
<middle test="test"/>
test text
</scratch>
EOF

$xml->prepend(XML::Snap->new('open'));
is ($xml->string."\n", <<'EOF');
<scratch><open/>
<top/>
<middle test="test"/>
test text
</scratch>
EOF

$xml->prepend_pretty(XML::Snap->new('start'));
is ($xml->string."\n", <<'EOF');
<scratch>
<start/><open/>
<top/>
<middle test="test"/>
test text
</scratch>
EOF

#done_testing();
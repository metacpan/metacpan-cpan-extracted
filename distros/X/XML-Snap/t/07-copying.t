#!perl -T

use Test::More;
use XML::Snap;
use Data::Dumper;

my $xml = XML::Snap->parse(<<'EOF');
<test>
<t1 a="aaa">
<t2/><t2/>
</t1>
</test>
EOF

is($xml->string . "\n", <<'EOF');
<test>
<t1 a="aaa">
<t2/><t2/>
</t1>
</test>
EOF

my $copy1 = $xml->copy();
$copy1->set("mark", "test!");
is($xml->string . "\n", <<'EOF');  # Note: parse doesn't include text outside first tag.
<test>
<t1 a="aaa">
<t2/><t2/>
</t1>
</test>
EOF
is($copy1->string . "\n", <<'EOF');
<test mark="test!">
<t1 a="aaa">
<t2/><t2/>
</t1>
</test>
EOF

my $t1 = $xml->first('t1')->copy;
is($t1->parent, undef);
is($t1->string ."\n", <<'EOF');
<t1 a="aaa">
<t2/><t2/>
</t1>
EOF

my $transformed = $xml->copy(['t2', undef, undef, sub { $_[0]->{name} = 't3'; $_[0]; }]); # Transform t2 nodes into t3 nodes during the copy.
is($transformed->string . "\n", <<'EOF');
<test>
<t1 a="aaa">
<t3/><t3/>
</t1>
</test>
EOF

my $text = XML::Snap->parse("<test><i>Some plain text</i></test>");
is ($text->string, "<test><i>Some plain text</i></test>");
my $caps = $text->copy(sub {$_[0] =~ tr/a-z/A-Z/; $_[0];});
is ($caps->string, "<test><i>SOME PLAIN TEXT</i></test>");

# Both at once!
my $tcaps = $caps->copy(['i', undef, undef, sub { $_[0]->{name} = 'b'; $_[0]; }], sub {$_[0] =~ tr/A-Z/a-z/; $_[0];});
is ($tcaps->string, "<test><b>some plain text</b></test>");

$text = XML::Snap->parse_with_refs("<test><i>Some plain text</i></test>");
is ($text->string, "<test><i>Some plain text</i></test>");
$caps = $text->copy(sub {$_[0] =~ tr/a-z/A-Z/; $_[0];});
is ($caps->string, "<test><i>SOME PLAIN TEXT</i></test>");


done_testing();
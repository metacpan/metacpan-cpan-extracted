use strict;
use warnings;

use Data::Dumper;
use Test::Most;

BEGIN { use_ok('XML::PP') }

my $parser = new_ok('XML::PP');

my $xml = q{
<note id="n1">
	<to priority="1">Tove</to>
	<from>Jani</from>
	<heading>Reminder</heading>
	<body importance="high">Don't forget me this weekend!</body>
</note>
};

my $tree = $parser->parse($xml);

diag(Data::Dumper->new([$tree])->Dump()) if($ENV{'TEST_VERBOSE'});
diag(Data::Dumper->new([XML::PP->collapse_structure($tree)])->Dump()) if($ENV{'TEST_VERBOSE'});

ok($tree, 'Parser returned a tree');

is($tree->{name}, 'note', 'Top-level tag is <note>');
ok($tree->{attributes}->{id}, 'note has id attribute');
is(scalar @{ $tree->{children} }, 4, 'note has 4 children');

is($tree->{children}[0]{name}, 'to', 'First child is <to>');
ok($tree->{children}[0]{attributes}->{priority}, '<to> has priority attribute');
like($tree->{children}[0]{children}[0]{text}, qr/Tove/, '<to> contains "Tove"');

is($tree->{children}[1]{name}, 'from', 'Second child is <from>');
like($tree->{children}[1]{children}[0]{text}, qr/Jani/, '<from> contains "Jani"');

is($tree->{children}[2]{name}, 'heading', 'Third child is <heading>');
like($tree->{children}[2]{children}[0]{text}, qr/Reminder/, '<heading> contains "Reminder"');

is($tree->{children}[3]{name}, 'body', 'Fourth child is <body>');
ok($tree->{children}[3]{attributes}->{importance}, '<body> has importance attribute');
like($tree->{children}[3]{children}[0]{text}, qr/Don't forget me this weekend!/, '<body> content matches');

my $self_closing = q{
<document>
	<line break="yes"/>
	<text>Hello</text>
</document>
};

my $doc = $parser->parse($self_closing);
ok($doc, 'Parsed document with self-closing tag');
is($doc->{name}, 'document', 'Root is <document>');
is(scalar @{ $doc->{children} }, 2, '<document> has 2 children');

is($doc->{children}[0]{name}, 'line', 'First child is <line>');
ok($doc->{children}[0]{attributes}->{break}, '<line> has break attribute');
is(scalar @{ $doc->{children}[0]{children} || [] }, 0, '<line> has no children');

is($doc->{children}[1]{name}, 'text', 'Second child is <text>');
like($doc->{children}[1]{children}[0]{text}, qr/Hello/, '<text> content matches');

my $namespaced = q{
<ns:note xmlns:ns="http://example.com/ns">
	<ns:to>Tove</ns:to>
</ns:note>
};

my $ns_tree = $parser->parse($namespaced);
ok($ns_tree, 'Parsed namespaced document');
is($ns_tree->{name}, 'note', 'Root name is note');
is($ns_tree->{ns}, 'ns', 'Root ns is ns');
is($ns_tree->{ns_uri}, 'http://example.com/ns', 'ns URI matches');

is($ns_tree->{children}[0]{name}, 'to', 'Child name is to');
is($ns_tree->{children}[0]{ns}, 'ns', 'Child ns is ns');
is($ns_tree->{children}[0]{ns_uri}, 'http://example.com/ns', 'Child ns URI matches');
like($ns_tree->{children}[0]{children}[0]{text}, qr/Tove/, 'Child text matches');

done_testing();

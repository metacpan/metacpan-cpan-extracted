#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;

BEGIN { use_ok('XML::PP') }

my $parser = new_ok('XML::PP');

# Basic named and numeric entities
my $xml = <<'XML';
<root title="Tom &amp; Jerry &#39;Cartoon&#39;">
  &lt;hello&gt; &amp; welcome &quot;friend&quot; &apos;pal&apos; &#x41;&#65;
</root>
XML

my $tree = $parser->parse($xml);
is $tree->{name}, 'root', 'Root tag is correct';
is $tree->{attributes}{title}, q{Tom & Jerry 'Cartoon'}, 'Attribute entities decoded (named + numeric)';
is $tree->{children}[0]{text}, q{<hello> & welcome "friend" 'pal' AA}, 'Text entities decoded (named + numeric)';

# Malformed entities (unknown)
my $malformed_entity_xml = '<root title="Tom &unknown;">Bad entity</root>';
my $tree2 = $parser->parse($malformed_entity_xml);
ok defined($tree2), 'Parser did not crash on unknown entity';
is $tree2->{attributes}{title}, 'Tom &unknown;', 'Unknown entity left untouched';

# Unescaped ampersands (technically invalid XML)
my $bad_ampersand_xml = '<root title="Tom & Jerry">Invalid amp</root>';
my $tree3 = $parser->parse($bad_ampersand_xml);
ok defined($tree3), 'Parser did not crash on unescaped ampersand';
is $tree3->{attributes}{title}, 'Tom & Jerry', 'Unescaped ampersand left as-is (permissive)';

# Strict mode: should die on unknown entity
throws_ok {
	my $p = XML::PP->new(strict => 1);
	$p->parse('<root title="Tom &unknown;">bad</root>');
} qr/Unknown or malformed XML entity/, 'Strict mode dies on unknown entity';

# Strict mode: should die on unescaped ampersand
throws_ok {
	my $p = XML::PP->new(strict => 1);
	$p->parse('<root title="Tom & Jerry">bad</root>');
} qr/Unescaped ampersand/, 'Strict mode dies on unescaped ampersand';

# Warning mode: unknown entity should warn but not die
my $warned;
{
	local $SIG{__WARN__} = sub { $warned = shift };
	my $p = XML::PP->new(warn_on_error => 1);
	my $tree = $p->parse('<root title="Tom &unknown;">bad</root>');
	ok(defined $tree, 'Parser survived unknown entity in warning mode');
	like($warned, qr/XML Parsing Error/, 'Warning issued for unknown entity');
}

# Warning mode: unescaped & should warn
{
	local $SIG{__WARN__} = sub { $warned = shift };
	my $p = XML::PP->new(warn_on_error => 1);
	my $tree = $p->parse('<root title="Tom & Jerry">bad</root>');
	ok defined $tree, 'Parser survived unescaped ampersand in warning mode';
	like($warned, qr/Unescaped ampersand/, 'Warning issued for unescaped ampersand');
}

done_testing();

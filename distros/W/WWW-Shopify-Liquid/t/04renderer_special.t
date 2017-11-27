use strict;
use warnings;
use Test::More;

use_ok("WWW::Shopify::Liquid");
use_ok("WWW::Shopify::Liquid::Operator");
use_ok("WWW::Shopify::Liquid::Lexer");
use_ok("WWW::Shopify::Liquid::Parser");
use_ok("WWW::Shopify::Liquid::Optimizer");
use_ok("WWW::Shopify::Liquid::Renderer");
my $liquid = WWW::Shopify::Liquid->new;
my $lexer = $liquid->lexer;
my $parser = $liquid->parser;
my $optimizer = $liquid->optimizer;
my $renderer = $liquid->renderer;

use WWW::Shopify::Liquid qw(liquid_render_text);

my $text = liquid_render_text({ test => "a" }, "{% assign test = 2 %}{{ test }}"); is($text, '2');

$text = liquid_render_text({ files => [{ extension => 'asd' }, { extension => 'fgdfg'}] }, "{% assign has_pdf = 0 %}{% for file in files %}{% if file.extension == 'pdf' %}{% assign has_pdf = 1%}{% endif %}{% endfor %} {{ has_pdf }}");
is($text, " 0");

$text = liquid_render_text({ files => [{ extension => 'asd' }, { extension => 'pdf'}] }, "{% assign has_pdf = 0 %}{% for file in files %}{% if file.extension == 'pdf' %}{% assign has_pdf = 1%}{% endif %}{% endfor %} {{ has_pdf }}");
is($text, " 1");

$text = liquid_render_text({ files => [{ extension => "pdf" }, { extension => "wrd" }, { extension => "png" }] }, '{{ files.first.extension }}|{{files.last.extension}}');
my ($first, $last) = split(/\|/, $text);
is($first, "pdf");
is($last, "png");

use DateTime;

my $date = DateTime->now;
$text = liquid_render_text({ date => $date }, 'a{{ date }}');
is($text, "a" . $date->iso8601);

$text = liquid_render_text({ date => $date }, 'a{{ date | date: "%Y" }}');
is($text, "a" . $date->strftime("%Y"));

$date = DateTime->new(year => int(rand()*14)+2000, month => int(rand()*12)+1, day => int(rand()*26)+1);
$text = liquid_render_text({ date => $date }, 'a{{ date }}');
is($text, "a" . $date->iso8601);

$text = liquid_render_text({ date => $date }, 'a{{ date | date: "%Y" }}');
is($text, "a" . $date->strftime("%Y"));


$date = DateTime->new(year => int(rand()*14)+2000, month => int(rand()*12)+1, day => int(rand()*26)+1);
my $ast = $liquid->parse_tokens($liquid->parse_text("a{{ date | date: '%Y' }}"));

$text = $liquid->render_ast({ date => $date }, $ast);
is($text, "a" . $date->strftime("%Y"));

$date = DateTime->new(year => int(rand()*14)+2000, month => int(rand()*12)+1, day => int(rand()*26)+1);
$text = $liquid->render_ast({ date => $date }, $ast);
is($text, "a" . $date->strftime("%Y"));

$ast = $liquid->parse_tokens($liquid->parse_text("{% for a in b %}{{ a }}{% endfor %}"));
$text = $liquid->render_ast({ b => [1..10] }, $ast);
is($text, join("", 1..10));

$text = $liquid->render_ast({ b => [10..20] }, $ast);
is($text, join("", 10..20));

$ast = $liquid->parse_tokens($liquid->parse_text("{% assign a.b = 3 %}{{ a.b }}"));
my $hash;
($text, $hash) = $liquid->render_ast({ }, $ast);
is($text, 3);
ok($hash->{a});
is($hash->{a}->{b}, 3);

# OOO
is($liquid->render_text({}, "{{ 1 + 6 * 2 }}"), 13);
is($liquid->render_text({}, "{{ 2 * 6 + 2 }}"), 14);

$hash = { global => { total_orders => 100 }, order => { total_price => 400 } };
($text, $hash) = $liquid->render_text($hash, "{% if global.total_orders > 10000 %}{% assign global.total_orders = 0 %}{% endif %}{% assign global.total_orders = global.total_orders + order.total_price %}{{ global.total_orders }}");
is($text, '500');
is($hash->{global}->{total_orders}, 500);
($text, $hash) = $liquid->render_text($hash, "{% if global.total_orders > 10000 %}{% assign global.total_orders = 0 %}{% endif %}{% assign global.total_orders = global.total_orders + order.total_price %}{{ global.total_orders }}");
is($text, '900');
is($hash->{global}->{total_orders}, 900);

is($liquid->render_text({}, '{% unless cart.attributes.registry_id == "1" %}success{% endunless %}'), "success");

is($liquid->render_text({}, '{% assign a = "A" + 2 %}{{ a }}'), "A2");
is($liquid->render_text({}, '{% assign a = 1 + 2 %}{{ a }}'), "3");
is($liquid->render_text({}, "{% assign a = 1 %}{% assign field_name = 'Runner #' + a + ' (full name)' %}{{ field_name }}"), "Runner #1 (full name)");

use Data::Dumper;

my $code = "{% for note in order.note_attributes %}{% if note.name == 'Edition' %}{% assign notes = note.value | split: '\\n' %}{% for line in notes %}{% if line contains line_item.title %}{% assign parts = line | split: 'edition: ' %}{{ parts | last }}{% endif %}{% endfor %}{% endif %}{% endfor %}";
is($liquid->render_text({
	order => {
		note_attributes => [
			{ name => 'a', value => 'b' },
			{ name => 'Edition', value => 'The Thoughts in My Head #30: Free Spirit - 11x14 / Unframed edition: 3/250' }
		]
	},
	line_item => {
		title => 'The Thoughts in My Head #30: Free Spirit - 11x14 / Unframed',
	}
}, $code), '3/250');

use utf8;
# utf8 checking.
is($liquid->render_text({ a => '✓' }, "{{ a }}"), "✓");

is($liquid->render_text({ a => "3 months" }, "{% if a contains 'month' %}{{ a }}{% endif %}"), "3 months");
is($liquid->render_text({ a => "3 asdfddsafg" }, "{% if a contains 'month' %}{{ a }}{% endif %}"), "");

is($liquid->render_text({ a => { b => [1, 4,6] } }, "{% if a.b.size > 2 %}{{ a.b.size }}{% endif %}"), "3");

my $address = {
	address1 => "1121 N. Taylor St. Apt. C",
	address2 => "",
	city => "Arlington",
	company =>  undef,
	country  => "United States",
	country_code => "US",
	first_name  => "Laura",
	id => 329155013,
	last_name => "Zamperini",
	name => "Laura Zamperini",
	phone => "",
	province => "Virginia",
	province_code => "VA",
	zip => '22201'
};

use File::Slurp;
# The version of this can change the MD5 hash, as it writes its version # into the first byte.
write_file("/tmp/test2", freeze($address));

use Storable qw(freeze);
use Digest::MD5 qw(md5_hex);
$Storable::canonical = 1;

is($liquid->render_text({ customer => { default_address => $address } }, "{{ customer.default_address | md5 }}"), "1149cd1396304e6f9784751a8f61e839");

is($liquid->render_text({ created_at => DateTime->now, updated_at => DateTime->now }, "{% if created_at == updated_at %}1{% else %}0{% endif %}"), 1);

is($liquid->render_text({ a => "asjfskldghklfjg" }, "{% if a =~ 'asj' %}1{% if a =~ 'aaa' %}1{% else %}0{% endif %}{% else %}0{% endif %}"), '10');
is($liquid->render_text({ a => "asjfskldghklfjg" }, "{% if a =~ '(afbdfbdf|asj)' %}1{% else %}0{% endif %}"), '1');
is($liquid->render_text({ order => { line_items => [{ sku => 'a' }] } }, "{% for line_item in order.line_items %}{% if line_item.sku =~ '(a|asj)' %}1{% endif %}{% endfor %}"), '1');

is($liquid->render_text({}, "{% for line_item in order.line_items %}{% if line_item.sku =~ 'a' %}1{% endif %}{% endfor %}"), '');

is($liquid->render_text({}, "{{ 'asfdsdfsa.jpg' | replace: '.jpg', '_large.jpg' }}"), 'asfdsdfsa_large.jpg');

is($liquid->render_text({ today => DateTime->today,  now => DateTime->now }, "{{ (now - today) / 3600 | floor }}"), int((DateTime->now->epoch - DateTime->today->epoch) / 3600));

is($liquid->render_text({ a => undef }, "{% if a == null %}1{% endif %}"), '1');
is($liquid->render_text({ a => 1 }, "{% if a == null %}1{% endif %}"), '');
is($liquid->render_text({ }, "{% if 0 == null %}1{% endif %}"), '');
is($liquid->render_text({ }, "{% assign b = 5 | plus: 5 %}{{ b }}"), '10');

package A;
sub new { return bless { }; }
package main;

# Blessedness should be preserved.
($text, $hash) = $liquid->render_text({ l =>  A->new }, "{% assign b = l %}");
ok($hash->{b});
isa_ok($hash->{b}, 'A');


($text, $hash) = $liquid->render_text({ }, "{% assign color = {} %}");
ok($hash);
ok(exists $hash->{color});
isa_ok($hash->{color}, 'HASH');
is(int(keys(%{$hash->{color}})), 0);

($text, $hash) = $liquid->render_text({ }, "{% assign color = [] %}");
ok($hash);
ok(exists $hash->{color});
isa_ok($hash->{color}, 'ARRAY');
is(int(@{$hash->{color}}), 0);


($text, $hash) = $liquid->render_text({ a => 10000, b => 10 }, "{{ a / b * 100 }}");
is($text, "100000");

($text, $hash) = $liquid->render_text({ }, "{% for a in (1..10) %}{% if a == 5 %}{% break %}{% endif %}{{ a }}{% endfor %}");
is($text, "1234");


($text, $hash) = $liquid->render_text({ }, "{% for a in (1..10) %}{% if a == 5 %}{% continue %}{% endif %}{{ a }}{% endfor %}");
is($text, "1234678910");

($text, $hash) = $liquid->render_text({ }, "{% for a in (1..10) %}a{% if a == 5 %}{% break %}{% endif %}{{ a }}{% endfor %}");
is($text, "a1a2a3a4a");

($text, $hash) = $liquid->render_text({ }, "{% for a in (1..10) %}a{% if a == 5 %}{% continue %}{% endif %}{{ a }}{% endfor %}");
is($text, "a1a2a3a4aa6a7a8a9a10");



package WWW::Shopify::Liquid::Tag::TestTag;
use base 'WWW::Shopify::Liquid::Tag::Enclosing';

sub operate {
	my ($self, $hash, $content, @arguments) = @_;
	return $content;
}

package main;

$liquid->register_tag('WWW::Shopify::Liquid::Tag::TestTag');
$text = $liquid->render_text({ }, "{% test_tag %}ASD{% endtest_tag %}");

is($text, 'ASD');

done_testing(); 
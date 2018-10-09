use strict;
use warnings;
use Test::More;

use_ok("WWW::Shopify::Liquid");use strict;
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

my $test = q(<script type='text/javascript' src="//{{ js_catalyst_src }}/hmac-sha256.js"></script>);

my $ast = $parser->parse_tokens($lexer->parse_text($test));
ok($ast);

$ast = $optimizer->optimize({}, $ast);


my @tokens = $parser->unparse_tokens($ast);

my $text = $lexer->unparse_text(@tokens);
is($text, q(<script type='text/javascript' src="//{{js_catalyst_src}}/hmac-sha256.js"></script>));

$test = q({% unless a %}asdf{% endunless %});

$ast = $parser->parse_tokens($lexer->parse_text($test));
ok($ast);

$ast = $optimizer->optimize({}, $ast);
@tokens = $parser->unparse_tokens($ast);

$text = $lexer->unparse_text(@tokens);
is($text, '{%unless a%}asdf{%endunless%}');

$ast = $parser->parse_tokens($lexer->parse_text($test));
ok($ast);

$ast = $optimizer->optimize({ a => 1 }, $ast);
@tokens = $parser->unparse_tokens($ast);

$text = $lexer->unparse_text(@tokens);
is($text, '');




$ast = $parser->parse_tokens($lexer->parse_text($test));
ok($ast);
$ast = $optimizer->optimize({ a => 0 }, $ast);
@tokens = $parser->unparse_tokens($ast);

$text = $lexer->unparse_text(@tokens);
is($text, 'asdf');




$test = q({% if a %}asdf{% endif %});

$ast = $parser->parse_tokens($lexer->parse_text($test));
ok($ast);

$ast = $optimizer->optimize({}, $ast);
@tokens = $parser->unparse_tokens($ast);

$text = $lexer->unparse_text(@tokens);
is($text, '{%if a%}asdf{%endif%}');

$ast = $parser->parse_tokens($lexer->parse_text($test));
ok($ast);

$ast = $optimizer->optimize({ a => 0 }, $ast);
@tokens = $parser->unparse_tokens($ast);

$text = $lexer->unparse_text(@tokens);
is($text, '');


$ast = $parser->parse_tokens($lexer->parse_text($test));
ok($ast);
$ast = $optimizer->optimize({ a => 1 }, $ast);
@tokens = $parser->unparse_tokens($ast);

$text = $lexer->unparse_text(@tokens);
is($text, 'asdf');



$test = q(<script type='text/javascript'>
var giftReggieCookieName = "giftreggie_session_cookie";
// SIGH; IE8.
if (!Object.keys) {
	Object.keys = function(obj) {
		var keys = [];

		for (var i in obj) {
			if (obj.hasOwnProperty(i)) {
				keys.push(i);
		}
	}
	return keys;
	};
}
</script>

<script type='text/javascript'>
	var valid = false;
	if (typeof jQuery != 'undefined') {  
		var version = jQuery().jquery;
		var groups = /(\d+)\.(\d+)/.exec(version);
		if (groups[1] > 1 || groups[2] >= 5)
			valid = true;
	}
	if (!valid && typeof jQuery != 'undefined')
		alert("Please upgrade your jQuery implementation to at least 1.5. You can learn how to do this by visting GiftReggie's setup guide, or sending an email to gift-reggie@eshopadmin.com.");
	else if (!valid)
		alert("Please install jQuery in the head of your theme. You can learn how to do this by visting GiftReggie's setup guide, or sending an email to gift-reggie@eshopadmin.com.");
	// Check to see if the actual URL matches the main domain. If it doesn't, throw up an alert.
	{% unless testing %}
		if (window.location.hostname != "{{ shop.domain }}")
			alert("You've entered Gift Reggie through " + window.location.hostname + ". For it to work properly you must enter through {{ shop.domain }}! Please redirect your links to there.");
	{% endunless %}
</script>

<script type='text/javascript' src="//{{ external_hostline }}/{{ js_catalyst_src }}/hmac-sha256.js"></script>
<script type='text/javascript' src="//{{ external_hostline }}/{{ js_catalyst_src }}/oauth.js"></script>
<script type='text/javascript' src="//{{ external_hostline }}/{{ js_catalyst_src }}/common.js"></script>

<script type='text/javascript'>
	userSessionCookieName = giftReggieCookieName;
</script>
{% if customer_account_integration %}
{% endif %}

<script type='text/javascript'>
	var displayModal;
	(function( $ ) {
		displayModal = function(text) {
			var modal = $('<div class="giftreggie-modal" style="display:none; background: #FFF; font-size: 24px; line-height: 24px; border: 1px solid #000; padding: 12px; margin: auto; top: 0; bottom: 0; left: 0; right: 0; position: fixed; width: 320px; z-index: 1000;">\
			<div class="giftreggie-modal-inner">\
			<div class="giftreggie-modal-top">' + text + '</div>\
			<div class="giftreggie-modal-bottom"><button style="margin: 8px auto; display: block; font-size: 18px; padding: 4px 8px;">OK</button></div></div></div>');
			modal.appendTo('body');
			modal.fadeIn();
			modal.height(modal.children(".giftreggie-modal-inner").height());
			var deferred = $.Deferred();
			modal.find('button').click(function() { modal.fadeOut(400, function() { modal.remove(); }); deferred.resolve(); });
			return deferred;
		}
	})(jQuery);
</script>);

$ast = $parser->parse_tokens($lexer->parse_text($test));
ok($ast);
$ast = $optimizer->optimize({}, $ast);
@tokens = $parser->unparse_tokens($ast);

$text = $lexer->unparse_text(@tokens);

$test = q(<script type='text/javascript'>
var giftReggieCookieName = "giftreggie_session_cookie";
// SIGH; IE8.
if (!Object.keys) {
	Object.keys = function(obj) {
		var keys = [];

		for (var i in obj) {
			if (obj.hasOwnProperty(i)) {
				keys.push(i);
		}
	}
	return keys;
	};
}
</script>

<script type='text/javascript'>
	var valid = false;
	if (typeof jQuery != 'undefined') {  
		var version = jQuery().jquery;
		var groups = /(\d+)\.(\d+)/.exec(version);
		if (groups[1] > 1 || groups[2] >= 5)
			valid = true;
	}
	if (!valid && typeof jQuery != 'undefined')
		alert("Please upgrade your jQuery implementation to at least 1.5. You can learn how to do this by visting GiftReggie's setup guide, or sending an email to gift-reggie@eshopadmin.com.");
	else if (!valid)
		alert("Please install jQuery in the head of your theme. You can learn how to do this by visting GiftReggie's setup guide, or sending an email to gift-reggie@eshopadmin.com.");
	// Check to see if the actual URL matches the main domain. If it doesn't, throw up an alert.
	{%unless testing%}
		if (window.location.hostname != "{{shop.domain}}")
			alert("You've entered Gift Reggie through " + window.location.hostname + ". For it to work properly you must enter through {{shop.domain}}! Please redirect your links to there.");
	{%endunless%}
</script>

<script type='text/javascript' src="//{{external_hostline}}/{{js_catalyst_src}}/hmac-sha256.js"></script>
<script type='text/javascript' src="//{{external_hostline}}/{{js_catalyst_src}}/oauth.js"></script>
<script type='text/javascript' src="//{{external_hostline}}/{{js_catalyst_src}}/common.js"></script>

<script type='text/javascript'>
	userSessionCookieName = giftReggieCookieName;
</script>
{%if customer_account_integration%}
{%endif%}

<script type='text/javascript'>
	var displayModal;
	(function( $ ) {
		displayModal = function(text) {
			var modal = $('<div class="giftreggie-modal" style="display:none; background: #FFF; font-size: 24px; line-height: 24px; border: 1px solid #000; padding: 12px; margin: auto; top: 0; bottom: 0; left: 0; right: 0; position: fixed; width: 320px; z-index: 1000;">\
			<div class="giftreggie-modal-inner">\
			<div class="giftreggie-modal-top">' + text + '</div>\
			<div class="giftreggie-modal-bottom"><button style="margin: 8px auto; display: block; font-size: 18px; padding: 4px 8px;">OK</button></div></div></div>');
			modal.appendTo('body');
			modal.fadeIn();
			modal.height(modal.children(".giftreggie-modal-inner").height());
			var deferred = $.Deferred();
			modal.find('button').click(function() { modal.fadeOut(400, function() { modal.remove(); }); deferred.resolve(); });
			return deferred;
		}
	})(jQuery);
</script>);

my @lines1 = split(/\n/, $text);
my @lines2 = split(/\n/, $test);
is(int(@lines1), int(@lines2));

for (0..$#lines1) {
	is($lines1[$_], $lines2[$_], "Line $_");
}


$test = q({% if registry_css %}
	<style type='text/css'>
		{{ registry_css | escape }}
	</style>
{% endif %});

use Data::Dumper;
@tokens = $lexer->parse_text($test);

$ast = $parser->parse_tokens(@tokens);
ok($ast);

$ast = $optimizer->optimize({}, $ast);
@tokens = $parser->unparse_tokens($ast);

$text = $lexer->unparse_text(@tokens);
is($text, q({%if registry_css%}
	<style type='text/css'>
		{{registry_css | escape}}
	</style>
{%endif%}));




@tokens = $lexer->parse_text($test);
$ast = $parser->parse_tokens(@tokens);
ok($ast);
$ast = $optimizer->optimize({ registry_css => '"testing escaping quote operator"'}, $ast);
ok($ast);

@tokens = $parser->unparse_tokens($ast);

$text = $lexer->unparse_text(@tokens);

is($text, q(
	<style type='text/css'>
		\"testing escaping quote operator\"
	</style>
));


# Loop unrolling.
$test = "{% for i in (1..10) %}{{ i }} {% endfor %}";
@tokens = $lexer->parse_text($test);
$ast = $parser->parse_tokens(@tokens);
$ast = $optimizer->optimize({}, $ast);
ok($ast);

isa_ok($ast, 'WWW::Shopify::Liquid::Token::Text');
is($renderer->render({ }, $ast), '1 2 3 4 5 6 7 8 9 10 ');


$test = "{% for i in (1..10) %}{{ i }}{{ b.c }}{% if i == 5 %}b{{ a.b }}{% endif %}{% endfor %}";
@tokens = $lexer->parse_text($test);
$ast = $parser->parse_tokens(@tokens);
$ast = $optimizer->optimize({}, $ast);
ok($ast);

is($renderer->render({ }, $ast), '12345b678910');

$test = q({% if search_results %}<tr>
		<th>{{ 'gift-reggie.terms.registry_name' }}</th>
		<th>{{ 'gift-reggie.terms.registry_event_date'  }}</th>
		<th>{{ 'gift-reggie.terms.registry_registrant'  }}</th>
		<th>{{ 'gift-reggie.terms.registry_coregistrant'  }}</th>
	</tr>
	{% for result in search_results %}
	<tr>
		<td><a href='{{ proxy_url }}/registry/{{ result.id }}'>{{ result.name | escape }}</a></td>
		<td>{{ result.event_date }}</td>
		<td>{{ result.registrant | escape }}</td>
		<td>{% if result.coregistrant %}{{ result.coregistrant | escape }}{% else %}None{% endif %}</td>
	</tr>
	{% endfor %}
</table>{% endif %});
@tokens = $lexer->parse_text($test);
$ast = $parser->parse_tokens(@tokens);
$ast = $optimizer->optimize({}, $ast);
ok($ast);
$ast = $optimizer->optimize({ search_results => [] }, $ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Token::Text');


@tokens = $lexer->parse_text("{% assign a = 2 %}{{ a }}");
$ast = $parser->parse_tokens(@tokens);
$ast = $optimizer->optimize({ }, $ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Operator::Concatenate');
isa_ok($ast->{operands}->[0], 'WWW::Shopify::Liquid::Tag::Assign');
is($ast->{operands}->[1], 2);


@tokens = $lexer->parse_text("{% if b == 0 %}{% assign a = 2 %}{% endif %}{{ a }}");
$ast = $parser->parse_tokens(@tokens);
$ast = $optimizer->optimize({ }, $ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Operator::Concatenate');
isa_ok($ast->{operands}->[0], 'WWW::Shopify::Liquid::Tag::If');
isa_ok($ast->{operands}->[1], 'WWW::Shopify::Liquid::Tag::Output');

@tokens = $lexer->parse_text("{% if b == 0 %}{% assign a = 2 %}{% endif %}{{ a }}");
$ast = $parser->parse_tokens(@tokens);
$ast = $optimizer->optimize({ b => 1 }, $ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Tag::Output');

@tokens = $lexer->parse_text("{% if b == 0 %}{% assign a = 2 %}{% endif %}{{ a }}");
$ast = $parser->parse_tokens(@tokens);
$ast = $optimizer->optimize({ b => 0 }, $ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Operator::Concatenate');
isa_ok($ast->{operands}->[0], 'WWW::Shopify::Liquid::Tag::Assign');
is($ast->{operands}->[1], 2);

@tokens = $lexer->parse_text("{% if b == 0 %}{% assign a = 2 %}{% endif %}{{ a }}");
$optimizer->remove_assignment(1);
$ast = $parser->parse_tokens(@tokens);
$ast = $optimizer->optimize({ b => 0 }, $ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Token::Text');
is($ast->{core}, 2);

$optimizer->remove_assignment(0);

@tokens = $lexer->parse_text("{% capture a %}2{% endcapture %}{{ a }}");
$ast = $parser->parse_tokens(@tokens);
$ast = $optimizer->optimize({ }, $ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Operator::Concatenate');
isa_ok($ast->{operands}->[0], 'WWW::Shopify::Liquid::Tag::Capture');
is($ast->{operands}->[1], 2);


@tokens = $lexer->parse_text("{% if b == 0 %}{% capture a %}2{% endcapture %}{% endif %}{{ a }}");
$ast = $parser->parse_tokens(@tokens);
$ast = $optimizer->optimize({ }, $ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Operator::Concatenate');
isa_ok($ast->{operands}->[0], 'WWW::Shopify::Liquid::Tag::If');
isa_ok($ast->{operands}->[1], 'WWW::Shopify::Liquid::Tag::Output');

@tokens = $lexer->parse_text("{% if b == 0 %}{% capture a %}2{% endcapture %}{% endif %}{{ a }}");
$ast = $parser->parse_tokens(@tokens);
$ast = $optimizer->optimize({ b => 1 }, $ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Tag::Output');

@tokens = $lexer->parse_text("{% if b == 0 %}{% capture a %}2{% endcapture %}{% endif %}{{ a }}");
$ast = $parser->parse_tokens(@tokens);
$ast = $optimizer->optimize({ b => 0 }, $ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Operator::Concatenate');
isa_ok($ast->{operands}->[0], 'WWW::Shopify::Liquid::Tag::Capture');
is($ast->{operands}->[1], 2);

@tokens = $lexer->parse_text("{% if b == 0 %}{% capture a %}2{% endcapture %}{% endif %}{{ a }}");
$optimizer->remove_assignment(1);
$ast = $parser->parse_tokens(@tokens);
$ast = $optimizer->optimize({ b => 0 }, $ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Token::Text');
is($ast->{core}, 2);

$optimizer->remove_assignment(0);


@tokens = $lexer->parse_text("{% capture signup_link %}<a class='registry-link' href='{{ proxy_url }}/signup' class='giftreggie-signup-show'>{{ b }}</a>{% endcapture %}{{ signup_link }}");
$ast = $parser->parse_tokens(@tokens);
$ast = $optimizer->optimize({ proxy_url => "A", b => 2 }, $ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Operator::Concatenate');
isa_ok($ast->{operands}->[0], 'WWW::Shopify::Liquid::Tag::Capture');
is($ast->{operands}->[1], "<a class='registry-link' href='A/signup' class='giftreggie-signup-show'>2</a>");


$optimizer->remove_assignment(1);


@tokens = $lexer->parse_text("{% capture signup_link %}<a class='registry-link' href='{{ proxy_url }}/signup' class='giftreggie-signup-show'>{{ b }}</a>{% endcapture %}{{ signup_link }}");
$ast = $parser->parse_tokens(@tokens);
$ast = $optimizer->optimize({ proxy_url => "A", b => 2 }, $ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Token::Text');
is($ast->{core}, "<a class='registry-link' href='A/signup' class='giftreggie-signup-show'>2</a>");
$optimizer->remove_assignment(0);

$ast = $parser->parse_tokens($lexer->parse_text("{% assign input_format = null %}"));
$ast = $optimizer->optimize({ }, $ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Tag::Assign');
isa_ok($ast->{arguments}->[0], 'WWW::Shopify::Liquid::Operator::Assignment');
is($ast->{arguments}->[0]->{operands}->[1], undef);


@tokens = $lexer->parse_text("{% if a %}{% capture signup_link %}<a class='registry-link' href='{{ proxy_url }}/signup' class='giftreggie-signup-show'>{{ b }}</a>{% endcapture %}{{ signup_link }}{% endif %}");
$ast = $parser->parse_tokens(@tokens);
$ast = $optimizer->optimize({ proxy_url => "A", b => 2 }, $ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Tag::If');
isa_ok($ast->{true_path}, 'WWW::Shopify::Liquid::Operator::Concatenate');
isa_ok($ast->{true_path}->{operands}->[0], 'WWW::Shopify::Liquid::Tag::Capture');
ok(!ref($ast->{true_path}->{operands}->[1]));
is($ast->{true_path}->{operands}->[1], "<a class='registry-link' href='A/signup' class='giftreggie-signup-show'>2</a>");

@tokens = $lexer->parse_text("{% if a %}{% capture signup_link %}<a class='registry-link' href='{{ proxy_url }}/signup' class='giftreggie-signup-show'>{{ b }}</a>{% endcapture %}{% endif %}{{ signup_link }}");
$ast = $parser->parse_tokens(@tokens);
$ast = $optimizer->optimize({ proxy_url => "A", b => 2 }, $ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Operator::Concatenate');
isa_ok($ast->{operands}->[1], 'WWW::Shopify::Liquid::Tag::Output');

@tokens = $lexer->parse_text("{% if a and b %}1{% endif %}");
$ast = $parser->parse_tokens(@tokens);
$ast = $optimizer->optimize({ b => 1 }, $ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Tag::If');
is(int(@{$ast->{arguments}}), 1);
isa_ok($ast->{arguments}->[0], 'WWW::Shopify::Liquid::Token::Variable');
is($ast->{arguments}->[0]->{core}->[0], 'a');

@tokens = $lexer->parse_text("{% if a and b %}1{% endif %}");
$ast = $parser->parse_tokens(@tokens);
$ast = $optimizer->optimize({ b => 0 }, $ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Token::Text::Whitespace');
is($ast->{core}, '');

@tokens = $lexer->parse_text("{% if a or b %}1{% endif %}");
$ast = $parser->parse_tokens(@tokens);
$ast = $optimizer->optimize({ b => 1 }, $ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Token::Text');
is($ast->{core}, '1');

@tokens = $lexer->parse_text("{% if a or b %}1{% endif %}");
$ast = $parser->parse_tokens(@tokens);
$ast = $optimizer->optimize({ b => 0 }, $ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Tag::If');
is(int(@{$ast->{arguments}}), 1);
isa_ok($ast->{arguments}->[0], 'WWW::Shopify::Liquid::Token::Variable');
is($ast->{arguments}->[0]->{core}->[0], 'a');


$ast = $liquid->parse_text('{% assign total = 0 %}

{{ total }}

{% for property in product.properties %}
	{% assign total = total + property.value %}
{% endfor %}

{{ total }}');

$ast = $liquid->optimizer->optimize({ }, $ast);

# Ensure that the totals in the loop, and outside the loop haven't been optimized.
ok($ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Operator::Concatenate');

is(int(@{$ast->{operands}}), 5);
like($ast->{operands}->[1], qr/^\s+0\s+/is);

isa_ok($ast->{operands}->[2], 'WWW::Shopify::Liquid::Tag::For');
isa_ok($ast->{operands}->[2]->{contents}, 'WWW::Shopify::Liquid::Operator::Concatenate');
is(int(@{$ast->{operands}->[2]->{contents}->{operands}}), 3);
isa_ok($ast->{operands}->[2]->{contents}->{operands}->[1], 'WWW::Shopify::Liquid::Tag::Assign');
isa_ok($ast->{operands}->[2]->{contents}->{operands}->[1]->{arguments}->[0], 'WWW::Shopify::Liquid::Operator::Assignment');
isa_ok($ast->{operands}->[2]->{contents}->{operands}->[1]->{arguments}->[0]->{operands}->[0], 'WWW::Shopify::Liquid::Token::Variable');
isa_ok($ast->{operands}->[2]->{contents}->{operands}->[1]->{arguments}->[0]->{operands}->[0]->{core}->[0], 'WWW::Shopify::Liquid::Token::String');
is($ast->{operands}->[2]->{contents}->{operands}->[1]->{arguments}->[0]->{operands}->[0]->{core}->[0]->{core}, 'total');

isa_ok($ast->{operands}->[-1], 'WWW::Shopify::Liquid::Tag::Output');
isa_ok($ast->{operands}->[-1]->{arguments}->[0], 'WWW::Shopify::Liquid::Token::Variable');


package WWW::Shopify::Liquid::Tag::TestTag;
use base 'WWW::Shopify::Liquid::Tag::Enclosing';

sub operate {
	my ($self, $hash, $content, @arguments) = @_;
	return $content;
}

package main;

$liquid->register_tag('WWW::Shopify::Liquid::Tag::TestTag');

@tokens = $lexer->parse_text("{% test_tag %}ASD{% endtest_tag %}");
$ast = $parser->parse_tokens(@tokens);
$ast = $optimizer->optimize({ }, $ast);

isa_ok($ast, 'WWW::Shopify::Liquid::Token::Text');
is($ast->{core}, 'ASD');

@tokens = $lexer->parse_text("{% for a in (1..2) %}{% continue %}{{ a }}{% endfor %}2");
$ast = $parser->parse_tokens(@tokens);
$ast = $optimizer->optimize({ b => 0 }, $ast);



@tokens = $lexer->parse_text("{% for a in (10..14) %}{{ forloop.index }}|{% endfor %}");
$ast = $parser->parse_tokens(@tokens);
$ast = $optimizer->optimize({ b => 0 }, $ast);
is($ast->{core}, '1|2|3|4|5|');


done_testing();
use strict;
use warnings;
use Test::More;
use utf8;
use DateTime;
use JSON qw(decode_json);
# Test bed for unary operators.
use_ok("WWW::Shopify::Liquid");
use_ok("WWW::Shopify::Liquid::Operator");
use_ok("WWW::Shopify::Liquid::Lexer");
use_ok("WWW::Shopify::Liquid::Parser");
use_ok("WWW::Shopify::Liquid::Optimizer");
use_ok("WWW::Shopify::Liquid::Renderer");
use_ok("WWW::Shopify::Liquid::Beautifier");
my $liquid = WWW::Shopify::Liquid->new(beautifier => WWW::Shopify::Liquid::Beautifier->new);
my $lexer = $liquid->lexer;
my $parser = $liquid->parser;
my $optimizer = $liquid->optimizer;
my $renderer = $liquid->renderer;

$parser->accept_unknown_filters(1);

my $string = '{% assign has_one = a | b: d, e, f %}';
my @tokens = $lexer->parse_text($string);
my $ast = $parser->parse_tokens(@tokens);


@tokens = $parser->unparse_tokens($ast);
@tokens = $liquid->{beautifier}->beautify(@tokens);
$liquid->lexer->unparse_spaces(1);
my $text = $liquid->lexer->unparse_text(@tokens);
is($text, '{% assign has_one = a | b: d, e, f %}');


$string = 'asjkldfskljghdfkjlghkjldfhglkjdfhgkljdfhgklj{% assign has_one = 0 %}{% capture order_list %}{% for order in orders %}{% assign should_capture = 0 %}{% for line_item in order.line_items %}{% assign builder_id = line_item.properties | pluck: "name", "builder_id", "value" %}{% assign dateProp = line_item.properties | pluck: "name", "Delivery Date Required", "value" | replace: "[^0-9\/]", "" | date_parse: "%d/%m/%Y" %}{% if dateProp and dateProp < end_date and dateProp > start_date and order.fulfillment_status == null %}{% assign should_capture = 1 %}{% endif %}{% endfor %}{% if should_capture %}{% if has_one %},{% endif %}{{ order.id }}{% for li in order.line_items %}{% assign bid = li.properties | pluck: "name", "builder_id", "value" %}{% if bid == builder_id %}:{{ li.id }}{% endif %}{% endfor %}{% assign has_one = 1 %}{% endif %}{% endfor %}{% endcapture %}{% assign override.html = \'<a target="_blank" href="https://value-flora.myshopify.com/apps/notifyme/order_fulfillment?orders=" + order_list + "&secret=sljgalksjlfdhfdlghdlghfd">Fulfill</a>\' %}';
@tokens = $lexer->parse_text($string);
$ast = $parser->parse_tokens(@tokens);

@tokens = $parser->unparse_tokens($ast);
@tokens = $liquid->{beautifier}->beautify(@tokens);
$liquid->lexer->unparse_spaces(1);
$text = $liquid->lexer->unparse_text(@tokens);

is($text, q{asjkldfskljghdfkjlghkjldfhglkjdfhgkljdfhgklj
{% assign has_one = 0 %}
{% capture order_list %}
	{% for order in orders %}
		{% assign should_capture = 0 %}
		{% for line_item in order.line_items %}
			{% assign builder_id = line_item.properties | pluck: 'name', 'builder_id', 'value' %}
			{% assign dateProp = line_item.properties | pluck: 'name', 'Delivery Date Required', 'value' | replace: '[^0-9\/]', '' | date_parse: '%d/%m/%Y' %}
			{% if dateProp and dateProp < end_date and dateProp > start_date and order.fulfillment_status == null %}
				{% assign should_capture = 1 %}
			{% endif %}
		{% endfor %}
		{% if should_capture %}
			{% if has_one %}
				,
			{% endif %}
			{{ order.id }}
			{% for li in order.line_items %}
				{% assign bid = li.properties | pluck: 'name', 'builder_id', 'value' %}
				{% if bid == builder_id %}
					:
					{{ li.id }}
				{% endif %}
			{% endfor %}
			{% assign has_one = 1 %}
		{% endif %}
	{% endfor %}
{% endcapture %}
{% assign override.html = '<a target="_blank" href="https://value-flora.myshopify.com/apps/notifyme/order_fulfillment?orders=" + order_list + "&secret=sljgalksjlfdhfdlghdlghfd">Fulfill</a>' %}});

@tokens = $lexer->parse_text($string);
$ast = $parser->parse_tokens(@tokens);

@tokens = $parser->unparse_tokens($ast);
@tokens = $liquid->{beautifier}->compress(@tokens);
$liquid->lexer->unparse_spaces(0);
$text = $liquid->lexer->unparse_text(@tokens);

is($text, q{asjkldfskljghdfkjlghkjldfhglkjdfhgkljdfhgklj{%assign has_one = 0%}{%capture order_list%}{%for order in orders%}{%assign should_capture = 0%}{%for line_item in order.line_items%}{%assign builder_id = line_item.properties | pluck: 'name', 'builder_id', 'value'%}{%assign dateProp = line_item.properties | pluck: 'name', 'Delivery Date Required', 'value' | replace: '[^0-9\/]', '' | date_parse: '%d/%m/%Y'%}{%if dateProp and dateProp < end_date and dateProp > start_date and order.fulfillment_status == null%}{%assign should_capture = 1%}{%endif%}{%endfor%}{%if should_capture%}{%if has_one%},{%endif%}{{order.id}}{%for li in order.line_items%}{%assign bid = li.properties | pluck: 'name', 'builder_id', 'value'%}{%if bid == builder_id%}:{{li.id}}{%endif%}{%endfor%}{%assign has_one = 1%}{%endif%}{%endfor%}{%endcapture%}{%assign override.html = '<a target="_blank" href="https://value-flora.myshopify.com/apps/notifyme/order_fulfillment?orders=" + order_list + "&secret=sljgalksjlfdhfdlghdlghfd">Fulfill</a>'%}});

$string = 'asjkldfskljghdfkjlghkjldfhglkjdfhgkljdfhgklj
{% assign has_one = 0 %}{% capture order_list %}{% for order in orders %}{% assign should_capture = 0 %}{% for line_item in order.line_items %}{% assign builder_id = line_item.properties | pluck: "name", "builder_id", "value" %}{% assign dateProp = line_item.properties | pluck: "name", "Delivery Date Required", "value" | replace: "[^0-9\/]", "" | date_parse: "%d/%m/%Y" %}{% if dateProp and dateProp < end_date and dateProp > start_date and order.fulfillment_status == null %}{% assign should_capture = 1 %}{% endif %}{% endfor %}{% if should_capture %}{% if has_one %},{% endif %}{{ order.id }}{% for li in order.line_items %}{% assign bid = li.properties | pluck: "name", "builder_id", "value" %}{% if bid == builder_id %}:{{ li.id }}{% endif %}{% endfor %}{% assign has_one = 1 %}{% endif %}{% endfor %}{% endcapture %}{% assign override.html = \'<a target="_blank" href="https://value-flora.myshopify.com/apps/notifyme/order_fulfillment?orders=" + order_list + "&secret=sljgalksjlfdhfdlghdlghfd">Fulfill</a>\' %}
asdfsdfsadfsdfd';
@tokens = $lexer->parse_text($string);
$ast = $parser->parse_tokens(@tokens);

@tokens = $parser->unparse_tokens($ast);
@tokens = $liquid->{beautifier}->beautify(@tokens);
$liquid->lexer->unparse_spaces(1);
$text = $liquid->lexer->unparse_text(@tokens);

is($text, q{asjkldfskljghdfkjlghkjldfhglkjdfhgkljdfhgklj
{% assign has_one = 0 %}
{% capture order_list %}
	{% for order in orders %}
		{% assign should_capture = 0 %}
		{% for line_item in order.line_items %}
			{% assign builder_id = line_item.properties | pluck: 'name', 'builder_id', 'value' %}
			{% assign dateProp = line_item.properties | pluck: 'name', 'Delivery Date Required', 'value' | replace: '[^0-9\/]', '' | date_parse: '%d/%m/%Y' %}
			{% if dateProp and dateProp < end_date and dateProp > start_date and order.fulfillment_status == null %}
				{% assign should_capture = 1 %}
			{% endif %}
		{% endfor %}
		{% if should_capture %}
			{% if has_one %}
				,
			{% endif %}
			{{ order.id }}
			{% for li in order.line_items %}
				{% assign bid = li.properties | pluck: 'name', 'builder_id', 'value' %}
				{% if bid == builder_id %}
					:
					{{ li.id }}
				{% endif %}
			{% endfor %}
			{% assign has_one = 1 %}
		{% endif %}
	{% endfor %}
{% endcapture %}
{% assign override.html = '<a target="_blank" href="https://value-flora.myshopify.com/apps/notifyme/order_fulfillment?orders=" + order_list + "&secret=sljgalksjlfdhfdlghdlghfd">Fulfill</a>' %}
asdfsdfsadfsdfd});

$string = 'asjkldfskljghdfkjlghkjldfhglkjdfhgkljdfhgklj
	{% assign has_one = 0 %}
	{% capture order_list %}{% for order in orders %}{% assign should_capture = 0 %}{% for line_item in order.line_items %}{% assign builder_id = line_item.properties | pluck: "name", "builder_id", "value" %}{% assign dateProp = line_item.properties | pluck: "name", "Delivery Date Required", "value" | replace: "[^0-9\/]", "" | date_parse: "%d/%m/%Y" %}{% if dateProp and dateProp < end_date and dateProp > start_date and order.fulfillment_status == null %}{% assign should_capture = 1 %}{% endif %}{% endfor %}{% if should_capture %}{% if has_one %},{% endif %}{{ order.id }}{% for li in order.line_items %}{% assign bid = li.properties | pluck: "name", "builder_id", "value" %}{% if bid == builder_id %}:{{ li.id }}{% endif %}{% endfor %}{% assign has_one = 1 %}{% endif %}{% endfor %}{% endcapture %}{% assign override.html = \'<a target="_blank" href="https://value-flora.myshopify.com/apps/notifyme/order_fulfillment?orders=" + order_list + "&secret=sljgalksjlfdhfdlghdlghfd">Fulfill</a>\' %}
asdfsdfsadfsdfd';
@tokens = $lexer->parse_text($string);
$ast = $parser->parse_tokens(@tokens);

@tokens = $parser->unparse_tokens($ast);
@tokens = $liquid->{beautifier}->beautify(@tokens);
$liquid->lexer->unparse_spaces(1);
$text = $liquid->lexer->unparse_text(@tokens);
is($text, q{asjkldfskljghdfkjlghkjldfhglkjdfhgkljdfhgklj
	{% assign has_one = 0 %}
	{% capture order_list %}
		{% for order in orders %}
			{% assign should_capture = 0 %}
			{% for line_item in order.line_items %}
				{% assign builder_id = line_item.properties | pluck: 'name', 'builder_id', 'value' %}
				{% assign dateProp = line_item.properties | pluck: 'name', 'Delivery Date Required', 'value' | replace: '[^0-9\/]', '' | date_parse: '%d/%m/%Y' %}
				{% if dateProp and dateProp < end_date and dateProp > start_date and order.fulfillment_status == null %}
					{% assign should_capture = 1 %}
				{% endif %}
			{% endfor %}
			{% if should_capture %}
				{% if has_one %}
					,
				{% endif %}
				{{ order.id }}
				{% for li in order.line_items %}
					{% assign bid = li.properties | pluck: 'name', 'builder_id', 'value' %}
					{% if bid == builder_id %}
						:
						{{ li.id }}
					{% endif %}
				{% endfor %}
				{% assign has_one = 1 %}
			{% endif %}
		{% endfor %}
	{% endcapture %}
	{% assign override.html = '<a target="_blank" href="https://value-flora.myshopify.com/apps/notifyme/order_fulfillment?orders=" + order_list + "&secret=sljgalksjlfdhfdlghdlghfd">Fulfill</a>' %}
asdfsdfsadfsdfd});


done_testing();
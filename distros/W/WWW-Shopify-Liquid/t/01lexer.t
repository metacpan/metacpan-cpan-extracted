use strict;
use warnings;
use Test::More;

use_ok("WWW::Shopify::Liquid");
use_ok("WWW::Shopify::Liquid::Operator");
use_ok("WWW::Shopify::Liquid::Lexer");

my $lexer = WWW::Shopify::Liquid->new->lexer;

my @tokens = $lexer->parse_text('{% if a %}	bd{%else%} {%if d%}flkdsajglk jfhdl{%else%}sa dfsdf{%endif%} {%endif%}');
is(int(@tokens),11);
is(@{$tokens[0]->{arguments}}, 1);
@tokens = $lexer->parse_text('{% for i in (1..2) %}adlkgjf{% endfor %}');
is(int(@tokens), 3);
is(@{$tokens[0]->{arguments}}, 3);
is(@{$tokens[0]->{arguments}->[2]->{members}}, 3);

@tokens = $lexer->parse_text(' {% for i in (1..2) %}{{ i }}{% endfor %}'); is(int(@tokens), 4);
@tokens = $lexer->parse_text(' {% for i in (1..2) %}{{ i }}{% endfor %} '); is(int(@tokens), 5);
@tokens = $lexer->parse_text('{% for i in (1..2) %}{{ i }}{% endfor %} ');

is(int(@tokens), 4);
is($tokens[0]->{line}->[1], 0);
is($tokens[1]->{line}->[1], 21);
is($tokens[2]->{line}->[1], 28);
is($tokens[3]->{line}->[1], 40);

@tokens = $lexer->parse_text('{% for i in (1..2) %}
	{{ i }}
{% endfor %} ');
is(int(@tokens), 6);
is($tokens[0]->{line}->[1], 0);
is($tokens[1]->{line}->[1], 21);
is($tokens[2]->{line}->[1], 1);
is($tokens[3]->{line}->[1], 8);
is($tokens[4]->{line}->[1], 0);
is($tokens[5]->{line}->[1], 12);

@tokens = $lexer->parse_text(' {{ a }} {{ b }}!'); is(int(@tokens), 5);
@tokens = $lexer->parse_text(' {{ a }} {{ b }}'); is(int(@tokens), 4);
@tokens = $lexer->parse_text('{{ a }} {{ b }}!'); is(int(@tokens), 4);

@tokens = $lexer->parse_text('Hi{% if customer %}{{ customer.first_name }} {{ customer.lastname }}{%endif%}!'); is(int(@tokens), 7);

@tokens = $lexer->parse_text('{% unless template == \'cart\' %}
<div class="cart-overlay" style="display: none;">
<style>
	.cart-body-interior {
		overflow-y: scroll;
	}
</style>
{% endunless %}');
is(int(@tokens), 3);
is(int(@{$tokens[0]->{arguments}}), 3);



@tokens = $lexer->parse_text("{{ variant[1] }}");

is(int(@tokens), 1);
isa_ok($tokens[0]->{core}->[0], "WWW::Shopify::Liquid::Token::Variable");
is(int(@{$tokens[0]->{core}->[0]->{core}}), 2);


@tokens = $lexer->parse_text("{{ variant['option' + 1] }}");
is(int(@tokens), 1);

is(int(@{$tokens[0]->{core}}), 1);
isa_ok($tokens[0]->{core}->[0], "WWW::Shopify::Liquid::Token::Variable");


@tokens = $lexer->parse_text("{% assign color = 1 %}{% if color %}{{ variant['option' + color] }}{% endif %}");

is(int(@tokens), 4);
isa_ok($tokens[0], "WWW::Shopify::Liquid::Token::Tag");
isa_ok($tokens[1], "WWW::Shopify::Liquid::Token::Tag");
isa_ok($tokens[2], "WWW::Shopify::Liquid::Token::Output");
isa_ok($tokens[3], "WWW::Shopify::Liquid::Token::Tag");


@tokens = $lexer->parse_text("{% if order.gateway == 'paypal' %}PayPal{% elsif order.payment_details.credit_card_company == 'Visa' %}Visa{% elsif order.payment_details.credit_card_company == 'MasterCard' %}MC{% elsif order.payment_details.credit_card_company == 'American Express' %}American Express{% else %}Void{% endif %}");
is(int(@tokens), 11);

@tokens = $lexer->parse_text("{{ order.line_items[line_item.loop_index].sku }}");
is(int(@tokens), 1);
is(int(@{$tokens[0]->{core}}), 1);
is(int(@{$tokens[0]->{core}->[0]->{core}}), 4);


@tokens = $lexer->parse_text("{% assign color = [] %}");
is(int(@tokens), 1);
isa_ok($tokens[0], 'WWW::Shopify::Liquid::Token::Tag');
is(int(@{$tokens[0]->{arguments}}), 3);
isa_ok($tokens[0]->{arguments}->[0], 'WWW::Shopify::Liquid::Token::Variable');
isa_ok($tokens[0]->{arguments}->[1], 'WWW::Shopify::Liquid::Token::Operator');
isa_ok($tokens[0]->{arguments}->[2], 'WWW::Shopify::Liquid::Token::Array');

@tokens = $lexer->parse_text("{% for link in linklists.main-menu.links %}{% endfor %}");
is(int(@tokens), 2);
is(int(@{$tokens[0]->{arguments}}), 3);

@tokens = $lexer->parse_text("{% for link in linklists.main -menu.links %}{% endfor %}");
is(int(@tokens), 2);
is(int(@{$tokens[0]->{arguments}}), 5);

@tokens = $lexer->parse_text('{% for product in products limit: settings.productspg_featured_limit offset: 4 %}{% endfor %}');
is(int(@tokens), 2);
is(int(@{$tokens[0]->{arguments}}), 5);
isa_ok($tokens[0]->{arguments}->[3], 'WWW::Shopify::Liquid::Token::Variable::Named');
isa_ok($tokens[0]->{arguments}->[4], 'WWW::Shopify::Liquid::Token::Variable::Named');

@tokens = $lexer->parse_text('{% assign gift_card_amount = gift_card_amount | plus: transaction.amount %}');

@tokens = $lexer->parse_text("{% assign notes = note.value | split: '\n' %}");

@tokens = $lexer->parse_text("{% comment to: test %}{% endcomment %}");
is(int(@tokens), 2);
is(int(@{$tokens[0]->{arguments}}), 1);

@tokens = $lexer->parse_text( q({{ "New Mom's Bundle of Joy" }}));
is(int(@tokens), 1);
is(int(@{$tokens[0]->{core}}), 1);
isa_ok($tokens[0]->{core}->[0], "WWW::Shopify::Liquid::Token::String");
is($tokens[0]->{core}->[0]->{core}, "New Mom's Bundle of Joy");

@tokens = $lexer->parse_text( q({{ 1-1 }}));
is(int(@tokens) , 1);
isa_ok($tokens[0], 'WWW::Shopify::Liquid::Token::Output');
is(int(@{$tokens[0]->{core}}), 3);
isa_ok($tokens[0]->{core}->[0], 'WWW::Shopify::Liquid::Token::Number');
isa_ok($tokens[0]->{core}->[1], 'WWW::Shopify::Liquid::Token::Operator');
isa_ok($tokens[0]->{core}->[2], 'WWW::Shopify::Liquid::Token::Number');


@tokens = $lexer->parse_text("1-1 }}");
is(int(@tokens), 1);

done_testing();
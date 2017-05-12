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
my $liquid = WWW::Shopify::Liquid->new;
my $lexer = $liquid->lexer;
my $parser = $liquid->parser;
my $optimizer = $liquid->optimizer;

my %errors = (
"gfdsgdfgdfg {% if a %}" => ['WWW::Shopify::Liquid::Exception::Parser::NoClose', 1, 12],
"{% for a in 1..1000000 %} {% endfor %}" => ['WWW::Shopify::Liquid::Exception::Parser::Arguments', 1],
"{% if customer %}
	{{ customer.first_name }}
	{{ customer.lastname }}
{% endif %}

nadsljkfhlksjdfhkjsdhf

{% sadfsdf %}

{% endif %}" => ['WWW::Shopify::Liquid::Exception::Parser::UnknownTag', 8, 0],
"{% if customer %}
	{% for 1 in (1..10) %}
		{{ customer.first_name }}
		{{ customer.lastname }}
{% endif %}
" => ['WWW::Shopify::Liquid::Exception::Parser::NoClose', 1, 0],
"{% if customer
	{{ customer.first_name }}
	{{ customer.lastname }}
{% endif %}" => ['WWW::Shopify::Liquid::Exception::Parser::NoOpen', 4, 0],
"{% if customer %}
	{{ customer.first_name + + 2 }}
	{{ customer.lastname }}
{% endif %}" => ['WWW::Shopify::Liquid::Exception::Parser::Operands', 2, 1],
"{%else %}{% if customer %}
	{{ customer.first_name + + 2 }}
	{{ customer.lastname }}
{% endif %}" => ['WWW::Shopify::Liquid::Exception::Parser::NakedInnerTag',1,0],
"{{ sdff.hgdd 3 }}" => ['WWW::Shopify::Liquid::Exception::Parser::Operands', 1,0],
"
{{ a | date_math: '' }}
", ['WWW::Shopify::Liquid::Exception::Parser::Arguments',2,0],
q({% if settings.global_js %}
{ endif %}) =>  ['WWW::Shopify::Liquid::Exception::Lexer::UnbalancedTag', 2,8],
q(<html>
<head>
    <script src="https://cdn.shopify.com/s/assets/external/app.js"></script>
    <script type="text/javascript">
        ShopifyApp.init({
            apiKey: '{{ api_key }}',
            shopOrigin: 'https://{{ shop.myshopify_domain }}'
        });
        ShopifyApp.ready(function(){
            ShopifyApp.Bar.initialize({
            })
        });
    </script>
    {% if settings.global_jquery %}
        <script src="//ajax.googleapis.com/ajax/libs/jquery/1.11.3/jquery.min.js"></script>
        <script src="/static/js/{% if is_testing %}plain{% else %}compiled{% endif %}/catalyst/shopify.js"></script>
    {% endif %}
    {% if settings.global_js %}
        <script type='text/javascript'>
            {{ settings.global_js | escape_js }}
        </script>
    { endif %}
    {% if settings.global_css %}
        <style type='text/css'>
            {{ settings.global_css | escape_css }}
        </style>
    {% endif %}
</head>
<body>
    {{ content_for_layout }}
</body>
</html>) =>  ['WWW::Shopify::Liquid::Exception::Lexer::UnbalancedTag', 22, 12]
);

for (keys(%errors)) {
	my $i = undef;
	eval { $i = $optimizer->optimize({}, $parser->parse_tokens($lexer->parse_text($_))) };
	my $exp = $@;
	ok(!$i);
	ok($exp);
	isa_ok($exp, $errors{$_}->[0], $_);
	is($exp->line, $errors{$_}->[1], $_);
	is($exp->column, $errors{$_}->[2], $_) if int(@{$errors{$_}}) == 3;
}

done_testing();
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

sub expected_exception {
    my ($text, $result) = @_;
    my $i = undef;
    my @tokens;
    eval { @tokens = $lexer->parse_text($text); $i = $optimizer->optimize({}, $parser->parse_tokens(@tokens)) };
    my $exp = $@;
    ok(!$i);
    ok($exp);
    is(ref($exp), $result->[0], $text);
    is($exp->line, $result->[1], $text);
    is($exp->column, $result->[2], $text) if int(@$result) == 3;
    return ($i, @tokens);
}

expected_exception("gfdsgdfgdfg {% if a %}" => ['WWW::Shopify::Liquid::Exception::Parser::NoClose', 1, 12]);

expected_exception("{% for a in 1..1000000 %} {% endfor %}" => ['WWW::Shopify::Liquid::Exception::Parser::Arguments', 1]);
expected_exception("{% if customer %}
	{{ customer.first_name }}
	{{ customer.lastname }}
{% endif %}

nadsljkfhlksjdfhkjsdhf

{% sadfsdf %}

{% endif %}" => ['WWW::Shopify::Liquid::Exception::Parser::UnknownTag', 8, 0]);
expected_exception("{% if customer %}
	{% for 1 in (1..10) %}
		{{ customer.first_name }}
		{{ customer.lastname }}
{% endif %}
" => ['WWW::Shopify::Liquid::Exception::Parser::NoClose', 1, 0]);
expected_exception("{% if customer
	{{ customer.first_name }}
	{{ customer.lastname }}
{% endif %}" => ['WWW::Shopify::Liquid::Exception::Lexer::UnbalancedControlTag', 1, 0]);
expected_exception("{% if customer %}
	{{ customer.first_name + + 2 }}
	{{ customer.lastname }}
{% endif %}" => ['WWW::Shopify::Liquid::Exception::Parser::Operands', 2, 24]);
expected_exception("{%else %}{% if customer %}
	{{ customer.first_name + + 2 }}
	{{ customer.lastname }}
{% endif %}" => ['WWW::Shopify::Liquid::Exception::Parser::NakedInnerTag',1,0]);
expected_exception("{{ sdff.hgdd 3 }}" => ['WWW::Shopify::Liquid::Exception::Parser::Operands', 1,3]);
expected_exception("
{{ a | date_math: '' }}
", ['WWW::Shopify::Liquid::Exception::Parser::Arguments',2,7]);
expected_exception(q({% if settings.global_js %}
{ endif %}) =>  ['WWW::Shopify::Liquid::Exception::Parser::NoClose', 1,0]);
expected_exception(q(<html>
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
</html>) =>  ['WWW::Shopify::Liquid::Exception::Parser::NoClose', 18, 4]);

expected_exception("{% for a in b %}
{% endfor % }

{% asdasd %}" =>  ['WWW::Shopify::Liquid::Exception::Lexer::UnbalancedBrace', 2, 2]);

done_testing();
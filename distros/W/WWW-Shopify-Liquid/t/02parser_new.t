
use strict;
use warnings;
use Test::More;

use_ok("WWW::Shopify::Liquid");
use_ok("WWW::Shopify::Liquid::Operator");
use_ok("WWW::Shopify::Liquid::Lexer");
use_ok("WWW::Shopify::Liquid::Parser");

use WWW::Shopify::Liquid qw(liquid_verify_text);

my $liquid = WWW::Shopify::Liquid->new;
my $lexer = $liquid->lexer;
my $parser = $liquid->parser;

my $string = q(<a href='/mock/proxy/{% if customer %}wishlists{% else %}login{% endif %}'>
	<div class="giftreggie-landing-row">
		<h4>WISHLIST &gt;</h4>
		<p>Set up your very own wishlist.</p>
	</div>
</a>);

my $ast = $parser->parse_tokens($lexer->parse_text("{% assign has_pdf = 0 %}{% for file in files %}{% if file.extension == 'pdf' %}{% assign has_pdf = 1%}{% endif %}{% endfor %} {{ has_pdf }}"));
ok($ast);
isa_ok($ast, 'WWW::Shopify::Liquid::Operator::Concatenate');
isa_ok($ast->{operands}->[0], 'WWW::Shopify::Liquid::Tag::Assign');
isa_ok($ast->{operands}->[1], 'WWW::Shopify::Liquid::Tag::For');

$ast = $parser->parse_tokens($lexer->parse_text($string));
ok($ast);
my $arg = $liquid->parser->parse_argument_tokens($liquid->lexer->parse_expression([1,0,0,undef], "order.created_at > 100"));
ok($arg);
ok($liquid->parser->parse_argument_tokens($liquid->lexer->parse_expression([1,0,0,undef], "variant.option2 == \"asbsa\"")));
my $template = "{% for prop in line_item.properties %}{% if prop.name contains 'Size'%}{% if prop.value == 'Small/Medium' %}S{% elsif prop.value == 'Medium/Large' %}L{% endif %}{% endif %}{% endfor %}";
$ast = $parser->parse_tokens($lexer->parse_text($template));
ok($ast);
isa_ok($ast->{contents}, 'WWW::Shopify::Liquid::Tag::If');
isa_ok($ast->{contents}->{true_path}, 'WWW::Shopify::Liquid::Tag::If');
isa_ok($ast->{contents}->{true_path}->{true_path}, 'WWW::Shopify::Liquid::Token::Text');
isa_ok($ast->{contents}->{true_path}->{false_path}, 'WWW::Shopify::Liquid::Tag::If');
isa_ok($ast->{contents}->{true_path}->{false_path}->{true_path}, 'WWW::Shopify::Liquid::Token::Text');

done_testing();


__DATA__
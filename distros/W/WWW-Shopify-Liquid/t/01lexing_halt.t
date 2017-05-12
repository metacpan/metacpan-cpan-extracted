use strict;
use warnings;
use Test::More;

use_ok("WWW::Shopify::Liquid");
use_ok("WWW::Shopify::Liquid::Operator");
use_ok("WWW::Shopify::Liquid::Lexer");

my $lexer = WWW::Shopify::Liquid->new->lexer;


my @tokens = $lexer->parse_text('{% assign res.content_type = "application/liquid" %}
		Please wait while you are redirected...
		<script type="text/javascript">
			{% raw %}{% if customer.id == {% endraw %}{{ form.customer_id }}{% raw %}%}{% endraw %}
				
					{% login_admin "ben@bencrudo.com", "quality1st" %}
					{% assign customer = form.customer_id | get: "Customer" %}
					{% assign token = customer | get_reset_token %}
					{% unless customer and token %}
						window.location = "/account/reset/{{ token }}";
					{% else %}
						window.location = "/account";
					{% endunless %}
					
			{% raw %}{% endif %}{% endraw %}
		</script>');
is(int(@tokens), 28);

@tokens = $lexer->parse_text("{% if a %}
	{{ a }}
	{% raw %}
	sadflsjdfksdfd {% if b %}
	{% endif %}
	{% endraw %}
{% endif %}");

is(int(@tokens), 9);

@tokens = $lexer->parse_text("{% comment %}
	{{ a }}
	{% raw %}
	sadflsjdfksdfd {% if b %}
	{% endif %}
	{% endraw %}
{% endcomment %}");

is(int(@tokens), 3);



done_testing();
use strict;
use Test;

BEGIN { plan tests => 3 }
 
use Text::Tmpl qw(TEMPLATE_TRUE
                  TEMPLATE_FALSE);

my $return;
my($context) = new Text::Tmpl;
ok(defined $context);

$return = $context->set_value('foo', TEMPLATE_TRUE);
ok($return);

$return = $context->set_value('foo', TEMPLATE_FALSE);
ok($return);

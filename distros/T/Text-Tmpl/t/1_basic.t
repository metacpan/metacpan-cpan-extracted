use strict;
use Test;

BEGIN { plan tests => 37 }

use Text::Tmpl;

use constant TEMPLATE => 't/1_basic.tmpl';

my($return, $subcontext, $output);
my($context) = Text::Tmpl::init();
ok(defined $context);

$return = Text::Tmpl::set_delimiters($context, '<%', '%>');
ok($return);

$return = Text::Tmpl::register_simple($context, 'foo', sub { });
ok($return);

$return = $context->register_simple('foo', sub { });
ok($return);

$return = Text::Tmpl::register_pair($context, 0, 'bar', 'baz', sub { });
ok($return);

$return = $context->register_pair(0, 'bar', 'baz', sub { });
ok($return);

$return = Text::Tmpl::alias_simple($context, 'foo', 'bar');
ok($return);

$return = $context->alias_simple('foo', 'bar');
ok($return);

$return = Text::Tmpl::alias_pair($context, 'bar', 'baz', 'barney', 'fred');
ok($return);

$return = $context->alias_pair('bar', 'baz', 'barney', 'fred');
ok($return);

$context->set_debug(1);
ok(1);

$context->set_strip(1);
ok(1);

$return = $context->set_dir('/');
ok($return);

$return = $context->set_value('foo', 'bar');
ok($return);

$return = $context->set_values({'foo' => 'bar',
                                'bar' => 'baz'});
ok($return);

$subcontext = $context->loop_iteration('foo');
ok(defined $subcontext);

$subcontext = $context->fetch_loop_iteration('foo', 0);
ok(defined $subcontext);

Text::Tmpl::set_debug($context, 1);
ok(1);

Text::Tmpl::set_strip($context, 1);
ok(1);

$return = Text::Tmpl::set_dir($context, '/');
ok($return);

$return = Text::Tmpl::set_value($context, 'bar', 'baz');
ok($return);

$return = Text::Tmpl::set_values($context, { 'foo' => 'bar',
                                             'bar' => 'baz' });
ok($return);


$subcontext = Text::Tmpl::loop_iteration($context, 'bar');
ok(defined $subcontext);

$subcontext = Text::Tmpl::fetch_loop_iteration($context, 'bar', 0);
ok(defined $subcontext);

$context = new Text::Tmpl;
ok(defined $context);

$output = Text::Tmpl::parse_file($context, TEMPLATE);
ok(defined $output);

$output = $context->parse_file(TEMPLATE);
ok(defined $output);

$output = Text::Tmpl::parse_string($context, 'this is not a test');
ok(defined $output);

$output = $context->parse_string('this is not a test');
ok(defined $output);

$return = $context->set_delimiters('<%', '%>');
ok($return);

$return = Text::Tmpl::errno();
ok(defined $return);

$return = Text::Tmpl::strerror();
ok($return);

Text::Tmpl::remove_simple($context, 'echo');
ok(1);

$context->remove_simple('include');
ok(1);

Text::Tmpl::remove_pair($context, 'comment');
ok(1);

$context->remove_pair('if');
ok(1);

$context->destroy();
ok(1);

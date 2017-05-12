use strict;
use Test;

BEGIN { plan tests => 13 }

use Text::Tmpl;

my($return, $subcontext);
my $context = new Text::Tmpl;

$return = $context->set_delimiters(undef, undef);
ok(! $return);

$return = $context->register_simple(undef, undef);
ok(! $return);

$return = $context->register_pair(undef, undef, undef, undef);
ok(! $return);

$return = $context->set_debug(undef);
ok(! $return);

$return = $context->set_strip(undef);
ok(! $return);

$return = $context->set_dir(undef);
ok(! $return);

$return = $context->set_value(undef, undef);
ok(! $return);

$return = $context->set_values(undef);
ok(! $return);

$return = $context->set_values({ 'key' => undef });
ok($return);

$subcontext = $context->loop_iteration(undef);
ok(! defined $subcontext);

$return = $context->alias_simple(undef, undef);
ok(! $return);

$return = $context->alias_pair(undef, undef, undef, undef);
ok(! $return);

$subcontext = $context->fetch_loop_iteration(undef, undef);
ok(! defined $subcontext);

use strict;
use Test;

BEGIN { plan tests => 3 }

use Text::Tmpl;

my $context = new Text::Tmpl;

my $output = $context->parse_file('nonexistent.tmpl');
ok(! defined $output);

undef $output;

$output = $context->parse_file(undef);
ok(! defined $output);

undef $output;

$output = $context->parse_string(undef);
ok(! defined $output);

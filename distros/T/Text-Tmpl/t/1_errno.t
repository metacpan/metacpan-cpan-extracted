use strict;
use Test;

BEGIN { plan tests => 6 }

use Text::Tmpl;

my($return, $errno, $errstr);
my($context) = Text::Tmpl::init();
ok(defined $context);

$return = $context->parse_file('nonexistent.tmpl');
$errno  = Text::Tmpl::errno();
$errstr = Text::Tmpl::strerror();
ok((! $return) && ($errno == 8) && ($errstr eq 'file not found'));

$return = $context->context_get_value('nonexistent');
$errno  = Text::Tmpl::errno();
$errstr = Text::Tmpl::strerror();
ok((! $return) && ($errno == 4) && ($errstr eq 'no such variable'));

$return = $context->context_get_named_child('nonexistent');
$errno  = Text::Tmpl::errno();
$errstr = Text::Tmpl::strerror();
ok((! $return) && ($errno == 5) && ($errstr eq 'no such named context'));

$return = $context->parse_string('<!--#loop "unbalanced"');
$errno  = Text::Tmpl::errno();
$errstr = Text::Tmpl::strerror();
ok(($errno == 10) && ($errstr eq 'unable to parse'));

$return = $context->parse_string('Hello <!--#if "true"-->');
$errno  = Text::Tmpl::errno();
$errstr = Text::Tmpl::strerror();
ok(($errno == 10) && ($errstr eq 'unable to parse'));

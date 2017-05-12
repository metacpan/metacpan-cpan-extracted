use strict;
use warnings;

use Test::More;
use Test::Deep;
plan qw/no_plan/;

use jQuery::Loader::Template;

my $template = jQuery::Loader::Template->new;

is($template->process("\%j"), "jquery.js");

$template->version("1.2.3");
is($template->process("\%j"), "jquery-1.2.3.js");

$template->filter("min");
is($template->process("\%j"), "jquery-1.2.3.min.js");

$template->filter("");
is($template->process("\%j"), "jquery-1.2.3.js");

$template->version("2");
is($template->process("\%j"), "jquery-2.js");

is($template->process("xyzzy.js"), "xyzzy.js");

is($template->process("/path/to/template/\%j"), "/path/to/template/jquery-2.js");
is($template->process("/path/to/\%v/template/\%j"), "/path/to/2/template/jquery-2.js");
is($template->process("/path/to/\%f/template/\%j", filter => "min"), "/path/to/min/template/jquery-2.min.js");

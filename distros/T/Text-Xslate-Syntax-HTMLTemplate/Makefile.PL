use strict;
use warnings;

use inc::Module::Install;

all_from 'lib/Text/Xslate/Syntax/HTMLTemplate.pm';

requires 'HTML::Template::Pro' => 0;
requires 'HTML::Template::Parser' => 0;
requires 'Text::Xslate' => 0;
requires 'YAML' => 0;

tests_recursive;

WriteAll;



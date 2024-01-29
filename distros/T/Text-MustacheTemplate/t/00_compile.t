use strict;
use warnings;
use Test::More 0.98;

use_ok $_ for qw(
    Text::MustacheTemplate
    Text::MustacheTemplate::Compiler
    Text::MustacheTemplate::Evaluator
    Text::MustacheTemplate::Generator
    Text::MustacheTemplate::HTML
    Text::MustacheTemplate::Lexer
    Text::MustacheTemplate::Parser
);

done_testing;


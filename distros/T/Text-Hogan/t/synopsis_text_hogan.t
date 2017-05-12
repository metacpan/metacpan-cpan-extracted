#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Text::Hogan::Compiler;

my $text = "Hello, {{name}}!";

my $compiler = Text::Hogan::Compiler->new;
my $template = $compiler->compile($text);

is $template->render({ name => "Alex" }), "Hello, Alex!", "Text::Hogan synopsis works";

done_testing();

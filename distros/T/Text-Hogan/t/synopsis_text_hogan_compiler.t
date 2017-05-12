#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Text::Hogan::Compiler;

my $compiler = Text::Hogan::Compiler->new;

my $text = "Hello, {{name}}!";

my $tokens   = $compiler->scan($text);
my $tree     = $compiler->parse($tokens, $text);
my $template = $compiler->generate($tree, $text);

is $template->render({ name => "Alex" }), "Hello, Alex!", "Text::Hogan::Compiler synopsis works";

# whitespace testing
my $ws_template = '{{ # foo }}do not render if whitespace allowed{{ / foo }}';
my $ws_data = { foo => 0 };

my $ws_compiler = Text::Hogan::Compiler->new();

is $ws_compiler->compile( $ws_template, { 'allow_whitespace_before_hashmark' => 0 } )->render($ws_data),
  "do not render if whitespace allowed",
  "Text::Hogan::Compiler doesn't allow whitespace between delimeters and tag type ...";
is $ws_compiler->compile( $ws_template, { 'allow_whitespace_before_hashmark' => 1 } )->render($ws_data),
  "",
  "... unless specified in the options";

done_testing();

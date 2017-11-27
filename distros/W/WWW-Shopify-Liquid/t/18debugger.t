use strict;
use warnings;
use Test::More;

use_ok("WWW::Shopify::Liquid");
use_ok("WWW::Shopify::Liquid::Operator");
use_ok("WWW::Shopify::Liquid::Lexer");
use_ok("WWW::Shopify::Liquid::Parser");
use_ok("WWW::Shopify::Liquid::Optimizer");
use_ok("WWW::Shopify::Liquid::Renderer");
use_ok("WWW::Shopify::Liquid::Debugger");

package Liquid::Debugger::Test;
use parent 'WWW::Shopify::Liquid::Debugger';

our $count = 0;

sub break {
    $count++;
}

package main;

my $liquid = WWW::Shopify::Liquid->new;
my $lexer = $liquid->lexer;
my $parser = $liquid->parser;

$liquid->lexer->file_context("test");
my $ast = $liquid->parse_text("{% if a %}
  {{ b }}
{% else %}
  {{ c }}
{% endif %}");

my $debugger = Liquid::Debugger::Test->new($liquid->renderer);
$debugger->add_breakpoint("test", 2);
my $text = $debugger->render({ a => 1, b => 2, c => 3 }, $ast);
like($text, qr/2/);
is($Liquid::Debugger::Test::count, 1);
$text = $debugger->render({ a => 1, b => 2, c => 3 }, $ast);
like($text, qr/2/);
is($Liquid::Debugger::Test::count, 2);
$debugger->remove_breakpoint("test", 2);
$text = $debugger->render({ a => 1, b => 2, c => 3 }, $ast);
like($text, qr/2/);
is($Liquid::Debugger::Test::count, 2);

done_testing();
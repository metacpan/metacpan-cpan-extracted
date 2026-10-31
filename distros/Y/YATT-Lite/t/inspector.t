#!/usr/bin/env perl
# -*- mode: perl; coding: utf-8 -*-
#----------------------------------------
use strict;
use warnings qw(FATAL all NONFATAL misc);
use FindBin;
use File::Basename qw(dirname);
BEGIN { do "$FindBin::Bin/t_lib.pl" }
#----------------------------------------

use Test::More;
use Test::Command;

my $distDir = dirname($FindBin::Bin);

unless ([File::Spec->splitdir($distDir)]->[-1] eq "YATT") {
  plan skip_all => "This test only works when \$distDir ends with 'YATT'";
}

require_ok('YATT::Lite::Inspector');

{
  my $test = sub {
    my ($before, $changeList, $expect, $title) = @_;
    my $got = YATT::Lite::Inspector->apply_all_change_to_lines($before, $changeList);
    is_deeply($got, $expect, $title);
  };

  $test->(
    ["foo", "bar"],
    [{"range" =>
      {"end" => {"character" => 0,"line" => 0}
       ,"start" => {"character" => 0,"line" => 0}}
      ,"rangeLength" => 0,"text" => "\n"}],
    ["", "foo", "bar"],
    "insert first newline"
  );

  $test->(
    ["foo", "bar"],
    [{"range" =>
      {"end" => {"character" => 0,"line" => 1}
       ,"start" => {"character" => 3,"line" => 0}}
      ,"rangeLength" => 0,"text" => "\nqux\nquuux"}],
    ["foo", "qux", "quuuxbar"],
    "insert multiline changes with newlines"
  );

  $test->(
    [qw(foo bar baz qux quux)],
    [
      {
        'range' => {
          'end' => { 'character' => 3, 'line' => 1, },
          'start' => { 'character' => 0, 'line' => 1, },
        },
        'rangeLength' => 3, 'text' => '',
      },
      {
        'range' => {
          'end' => { 'character' => 0, 'line' => 2, },
          'start' => { 'character' => 0, 'line' => 1, },
        },
        'rangeLength' => 1, 'text' => '',
      },
      {
        'range' => {
          'end' => { 'character' => 3, 'line' => 2, },
          'start' => { 'character' => 0, 'line' => 2, },
        },
        'rangeLength' => 3, 'text' => '',
      },
      {
        'range' => {
          'end' => { 'character' => 0, 'line' => 3, },
          'start' => { 'character' => 0, 'line' => 2, },
        },
        'rangeLength' => 1, 'text' => '',
      },
    ],
    [qw(foo baz quux)],
    "delete 2nd and 4th lines"
  );

}

# Widget, Entity and Declaration completion tests
SKIP: {
  my $base_dir = dirname($FindBin::Bin);
  my $dir = "$base_dir/samples/basic/1";
  skip "Sample directory not found", 39 unless -d $dir;
  
  my $inspector = YATT::Lite::Inspector->new(dir => $dir);
  
  # Widget completion tests
  
  # Test macro widget completion
  {
    my @items = $inspector->complete_widgets("html/index.yatt", "yatt", "");
    my @macros = grep { $_->{kind} == 9 } @items; # SymbolKind__Constructor = 9
    ok(@macros > 0, "Should have macro widgets");
    
    my ($foreach) = grep { $_->{label} eq 'foreach' } @macros;
    ok($foreach, "Should find 'foreach' macro");
    is($foreach->{detail}, "macro yatt:foreach", "foreach detail should be correct");
  }
  
  # Test widget completion with prefix 'e'
  {
    my @items = $inspector->complete_widgets("html/index.yatt", "yatt", "e");
    my @envelope_items = grep { $_->{label} =~ /^envelope/ } @items;
    is(scalar(@envelope_items), 2, "Should have two envelope completion items");
    
    my ($envelope_open) = grep { $_->{label} eq 'envelope' } @envelope_items;
    ok($envelope_open, "Should find 'envelope' widget (open/close)");
    is($envelope_open->{detail}, "template yatt:envelope (default widget)", "envelope detail should be correct");
    like($envelope_open->{documentation}, qr/title: html/, "envelope should have title argument");
    like($envelope_open->{documentation}, qr/body: code/, "envelope should have body argument");
    is($envelope_open->{insertText}, 'envelope>$1</yatt:envelope>', "envelope open/close insertText should be correct");
    is($envelope_open->{insertTextFormat}, 2, "envelope open/close should use snippet format");
    
    my ($envelope_self) = grep { $_->{label} eq 'envelope (self-closing)' } @envelope_items;
    ok($envelope_self, "Should find 'envelope (self-closing)' widget");
    is($envelope_self->{insertText}, 'envelope/>', "envelope self-closing insertText should be correct");
    is($envelope_self->{insertTextFormat}, 1, "envelope self-closing should use plain text format");
  }
  
  # Test widget completion from foobar.yatt
  {
    my @items = $inspector->complete_widgets("html/foobar.yatt", "yatt", "f");
    
    my ($foreach) = grep { $_->{label} eq 'foreach' } @items;
    ok($foreach, "Should find 'foreach' macro from foobar.yatt");
    
    my ($foo) = grep { $_->{label} eq 'foo' } @items;
    ok($foo, "Should find 'foo' widget in the same file");
    is($foo->{detail}, "widget yatt:foo", "foo detail should be correct");
    like($foo->{documentation}, qr/a: text/, "foo should have 'a' argument");
    like($foo->{documentation}, qr/body: code/, "foo should have body argument");
  }
  
  # Entity completion tests
  
  # Test entity macro completion
  {
    my @items = $inspector->complete_entities("html/index.yatt", "yatt", "", 0);
    my @macros = grep { $_->{detail} =~ /entity macro/ } @items;
    ok(@macros > 0, "Should have entity macros");
    
    my ($if_macro) = grep { $_->{label} eq 'if' } @macros;
    ok($if_macro, "Should find 'if' entity macro");
    is($if_macro->{detail}, "entity macro yatt:if", "if entity macro detail should be correct");
  }
  
  # Test entity variable completion in default widget
  {
    my @items = $inspector->complete_entities("html/foobar.yatt", "yatt", "", 1);  # Line 2 in editor (0-based: 1)
    my @vars = grep { $_->{kind} == 13 } @items; # SymbolKind__Variable = 13
    ok(@vars > 0, "Should have variables from default widget arguments");
    
    my ($x_var) = grep { $_->{label} eq 'x' } @vars;
    ok($x_var, "Should find 'x' variable");
    is($x_var->{detail}, "var x: text", "variable 'x' detail should be correct");
    
    my ($y_var) = grep { $_->{label} eq 'y' } @vars;
    ok($y_var, "Should find 'y' variable");
    is($y_var->{detail}, "var y: text", "variable 'y' detail should be correct");
  }
  
  # Test entity variable completion in foo widget
  {
    my @items = $inspector->complete_entities("html/foobar.yatt", "yatt", "", 5);  # Line 6 in editor (0-based: 5)
    my @vars = grep { $_->{kind} == 13 } @items;
    
    my ($a_var) = grep { $_->{label} eq 'a' } @vars;
    ok($a_var, "Should find 'a' variable in foo widget");
    is($a_var->{detail}, "var a: text", "variable 'a' detail should be correct");
    
    # Check that x and y are NOT present
    my ($x_var) = grep { $_->{label} eq 'x' } @vars;
    ok(!$x_var, "Should NOT find 'x' variable in foo widget");
  }
  
  # Test entity completion with prefix 'd'
  {
    my @items = $inspector->complete_entities("html/index.yatt", "yatt", "d", 0);
    my ($default) = grep { $_->{label} eq 'default' } @items;
    ok($default, "Should find 'default' entity function");
    is($default->{detail}, "entity yatt:default", "default entity detail should be correct");
  }
  
  # Declaration completion tests
  
  # Test declaration completion
  {
    my @items = $inspector->complete_declarations("html/index.yatt", "yatt", "");
    ok(@items > 0, "Should have declarations");
    
    my ($args) = grep { $_->{label} eq 'args' } @items;
    ok($args, "Should find 'args' declaration");
    is($args->{detail}, "declaration yatt:args", "args declaration detail should be correct");
    
    my ($widget) = grep { $_->{label} eq 'widget' } @items;
    ok($widget, "Should find 'widget' declaration");
    is($widget->{detail}, "declaration yatt:widget", "widget declaration detail should be correct");
  }
  
  # Test declaration completion with prefix 'a'
  {
    my @items = $inspector->complete_declarations("html/index.yatt", "yatt", "a");
    
    my ($action) = grep { $_->{label} eq 'action' } @items;
    ok($action, "Should find 'action' declaration");
    
    my ($args) = grep { $_->{label} eq 'args' } @items;
    ok($args, "Should find 'args' declaration with prefix 'a'");
    
    # Should NOT find 'widget' with prefix 'a'
    my ($widget) = grep { $_->{label} eq 'widget' } @items;
    ok(!$widget, "Should NOT find 'widget' declaration with prefix 'a'");
  }
}

{
  my $list_widgets = Test::Command->new(cmd => [
    "$distDir/Lite/Inspector.pm",
    "--dir=$distDir/samples/basic/1/",
    "list_widgets",
  ]);

  $list_widgets->exit_is_num(0);

  is $list_widgets->stderr_value, '', "list_widgets runs without error";

  is_deeply +{
    map {
      my $json = MOP4Import::Base::CLI_JSON->new->cli_decode_json($_);
      ($json->{name} => $json)
    } split /\n/
    , $list_widgets->stdout_value
  }, +{
    'foobar' => {
      'args' => [
        'x',
        'y',
        'body',
      ],
      'kind' => 'page',
      'name' => 'foobar',
      'path' => 'html/foobar.yatt',
    },
    'foobar:foo' => {
      'args' => [
        'a',
        'body',
      ],
      'kind' => 'widget',
      'name' => 'foobar:foo',
      'path' => 'html/foobar.yatt',
    },
    'index' => {
      'args' => [
        'body',
      ],
      'kind' => 'page',
      'name' => 'index',
      'path' => 'html/index.yatt',
    },
    'perlerr' => {
      'args' => [
        'body',
      ],
      'kind' => 'page',
      'name' => 'perlerr',
      'path' => 'html/perlerr.yatt',
    },
    'varerr' => {
      'args' => [
        'body',
      ],
      'kind' => 'page',
      'name' => 'varerr',
      'path' => 'html/varerr.yatt',
    },
    'envelope' => {
      'args' => [
        'title',
        'body',
      ],
      'kind' => 'widget',
      'name' => 'envelope',
      'path' => 'html/envelope.ytmpl',
    },

  }, "list_widgets result"
}

{
  my $list_entities = Test::Command->new(cmd => [
    "$distDir/Lite/Inspector.pm",
    "--dir=$distDir/samples/more/1/",
    "list_entities",
  ]);

  $list_entities->exit_is_num(0);

  is $list_entities->stderr_value, '', "list_entities runs without error";

  is_deeply [
    map {
      my $dict = +{@{MOP4Import::Base::CLI_JSON->new->cli_decode_json($_)}};
      $dict->{file} =~ s,^.*?(\.htyattrc\.pl)\z,$1,;
      $dict;
    }
    grep {/\.htyattrc\.pl/}
    split /\n/, $list_entities->stdout_value
  ], [
      {name => 'foo',
       entns => 'MyYATT::INST1::EntNS',
       file => '.htyattrc.pl',
       line => 6
     },
  ], "list_entities contains .htyattrc.pl";
}

done_testing();


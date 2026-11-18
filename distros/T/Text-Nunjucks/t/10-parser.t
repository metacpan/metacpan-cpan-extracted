#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Scalar::Util qw( blessed );
use JSON::MaybeXS ();
use builtin qw( true false );

no warnings 'experimental::builtin';

use Text::Nunjucks::Parser;
use Text::Nunjucks::Nodes;

# Perl-side grammar unit tests for Text::Nunjucks::Parser. The structural
# assertions are a port of the isAST/toNodes helpers from upstream
# tests/parser.js: they compare node typenames, child counts and leaf FIELD
# values, deliberately ignoring lineno/colno (positions are oracle-checked by
# the t/corpus/parse.json cases). The expected trees below mirror the AST
# literals asserted in tests/parser.js one-to-one; the error messages are the
# exact strings the oracle emits (node maint/oracle.js, parse mode) -- never
# typed from memory.

my $CANON = JSON::MaybeXS->new(
  canonical       => 1,
  convert_blessed => 1,
  allow_nonref    => 1,
  utf8            => 0,
);
sub canon { $CANON->encode( $_[0] ) }

# Short handles for the node classes, so the AST literals read like upstream's
# [nodes.Root, [nodes.Output, ...]].
my (
  $Root,   $Output,   $Literal, $Symbol,  $Array,      $Group,
  $Dict,   $Pair,      $Filter,  $NodeList, $For,       $If,
  $IfAsync, $InlineIf, $Compare, $CompareOperand, $Or,  $And,
  $Not,    $In,        $Is,      $Concat,  $Add,        $Sub,
  $Mul,    $Div,       $FloorDiv, $Mod,    $Pow,        $Neg,
  $Pos,    $Macro,     $KeywordArgs, $FunCall, $Caller, $Import,
  $FromImport, $Block,  $Extends, $Include, $Set,       $Switch,
  $Case,   $TemplateData, $LookupVal
  )
  = map { "Text::Nunjucks::Nodes::$_" }
  qw(
  Root Output Literal Symbol Array Group
  Dict Pair Filter NodeList For If
  IfAsync InlineIf Compare CompareOperand Or And
  Not In Is Concat Add Sub
  Mul Div FloorDiv Mod Pow Neg
  Pos Macro KeywordArgs FunCall Caller Import
  FromImport Block Extends Include Set Switch
  Case TemplateData LookupVal
  );

sub node_class { 'Text::Nunjucks::Nodes::' . $_[0] }

sub parse {
  my ($tpl) = @_;
  return Text::Nunjucks::Parser->parse( $tpl, [], undef );
}

sub parse_err {
  my ($tpl) = @_;
  my $err;
  eval { Text::Nunjucks::Parser->parse( $tpl, [], undef ); 1 } or $err = $@;
  return $err;
}

# Port of upstream toNodes: turn an "AST literal" (nested arrayrefs whose first
# element is a node class name) into a real expected node tree. Node positions
# are (0,0) and never compared.
sub to_nodes {
  my ($ast) = @_;
  return $ast unless ref $ast eq 'ARRAY';    # JS: !(ast && isArray(ast))

  my $Type = $ast->[0];
  # Some fields (Compare.ops) are plain arrays of nodes: the first element is
  # itself an array literal, not a class name.
  if ( ref $Type eq 'ARRAY' ) {
    return [ map { to_nodes($_) } @$ast ];
  }

  if ( $Type->isa($NodeList) ) {
    return $Type->new( 0, 0, [ map { to_nodes($_) } @{$ast}[ 1 .. $#$ast ] ] );
  }

  # CallExtension is skipped here (extension representation is k8).
  return $Type->new(
    0, 0,
    to_nodes( $ast->[1] ), to_nodes( $ast->[2] ), to_nodes( $ast->[3] ),
    to_nodes( $ast->[4] ), to_nodes( $ast->[5] )
  );
}

# Port of upstream _isAST: compare a parsed tree against an expected tree by
# typename, child count and leaf field values (positions ignored).
sub _is_ast {
  my ( $n1, $n2, $label ) = @_;

  is( $n1->typename, $n2->typename, "$label: typename " . $n2->typename )
    or return;

  if ( $n2->isa($NodeList) ) {
    is(
      $n1->typename . ': num-children: ' . scalar( @{ $n1->children } ),
      $n2->typename . ': num-children: ' . scalar( @{ $n2->children } ),
      "$label: children count"
    );
    for my $i ( 0 .. $#{ $n2->children } ) {
      _is_ast( $n1->children->[$i], $n2->children->[$i], "$label/$i" );
    }
    return;
  }

  $n2->iter_fields(
    sub {
      my ( $value, $field ) = @_;
      my $ofield = $n1->$field;

      if ( blessed($value) && $value->isa( node_class('Node') ) ) {
        _is_ast( $ofield, $value, "$label.$field" );
      }
      elsif ( ref($ofield) eq 'ARRAY' && ref($value) eq 'ARRAY' ) {
        is( scalar @$ofield, scalar @$value, "$label.$field: array len" );
        for my $i ( 0 .. $#$value ) {
          if ( blessed( $ofield->[$i] ) && $ofield->[$i]->isa( node_class('Node') ) ) {
            _is_ast( $ofield->[$i], $value->[$i], "$label.$field/$i" );
          }
          elsif ( defined $ofield->[$i] && defined $value->[$i] ) {
            is( canon( $ofield->[$i] ), canon( $value->[$i] ), "$label.$field/$i leaf" );
          }
        }
      }
      elsif ( defined($ofield) || defined($value) ) {
        # at least one side defined; undef==undef is treated equal (skipped)
        is( canon($ofield), canon($value), "$label.$field leaf" );
      }
    }
  );
}

sub is_ast {
  my ( $actual, $ast_literal, $label ) = @_;
  _is_ast( $actual, to_nodes($ast_literal), $label // 'ast' );
}

#### structural grammar tests (ported from tests/parser.js) ####

subtest 'should parse basic types' => sub {
  is_ast( parse('{{ 1 }}'),       [ $Root, [ $Output, [ $Literal, 0 + 1 ] ] ] );
  is_ast( parse('{{ 4.567 }}'),   [ $Root, [ $Output, [ $Literal, 0 + 4.567 ] ] ] );
  is_ast( parse('{{ "foo" }}'),   [ $Root, [ $Output, [ $Literal, 'foo' ] ] ] );
  is_ast( parse("{{ 'foo' }}"),   [ $Root, [ $Output, [ $Literal, 'foo' ] ] ] );
  is_ast( parse('{{ true }}'),    [ $Root, [ $Output, [ $Literal, true ] ] ] );
  is_ast( parse('{{ false }}'),   [ $Root, [ $Output, [ $Literal, false ] ] ] );
  is_ast( parse('{{ none }}'),    [ $Root, [ $Output, [ $Literal, undef ] ] ] );
  is_ast( parse('{{ foo }}'),     [ $Root, [ $Output, [ $Symbol, 'foo' ] ] ] );
  is_ast(
    parse('{{ r/23/gi }}'),
    [ $Root, [ $Output, [ $Literal, { regex => '23', flags => 'gi' } ] ] ]
  );
};

subtest 'should parse aggregate types' => sub {
  is_ast(
    parse('{{ [1,2,3] }}'),
    [ $Root, [ $Output, [ $Array, [ $Literal, 0 + 1 ], [ $Literal, 0 + 2 ], [ $Literal, 0 + 3 ] ] ] ]
  );
  is_ast(
    parse('{{ (1,2,3) }}'),
    [ $Root, [ $Output, [ $Group, [ $Literal, 0 + 1 ], [ $Literal, 0 + 2 ], [ $Literal, 0 + 3 ] ] ] ]
  );
  is_ast(
    parse("{{ {foo: 1, 'two': 2} }}"),
    [ $Root,
      [ $Output,
        [ $Dict,
          [ $Pair, [ $Symbol, 'foo' ], [ $Literal, 0 + 1 ] ],
          [ $Pair, [ $Literal, 'two' ], [ $Literal, 0 + 2 ] ]
        ]
      ]
    ]
  );
};

subtest 'should parse variables' => sub {
  is_ast(
    parse('hello {{ foo }}, how are you'),
    [ $Root,
      [ $Output, [ $TemplateData, 'hello ' ] ],
      [ $Output, [ $Symbol, 'foo' ] ],
      [ $Output, [ $TemplateData, ', how are you' ] ]
    ]
  );
};

subtest 'should parse operators' => sub {
  is_ast(
    parse('{{ x == y }}'),
    [ $Root, [ $Output, [ $Compare, [ $Symbol, 'x' ], [ [ $CompareOperand, [ $Symbol, 'y' ], '==' ] ] ] ] ]
  );
  is_ast(
    parse('{{ x or y }}'),
    [ $Root, [ $Output, [ $Or, [ $Symbol, 'x' ], [ $Symbol, 'y' ] ] ] ]
  );
  is_ast(
    parse('{{ x in y }}'),
    [ $Root, [ $Output, [ $In, [ $Symbol, 'x' ], [ $Symbol, 'y' ] ] ] ]
  );
  is_ast(
    parse('{{ x not in y }}'),
    [ $Root, [ $Output, [ $Not, [ $In, [ $Symbol, 'x' ], [ $Symbol, 'y' ] ] ] ] ]
  );
  is_ast(
    parse('{{ x is callable }}'),
    [ $Root, [ $Output, [ $Is, [ $Symbol, 'x' ], [ $Symbol, 'callable' ] ] ] ]
  );
  is_ast(
    parse('{{ x is not callable }}'),
    [ $Root, [ $Output, [ $Not, [ $Is, [ $Symbol, 'x' ], [ $Symbol, 'callable' ] ] ] ] ]
  );
};

subtest 'should parse tilde' => sub {
  is_ast(
    parse('{{ 2 ~ 3 }}'),
    [ $Root, [ $Output, [ $Concat, [ $Literal, 0 + 2 ], [ $Literal, 0 + 3 ] ] ] ]
  );
};

subtest 'should parse operators with correct precedence' => sub {
  is_ast(
    parse('{{ x in y and z }}'),
    [ $Root, [ $Output, [ $And, [ $In, [ $Symbol, 'x' ], [ $Symbol, 'y' ] ], [ $Symbol, 'z' ] ] ] ]
  );
  is_ast(
    parse('{{ x not in y or z }}'),
    [ $Root,
      [ $Output, [ $Or, [ $Not, [ $In, [ $Symbol, 'x' ], [ $Symbol, 'y' ] ] ], [ $Symbol, 'z' ] ] ]
    ]
  );
  is_ast(
    parse('{{ x or y and z }}'),
    [ $Root,
      [ $Output, [ $Or, [ $Symbol, 'x' ], [ $And, [ $Symbol, 'y' ], [ $Symbol, 'z' ] ] ] ]
    ]
  );
};

subtest 'should parse arithmetic and unary' => sub {
  is_ast(
    parse('{{ -1 }}'),
    [ $Root, [ $Output, [ $Neg, [ $Literal, 0 + 1 ] ] ] ]
  );
  is_ast(
    parse('{{ +1 }}'),
    [ $Root, [ $Output, [ $Pos, [ $Literal, 0 + 1 ] ] ] ]
  );
  is_ast(
    parse('{{ 1 + 2 }}'),
    [ $Root, [ $Output, [ $Add, [ $Literal, 0 + 1 ], [ $Literal, 0 + 2 ] ] ] ]
  );
  is_ast(
    parse('{{ 6 // 2 }}'),
    [ $Root, [ $Output, [ $FloorDiv, [ $Literal, 0 + 6 ], [ $Literal, 0 + 2 ] ] ] ]
  );
  is_ast(
    parse('{{ 2 ** 3 }}'),
    [ $Root, [ $Output, [ $Pow, [ $Literal, 0 + 2 ], [ $Literal, 0 + 3 ] ] ] ]
  );
  is_ast(
    parse('{{ 7 % 3 }}'),
    [ $Root, [ $Output, [ $Mod, [ $Literal, 0 + 7 ], [ $Literal, 0 + 3 ] ] ] ]
  );
  # precedence: 1 + 2 * 3 -> Add(1, Mul(2, 3))
  is_ast(
    parse('{{ 1 + 2 * 3 }}'),
    [ $Root, [ $Output, [ $Add, [ $Literal, 0 + 1 ], [ $Mul, [ $Literal, 0 + 2 ], [ $Literal, 0 + 3 ] ] ] ] ]
  );
};

subtest 'should parse inline if' => sub {
  is_ast(
    parse('{{ a if b else c }}'),
    [ $Root, [ $Output, [ $InlineIf, [ $Symbol, 'b' ], [ $Symbol, 'a' ], [ $Symbol, 'c' ] ] ] ]
  );
};

subtest 'should parse member lookup and funcall' => sub {
  is_ast(
    parse('{{ a.b }}'),
    [ $Root, [ $Output, [ $LookupVal, [ $Symbol, 'a' ], [ $Literal, 'b' ] ] ] ]
  );
  is_ast(
    parse('{{ a["b"] }}'),
    [ $Root, [ $Output, [ $LookupVal, [ $Symbol, 'a' ], [ $Literal, 'b' ] ] ] ]
  );
  is_ast(
    parse('{{ foo(1, 2) }}'),
    [ $Root,
      [ $Output, [ $FunCall, [ $Symbol, 'foo' ], [ $NodeList, [ $Literal, 0 + 1 ], [ $Literal, 0 + 2 ] ] ] ]
    ]
  );
};

subtest 'should parse blocks' => sub {
  my $n = parse('want some {% if hungry %}pizza{% else %}water{% endif %}?');
  is( $n->children->[1]->typename, 'If', 'if block' );

  $n = parse('{% block foo %}stuff{% endblock %}');
  is( $n->children->[0]->typename, 'Block', 'block' );

  $n = parse('{% block foo %}stuff{% endblock foo %}');
  is( $n->children->[0]->typename, 'Block', 'block with name' );

  $n = parse('{% extends "test.njk" %}stuff');
  is( $n->children->[0]->typename, 'Extends', 'extends' );

  $n = parse('{% include "test.njk" %}');
  is( $n->children->[0]->typename, 'Include', 'include' );
};

subtest 'should accept attributes and methods of statics' => sub {
  my @ok = (
    '{{ ([1, 2, 3]).indexOf(1) }}',
    '{{ [1, 2, 3].length }}',
    '{{ "Some String".replace("S", "$") }}',
    '{{ ({ name : "Khalid" }).name }}',
    '{{ 1.618.toFixed(2) }}',
  );
  for my $tpl (@ok) {
    ok( eval { parse($tpl); 1 }, "parses: $tpl" ) or diag($@);
  }
};

subtest 'should parse include tags' => sub {
  is( parse('{% include "test.njk" %}')->children->[0]->typename, 'Include' );
  is( parse('{% include "test.html"|replace("html","j2") %}')->children->[0]->typename, 'Include' );
  is( parse('{% include ""|default("test.njk") %}')->children->[0]->typename, 'Include' );

  is_ast(
    parse('{% include "x" ignore missing %}'),
    [ $Root, [ $Include, [ $Literal, 'x' ], true ] ]
  );
};

subtest 'should parse for loops' => sub {
  is_ast(
    parse('{% for x in [1, 2] %}{{ x }}{% endfor %}'),
    [ $Root,
      [ $For,
        [ $Array, [ $Literal, 0 + 1 ], [ $Literal, 0 + 2 ] ],
        [ $Symbol, 'x' ],
        [ $NodeList, [ $Output, [ $Symbol, 'x' ] ] ]
      ]
    ]
  );
};

subtest 'should parse for loops with else' => sub {
  is_ast(
    parse('{% for x in [] %}{{ x }}{% else %}empty{% endfor %}'),
    [ $Root,
      [ $For,
        [ $Array ],
        [ $Symbol, 'x' ],
        [ $NodeList, [ $Output, [ $Symbol, 'x' ] ] ],
        [ $NodeList, [ $Output, [ $TemplateData, 'empty' ] ] ]
      ]
    ]
  );
};

subtest 'should parse key/value for loops' => sub {
  my $n = parse('{% for k, v in obj %}{{ k }}{% endfor %}');
  is( $n->children->[0]->typename,           'For',   'For' );
  is( $n->children->[0]->name->typename,     'Array', 'name is Array' );
  is( scalar @{ $n->children->[0]->name->children }, 2, 'two loop vars' );
};

subtest 'should parse async each/all' => sub {
  is( parse('{% asyncEach x in y %}{{x}}{% endeach %}')->children->[0]->typename, 'AsyncEach' );
  is( parse('{% asyncAll x in y %}{{x}}{% endall %}')->children->[0]->typename,   'AsyncAll' );
  is( parse('{% ifAsync x %}y{% endif %}')->children->[0]->typename,              'IfAsync' );
};

subtest 'should parse filters' => sub {
  is_ast(
    parse('{{ foo | bar }}'),
    [ $Root, [ $Output, [ $Filter, [ $Symbol, 'bar' ], [ $NodeList, [ $Symbol, 'foo' ] ] ] ] ]
  );
  is_ast(
    parse('{{ foo | bar | baz }}'),
    [ $Root,
      [ $Output,
        [ $Filter, [ $Symbol, 'baz' ],
          [ $NodeList, [ $Filter, [ $Symbol, 'bar' ], [ $NodeList, [ $Symbol, 'foo' ] ] ] ]
        ]
      ]
    ]
  );
  is_ast(
    parse('{{ foo | bar(3) }}'),
    [ $Root,
      [ $Output, [ $Filter, [ $Symbol, 'bar' ], [ $NodeList, [ $Symbol, 'foo' ], [ $Literal, 0 + 3 ] ] ] ]
    ]
  );
};

subtest 'should parse macro definitions' => sub {
  is_ast(
    parse('{% macro foo(bar, baz="foobar") %}This is a macro{% endmacro %}'),
    [ $Root,
      [ $Macro,
        [ $Symbol, 'foo' ],
        [ $NodeList,
          [ $Symbol, 'bar' ],
          [ $KeywordArgs, [ $Pair, [ $Symbol, 'baz' ], [ $Literal, 'foobar' ] ] ]
        ],
        [ $NodeList, [ $Output, [ $TemplateData, 'This is a macro' ] ] ]
      ]
    ]
  );
};

subtest 'should parse call blocks' => sub {
  is_ast(
    parse('{% call foo("bar") %}This is the caller{% endcall %}'),
    [ $Root,
      [ $Output,
        [ $FunCall,
          [ $Symbol, 'foo' ],
          [ $NodeList,
            [ $Literal, 'bar' ],
            [ $KeywordArgs,
              [ $Pair,
                [ $Symbol, 'caller' ],
                [ $Caller,
                  [ $Symbol, 'caller' ],
                  [ $NodeList ],
                  [ $NodeList, [ $Output, [ $TemplateData, 'This is the caller' ] ] ]
                ]
              ]
            ]
          ]
        ]
      ]
    ]
  );
};

subtest 'should parse call blocks with args' => sub {
  is_ast(
    parse('{% call(i) foo("bar", baz="foobar") %}This is {{ i }}{% endcall %}'),
    [ $Root,
      [ $Output,
        [ $FunCall,
          [ $Symbol, 'foo' ],
          [ $NodeList,
            [ $Literal, 'bar' ],
            [ $KeywordArgs,
              [ $Pair, [ $Symbol, 'baz' ], [ $Literal, 'foobar' ] ],
              [ $Pair,
                [ $Symbol, 'caller' ],
                [ $Caller,
                  [ $Symbol, 'caller' ],
                  [ $NodeList, [ $Symbol, 'i' ] ],
                  [ $NodeList,
                    [ $Output, [ $TemplateData, 'This is ' ] ],
                    [ $Output, [ $Symbol, 'i' ] ]
                  ]
                ]
              ]
            ]
          ]
        ]
      ]
    ]
  );
};

subtest 'should parse raw' => sub {
  is_ast(
    parse('{% raw %}hello {{ {% %} }}{% endraw %}'),
    [ $Root, [ $Output, [ $TemplateData, 'hello {{ {% %} }}' ] ] ]
  );
  is_ast(
    parse('{% raw %}{{ x }{% endraw %}'),
    [ $Root, [ $Output, [ $TemplateData, '{{ x }' ] ] ]
  );
  is_ast(
    parse('{% raw %}{% if i_am_stupid }Still do your job well{% endraw %}'),
    [ $Root, [ $Output, [ $TemplateData, '{% if i_am_stupid }Still do your job well' ] ] ]
  );
  is_ast(
    parse('{% raw %}abc{% endraw %}'),
    [ $Root, [ $Output, [ $TemplateData, 'abc' ] ] ]
  );
  is_ast(
    parse('{% raw %}{% raw %}{{ x }{% endraw %}{% endraw %}'),
    [ $Root, [ $Output, [ $TemplateData, '{% raw %}{{ x }{% endraw %}' ] ] ]
  );
  is_ast(
    parse('{% raw %}{# test {% endraw %}'),
    [ $Root, [ $Output, [ $TemplateData, '{# test ' ] ] ]
  );
  is_ast(
    parse('{% raw %}{{ var }}{% endraw %}{{ var }}{% raw %}{{ var }}{% endraw %}'),
    [ $Root,
      [ $Output, [ $TemplateData, '{{ var }}' ] ],
      [ $Output, [ $Symbol, 'var' ] ],
      [ $Output, [ $TemplateData, '{{ var }}' ] ]
    ]
  );
};

subtest 'should parse verbatim' => sub {
  is_ast(
    parse('{% verbatim %}hello {{ {% %} }}{% endverbatim %}'),
    [ $Root, [ $Output, [ $TemplateData, 'hello {{ {% %} }}' ] ] ]
  );
  is_ast(
    parse('{% verbatim %}{% verbatim %}{{ x }{% endverbatim %}{% endverbatim %}'),
    [ $Root, [ $Output, [ $TemplateData, '{% verbatim %}{{ x }{% endverbatim %}' ] ] ]
  );
};

subtest 'should parse switch statements' => sub {
  my $tpl =
    '{% switch foo %}{% case "bar" %}BAR{% case "baz" %}BAZ{% default %}NEITHER FOO NOR BAR{% endswitch %}';
  is_ast(
    parse($tpl),
    [ $Root,
      [ $Switch,
        [ $Symbol, 'foo' ],
        [ [ $Case, [ $Literal, 'bar' ], [ $NodeList, [ $Output, [ $TemplateData, 'BAR' ] ] ] ],
          [ $Case, [ $Literal, 'baz' ], [ $NodeList, [ $Output, [ $TemplateData, 'BAZ' ] ] ] ]
        ],
        [ $NodeList, [ $Output, [ $TemplateData, 'NEITHER FOO NOR BAR' ] ] ]
      ]
    ]
  );
};

subtest 'should parse keyword and non-keyword arguments' => sub {
  is_ast(
    parse('{{ foo("bar", falalalala, baz="foobar") }}'),
    [ $Root,
      [ $Output,
        [ $FunCall,
          [ $Symbol, 'foo' ],
          [ $NodeList,
            [ $Literal, 'bar' ],
            [ $Symbol, 'falalalala' ],
            [ $KeywordArgs, [ $Pair, [ $Symbol, 'baz' ], [ $Literal, 'foobar' ] ] ]
          ]
        ]
      ]
    ]
  );
};

subtest 'should parse imports' => sub {
  is_ast(
    parse('{% import "foo/bar.njk" as baz %}'),
    [ $Root, [ $Import, [ $Literal, 'foo/bar.njk' ], [ $Symbol, 'baz' ] ] ]
  );
  is_ast(
    parse('{% from "foo/bar.njk" import baz, foobar as foobarbaz %}'),
    [ $Root,
      [ $FromImport,
        [ $Literal, 'foo/bar.njk' ],
        [ $NodeList, [ $Symbol, 'baz' ], [ $Pair, [ $Symbol, 'foobar' ], [ $Symbol, 'foobarbaz' ] ] ]
      ]
    ]
  );
  is_ast(
    parse('{% import "foo/bar.html"|replace("html", "j2") as baz %}'),
    [ $Root,
      [ $Import,
        [ $Filter,
          [ $Symbol, 'replace' ],
          [ $NodeList, [ $Literal, 'foo/bar.html' ], [ $Literal, 'html' ], [ $Literal, 'j2' ] ]
        ],
        [ $Symbol, 'baz' ]
      ]
    ]
  );
};

subtest 'should parse set' => sub {
  is_ast(
    parse('{% set x = 1 %}'),
    [ $Root, [ $Set, [ [ $Symbol, 'x' ] ], [ $Literal, 0 + 1 ] ] ]
  );
  # block-set: value is null, body (a Capture) is a non-field property
  my $n = parse('{% set x %}hi{% endset %}')->children->[0];
  is( $n->typename, 'Set', 'block-set is a Set' );
  is( $n->value,    undef, 'block-set value is null' );
  is( $n->body->typename, 'Capture', 'block-set body is a Capture' );
};

subtest 'should parse whitespace control' => sub {
  is_ast(
    parse("{% if x %}\n  hi \n{% endif %}"),
    [ $Root, [ $If, [ $Symbol, 'x' ], [ $NodeList, [ $Output, [ $TemplateData, "\n  hi \n" ] ] ] ] ]
  );
  is_ast(
    parse("{% if x -%}\n  hi \n{% endif %}"),
    [ $Root, [ $If, [ $Symbol, 'x' ], [ $NodeList, [ $Output, [ $TemplateData, "hi \n" ] ] ] ] ]
  );
  is_ast(
    parse("{% if x %}\n  hi \n{%- endif %}"),
    [ $Root, [ $If, [ $Symbol, 'x' ], [ $NodeList, [ $Output, [ $TemplateData, "\n  hi" ] ] ] ] ]
  );
  is_ast(
    parse("{% if x -%}\n  hi \n{%- endif %}"),
    [ $Root, [ $If, [ $Symbol, 'x' ], [ $NodeList, [ $Output, [ $TemplateData, "hi" ] ] ] ] ]
  );
  is_ast(
    parse("poop  \n{%- if x -%}\n  hi \n{%- endif %}"),
    [ $Root,
      [ $Output, [ $TemplateData, 'poop' ] ],
      [ $If, [ $Symbol, 'x' ], [ $NodeList, [ $Output, [ $TemplateData, 'hi' ] ] ] ]
    ]
  );
  is_ast(
    parse("hello \n{#- comment #}"),
    [ $Root, [ $Output, [ $TemplateData, 'hello' ] ] ]
  );
  is_ast(
    parse("{# comment -#} \n world"),
    [ $Root, [ $Output, [ $TemplateData, 'world' ] ] ]
  );
  # from-statement whitespace control (the special case in parseFrom)
  is_ast(
    parse("{% from x import y -%}\n  hi \n"),
    [ $Root,
      [ $FromImport, [ $Symbol, 'x' ], [ $NodeList, [ $Symbol, 'y' ] ] ],
      [ $Output, [ $TemplateData, "hi \n" ] ]
    ]
  );
  # empty-but-space TemplateData between two trimmed tags stays ' '
  is_ast(
    parse('{% if x -%}{{y}} {{z}}{% endif %}'),
    [ $Root,
      [ $If,
        [ $Symbol, 'x' ],
        [ $NodeList,
          [ $Output, [ $Symbol, 'y' ] ],
          [ $Output, [ $TemplateData, ' ' ] ],
          [ $Output, [ $Symbol, 'z' ] ]
        ]
      ]
    ]
  );
};

#### error paths (exact oracle messages, parse mode) ####

subtest 'should throw errors with exact messages' => sub {
  my %cases = (
    'hello {{ foo'                               => 'expected variable end',
    'hello {% if'                                => 'expected expression, got end of file',
    'hello {% if sdf zxc'                        => 'expected block end in if statement',
    '{% include "foo %}'                         => 'expected block end in include statement',
    'hello {% if sdf %} data'                    => 'parseIf: expected elif, else, or endif, got end of file',
    'hello {% block sdf %} data'                 => 'parseBlock: expected endblock, got end of file',
    'hello {% block sdf %} data{% endblock foo %}' => 'expected block end in foo statement',
    'hello {% bar %} dsfsdf'                      => 'unknown block tag: bar',
    '{{ foo(bar baz) }}'                          => 'parseSignature: expected comma after expression',
    '{% import "foo" %}'                          => 'parseImport: expected "as" keyword',
    '{% from "foo" %}'                            => 'parseFrom: expected import',
    '{% from "foo" import bar baz %}'             => 'parseFrom: expected comma',
    '{% from "foo" import _bar %}'                => 'parseFrom: names starting with an underscore cannot be imported',
    '{% set %}'                                   => 'unexpected token: %}',
    '{{ }}'                                       => 'unexpected token: }}',
  );

  for my $tpl ( sort keys %cases ) {
    my $err = parse_err($tpl);
    ok( blessed($err) && $err->isa('Text::Nunjucks::Lib::TemplateError'),
      "error object for: $tpl" )
      or next;
    is( $err->message, $cases{$tpl}, "message for: $tpl" );
    is( $err->name,    'Template render error', "name for: $tpl" );
  }
};

done_testing;

#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Scalar::Util qw( blessed refaddr );
use JSON::MaybeXS ();
use builtin qw( true false );

no warnings 'experimental::builtin';

# 1:1 port of upstream tests/parser.js (describe('parser', ...)). One subtest
# per it(...), same title, same order as the grep below confirms:
#   grep -n "    it(" upstream/nunjucks/tests/parser.js
#
# tests/parser.js requires only expect/lib/nodes/parser -- it never touches
# tests/util.js (no render/equal/finish), so there is nothing to lift into
# t/lib/ for this file. What it *does* define for itself are the _isAST /
# toNodes / isAST helpers below: a structural AST comparison (typename, child
# counts, leaf field values) that deliberately ignores lineno/colno. Those are
# ported here, not reinvented -- the expected trees are the AST literals
# tests/parser.js asserts, transcribed 1:1; the "should throw errors" regexes
# are the literal regexes from tests/parser.js's own .to.throwException(/.../)
# calls. Position tracking (lineno/colno) is exercised separately and against
# the oracle by t/corpus/parse.json + t/corpus.t.

unless ( eval { require Text::Nunjucks::Parser; require Text::Nunjucks::Nodes; 1 } ) {
  plan skip_all => "Text::Nunjucks::Parser not available: $@";
}

my $CANON = JSON::MaybeXS->new(
  canonical       => 1,
  convert_blessed => 1,
  allow_nonref    => 1,
  utf8            => 0,
);
sub canon { $CANON->encode( $_[0] ) }

# Node-class shortcuts, so the AST literals below read like upstream's
# [nodes.Root, [nodes.Output, ...]].
my (
  $Node,   $NodeList, $Root,    $Output,  $Literal, $Symbol,
  $Array,  $Group,    $Dict,    $Pair,    $TemplateData,
  $Compare, $CompareOperand, $Or, $And,   $Not,     $In,
  $Is,     $Concat,   $If,      $Block,   $Extends, $Include,
  $For,    $Filter,   $Macro,   $KeywordArgs, $FunCall, $Caller,
  $Switch, $Case,     $Import,  $FromImport,  $CallExtension,
  )
  = map { "Text::Nunjucks::Nodes::$_" }
  qw(
  Node NodeList Root Output Literal Symbol
  Array Group Dict Pair TemplateData
  Compare CompareOperand Or And Not In
  Is Concat If Block Extends Include
  For Filter Macro KeywordArgs FunCall Caller
  Switch Case Import FromImport CallExtension
  );

#### local test helpers (upstream: the _isAST/toNodes/isAST closures at the
#### top of tests/parser.js) ####

# Port of upstream toNodes: turn an "AST literal" (nested arrayrefs whose
# first element is a node class name) into a real expected node tree.
sub to_nodes {
  my ($ast) = @_;
  return $ast unless ref($ast) eq 'ARRAY';    # JS: !(ast && isArray(ast))

  my $Type = $ast->[0];
  # Some fields (Compare.ops, Switch.cases) are plain arrays of node literals:
  # the first element is itself an array, not a class name.
  if ( ref($Type) eq 'ARRAY' ) {
    return [ map { to_nodes($_) } @$ast ];
  }

  if ( $Type->isa($NodeList) ) {
    return $Type->new( 0, 0, [ map { to_nodes($_) } @{$ast}[ 1 .. $#$ast ] ] );
  }
  elsif ( $Type->isa($CallExtension) ) {
    # CallExtension's constructor is (ext, prop, args, contentArgs) -- no
    # lineno/colno -- so it gets its own branch, exactly as upstream toNodes
    # does. ext (ast->[1]) is the extension instance itself, passed through
    # unconverted (a blessed ref is never `ref eq 'ARRAY'`).
    return $Type->new(
      $ast->[1],
      $ast->[2],
      ( $ast->[3] ? to_nodes( $ast->[3] ) : $ast->[3] ),
      ( ref( $ast->[4] ) eq 'ARRAY' ? [ map { to_nodes($_) } @{ $ast->[4] } ] : $ast->[4] ),
    );
  }
  else {
    return $Type->new(
      0, 0,
      to_nodes( $ast->[1] ), to_nodes( $ast->[2] ), to_nodes( $ast->[3] ),
      to_nodes( $ast->[4] ), to_nodes( $ast->[5] )
    );
  }
}

# Port of upstream expect(x).to.be(y): strict equality. For two blessed
# non-Node values (the extName field CallExtension carries -- k8, "should
# parse custom tags" below) JS strict equality on objects is reference
# identity; everything else compares by canonical-JSON value, which keeps
# JS's number/string/boolean distinction (ADR 0001).
sub _to_be {
  my ( $ofield, $value, $label ) = @_;
  if ( blessed($value) && !$value->isa($Node) ) {
    ok( blessed($ofield) && refaddr($ofield) == refaddr($value), $label );
  }
  else {
    is( canon($ofield), canon($value), $label );
  }
}

# Port of upstream _isAST. Perl has one undef for JS's null and undefined, so
# the upstream branches that throw when exactly one side is `null` (a
# test-author-error guard, never hit by a passing assertion) have no Perl
# equivalent and are not ported; both sides land in the ordinary compare below
# whenever at least one of them is defined, same as upstream's outer guard.
sub _is_ast {
  my ( $node1, $node2, $label ) = @_;
  $label = 'ast' unless defined $label;

  is( $node1->typename, $node2->typename, "$label: typename" );

  if ( $node2->isa($NodeList) ) {
    my $lit  = ': num-children: ';
    my $sig2 = $node2->typename . $lit . scalar( @{ $node2->children } );

    ok( $node1->children, "$label: node1 has children" );
    my $sig1 = $node1->typename . $lit . scalar( @{ $node1->children || [] } );

    is( $sig1, $sig2, "$label: children signature" );

    for my $n ( 0 .. $#{ $node2->children } ) {
      _is_ast( $node1->children->[$n], $node2->children->[$n], "$label\[$n]" );
    }
    return;
  }

  $node2->iter_fields(
    sub {
      my ( $value, $field ) = @_;
      my $ofield = $node1->$field;

      if ( blessed($value) && $value->isa($Node) ) {
        _is_ast( $ofield, $value, "$label.$field" );
      }
      elsif ( ref($ofield) eq 'ARRAY' && ref($value) eq 'ARRAY' ) {
        is( scalar(@$ofield), scalar(@$value), "$label.$field: array len" );
        for my $i ( 0 .. $#$value ) {
          if ( blessed( $ofield->[$i] ) && $ofield->[$i]->isa($Node) ) {
            _is_ast( $ofield->[$i], $value->[$i], "$label.$field\[$i]" );
          }
          elsif ( defined $ofield->[$i] && defined $value->[$i] ) {
            _to_be( $ofield->[$i], $value->[$i], "$label.$field\[$i]" );
          }
        }
      }
      elsif ( defined($ofield) || defined($value) ) {
        _to_be( $ofield, $value, "$label.$field" );
      }
    }
  );
}

sub is_ast {
  my ( $actual, $ast_literal, $label ) = @_;
  _is_ast( $actual, to_nodes($ast_literal), $label );
}

sub parse {
  my ( $tpl, $extensions ) = @_;
  return Text::Nunjucks::Parser->parse( $tpl, $extensions, undef );
}

sub parse_err {
  my ($tpl) = @_;
  my $err;
  eval { Text::Nunjucks::Parser->parse( $tpl, [], undef ); 1 } or $err = $@;
  return $err;
}

#### extension stand-ins for 'should parse custom tags' (test-local, mirroring
#### the TestTagExtension / TestBlockTagExtension / TestArgsExtension function
#### closures tests/parser.js defines inline for that one it()). Perl has no
#### bare-function-as-object closures, so each becomes a tiny blessed-hashref
#### with a `tags` accessor and a `parse` method, called the way
#### Parser::Parser->parse_statement calls an extension:
####   $ext->parse( $parser, $self->nodes_module, $self->lexer )
#### i.e. (parser, nodes-module-name, lexer-module-name) -- matching upstream
#### parser.js's `ext.parse(this, nodes, lexer)`.

package Text::Nunjucks::Test::Parser::TestTagExtension {
  sub new  { bless { tags => ['testtag'], _name => 'testtagExtension' }, shift }
  sub tags { $_[0]->{tags} }

  sub parse {
    my ( $self, $parser, $nodes_module, $lexer_module ) = @_;
    $parser->peek_token;
    $parser->advance_after_block_end;
    return "${nodes_module}::CallExtension"->new( $self, 'foo' );
  }
}

package Text::Nunjucks::Test::Parser::TestBlockTagExtension {
  sub new  { bless { tags => ['testblocktag'], _name => 'testblocktagExtension' }, shift }
  sub tags { $_[0]->{tags} }

  sub parse {
    my ( $self, $parser, $nodes_module, $lexer_module ) = @_;
    $parser->peek_token;
    $parser->advance_after_block_end;

    my $content = $parser->parse_until_blocks('endtestblocktag');
    my $tag = "${nodes_module}::CallExtension"->new( $self, 'bar', undef, [ 1, $content ] );
    $parser->advance_after_block_end;

    return $tag;
  }
}

package Text::Nunjucks::Test::Parser::TestArgsExtension {
  sub new  { bless { tags => ['testargs'], _name => 'testargsExtension' }, shift }
  sub tags { $_[0]->{tags} }

  sub parse {
    my ( $self, $parser, $nodes_module, $lexer_module ) = @_;
    my $begun = $parser->peek_token;

    # Skip the name
    $parser->next_token;

    my $args = $parser->parse_signature(1);
    $parser->advance_after_block_end( $begun->value );

    return "${nodes_module}::CallExtension"->new( $self, 'biz', $args );
  }
}

#### describe('parser', ...) ####

subtest 'should parse basic types' => sub {
  is_ast( parse('{{ 1 }}'),     [ $Root, [ $Output, [ $Literal, 0 + 1 ] ] ] );
  is_ast( parse('{{ 4.567 }}'), [ $Root, [ $Output, [ $Literal, 0 + 4.567 ] ] ] );
  is_ast( parse('{{ "foo" }}'), [ $Root, [ $Output, [ $Literal, 'foo' ] ] ] );
  is_ast( parse("{{ 'foo' }}"), [ $Root, [ $Output, [ $Literal, 'foo' ] ] ] );
  is_ast( parse('{{ true }}'),  [ $Root, [ $Output, [ $Literal, true ] ] ] );
  is_ast( parse('{{ false }}'), [ $Root, [ $Output, [ $Literal, false ] ] ] );
  is_ast( parse('{{ none }}'),  [ $Root, [ $Output, [ $Literal, undef ] ] ] );
  is_ast( parse('{{ foo }}'),   [ $Root, [ $Output, [ $Symbol, 'foo' ] ] ] );
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

subtest 'should parse blocks' => sub {
  my $n = parse('want some {% if hungry %}pizza{% else %}water{% endif %}?');
  is( $n->children->[1]->typename, 'If' );

  $n = parse('{% block foo %}stuff{% endblock %}');
  is( $n->children->[0]->typename, 'Block' );

  $n = parse('{% block foo %}stuff{% endblock foo %}');
  is( $n->children->[0]->typename, 'Block' );

  $n = parse('{% extends "test.njk" %}stuff');
  is( $n->children->[0]->typename, 'Extends' );

  $n = parse('{% include "test.njk" %}');
  is( $n->children->[0]->typename, 'Include' );
};

subtest 'should accept attributes and methods of static arrays, objects and primitives' => sub {
  ok( eval { parse('{{ ([1, 2, 3]).indexOf(1) }}'); 1 }, 'no exception' ) or diag($@);
  ok( eval { parse('{{ [1, 2, 3].length }}'); 1 },        'no exception' ) or diag($@);
  ok( eval { parse('{{ "Some String".replace("S", "$") }}'); 1 }, 'no exception' ) or diag($@);
  ok( eval { parse('{{ ({ name : "Khalid" }).name }}'); 1 }, 'no exception' ) or diag($@);
  ok( eval { parse('{{ 1.618.toFixed(2) }}'); 1 },           'no exception' ) or diag($@);
};

subtest 'should parse include tags' => sub {
  my $n = parse('{% include "test.njk" %}');
  is( $n->children->[0]->typename, 'Include' );

  $n = parse('{% include "test.html"|replace("html","j2") %}');
  is( $n->children->[0]->typename, 'Include' );

  $n = parse('{% include ""|default("test.njk") %}');
  is( $n->children->[0]->typename, 'Include' );
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
        [$Array],
        [ $Symbol, 'x' ],
        [ $NodeList, [ $Output, [ $Symbol, 'x' ] ] ],
        [ $NodeList, [ $Output, [ $TemplateData, 'empty' ] ] ]
      ]
    ]
  );
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
  my $ast = parse('{% macro foo(bar, baz="foobar") %}' . 'This is a macro' . '{% endmacro %}');
  is_ast(
    $ast,
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
  my $ast = parse('{% call foo("bar") %}' . 'This is the caller' . '{% endcall %}');
  is_ast(
    $ast,
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
                  [$NodeList],
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
  my $ast = parse('{% call(i) foo("bar", baz="foobar") %}' . 'This is {{ i }}' . '{% endcall %}');
  is_ast(
    $ast,
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
};

subtest 'should parse raw with broken variables' => sub {
  is_ast(
    parse('{% raw %}{{ x }{% endraw %}'),
    [ $Root, [ $Output, [ $TemplateData, '{{ x }' ] ] ]
  );
};

subtest 'should parse raw with broken blocks' => sub {
  is_ast(
    parse('{% raw %}{% if i_am_stupid }Still do your job well{% endraw %}'),
    [ $Root, [ $Output, [ $TemplateData, '{% if i_am_stupid }Still do your job well' ] ] ]
  );
};

subtest 'should parse raw with pure text' => sub {
  is_ast(
    parse('{% raw %}abc{% endraw %}'),
    [ $Root, [ $Output, [ $TemplateData, 'abc' ] ] ]
  );
};

subtest 'should parse raw with raw blocks' => sub {
  is_ast(
    parse('{% raw %}{% raw %}{{ x }{% endraw %}{% endraw %}'),
    [ $Root, [ $Output, [ $TemplateData, '{% raw %}{{ x }{% endraw %}' ] ] ]
  );
};

subtest 'should parse raw with comment blocks' => sub {
  is_ast(
    parse('{% raw %}{# test {% endraw %}'),
    [ $Root, [ $Output, [ $TemplateData, '{# test ' ] ] ]
  );
};

subtest 'should parse multiple raw blocks' => sub {
  is_ast(
    parse('{% raw %}{{ var }}{% endraw %}{{ var }}{% raw %}{{ var }}{% endraw %}'),
    [ $Root,
      [ $Output, [ $TemplateData, '{{ var }}' ] ],
      [ $Output, [ $Symbol, 'var' ] ],
      [ $Output, [ $TemplateData, '{{ var }}' ] ]
    ]
  );
};

subtest 'should parse multiline multiple raw blocks' => sub {
  is_ast(
    parse("\n{% raw %}{{ var }}{% endraw %}\n{{ var }}\n{% raw %}{{ var }}{% endraw %}\n"),
    [ $Root,
      [ $Output, [ $TemplateData, "\n" ] ],
      [ $Output, [ $TemplateData, '{{ var }}' ] ],
      [ $Output, [ $TemplateData, "\n" ] ],
      [ $Output, [ $Symbol, 'var' ] ],
      [ $Output, [ $TemplateData, "\n" ] ],
      [ $Output, [ $TemplateData, '{{ var }}' ] ],
      [ $Output, [ $TemplateData, "\n" ] ]
    ]
  );
};

subtest 'should parse verbatim' => sub {
  is_ast(
    parse('{% verbatim %}hello {{ {% %} }}{% endverbatim %}'),
    [ $Root, [ $Output, [ $TemplateData, 'hello {{ {% %} }}' ] ] ]
  );
};

subtest 'should parse verbatim with broken variables' => sub {
  is_ast(
    parse('{% verbatim %}{{ x }{% endverbatim %}'),
    [ $Root, [ $Output, [ $TemplateData, '{{ x }' ] ] ]
  );
};

subtest 'should parse verbatim with broken blocks' => sub {
  is_ast(
    parse('{% verbatim %}{% if i_am_stupid }Still do your job well{% endverbatim %}'),
    [ $Root, [ $Output, [ $TemplateData, '{% if i_am_stupid }Still do your job well' ] ] ]
  );
};

subtest 'should parse verbatim with pure text' => sub {
  is_ast(
    parse('{% verbatim %}abc{% endverbatim %}'),
    [ $Root, [ $Output, [ $TemplateData, 'abc' ] ] ]
  );
};

subtest 'should parse verbatim with verbatim blocks' => sub {
  is_ast(
    parse('{% verbatim %}{% verbatim %}{{ x }{% endverbatim %}{% endverbatim %}'),
    [ $Root, [ $Output, [ $TemplateData, '{% verbatim %}{{ x }{% endverbatim %}' ] ] ]
  );
};

subtest 'should parse verbatim with comment blocks' => sub {
  is_ast(
    parse('{% verbatim %}{# test {% endverbatim %}'),
    [ $Root, [ $Output, [ $TemplateData, '{# test ' ] ] ]
  );
};

subtest 'should parse multiple verbatim blocks' => sub {
  is_ast(
    parse('{% verbatim %}{{ var }}{% endverbatim %}{{ var }}{% verbatim %}{{ var }}{% endverbatim %}'),
    [ $Root,
      [ $Output, [ $TemplateData, '{{ var }}' ] ],
      [ $Output, [ $Symbol, 'var' ] ],
      [ $Output, [ $TemplateData, '{{ var }}' ] ]
    ]
  );
};

subtest 'should parse multiline multiple verbatim blocks' => sub {
  is_ast(
    parse("\n{% verbatim %}{{ var }}{% endverbatim %}\n{{ var }}\n{% verbatim %}{{ var }}{% endverbatim %}\n"),
    [ $Root,
      [ $Output, [ $TemplateData, "\n" ] ],
      [ $Output, [ $TemplateData, '{{ var }}' ] ],
      [ $Output, [ $TemplateData, "\n" ] ],
      [ $Output, [ $Symbol, 'var' ] ],
      [ $Output, [ $TemplateData, "\n" ] ],
      [ $Output, [ $TemplateData, '{{ var }}' ] ],
      [ $Output, [ $TemplateData, "\n" ] ]
    ]
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

  is_ast(
    parse('{% from ""|default("foo/bar.njk") import baz, foobar as foobarbaz %}'),
    [ $Root,
      [ $FromImport,
        [ $Filter,
          [ $Symbol, 'default' ],
          [ $NodeList, [ $Literal, '' ], [ $Literal, 'foo/bar.njk' ] ]
        ],
        [ $NodeList, [ $Symbol, 'baz' ], [ $Pair, [ $Symbol, 'foobar' ], [ $Symbol, 'foobarbaz' ] ] ]
      ]
    ]
  );
};

subtest 'should parse whitespace control' => sub {
  # Every start/end tag with "-" should trim the whitespace before or after it

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

  is_ast(
    parse("hello \n{#- comment -#} \n world"),
    [ $Root,
      [ $Output, [ $TemplateData, 'hello' ] ],
      [ $Output, [ $TemplateData, 'world' ] ]
    ]
  );

  is_ast(
    parse("hello \n{# - comment - #} \n world"),
    [ $Root,
      [ $Output, [ $TemplateData, "hello \n" ] ],
      [ $Output, [ $TemplateData, " \n world" ] ]
    ]
  );

  # The from statement required a special case so make sure to test it
  is_ast(
    parse("{% from x import y %}\n  hi \n"),
    [ $Root,
      [ $FromImport, [ $Symbol, 'x' ], [ $NodeList, [ $Symbol, 'y' ] ] ],
      [ $Output, [ $TemplateData, "\n  hi \n" ] ]
    ]
  );

  is_ast(
    parse("{% from x import y -%}\n  hi \n"),
    [ $Root,
      [ $FromImport, [ $Symbol, 'x' ], [ $NodeList, [ $Symbol, 'y' ] ] ],
      [ $Output, [ $TemplateData, "hi \n" ] ]
    ]
  );

  is_ast(
    parse('{% if x -%}{{y}} {{z}}{% endif %}'),
    [ $Root,
      [ $If,
        [ $Symbol, 'x' ],
        [ $NodeList,
          [ $Output, [ $Symbol, 'y' ] ],
          # the value of TemplateData should be ' ' instead of ''
          [ $Output, [ $TemplateData, ' ' ] ],
          [ $Output, [ $Symbol, 'z' ] ]
        ]
      ]
    ]
  );

  is_ast(
    parse('{% if x -%}{% if y %} {{z}}{% endif %}{% endif %}'),
    [ $Root,
      [ $If,
        [ $Symbol, 'x' ],
        [ $NodeList,
          [ $If,
            [ $Symbol, 'y' ],
            [ $NodeList,
              # the value of TemplateData should be ' ' instead of ''
              [ $Output, [ $TemplateData, ' ' ] ],
              [ $Output, [ $Symbol, 'z' ] ]
            ]
          ]
        ]
      ]
    ]
  );

  is_ast(
    parse('{% if x -%}{# comment #} {{z}}{% endif %}'),
    [ $Root,
      [ $If,
        [ $Symbol, 'x' ],
        [ $NodeList,
          # the value of TemplateData should be ' ' instead of ''
          [ $Output, [ $TemplateData, ' ' ] ],
          [ $Output, [ $Symbol, 'z' ] ]
        ]
      ]
    ]
  );
};

subtest 'should throw errors' => sub {
  # Same regexes as upstream's .to.throwException(/.../) calls, in the same
  # order, matched against the thrown TemplateError's ->message.
  my @cases = (
    [ 'hello {{ foo',                                 qr/expected variable end/ ],
    [ 'hello {% if',                                  qr/expected expression/ ],
    [ 'hello {% if sdf zxc',                           qr/expected block end/ ],
    [ '{% include "foo %}',                            qr/expected block end/ ],
    [ 'hello {% if sdf %} data',                       qr/expected elif, else, or endif/ ],
    [ 'hello {% block sdf %} data',                    qr/expected endblock/ ],
    [ 'hello {% block sdf %} data{% endblock foo %}',  qr/expected block end/ ],
    [ 'hello {% bar %} dsfsdf',                        qr/unknown block tag/ ],
    [ '{{ foo(bar baz) }}',                            qr/expected comma after expression/ ],
    [ '{% import "foo" %}',                            qr/expected "as" keyword/ ],
    [ '{% from "foo" %}',                              qr/expected import/ ],
    [ '{% from "foo" import bar baz %}',                qr/expected comma/ ],
    [ '{% from "foo" import _bar %}',
      qr/names starting with an underscore cannot be imported/ ],
  );

  for my $case (@cases) {
    my ( $tpl, $re ) = @$case;
    my $err = parse_err($tpl);
    ok( blessed($err), "throws for: $tpl" ) or next;
    like( $err->message, $re, "message for: $tpl" );
  }
};

subtest 'should parse custom tags' => sub {
  my @extensions = (
    Text::Nunjucks::Test::Parser::TestTagExtension->new,
    Text::Nunjucks::Test::Parser::TestBlockTagExtension->new,
    Text::Nunjucks::Test::Parser::TestArgsExtension->new,
  );

  is_ast(
    parse( '{% testtag %}', \@extensions ),
    [ $Root, [ $CallExtension, $extensions[0], 'foo', undef, undef ] ]
  );

  is_ast(
    parse( '{% testblocktag %}sdfd{% endtestblocktag %}', \@extensions ),
    [ $Root,
      [ $CallExtension, $extensions[1], 'bar', undef,
        [ 1, [ $NodeList, [ $Output, [ $TemplateData, 'sdfd' ] ] ] ]
      ]
    ]
  );

  is_ast(
    parse( '{% testblocktag %}{{ 123 }}{% endtestblocktag %}', \@extensions ),
    [ $Root,
      [ $CallExtension, $extensions[1], 'bar', undef,
        [ 1, [ $NodeList, [ $Output, [ $Literal, 0 + 123 ] ] ] ]
      ]
    ]
  );

  is_ast(
    parse( '{% testargs(123, "abc", foo="bar") %}', \@extensions ),
    [ $Root,
      [ $CallExtension, $extensions[2], 'biz',

        # The only arg is the list of run-time arguments coming from the
        # template
        [ $NodeList,
          [ $Literal, 0 + 123 ],
          [ $Literal, 'abc' ],
          [ $KeywordArgs, [ $Pair, [ $Symbol, 'foo' ], [ $Literal, 'bar' ] ] ]
        ]
      ]
    ]
  );

  is_ast(
    parse( '{% testargs %}', \@extensions ),
    [ $Root, [ $CallExtension, $extensions[2], 'biz', undef ] ]
  );
};

done_testing;

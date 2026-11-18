#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Scalar::Util qw( blessed );
use JSON::MaybeXS ();
use Path::Tiny qw( path );

use Text::Nunjucks::Nodes;

# Unit tests for the AST node types (port of nodes.js). The parser (k12) does
# not exist yet, so the parse-mode corpus cases stay TODO in t/corpus.t; here we
# drive the node classes directly -- construction, typename, fields, accessors,
# the custom inits -- and prove that the SAME ast_dump routine t/corpus.t uses
# turns hand-built trees into the oracle's committed AST shapes.

my $N = 'Text::Nunjucks::Nodes';
sub cls { $N . '::' . $_[0] }

#### ast_dump -- a copy of the routine in t/corpus.t, so this test proves the
#### nodes feed that exact shape without waiting on the parser.
my $CANON = JSON::MaybeXS->new(
  canonical       => 1,
  convert_blessed => 1,
  allow_nonref    => 1,
  utf8            => 0,
);
sub canon { $CANON->encode( $_[0] ) }

sub ast_dump {
  my ($n) = @_;
  if ( blessed($n) && $n->can('typename') && $n->can('fields') ) {
    my %out = ( type => $n->typename, lineno => $n->lineno, colno => $n->colno );
    for my $f ( @{ $n->fields } ) {
      $out{$f} = ast_dump( $n->$f );
    }
    return \%out;
  }
  return [ map { ast_dump($_) } @$n ] if ref $n eq 'ARRAY';
  return $n;
}

#### typename + field lists (order matters -- it is the oracle AST key order)

my %EXPECT_FIELDS = (
  Node           => [],
  Value          => ['value'],
  NodeList       => ['children'],
  Root           => ['children'],
  Literal        => ['value'],
  Symbol         => ['value'],
  Group          => ['children'],
  Array          => ['children'],
  Pair           => [ 'key', 'value' ],
  Dict           => ['children'],
  LookupVal      => [ 'target', 'val' ],
  If             => [ 'cond', 'body', 'else_' ],
  IfAsync        => [ 'cond', 'body', 'else_' ],
  InlineIf       => [ 'cond', 'body', 'else_' ],
  For            => [ 'arr', 'name', 'body', 'else_' ],
  AsyncEach      => [ 'arr', 'name', 'body', 'else_' ],
  AsyncAll       => [ 'arr', 'name', 'body', 'else_' ],
  Macro          => [ 'name', 'args', 'body' ],
  Caller         => [ 'name', 'args', 'body' ],
  Import         => [ 'template', 'target', 'withContext' ],
  FromImport     => [ 'template', 'names', 'withContext' ],
  FunCall        => [ 'name', 'args' ],
  Filter         => [ 'name', 'args' ],
  FilterAsync    => [ 'name', 'args', 'symbol' ],
  KeywordArgs    => ['children'],
  Block          => [ 'name', 'body' ],
  Super          => [ 'blockName', 'symbol' ],
  TemplateRef    => ['template'],
  Extends        => ['template'],
  Include        => [ 'template', 'ignoreMissing' ],
  Set            => [ 'targets', 'value' ],
  Switch         => [ 'expr', 'cases', 'default' ],
  Case           => [ 'cond', 'body' ],
  Output         => ['children'],
  Capture        => ['body'],
  TemplateData   => ['value'],
  UnaryOp        => ['target'],
  BinOp          => [ 'left', 'right' ],
  In             => [ 'left', 'right' ],
  Is             => [ 'left', 'right' ],
  Or             => [ 'left', 'right' ],
  And            => [ 'left', 'right' ],
  Not            => ['target'],
  Add            => [ 'left', 'right' ],
  Concat         => [ 'left', 'right' ],
  Sub            => [ 'left', 'right' ],
  Mul            => [ 'left', 'right' ],
  Div            => [ 'left', 'right' ],
  FloorDiv       => [ 'left', 'right' ],
  Mod            => [ 'left', 'right' ],
  Pow            => [ 'left', 'right' ],
  Neg            => ['target'],
  Pos            => ['target'],
  Compare        => [ 'expr', 'ops' ],
  CompareOperand => [ 'expr', 'type' ],
  CallExtension      => [ 'extName', 'prop', 'args', 'contentArgs' ],
  CallExtensionAsync => [ 'extName', 'prop', 'args', 'contentArgs' ],
);

for my $name ( sort keys %EXPECT_FIELDS ) {
  my $c = cls($name);
  is( $c->typename, $name, "$name typename" );
  is_deeply( $c->fields, $EXPECT_FIELDS{$name}, "$name fields (order)" );
}

is( scalar keys %EXPECT_FIELDS, 57, 'all 57 node types covered (56 exported + base Node)' );

#### positional construction, accessors, undef stays undef -> JSON null

subtest 'positional construction and undef->null' => sub {
  my $sym = cls('Symbol')->new( 0, 3, 'a' );
  is( $sym->typename, 'Symbol', 'typename' );
  is( $sym->lineno,   0,        'lineno' );
  is( $sym->colno,    3,        'colno' );
  is( $sym->value,    'a',      'value accessor' );

  # If built with only cond+body: else_ was never passed -> undef -> null
  my $if = cls('If')->new( 0, 3, $sym, undef );
  is( $if->else_, undef, 'unpassed field is undef' );
  like( canon( ast_dump($if) ), qr/"else_":null/, 'undef field dumps as null' );
};

#### fields are rw (the parser mutates nodes after construction)

subtest 'fields are writable (parser mutates them)' => sub {
  my $if = cls('If')->new( 0, 3, undef, undef, undef );
  my $body = cls('NodeList')->new( 0, 0 );
  $if->body($body);
  $if->cond( cls('Symbol')->new( 0, 6, 'x' ) );
  is( $if->body,        $body, 'body set post-construction' );
  is( $if->cond->value, 'x',   'cond set post-construction' );

  # dynamic field assignment the way transformer does: node[prop] = walked
  my $prop = 'else_';
  $if->$prop( cls('Symbol')->new( 0, 0, 'z' ) );
  is( $if->else_->value, 'z', 'dynamic $node->$prop($v) works' );
};

#### NodeList: children default [], add_child

subtest 'NodeList children default and add_child' => sub {
  my $nl = cls('NodeList')->new( 0, 0 );
  is( ref $nl->children, 'ARRAY', 'children defaults to arrayref' );
  is( scalar @{ $nl->children }, 0, 'children empty' );
  my $sym = cls('Symbol')->new( 0, 0, 'a' );
  $nl->add_child($sym);
  is( scalar @{ $nl->children }, 1, 'add_child appends' );
  is( $nl->children->[0], $sym, 'appended node' );

  # a passed arrayref is kept as-is
  my $ref = [];
  my $nl2 = cls('NodeList')->new( 0, 0, $ref );
  is( $nl2->children, $ref, 'passed children arrayref kept' );

  # every NodeList subclass inherits the [] default
  for my $t (qw( Root Group Array Dict Output KeywordArgs )) {
    is( ref cls($t)->new( 0, 0 )->children, 'ARRAY', "$t children default []" );
  }
};

#### FromImport: names defaults to a NodeList

subtest 'FromImport names default' => sub {
  my $fi = cls('FromImport')->new( 0, 0, undef, undef, undef );
  ok( blessed( $fi->names ), 'names is an object' );
  isa_ok( $fi->names, cls('NodeList'), 'names' );
  my $given = cls('NodeList')->new( 0, 0 );
  my $fi2 = cls('FromImport')->new( 0, 0, undef, $given, undef );
  is( $fi2->names, $given, 'passed names kept' );
};

#### CallExtension: custom init, non-field autoescape, no lineno/colno

subtest 'CallExtension custom init' => sub {
  # hashref extension
  my $ce = cls('CallExtension')->new( { __name => 'myext', autoescape => 1 }, 'run', undef, undef );
  is( $ce->extName,    'myext', 'extName from ext.__name' );
  is( $ce->prop,       'run',   'prop' );
  is( $ce->autoescape, 1,       'autoescape carried from ext' );
  isa_ok( $ce->args, cls('NodeList'), 'args default NodeList' );
  is( ref $ce->contentArgs, 'ARRAY', 'contentArgs default []' );
  is( $ce->lineno, undef, 'lineno left undef' );
  is( $ce->colno,  undef, 'colno left undef' );

  # autoescape is NOT one of the dumped fields
  ok( !( grep { $_ eq 'autoescape' } @{ cls('CallExtension')->fields } ), 'autoescape not a dumped field' );

  # plain-string extension -> ext.__name falsy, falls back to ext itself
  my $ce2 = cls('CallExtension')->new( 'plainstr', 'p', undef, undef );
  is( $ce2->extName, 'plainstr', 'extName falls back to ext when no __name' );

  # CallExtensionAsync inherits the same custom init
  my $cea = cls('CallExtensionAsync')->new( { __name => 'x' }, 'q', undef, undef );
  is( $cea->typename, 'CallExtensionAsync', 'async typename' );
  is( $cea->extName,  'x',                  'async extName' );
};

#### find_all and iter_fields

subtest 'find_all / iter_fields' => sub {
  my $s1   = cls('Symbol')->new( 0, 0, 'a' );
  my $s2   = cls('Symbol')->new( 0, 0, 'b' );
  my $out  = cls('Output')->new( 0, 0, [ $s1, $s2 ] );
  my $root = cls('Root')->new( 0, 0, [$out] );

  my $syms = $root->find_all( cls('Symbol') );
  is( scalar @$syms, 2, 'find_all descends NodeList children' );

  # find_all over a non-NodeList node walks its fields
  my $if = cls('If')->new( 0, 0, $s1, undef, undef );
  is( scalar @{ $if->find_all( cls('Symbol') ) }, 1, 'find_all walks fields of a plain node' );

  my %seen;
  $if->iter_fields( sub { my ( $v, $f ) = @_; $seen{$f} = 1 } );
  is_deeply( [ sort keys %seen ], [qw( body cond else_ )], 'iter_fields visits every field' );
};

#### CompareOperand: the field named `type` overwrites the dump's type key.
#### The oracle's ast() does {type: typename, ...fields}; the `type` field
#### shadows the typename, and ast_dump reproduces that on the Perl side.

subtest 'CompareOperand type field shadows typename in the dump' => sub {
  my $op = cls('CompareOperand')->new( 0, 5, cls('Literal')->new( 0, 7, 2 ), '<' );
  is( $op->typename, 'CompareOperand', 'the node still knows its typename' );
  my $dump = ast_dump($op);
  is( $dump->{type}, '<', 'dumped type is the operator, not the typename' );
  is( $dump->{expr}{value}, 2, 'expr field present' );
};

#### hand-built trees reproduce the oracle-committed parse.json shapes

subtest 'ast_dump reproduces oracle-committed AST shapes' => sub {
  my $cases = JSON::MaybeXS->new( utf8 => 1 )
    ->decode( path(__FILE__)->parent->child('corpus/parse.json')->slurp_raw );
  my %want = map { $_->{name} => $_->{expected}{output} } @$cases;

  # {{ a }}
  my $t_symbol = cls('Root')->new(
    0, 0,
    [ cls('Output')->new( 0, 0, [ cls('Symbol')->new( 0, 3, 'a' ) ] ) ]
  );
  is( canon( ast_dump($t_symbol) ), canon( $want{'symbol lookup'} ), 'symbol lookup' );

  # {{ [1,2] }}
  my $t_array = cls('Root')->new(
    0, 0,
    [ cls('Output')->new(
        0, 0,
        [ cls('Array')->new(
            0, 3,
            [ cls('Literal')->new( 0, 4, 1 ), cls('Literal')->new( 0, 6, 2 ) ]
          )
        ]
      )
    ]
  );
  is( canon( ast_dump($t_array) ), canon( $want{'literal array'} ), 'literal array' );

  # {% if x %}y{% endif %}  -- else_ unpassed -> null
  my $t_if = cls('Root')->new(
    0, 0,
    [ cls('If')->new(
        0, 3,
        cls('Symbol')->new( 0, 6, 'x' ),
        cls('NodeList')->new(
          0, 0,
          [ cls('Output')->new(
              0, 10, [ cls('TemplateData')->new( 0, 10, 'y' ) ]
            )
          ]
        )
      )
    ]
  );
  is( canon( ast_dump($t_if) ), canon( $want{'if statement'} ), 'if statement' );
};

done_testing;

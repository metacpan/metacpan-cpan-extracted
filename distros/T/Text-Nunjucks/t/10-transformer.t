#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Scalar::Util qw( blessed );
use JSON::MaybeXS ();

use Text::Nunjucks::Parser;
use Text::Nunjucks::Transformer;
use Text::Nunjucks::Nodes;

# Perl-side unit tests for Text::Nunjucks::Transformer (port of transformer.js).
# There is NO oracle transform mode and no upstream tests/transformer.js, so the
# expected transformed ASTs below were captured DIFFERENTIALLY from the real
# upstream transformer: each case was parsed with upstream parser.js, run through
# upstream transformer.transform(ast, asyncFilters), and its AST dumped in the
# exact shape maint/oracle.js uses. The Perl port was proven byte-identical to
# that upstream output for these (and more) cases via an ad-hoc node comparison
# script; the verified upstream ASTs are pinned here as __DATA__. They are
# generated, never typed from memory -- the same rule the corpus lives by.
#
# gensym()'s counter (`var sym` upstream) is process-global and never resets, so
# the absolute hole number is not a stable observable. Both the expected and the
# actual AST have their hole_N symbols relabelled in first-appearance order
# (canonical sorted-key traversal) before comparison, which pins the *structure*
# and the tying of each FilterAsync/Super symbol to its use, without depending on
# how many holes earlier subtests minted.

my $CANON = JSON::MaybeXS->new(
  canonical       => 1,
  convert_blessed => 1,
  allow_nonref    => 1,
  utf8            => 0,
);
my $DEC = JSON::MaybeXS->new( utf8 => 0, allow_nonref => 1 );

# ast_dump: the exact routine t/corpus.t and t/10-nodes.t use, so this test
# proves the transformer feeds that same oracle-shaped AST.
sub ast_dump {
  my ($n) = @_;
  if ( blessed($n) && $n->can('typename') && $n->can('fields') ) {
    my %out = ( type => $n->typename, lineno => $n->lineno, colno => $n->colno );
    for my $f ( @{ $n->fields } ) {
      $out{$f} = ast_dump( $n->$f );
    }
    return \%out;
  }
  if ( ref $n eq 'ARRAY' ) {
    return [ map { ast_dump($_) } @$n ];
  }
  return $n;
}

# Relabel hole_<N> to hole_0, hole_1, ... in order of first appearance in the
# canonical string, so a process-global counter value never reaches an assertion.
sub norm_holes {
  my ($str) = @_;
  my %map;
  my $next = 0;
  $str =~ s{hole_\d+}{
    my $hole = $&;
    $map{$hole} = 'hole_' . $next++ unless exists $map{$hole};
    $map{$hole};
  }ge;
  return $str;
}

sub canon_ast {
  my ($node) = @_;
  return norm_holes( $CANON->encode( ast_dump($node) ) );
}

my @cases;
while ( my $line = <DATA> ) {
  next unless $line =~ /\S/;
  push @cases, $DEC->decode($line);
}

for my $c (@cases) {
  my $ast = Text::Nunjucks::Parser->parse( $c->{template}, [], undef );
  my $xformed = Text::Nunjucks::Transformer->transform( $ast, $c->{asyncFilters} );
  my $got = canon_ast($xformed);
  # Expected came from upstream's JSON; re-encode it through the same canonical
  # encoder + hole normaliser so only structure and values are compared.
  my $want = norm_holes( $CANON->encode( $DEC->decode( $c->{expected} ) ) );
  is( $got, $want, $c->{name} );
}

# Regression for _lift_filters on a CallExtensionAsync descendant (transformer.js
# _liftFilters, the `descNode instanceof CallExtensionAsync` branch). A
# CallExtensionAsync has fields extName/prop/args/contentArgs but NO `name`:
# upstream reads descNode.name as undefined and builds FilterAsync(name=null);
# calling ->name as a method on the Perl node used to die ("Can't locate object
# method name"). CallExtensionAsync nodes are only produced by registered
# extensions (k8/Environment, not yet ported), so this cannot come from a
# template -- the AST is built directly, the way the fidelity auditor did. The
# expected shape was captured from upstream: the CEA is lifted into a FilterAsync
# with name=null and replaced in place by the hole Symbol.
subtest 'callextensionasync descendant does not die (name is null)' => sub {
  my $N = 'Text::Nunjucks::Nodes';
  my $args = "${N}::NodeList"->new( 0, 0, [] );
  # CallExtensionAsync(ext, prop, args, contentArgs); a bare-string ext passes
  # through to extName. lineno/colno stay undef, as CallExtension has none.
  my $cea    = "${N}::CallExtensionAsync"->new( 'myext', 'run', $args, [] );
  my $output = "${N}::Output"->new( 0, 0, [$cea] );
  my $root   = "${N}::Root"->new( 0, 0, [$output] );

  my $xformed;
  my $ok = eval { $xformed = Text::Nunjucks::Transformer->transform( $root, [] ); 1 };
  ok( $ok, 'transform survives a CallExtensionAsync descendant' )
    or diag("died: $@");
  return unless $ok;

  # Root -> [ NodeList( FilterAsync, Output ) ] : the async lift wraps the Output.
  my $wrap = $xformed->children->[0];
  isa_ok( $wrap, "${N}::NodeList", 'output was wrapped in a NodeList' );

  my $fa = $wrap->children->[0];
  isa_ok( $fa, "${N}::FilterAsync", 'first child is the lifted FilterAsync' );
  is( $fa->name, undef, 'FilterAsync.name is null (CEA has no name field)' );
  isa_ok( $fa->args, "${N}::NodeList", 'FilterAsync.args carried over from the CEA' );

  my $hole = $fa->symbol;
  isa_ok( $hole, "${N}::Symbol", 'FilterAsync.symbol is a Symbol' );
  like( $hole->value, qr/\Ahole_\d+\z/, 'symbol is a gensym hole' );

  # The CEA in the Output was replaced in place by that same hole symbol.
  my $replaced = $wrap->children->[1];
  isa_ok( $replaced, "${N}::Output", 'second child is the original Output' );
  my $sym = $replaced->children->[0];
  isa_ok( $sym, "${N}::Symbol", 'CallExtensionAsync was replaced by a Symbol' );
  is( $sym->value, $hole->value, 'the replacement uses the same hole as the FilterAsync' );
};

done_testing;

__DATA__
{"name":"plain-output-no-async","template":"{{ x }}","asyncFilters":[],"expected":"{\"children\":[{\"children\":[{\"colno\":3,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"x\"}],\"colno\":0,\"lineno\":0,\"type\":\"Output\"}],\"colno\":0,\"lineno\":0,\"type\":\"Root\"}"}
{"name":"plain-for-if","template":"{% for i in items %}{% if i %}{{ i }}{% endif %}{% endfor %}","asyncFilters":[],"expected":"{\"children\":[{\"arr\":{\"colno\":12,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"items\"},\"body\":{\"children\":[{\"body\":{\"children\":[{\"children\":[{\"colno\":33,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"i\"}],\"colno\":30,\"lineno\":0,\"type\":\"Output\"}],\"colno\":0,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":23,\"cond\":{\"colno\":26,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"i\"},\"else_\":null,\"lineno\":0,\"type\":\"If\"}],\"colno\":0,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":3,\"else_\":null,\"lineno\":0,\"name\":{\"colno\":7,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"i\"},\"type\":\"For\"}],\"colno\":0,\"lineno\":0,\"type\":\"Root\"}"}
{"name":"async-filter-in-output","template":"{{ x | bar }}","asyncFilters":["bar"],"expected":"{\"children\":[{\"children\":[{\"args\":{\"children\":[{\"colno\":3,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"x\"}],\"colno\":7,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":7,\"lineno\":0,\"name\":{\"colno\":7,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"bar\"},\"symbol\":{\"colno\":7,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_0\"},\"type\":\"FilterAsync\"},{\"children\":[{\"colno\":7,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_0\"}],\"colno\":0,\"lineno\":0,\"type\":\"Output\"}],\"colno\":0,\"lineno\":0,\"type\":\"NodeList\"}],\"colno\":0,\"lineno\":0,\"type\":\"Root\"}"}
{"name":"async-filter-not-registered","template":"{{ x | bar }}","asyncFilters":[],"expected":"{\"children\":[{\"children\":[{\"args\":{\"children\":[{\"colno\":3,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"x\"}],\"colno\":7,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":7,\"lineno\":0,\"name\":{\"colno\":7,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"bar\"},\"type\":\"Filter\"}],\"colno\":0,\"lineno\":0,\"type\":\"Output\"}],\"colno\":0,\"lineno\":0,\"type\":\"Root\"}"}
{"name":"two-async-outputs","template":"{{ x | bar }} {{ y | bar }}","asyncFilters":["bar"],"expected":"{\"children\":[{\"children\":[{\"args\":{\"children\":[{\"colno\":3,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"x\"}],\"colno\":7,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":7,\"lineno\":0,\"name\":{\"colno\":7,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"bar\"},\"symbol\":{\"colno\":7,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_0\"},\"type\":\"FilterAsync\"},{\"children\":[{\"colno\":7,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_0\"}],\"colno\":0,\"lineno\":0,\"type\":\"Output\"}],\"colno\":0,\"lineno\":0,\"type\":\"NodeList\"},{\"children\":[{\"colno\":13,\"lineno\":0,\"type\":\"TemplateData\",\"value\":\" \"}],\"colno\":13,\"lineno\":0,\"type\":\"Output\"},{\"children\":[{\"args\":{\"children\":[{\"colno\":17,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"y\"}],\"colno\":21,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":21,\"lineno\":0,\"name\":{\"colno\":21,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"bar\"},\"symbol\":{\"colno\":21,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_1\"},\"type\":\"FilterAsync\"},{\"children\":[{\"colno\":21,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_1\"}],\"colno\":14,\"lineno\":0,\"type\":\"Output\"}],\"colno\":14,\"lineno\":0,\"type\":\"NodeList\"}],\"colno\":0,\"lineno\":0,\"type\":\"Root\"}"}
{"name":"chained-async-filters","template":"{{ x | bar | baz }}","asyncFilters":["bar","baz"],"expected":"{\"children\":[{\"children\":[{\"args\":{\"children\":[{\"colno\":3,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"x\"}],\"colno\":7,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":7,\"lineno\":0,\"name\":{\"colno\":7,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"bar\"},\"symbol\":{\"colno\":7,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_0\"},\"type\":\"FilterAsync\"},{\"args\":{\"children\":[{\"colno\":7,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_0\"}],\"colno\":13,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":13,\"lineno\":0,\"name\":{\"colno\":13,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"baz\"},\"symbol\":{\"colno\":13,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_1\"},\"type\":\"FilterAsync\"},{\"children\":[{\"colno\":13,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_1\"}],\"colno\":0,\"lineno\":0,\"type\":\"Output\"}],\"colno\":0,\"lineno\":0,\"type\":\"NodeList\"}],\"colno\":0,\"lineno\":0,\"type\":\"Root\"}"}
{"name":"mixed-sync-async-filter","template":"{{ x | upper | bar }}","asyncFilters":["bar"],"expected":"{\"children\":[{\"children\":[{\"args\":{\"children\":[{\"args\":{\"children\":[{\"colno\":3,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"x\"}],\"colno\":7,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":7,\"lineno\":0,\"name\":{\"colno\":7,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"upper\"},\"type\":\"Filter\"}],\"colno\":15,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":15,\"lineno\":0,\"name\":{\"colno\":15,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"bar\"},\"symbol\":{\"colno\":15,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_0\"},\"type\":\"FilterAsync\"},{\"children\":[{\"colno\":15,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_0\"}],\"colno\":0,\"lineno\":0,\"type\":\"Output\"}],\"colno\":0,\"lineno\":0,\"type\":\"NodeList\"}],\"colno\":0,\"lineno\":0,\"type\":\"Root\"}"}
{"name":"async-filter-in-set","template":"{% set z = x | bar %}{{ z }}","asyncFilters":["bar"],"expected":"{\"children\":[{\"children\":[{\"args\":{\"children\":[{\"colno\":11,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"x\"}],\"colno\":15,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":15,\"lineno\":0,\"name\":{\"colno\":15,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"bar\"},\"symbol\":{\"colno\":15,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_0\"},\"type\":\"FilterAsync\"},{\"colno\":3,\"lineno\":0,\"targets\":[{\"colno\":7,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"z\"}],\"type\":\"Set\",\"value\":{\"colno\":15,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_0\"}}],\"colno\":3,\"lineno\":0,\"type\":\"NodeList\"},{\"children\":[{\"colno\":24,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"z\"}],\"colno\":21,\"lineno\":0,\"type\":\"Output\"}],\"colno\":0,\"lineno\":0,\"type\":\"Root\"}"}
{"name":"async-filter-in-for-arr","template":"{% for i in items | bar %}{{ i }}{% endfor %}","asyncFilters":["bar"],"expected":"{\"children\":[{\"children\":[{\"args\":{\"children\":[{\"colno\":12,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"items\"}],\"colno\":20,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":20,\"lineno\":0,\"name\":{\"colno\":20,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"bar\"},\"symbol\":{\"colno\":20,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_0\"},\"type\":\"FilterAsync\"},{\"arr\":{\"colno\":20,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_0\"},\"body\":{\"children\":[{\"children\":[{\"colno\":29,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"i\"}],\"colno\":26,\"lineno\":0,\"type\":\"Output\"}],\"colno\":0,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":3,\"else_\":null,\"lineno\":0,\"name\":{\"colno\":7,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"i\"},\"type\":\"For\"}],\"colno\":3,\"lineno\":0,\"type\":\"NodeList\"}],\"colno\":0,\"lineno\":0,\"type\":\"Root\"}"}
{"name":"async-filter-in-if-cond","template":"{% if x | bar %}yes{% endif %}","asyncFilters":["bar"],"expected":"{\"children\":[{\"children\":[{\"args\":{\"children\":[{\"colno\":6,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"x\"}],\"colno\":10,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":10,\"lineno\":0,\"name\":{\"colno\":10,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"bar\"},\"symbol\":{\"colno\":10,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_0\"},\"type\":\"FilterAsync\"},{\"body\":{\"children\":[{\"children\":[{\"colno\":16,\"lineno\":0,\"type\":\"TemplateData\",\"value\":\"yes\"}],\"colno\":16,\"lineno\":0,\"type\":\"Output\"}],\"colno\":0,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":3,\"cond\":{\"colno\":10,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_0\"},\"else_\":null,\"lineno\":0,\"type\":\"If\"}],\"colno\":3,\"lineno\":0,\"type\":\"NodeList\"}],\"colno\":0,\"lineno\":0,\"type\":\"Root\"}"}
{"name":"async-filter-in-for-body","template":"{% for i in items %}{{ i | bar }}{% endfor %}","asyncFilters":["bar"],"expected":"{\"children\":[{\"arr\":{\"colno\":12,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"items\"},\"body\":{\"children\":[{\"children\":[{\"args\":{\"children\":[{\"colno\":23,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"i\"}],\"colno\":27,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":27,\"lineno\":0,\"name\":{\"colno\":27,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"bar\"},\"symbol\":{\"colno\":27,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_0\"},\"type\":\"FilterAsync\"},{\"children\":[{\"colno\":27,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_0\"}],\"colno\":20,\"lineno\":0,\"type\":\"Output\"}],\"colno\":20,\"lineno\":0,\"type\":\"NodeList\"}],\"colno\":0,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":3,\"else_\":null,\"lineno\":0,\"name\":{\"colno\":7,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"i\"},\"type\":\"AsyncEach\"}],\"colno\":0,\"lineno\":0,\"type\":\"Root\"}"}
{"name":"async-filter-in-if-body","template":"{% if cond %}{{ x | bar }}{% endif %}","asyncFilters":["bar"],"expected":"{\"children\":[{\"body\":{\"children\":[{\"children\":[{\"args\":{\"children\":[{\"colno\":16,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"x\"}],\"colno\":20,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":20,\"lineno\":0,\"name\":{\"colno\":20,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"bar\"},\"symbol\":{\"colno\":20,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_0\"},\"type\":\"FilterAsync\"},{\"children\":[{\"colno\":20,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_0\"}],\"colno\":13,\"lineno\":0,\"type\":\"Output\"}],\"colno\":13,\"lineno\":0,\"type\":\"NodeList\"}],\"colno\":0,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":3,\"cond\":{\"colno\":6,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"cond\"},\"else_\":null,\"lineno\":0,\"type\":\"IfAsync\"}],\"colno\":0,\"lineno\":0,\"type\":\"Root\"}"}
{"name":"nested-for-if-async-body","template":"{% for i in items %}{% if i %}{{ i | bar }}{% endif %}{% endfor %}","asyncFilters":["bar"],"expected":"{\"children\":[{\"arr\":{\"colno\":12,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"items\"},\"body\":{\"children\":[{\"body\":{\"children\":[{\"children\":[{\"args\":{\"children\":[{\"colno\":33,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"i\"}],\"colno\":37,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":37,\"lineno\":0,\"name\":{\"colno\":37,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"bar\"},\"symbol\":{\"colno\":37,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_0\"},\"type\":\"FilterAsync\"},{\"children\":[{\"colno\":37,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_0\"}],\"colno\":30,\"lineno\":0,\"type\":\"Output\"}],\"colno\":30,\"lineno\":0,\"type\":\"NodeList\"}],\"colno\":0,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":23,\"cond\":{\"colno\":26,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"i\"},\"else_\":null,\"lineno\":0,\"type\":\"IfAsync\"}],\"colno\":0,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":3,\"else_\":null,\"lineno\":0,\"name\":{\"colno\":7,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"i\"},\"type\":\"AsyncEach\"}],\"colno\":0,\"lineno\":0,\"type\":\"Root\"}"}
{"name":"super-in-block","template":"{% block content %}{{ super() }}{% endblock %}","asyncFilters":[],"expected":"{\"children\":[{\"body\":{\"children\":[{\"blockName\":{\"colno\":9,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"content\"},\"colno\":0,\"lineno\":0,\"symbol\":{\"colno\":0,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_0\"},\"type\":\"Super\"},{\"children\":[{\"colno\":27,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_0\"}],\"colno\":19,\"lineno\":0,\"type\":\"Output\"}],\"colno\":0,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":3,\"lineno\":0,\"name\":{\"colno\":9,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"content\"},\"type\":\"Block\"}],\"colno\":0,\"lineno\":0,\"type\":\"Root\"}"}
{"name":"super-with-content","template":"{% block content %}before {{ super() }} after{% endblock %}","asyncFilters":[],"expected":"{\"children\":[{\"body\":{\"children\":[{\"blockName\":{\"colno\":9,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"content\"},\"colno\":0,\"lineno\":0,\"symbol\":{\"colno\":0,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_0\"},\"type\":\"Super\"},{\"children\":[{\"colno\":19,\"lineno\":0,\"type\":\"TemplateData\",\"value\":\"before \"}],\"colno\":19,\"lineno\":0,\"type\":\"Output\"},{\"children\":[{\"colno\":34,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_0\"}],\"colno\":26,\"lineno\":0,\"type\":\"Output\"},{\"children\":[{\"colno\":39,\"lineno\":0,\"type\":\"TemplateData\",\"value\":\" after\"}],\"colno\":39,\"lineno\":0,\"type\":\"Output\"}],\"colno\":0,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":3,\"lineno\":0,\"name\":{\"colno\":9,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"content\"},\"type\":\"Block\"}],\"colno\":0,\"lineno\":0,\"type\":\"Root\"}"}
{"name":"block-no-super","template":"{% block content %}just text {{ x }}{% endblock %}","asyncFilters":[],"expected":"{\"children\":[{\"body\":{\"children\":[{\"children\":[{\"colno\":19,\"lineno\":0,\"type\":\"TemplateData\",\"value\":\"just text \"}],\"colno\":19,\"lineno\":0,\"type\":\"Output\"},{\"children\":[{\"colno\":32,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"x\"}],\"colno\":29,\"lineno\":0,\"type\":\"Output\"}],\"colno\":0,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":3,\"lineno\":0,\"name\":{\"colno\":9,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"content\"},\"type\":\"Block\"}],\"colno\":0,\"lineno\":0,\"type\":\"Root\"}"}
{"name":"asyncEach-tag","template":"{% asyncEach i in items %}{{ i }}{% endeach %}","asyncFilters":[],"expected":"{\"children\":[{\"arr\":{\"colno\":18,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"items\"},\"body\":{\"children\":[{\"children\":[{\"colno\":29,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"i\"}],\"colno\":26,\"lineno\":0,\"type\":\"Output\"}],\"colno\":0,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":3,\"else_\":null,\"lineno\":0,\"name\":{\"colno\":13,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"i\"},\"type\":\"AsyncEach\"}],\"colno\":0,\"lineno\":0,\"type\":\"Root\"}"}
{"name":"asyncAll-tag","template":"{% asyncAll i in items %}{{ i }}{% endall %}","asyncFilters":[],"expected":"{\"children\":[{\"arr\":{\"colno\":17,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"items\"},\"body\":{\"children\":[{\"children\":[{\"colno\":28,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"i\"}],\"colno\":25,\"lineno\":0,\"type\":\"Output\"}],\"colno\":0,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":3,\"else_\":null,\"lineno\":0,\"name\":{\"colno\":12,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"i\"},\"type\":\"AsyncAll\"}],\"colno\":0,\"lineno\":0,\"type\":\"Root\"}"}
{"name":"asyncAll-with-async-filter-body","template":"{% asyncAll i in items %}{{ i | bar }}{% endall %}","asyncFilters":["bar"],"expected":"{\"children\":[{\"arr\":{\"colno\":17,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"items\"},\"body\":{\"children\":[{\"children\":[{\"args\":{\"children\":[{\"colno\":28,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"i\"}],\"colno\":32,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":32,\"lineno\":0,\"name\":{\"colno\":32,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"bar\"},\"symbol\":{\"colno\":32,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_0\"},\"type\":\"FilterAsync\"},{\"children\":[{\"colno\":32,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_0\"}],\"colno\":25,\"lineno\":0,\"type\":\"Output\"}],\"colno\":25,\"lineno\":0,\"type\":\"NodeList\"}],\"colno\":0,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":3,\"else_\":null,\"lineno\":0,\"name\":{\"colno\":12,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"i\"},\"type\":\"AsyncAll\"}],\"colno\":0,\"lineno\":0,\"type\":\"Root\"}"}
{"name":"ifAsync-tag","template":"{% ifAsync x %}yes{% endif %}","asyncFilters":[],"expected":"{\"children\":[{\"body\":{\"children\":[{\"children\":[{\"colno\":15,\"lineno\":0,\"type\":\"TemplateData\",\"value\":\"yes\"}],\"colno\":15,\"lineno\":0,\"type\":\"Output\"}],\"colno\":0,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":3,\"cond\":{\"colno\":11,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"x\"},\"else_\":null,\"lineno\":0,\"type\":\"IfAsync\"}],\"colno\":0,\"lineno\":0,\"type\":\"Root\"}"}
{"name":"lookupval-funcall","template":"{% block content %}{{ obj.method() }}{% endblock %}","asyncFilters":[],"expected":"{\"children\":[{\"body\":{\"children\":[{\"children\":[{\"args\":{\"children\":[],\"colno\":32,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":32,\"lineno\":0,\"name\":{\"colno\":25,\"lineno\":0,\"target\":{\"colno\":22,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"obj\"},\"type\":\"LookupVal\",\"val\":{\"colno\":26,\"lineno\":0,\"type\":\"Literal\",\"value\":\"method\"}},\"type\":\"FunCall\"}],\"colno\":19,\"lineno\":0,\"type\":\"Output\"}],\"colno\":0,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":3,\"lineno\":0,\"name\":{\"colno\":9,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"content\"},\"type\":\"Block\"}],\"colno\":0,\"lineno\":0,\"type\":\"Root\"}"}
{"name":"two-blocks-super","template":"{% block a %}{{ super() }}{% endblock %}{% block b %}{{ super() }}{% endblock %}","asyncFilters":[],"expected":"{\"children\":[{\"body\":{\"children\":[{\"blockName\":{\"colno\":9,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"a\"},\"colno\":0,\"lineno\":0,\"symbol\":{\"colno\":0,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_0\"},\"type\":\"Super\"},{\"children\":[{\"colno\":21,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_0\"}],\"colno\":13,\"lineno\":0,\"type\":\"Output\"}],\"colno\":0,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":3,\"lineno\":0,\"name\":{\"colno\":9,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"a\"},\"type\":\"Block\"},{\"body\":{\"children\":[{\"blockName\":{\"colno\":49,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"b\"},\"colno\":0,\"lineno\":0,\"symbol\":{\"colno\":0,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_1\"},\"type\":\"Super\"},{\"children\":[{\"colno\":61,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_1\"}],\"colno\":53,\"lineno\":0,\"type\":\"Output\"}],\"colno\":0,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":43,\"lineno\":0,\"name\":{\"colno\":49,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"b\"},\"type\":\"Block\"}],\"colno\":0,\"lineno\":0,\"type\":\"Root\"}"}
{"name":"dollar-at-backslash-literal","template":"{% set s = a | bar %}{{ s }}$@\\","asyncFilters":["bar"],"expected":"{\"children\":[{\"children\":[{\"args\":{\"children\":[{\"colno\":11,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"a\"}],\"colno\":15,\"lineno\":0,\"type\":\"NodeList\"},\"colno\":15,\"lineno\":0,\"name\":{\"colno\":15,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"bar\"},\"symbol\":{\"colno\":15,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_0\"},\"type\":\"FilterAsync\"},{\"colno\":3,\"lineno\":0,\"targets\":[{\"colno\":7,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"s\"}],\"type\":\"Set\",\"value\":{\"colno\":15,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"hole_0\"}}],\"colno\":3,\"lineno\":0,\"type\":\"NodeList\"},{\"children\":[{\"colno\":24,\"lineno\":0,\"type\":\"Symbol\",\"value\":\"s\"}],\"colno\":21,\"lineno\":0,\"type\":\"Output\"},{\"children\":[{\"colno\":28,\"lineno\":0,\"type\":\"TemplateData\",\"value\":\"$@\\\\\"}],\"colno\":28,\"lineno\":0,\"type\":\"Output\"}],\"colno\":0,\"lineno\":0,\"type\":\"Root\"}"}

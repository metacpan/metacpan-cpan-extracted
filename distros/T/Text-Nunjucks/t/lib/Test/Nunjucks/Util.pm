package Test::Nunjucks::Util;
# ABSTRACT: shared render()/equal() harness for ported upstream suites (t/upstream/*.t)
#
# Perl analogue of upstream/nunjucks/tests/util.js. util.js's render() builds a
# real Environment + FileSystemLoader(templatesPath) and calls t.render(ctx, cb);
# now that Environment/Context/Template (k16) are ported, this does the same
# with a real Text::Nunjucks::Environment / ::Template -- the only difference is
# the loader: a MemoryLoader below, seeded from committed copies of the actual
# upstream template files (t/upstream/templates/, byte-identical to
# upstream/nunjucks/tests/templates/), so include/extends/import tests run
# without the gitignored upstream/ tree present -- the same MemoryLoader
# convention t/corpus.t uses for its in-memory cases. It was written while
# FileSystemLoader was not ported; since k19 it is
# (Text::Nunjucks::Loader::FileSystem), and the MemoryLoader stays: it reports a
# template's name as its path where FileSystemLoader reports the absolute file
# path, so moving the suites over is a change of its own (k98).
#
# util.js also exports `jinjaEqual`, not ported here yet -- no suite ported so
# far needs it. Port it alongside the first t/upstream/*.t that calls it,
# oracle-grounded like everything else, rather than writing it speculatively.
# `normEOL` is ported below (first caller: t/upstream/api.t).
#
# `finish(done)` has no Perl counterpart and is never ported: it exists in
# util.js only to coordinate mocha's async done() with nunjucks' CPS callbacks
# that may or may not fire synchronously. Perl callbacks in this port run
# synchronously unless user code defers them (ADR 0003), and Test::More has no
# `done` ceremony -- render() below simply returns (err, output) once the
# root() callback has fired. Ported suites (t/upstream/runtime.t) simply omit
# the finish(done) call at each site; do the same here.

use strict;
use warnings;
use Exporter 'import';
use Carp qw( croak );
use Test::More ();
use Path::Tiny qw( path );
use Text::Nunjucks::Environment;
use Text::Nunjucks::Loader;

our @EXPORT_OK = qw( render equal normEOL );

#### MemoryLoader -- Perl analogue of maint/oracle.js's MemoryLoader; it stands
#### in for the FileSystemLoader(templatesPath) util.js's render() builds,
#### seeded from committed copies of the real upstream template files (see
#### header comment).

package Test::Nunjucks::Util::_MemoryLoader {
  use Moo;
  extends 'Text::Nunjucks::Loader';

  has templates => ( is => 'ro', default => sub { {} } );

  sub get_source {
    my ( $self, $name ) = @_;
    return undef unless exists $self->templates->{$name};
    return { src => $self->templates->{$name}, path => $name, noCache => 1 };
  }
}

{
  my $DEFAULT_TEMPLATES;

  sub _default_templates {
    return $DEFAULT_TEMPLATES if $DEFAULT_TEMPLATES;
    my $dir = path(__FILE__)->parent->parent->parent->parent->child( 'upstream', 'templates' );
    my %templates;
    for my $file ( $dir->children ) {
      next unless $file->is_file;
      $templates{ $file->basename } = $file->slurp_utf8;
    }
    return $DEFAULT_TEMPLATES = \%templates;
  }
}

sub _fresh_loader {
  return Test::Nunjucks::Util::_MemoryLoader->new( templates => _default_templates() );
}

#### Extension -- Perl analogue of the JS constructor-function extension
#### objects tests/compiler.js defines inline, e.g.:
####   function TestExtension() {
####     this.tags = ['test'];
####     this.parse = function(parser, nodes, lexer) { ... };
####     this.run = function(context, ...) { ... };
####   }
#### JS stores `parse`/`run` as per-instance closures, not class methods, and
#### the closure body freely reads `this` (the extension itself, e.g. to build
#### `new nodes.CallExtension(this, 'run', ...)`); Environment::add_extension
#### also stamps `ext.__name = name` as a plain property set
#### (Nodes::CallExtension._ext_attr then reads extName/autoescape back through
#### ->can/method for a blessed ref -- see its own header comment). This bridges
#### the same shape -- a blessed hashref whose parse/run/__name/autoescape are
#### backed by the constructor's tags/parse/run/autoescape arguments -- with one
#### adaptation: Perl closures have no implicit `this`, so parse/run dispatch
#### passes the extension object as an explicit leading argument instead
#### ($ext->parse(@rest) invokes parse->($ext, @rest), not just parse->(@rest)).
package Test::Nunjucks::Util::_Extension {
  sub new {
    my ( $class, %args ) = @_;
    return bless {
      tags       => $args{tags} || [],
      _parse     => $args{parse},
      _run       => $args{run},
      autoescape => $args{autoescape},
    }, $class;
  }
  sub tags       { $_[0]->{tags} }
  sub autoescape { $_[0]->{autoescape} }
  sub __name     { my $self = shift; $self->{__name} = shift if @_; return $self->{__name} }
  sub parse      { my $self = shift; return $self->{_parse}->( $self, @_ ) }
  sub run        { my $self = shift; return $self->{_run}->( $self, @_ ) }
}

#### normEOL(str) -> str
#
# JS: if (!str) return str; return str.replace(/\r\n|\r/g, '\n');
sub normEOL {
  my ($str) = @_;
  return $str unless $str;
  $str =~ s/\r\n|\r/\n/g;
  return $str;
}

#### render(template, ctx, opts, env) -> (err, output)
#
# JS: render(str, ctx, opts, env, cb) constructs Environment+Template (unless
# env is passed) and calls t.render(ctx, cb); cb(err, res) throws err (unless
# opts.noThrow) or hands (err, normEOL(res)) to the caller. Ported as a direct
# (err, output) return -- see the file header for why no callback/done plumbing
# is needed; the CPS callback still runs, it is just guaranteed synchronous
# here (ADR 0003).
sub render {
  my ( $template, $ctx, $opts, $env ) = @_;
  $opts = { %{ $opts // {} } };
  $ctx  //= {};

  my $no_throw      = delete $opts->{noThrow};
  my $filters       = delete $opts->{filters};
  my $async_filters = delete $opts->{asyncFilters};
  my $extensions    = delete $opts->{extensions};

  $env //= Text::Nunjucks::Environment->new( [ _fresh_loader() ], $opts );

  for my $name ( keys %{ $filters || {} } ) {
    $env->add_filter( $name, $filters->{$name} );
  }
  for my $name ( keys %{ $async_filters || {} } ) {
    $env->add_filter( $name, $async_filters->{$name}, 1 );
  }
  for my $name ( keys %{ $extensions || {} } ) {
    $env->add_extension( $name, $extensions->{$name} );
  }

  my $tmpl = $env->template_class->new( $template, $env );

  my $out;
  my $ok = eval { $out = $tmpl->render($ctx); 1 };
  if ( !$ok ) {
    my $err = $@;
    croak $err unless $no_throw;
    return ( $err, undef );
  }
  return ( undef, $out );
}

#### equal(template, ctx, opts, expected, env) -- JS's type-based argument
# juggling (equal(str, ctx, opts, str2, env), any of ctx/opts/env omittable
# because JS can tell a string apart from an object at the call site) becomes
# arity-based dispatch here: every ported call site passes exactly the JS call's
# argument count, `undef` standing in for an omitted middle argument (JS `null`)
# exactly as the upstream call sites already do.
sub equal {
  my ( $template, @rest ) = @_;
  my ( $ctx, $opts, $expected, $env );

  if ( @rest == 1 ) {
    ($expected) = @rest;
  }
  elsif ( @rest == 2 ) {
    ( $ctx, $expected ) = @rest;
  }
  elsif ( @rest == 3 ) {
    ( $ctx, $opts, $expected ) = @rest;
  }
  elsif ( @rest == 4 ) {
    ( $ctx, $opts, $expected, $env ) = @rest;
  }
  else {
    croak 'equal: wrong number of arguments';
  }

  my ( $err, $res ) = render( $template, $ctx, $opts, $env );
  croak $err if $err;
  Test::More::is( $res, $expected );
  return $res;
}

1;

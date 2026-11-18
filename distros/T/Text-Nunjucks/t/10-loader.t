#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Cwd ();
use Path::Tiny qw( path );
use Scalar::Util qw( blessed weaken );

# Perl-side API tests for the concrete loaders (k19): Loader resolve,
# Text::Nunjucks::Loader::FileSystem (src/node-loaders.js FileSystemLoader) and
# Text::Nunjucks::Loader::Precompiled (src/precompiled-loader.js), and how the
# Environment caches through them. What a render through a FileSystemLoader
# gives -- relative names, the search-path guard, the UTF-8 decode, node's
# errors, the boolean-opts warning, the default loader -- is oracle-grounded in
# t/corpus/render-loaders.json; this file pins the object surface around it.
# PrecompiledLoader has no upstream test (its templates come from precompile,
# k23); its tests hand-build the code object a precompiled template evaluates to.

use Text::Nunjucks::Environment;
use Text::Nunjucks::Loader;
use Text::Nunjucks::Loader::FileSystem;
use Text::Nunjucks::Loader::Precompiled;

sub msg { my ($e) = @_; blessed($e) && $e->can('message') ? $e->message : "$e" }

my $FS   = 'Text::Nunjucks::Loader::FileSystem';
my $ROOT = path(__FILE__)->parent->parent->realpath;
my $DATA = $ROOT->child( 't', 'data', 'loader' );
my $CWD  = Cwd::getcwd();

# Paths follow node's POSIX path model; on Windows ('C:/...' is not absolute
# there) the tests that resolve a file's path are skipped (path.win32 comes later).
my $WIN_SKIP = $^O eq 'MSWin32' ? 'POSIX path model; path.win32 comes later' : undef;

#### Loader resolve -- node's path.resolve(path.dirname(from), to), lexical

subtest 'Loader resolve collapses .. on the string (k16 self-flag)' => sub {
  my $loader = Text::Nunjucks::Loader->new;
  is( $loader->resolve( 'views/sub/page.njk', '../d.njk' ), $CWD . '/views/d.njk', 'relative from: anchored at the cwd, .. collapsed' );
  is( $loader->resolve( '/a/b/c.njk', './d.njk' ),         '/a/b/d.njk',        './ stays in the directory' );
  is( $loader->resolve( '/a/b/c.njk', '../../../../x' ),   '/x',                'nothing above /' );
  is( $loader->resolve( '/no/such/dir/c.njk', '../x' ),    '/no/such/x',        'the file system is never asked' );
};

#### FileSystemLoader -- constructor

subtest 'FileSystemLoader: search paths, noCache, pathsToNames' => sub {
  my $loader = $FS->new;
  isa_ok( $loader, 'Text::Nunjucks::Loader' );
  is_deeply( $loader->search_paths,   ['.'], 'no search paths: [.]' );
  is_deeply( $loader->paths_to_names, {},    'pathsToNames starts empty' );
  ok( !$loader->no_cache, 'noCache defaults to false' );
  is_deeply( $loader->cache, {}, 'the Loader cache' );

  is_deeply( $FS->new('./views//sub/../')->search_paths, ['views/'], 'one search path, path.normalize d' );
  is_deeply( $FS->new( [ 'a/./b', '/x/../y' ] )->search_paths, [ 'a/b', '/y' ], 'an array, each normalized' );
  is_deeply( $FS->new('')->search_paths, ['.'], 'a falsy search path is the default' );
  ok( $FS->new( 'views', { noCache => 1 } )->no_cache, 'opts noCache' );
};

subtest 'FileSystemLoader: a boolean as opts warns on STDOUT' => sub {
  my $out = '';
  my $loader = do {
    local *STDOUT;
    open( STDOUT, '>', \$out ) or die $!;
    $FS->new( 'views', builtin::true() );
  };
  like( $out, qr/\A\[nunjucks\] Warning: you passed a boolean as the second argument to FileSystemLoader[^\n]*\n\z/,
    'one line, the upstream text (exact text: t/corpus/render-loaders.json)' );
  ok( !$loader->no_cache, 'true.noCache is undefined' );

  $out = '';
  {
    local *STDOUT;
    open( STDOUT, '>', \$out ) or die $!;
    $FS->new( 'views', 1 );
    $FS->new( 'views', {} );
  }
  is( $out, '', 'a number or a hash is no boolean: no warning' );
};

subtest 'FileSystemLoader: watch dies with upstream\'s no-chokidar text' => sub {
  my $e = do { local $@; eval { $FS->new( 'views', { watch => 1 } ); 1 } ? undef : $@ };
  ok( blessed($e) && $e->isa('Text::Nunjucks::Lib::Error'), 'an Error' );
  is( msg($e), 'watch requires chokidar to be installed', 'its message' );
};

subtest 'FileSystemLoader: a search path that is no string dies with node\'s TypeError' => sub {
  # searchPaths.map(path.normalize): node's validateString. The texts are
  # node's (t/data/node-builtins.json pins every kind, t/corpus/render-loaders.json
  # the JSON-borne ones through the oracle); undefined and a function have no
  # JSON form, so they are checked here.
  for my $c (
    [ [undef],                     'Received undefined',                   'an undefined search path' ],
    [ [ sub { } ],                 'Received function ',                   'a coderef, a function without a name (k88)' ],
    [ [ 'views', path('views') ],  'Received an instance of Object',       'a Path::Tiny object, a blessed object, is no string' ],
  ) {
    my ( $search_paths, $received, $what ) = @$c;
    my $e = do { local $@; eval { $FS->new($search_paths); 1 } ? undef : $@ };
    ok( blessed($e) && $e->isa('Text::Nunjucks::Lib::Error'), "$what: an Error" );
    is( $e && $e->name, 'TypeError', '... a TypeError' );
    is( msg($e), 'The "path" argument must be of type string. ' . $received, '... with node\'s message' );
  }
};

#### FileSystemLoader -- getSource

subtest 'FileSystemLoader: getSource and the load event' => sub {
  plan skip_all => $WIN_SKIP if $WIN_SKIP;
  my $loader = $FS->new( [ "$DATA/views2", "$DATA/views" ] );
  my @loads;
  $loader->on( 'load', sub { push @loads, [@_] } );

  my $src = $loader->get_source('sub/part.njk');
  is_deeply( $src, { src => 'part', path => "$DATA/views/sub/part.njk", noCache => !!0 }, '{src, path, noCache}' );
  is( scalar(@loads),  1,              'one load event' );
  is( $loads[0][0],    'sub/part.njk', '... with the name' );
  is( $loads[0][1],    $src,           '... and the very source object' );
  is( $loader->paths_to_names->{"$DATA/views/sub/part.njk"}, 'sub/part.njk', 'pathsToNames maps the full path to the name' );

  is( $loader->get_source('same.njk')->{src}, 'views2:same', 'the first search path wins' );
  is( $loader->get_source('nope.njk'), undef, 'nothing found: null' );
  is( scalar(@loads), 2, 'no load event without a source' );

  my $views = $FS->new("$DATA/views");
  is( $views->get_source('../views2/secret.njk')->{path}, "$DATA/views2/secret.njk",
    "a sibling extending the search path's name passes the string-prefix guard (upstream, ADR 0004)" );
  is( $views->get_source('../outside.njk'), undef, 'a file above the search path does not' );
  is( $FS->new( "$DATA/views", { noCache => 1 } )->get_source('d.njk')->{noCache}, !!1, 'noCache rides on the source' );
};

#### Environment -- the default loader, caching, the load event

subtest 'Environment: no loaders is [FileSystemLoader(views)]' => sub {
  my $env = Text::Nunjucks::Environment->new;
  is( scalar @{ $env->loaders }, 1, 'one loader' );
  isa_ok( $env->loaders->[0], $FS );
  is_deeply( $env->loaders->[0]->search_paths, ['views'], "search path 'views'" );
};

subtest 'Environment: caching through a FileSystemLoader' => sub {
  plan skip_all => $WIN_SKIP if $WIN_SKIP;
  my $loader = $FS->new("$DATA/views");
  my $env    = Text::Nunjucks::Environment->new($loader);
  my @loads;
  $env->on( 'load', sub { push @loads, [@_] } );

  my $tmpl = $env->get_template('sub/page.njk');
  is( $loader->cache->{'sub/page.njk'}, $tmpl, 'cached under its name' );
  is( $env->get_template('sub/page.njk'), $tmpl, 'the second get_template is the cache' );
  is( scalar(@loads), 1, 'the Environment re-emitted one load' );
  is( $loads[0][2], $loader, '... with the loader' );

  is( $tmpl->render( {} ), "<layout>page[part][d][x(d)]</layout>\n", 'renders' );
  ok( exists $loader->cache->{"$DATA/views/d.njk"}, 'a relative include is cached under its resolved path' );
  ok( exists $loader->cache->{"$DATA/views/layout.njk"}, '... as is the parent template' );

  my $nocache = $FS->new( "$DATA/views", { noCache => 1 } );
  my $env2    = Text::Nunjucks::Environment->new($nocache);
  $env2->get_template('d.njk');
  is_deeply( $nocache->cache, {}, 'noCache: nothing cached' );
};

#### PrecompiledLoader

subtest 'PrecompiledLoader: getSource' => sub {
  my $none = Text::Nunjucks::Loader::Precompiled->new;
  is_deeply( $none->precompiled, {}, 'no templates: {}' );
  is( $none->get_source('a.njk'), undef, 'null for an unknown name' );

  my $obj    = { root => sub { my ( $env, $context, $frame, $runtime, $cb ) = @_; $cb->( undef, 'pre' ) } };
  my $loader = Text::Nunjucks::Loader::Precompiled->new( { 'a.njk' => $obj } );
  isa_ok( $loader, 'Text::Nunjucks::Loader' );
  is_deeply( $loader->get_source('a.njk'), { src => { type => 'code', obj => $obj }, path => 'a.njk' },
    '{src: {type: code, obj}, path: name}' );
  is( $loader->get_source('b.njk'), undef, 'null for an unknown name' );

  # this.precompiled[name] is a JS property read (node: a string's character, a
  # number's nothing)
  is( Text::Nunjucks::Loader::Precompiled->new(5)->get_source('a.njk'), undef, 'a number as compiledTemplates: null' );
  is_deeply( Text::Nunjucks::Loader::Precompiled->new('abc')->get_source('0'), { src => { type => 'code', obj => 'a' }, path => '0' },
    "a string as compiledTemplates: its character, as JS reads 'abc'['0']" );
};

subtest 'PrecompiledLoader: rendering a hand-built code object' => sub {
  # What a precompiled template with one block evaluates to: root renders the
  # parent-less frame and calls b_content (compiler output, simplified).
  my $obj = {
    b_content => sub {
      my ( $env, $context, $frame, $runtime, $cb ) = @_;
      $cb->( undef, 'block:' . $context->lookup('name') );
    },
    root => sub {
      my ( $env, $context, $frame, $runtime, $cb ) = @_;
      $context->get_block('content')->( $env, $context, $frame, $runtime, sub {
        my ( $err, $out ) = @_;
        return $cb->($err) if $err;
        $cb->( undef, '[' . $out . ']' );
      } );
    },
  };
  my $env = Text::Nunjucks::Environment->new( Text::Nunjucks::Loader::Precompiled->new( { 'p.njk' => $obj } ) );
  is( $env->render( 'p.njk', { name => 'x' } ), '[block:x]', 'root and its block run' );
  is( $env->loaders->[0]->cache->{'p.njk'}, $env->get_template('p.njk'), 'no noCache: cached' );
};

#### memory -- the Environment's listeners on a loader do not keep either alive

subtest 'an Environment and its loader are freed once dropped' => sub {
  my $loader = $FS->new("$DATA/views");
  my $env    = Text::Nunjucks::Environment->new($loader);
  my ( $weak_env, $weak_loader ) = ( $env, $loader );
  weaken($weak_env);
  weaken($weak_loader);
  undef $env;
  ok( !defined $weak_env, 'the Environment, while its loader lives on' );
  undef $loader;
  ok( !defined $weak_loader, 'the loader' );

  $env = Text::Nunjucks::Environment->new;
  $weak_env = $env;
  weaken($weak_env);
  undef $env;
  ok( !defined $weak_env, 'an Environment with the default loader' );
};

done_testing;

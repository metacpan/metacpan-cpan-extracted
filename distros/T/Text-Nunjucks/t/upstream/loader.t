#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use Scalar::Util qw( blessed );
use builtin qw( is_bool );
no warnings 'experimental::builtin';
use FindBin;
use lib "$FindBin::Bin/../lib";

# Port of upstream/nunjucks/tests/loader.js (describe('loader', ...)), k37.
# One subtest per upstream it(), same title, same order, describe nesting kept.
# 11 it() upstream, 11 it() subtests here (2 + WebLoader 2 + FileSystemLoader 2
# + NodeResolveLoader 5).
#
# TODO scheme (as t/upstream/tests.t): an it() that fails today is marked TODO
# through the %TODO table, keyed by the upstream it() title; every assertion
# runs, so a TODO that starts passing shows up as "unexpectedly succeeded" and
# the entry is dropped. it()s with no Perl image at all (out of scope by
# decision) run a TODO fail() placeholder, as the k44 ones in tests.t.
#
# templatesPath: upstream 'tests/templates' is t/upstream/templates here.
#
# JS -> Perl value mapping:
#   function MyLoader() {...}  -> a plain package that is NOT a
#                                 Text::Nunjucks::Loader subclass (upstream's
#                                 point: a loader only needs getSource)
#   getSource                  -> get_source
#   FileSystemLoader           -> Text::Nunjucks::Loader::FileSystem
#   loader.noCache             -> $loader->no_cache (the Perl API is snake_case)
#   this.async = true          -> sub async { 1 }
#   setTimeout(cb, 1)          -> no image: the callback fires synchronously
#                                 (ADR 0003), so `done` is not needed

plan skip_all => 'Text::Nunjucks::Environment not available'
  unless eval { require Text::Nunjucks::Environment; 1 };

require Text::Nunjucks::Loader::FileSystem;

my $templatesPath = "$FindBin::Bin/templates";

# TODO table: upstream it() title => reason. Remove an entry when it passes.
# The two duck-typed loaders wait for a decision: upstream's _initLoaders
# writes `loader.cache = {}` onto any object, and a Perl object that is no
# Text::Nunjucks::Loader has no `cache` to write (open mapping, k94).
my %TODO = (
  'should allow a simple loader to be created' => 'k94 open mapping: Environment writes loader.cache onto a loader that is no Loader subclass (decision pending)',
  'should catch loader error'                  => 'k94 open mapping: Environment writes loader.cache onto a loader that is no Loader subclass (decision pending)',
);

# On Windows 'C:/...' is no absolute path to node's POSIX path model, so a
# FileSystemLoader over $templatesPath finds nothing there (path.win32 comes later).
my %WIN_SKIP = ( 'should emit a "load" event' => 1 );

sub it {
  my ( $title, $code ) = @_;
  subtest $title => sub {
    plan skip_all => 'POSIX path model; path.win32 comes later' if $^O eq 'MSWin32' && $WIN_SKIP{$title};
    local $TODO = $TODO{$title};
    # a die inside the body is a failed assertion, not an aborted file
    eval { $code->(); 1 } or fail( "died: " . ( $@ =~ s/\n.*//sr ) );
  };
}

sub describe { my ( $title, $code ) = @_; subtest $title => $code }

# An it() out of scope by maintainer decision: keep it, fail inside TODO.
sub out_of_scope {
  my ( $title, $what ) = @_;
  subtest $title => sub {
  TODO: {
      local $TODO = "ADR 0018: $what is out of scope";
      fail($title);
    }
  };
}

describe 'loader' => sub {

  it 'should allow a simple loader to be created' => sub {
    # From Docs: http://mozilla.github.io/nunjucks/api.html#writing-a-loader
    # We should be able to create a loader that only exposes getSource
    {

      package MyLoader;
      sub new { my $class = shift; return bless {}, $class }    # configuration
      sub get_source { return { src => 'Hello World', path => '/tmp/somewhere' } }
    }
    my $env    = Text::Nunjucks::Environment->new( MyLoader->new($templatesPath) );
    my $parent = $env->get_template('fake.njk');
    is( $parent->render, 'Hello World' );
  };

  it 'should catch loader error' => sub {
    # From Docs: http://mozilla.github.io/nunjucks/api.html#writing-a-loader
    # We should be able to create a loader that only exposes getSource
    {

      package MyAsyncLoader;
      sub new   { my $class = shift; return bless {}, $class }
      sub async { 1 }
      # setTimeout has no image (ADR 0003): the callback fires synchronously.
      sub get_source { my ( $self, $s, $cb ) = @_; $cb->( Text::Nunjucks::Lib::Error->new('test') ) }
    }
    my $env = Text::Nunjucks::Environment->new( MyAsyncLoader->new($templatesPath) );
    my $called = 0;
    $env->get_template(
      'fake.njk',
      sub {
        my ( $err, $parent ) = @_;
        $called++;
        ok( blessed($err) && $err->isa('Text::Nunjucks::Lib::Error'), 'err is an Error' );
        is( $parent, undef, 'parent is undefined' );
      }
    );
    is( $called, 1, 'callback fired (done)' );
  };

  describe 'WebLoader' => sub {

    out_of_scope 'should have default opts for WebLoader' => 'WebLoader';

    # Upstream skips this one outside a browser (this.skip() when window is
    # undefined); kept as a placeholder all the same.
    out_of_scope 'should emit a "load" event' => 'WebLoader';
  };

  describe 'FileSystemLoader' => sub {

    it 'should have default opts' => sub {
      my $loader = Text::Nunjucks::Loader::FileSystem->new($templatesPath);
      isa_ok( $loader, 'Text::Nunjucks::Loader::FileSystem' );
      # expect(loader.noCache).to.be(false): the boolean false, not just falsy
      ok( is_bool( $loader->no_cache ) && !$loader->no_cache, 'noCache is false' );
    };

    it 'should emit a "load" event' => sub {
      my $loader = Text::Nunjucks::Loader::FileSystem->new($templatesPath);
      my $fired  = 0;
      $loader->on(
        'load',
        sub {
          my ( $name, $source ) = @_;
          $fired++;
          is( $name, 'simple-base.njk' );
        }
      );
      $loader->get_source('simple-base.njk');
      is( $fired, 1, 'load event fired (done)' );
    };
  };

  describe 'NodeResolveLoader' => sub {
    out_of_scope 'should have default opts'                 => 'NodeResolveLoader';
    out_of_scope 'should emit a "load" event'               => 'NodeResolveLoader';
    out_of_scope 'should render templates'                  => 'NodeResolveLoader';
    out_of_scope 'should not allow directory traversal'     => 'NodeResolveLoader';
    out_of_scope 'should return null if no match'           => 'NodeResolveLoader';
  };
};

done_testing;

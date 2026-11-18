#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# Port of upstream/nunjucks/tests/api.js (describe('api', ...)), k38.
# One subtest per upstream it(), same title, same order.
# 6 it() upstream, 6 it() subtests here.
#
# templatesPath: upstream 'tests/templates' is t/upstream/templates here,
# read through Text::Nunjucks::Loader::FileSystem (upstream's FileSystemLoader).
#
# The three `this.skip()` guards (`typeof path === 'undefined'`) never fire
# under node, where path is required; they are not ported.
# util.normEOL: Test::Nunjucks::Util::normEOL (t/lib).

plan skip_all => 'Text::Nunjucks::Environment not available'
  unless eval { require Text::Nunjucks::Environment; 1 };

require Test::Nunjucks::Util;
Test::Nunjucks::Util->import(q(normEOL));
require Text::Nunjucks::Loader::FileSystem;
require Text::Nunjucks::Lib;

my $templatesPath = "$FindBin::Bin/templates";

# On Windows 'C:/...' is no absolute path to node's POSIX path model, so a
# FileSystemLoader over $templatesPath finds nothing there (path.win32 comes later).
my %WIN_SKIP = map { $_ => 1 } (
  'should always force compilation of parent template',
  'should handle correctly relative paths',
  'should handle correctly cache for relative paths',
  'should handle correctly relative paths in renderString',
  'should emit "load" event on Environment instance',
);

sub it {
  my ( $title, $code ) = @_;
  subtest $title => sub {
    plan skip_all => 'POSIX path model; path.win32 comes later' if $^O eq 'MSWin32' && $WIN_SKIP{$title};
    # a die inside the body is a failed assertion, not an aborted file
    eval { $code->(); 1 } or fail( "died: " . ( $@ =~ s/\n.*//sr ) );
  };
}

sub describe { my ( $title, $code ) = @_; subtest $title => $code }

sub new_env { Text::Nunjucks::Environment->new( Text::Nunjucks::Loader::FileSystem->new($templatesPath) ) }

describe 'api' => sub {

  it 'should always force compilation of parent template' => sub {
    my $env = new_env();

    my $child = $env->get_template('base-inherit.njk');
    is( $child->render, 'Foo*Bar*BazFizzle' );
  };

  it 'should only call the callback once when conditional import fails' => sub {
    my $env    = new_env();
    my $called = 0;
    $env->render( 'broken-conditional-include.njk', sub { ++$called } );
    # upstream: setTimeout(done, 0) lets a second call land before done.
    # No image (ADR 0003): callbacks fire synchronously, so by the time
    # render returns every call has happened; assert exactly one (the
    # upstream expect(++called).to.be(1) in each call).
    is( $called, 1, 'callback called exactly once' );
  };

  it 'should handle correctly relative paths' => sub {
    # upstream: this.skip() when path is undefined -- never under node
    my $env    = new_env();
    my $child1 = $env->get_template('relative/test1.njk');
    my $child2 = $env->get_template('relative/test2.njk');

    is( $child1->render, 'FooTest1BazFizzle' );
    is( $child2->render, 'FooTest2BazFizzle' );
  };

  it 'should handle correctly cache for relative paths' => sub {
    # upstream: this.skip() when path is undefined -- never under node
    my $env  = new_env();
    my $test = $env->get_template('relative/test-cache.njk');

    is( normEOL( $test->render ), "Test1\nTest2" );
  };

  it 'should handle correctly relative paths in renderString' => sub {
    # upstream: this.skip() when path is undefined -- never under node
    my $env = new_env();
    is(
      $env->render_string(
        '{% extends "./relative/test1.njk" %}{% block block1 %}Test3{% endblock %}',
        {},
        { path => Text::Nunjucks::Lib->node_path_resolve( $templatesPath, 'string.njk' ) }
      ),
      'FooTest3BazFizzle'
    );
  };

  it 'should emit "load" event on Environment instance' => sub {
    my $env   = new_env();
    my $fired = 0;
    $env->on(
      'load',
      sub {
        my ( $name, $source ) = @_;
        $fired++;
        is( $name, 'item.njk' );
      }
    );
    $env->render( 'item.njk', {} );
    # upstream's done() is only reached if the handler ran
    is( $fired, 1, 'load handler ran (done)' );
  };
};

done_testing;

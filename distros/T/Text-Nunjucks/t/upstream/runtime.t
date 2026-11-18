#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Scalar::Util qw( blessed );
use FindBin;
use lib "$FindBin::Bin/../lib";

# Port of upstream/nunjucks/tests/runtime.js ("describe('runtime', ...)").
# One subtest per upstream it(), same title, same order (k32).
#
# util.js's own render() builds a real Environment + FileSystemLoader.
# Test::Nunjucks::Util::render() (t/lib) builds a real Environment as well, but
# loads through a MemoryLoader seeded from t/upstream/templates rather than
# the FileSystemLoader (ported since k19); see that module's header comment for
# why.
#
# Every it() in this suite renders a template and inspects the callback's
# (err, res): expect(err).to.match(regex) or expect(res).to.equal(value).
# Where upstream asserts a *regex* against the error, this stays a regex --
# that is the ported upstream assertion (the hard rule's "expected value from
# the ported upstream assertion"), and it also survives the fact that our
# stub harness does not (yet) wrap the error through Template.render()'s
# err.update(path) the way env.render()/env.renderString() do -- that only
# adds a "(unknown path)\n " prefix, which the upstream regexes never pin
# either. The oracle-exact, fully-wrapped message (with that prefix) is
# instead captured in t/corpus/runtime.json for k16 to make good on later.

plan skip_all => 'Text::Nunjucks::Runtime not available'
  unless eval { require Text::Nunjucks::Runtime; 1 };
plan skip_all => 'Text::Nunjucks::Compiler not available (render harness needs it too)'
  unless eval { require Text::Nunjucks::Compiler; 1 };

require Test::Nunjucks::Util;
Test::Nunjucks::Util->import('render');

# expect(err).to.match(/regex/) -- err is a blessed error; match its message.
sub err_message {
  my ($err) = @_;
  return '' unless defined $err;
  return ( blessed($err) && $err->can('message') ) ? $err->message : "$err";
}

subtest 'runtime' => sub {

  subtest 'should report the failed function calls to symbols' => sub {
    my ( $err, $res ) = render( '{{ foo("cvan") }}', {}, { noThrow => 1 } );
    like( err_message($err), qr/Unable to call `foo`, which is undefined/,
      'error mentions the undefined symbol' );
  };

  subtest 'should report the failed function calls to lookups' => sub {
    my ( $err, $res ) = render( '{{ foo["bar"]("cvan") }}', {}, { noThrow => 1 } );
    like( err_message($err), qr/foo\["bar"\]/, 'error names the bracket lookup' );
  };

  subtest 'should report the failed function calls to calls' => sub {
    my ( $err, $res ) = render( '{{ foo.bar("second call") }}', {}, { noThrow => 1 } );
    like( err_message($err), qr/foo\["bar"\]/, 'error names the dotted lookup' );
  };

  subtest 'should report full function name in error' => sub {
    my ( $err, $res ) = render( '{{ foo.barThatIsLongerThanTen() }}', {}, { noThrow => 1 } );
    like( err_message($err), qr/foo\["barThatIsLongerThanTen"\]/,
      'error is not truncated' );
  };

  subtest 'should report the failed function calls w/multiple args' => sub {
    my ( $err1, $res1 ) = render( '{{ foo.bar("multiple", "args") }}', {}, { noThrow => 1 } );
    like( err_message($err1), qr/foo\["bar"\]/, 'dotted lookup, multiple args' );

    my ( $err2, $res2 ) = render(
      '{{ foo["bar"]["zip"]("multiple", "args") }}', {}, { noThrow => 1 } );
    like( err_message($err2), qr/foo\["bar"\]\["zip"\]/,
      'nested bracket lookup, multiple args' );
  };

  subtest 'should allow for undefined macro arguments in the last position' => sub {
    my ( $err, $res ) = render(
      '{% macro foo(bar, baz) %}' .
      '{{ bar }} {{ baz }}{% endmacro %}' .
      '{{ foo("hello", nosuchvar) }}',
      {},
      { noThrow => 1 }
    );
    is( $err, undef, 'no error' );
    ok( defined($res) && !ref($res), 'result is a string' );
  };

  subtest 'should allow for objects without a prototype macro arguments in the last position' => sub {
    # Upstream builds noProto via Object.create(null) to prove member lookup
    # on baz.qux does not assume an Object.prototype is present. Perl
    # hashrefs never have a prototype to begin with, so a plain hashref IS
    # the faithful equivalent input here -- there is nothing extra to strip.
    my $no_proto = { qux => 'world' };

    my ( $err, $res ) = render(
      '{% macro foo(bar, baz) %}' .
      '{{ bar }} {{ baz.qux }}{% endmacro %}' .
      '{{ foo("hello", noProto) }}',
      { noProto => $no_proto },
      { noThrow => 1 }
    );
    is( $err, undef, 'no error' );
    is( $res, 'hello world', 'macro read the passed-in hashref' );
  };

  subtest 'should not read variables property from Object.prototype' => sub {
    # Upstream mutates the global, shared Object.prototype
    # (Object.getPrototypeOf({}).payload = ...) and checks that Context
    # lookup on an unrelated {} still resolves it via ordinary JS property
    # access (Context.lookup does `this.ctx[name]`, and `in`/`[]` both walk
    # the prototype chain in JS). Perl hashrefs have no shared, mutable
    # prototype -- there is nothing to pollute and no `in`-operator-style
    # prototype walk to reproduce, so the scenario as coded has no Perl
    # equivalent to construct. It also needs the real Context (k16); the
    # stub Context in Test::Nunjucks::Util is a plain hash lookup with no
    # analogous chain at all. TODO once k16 lands: re-derive whatever the
    # real Context.lookup's Perl equivalent should guarantee here instead.
    TODO: {
      local $TODO = 'no Perl equivalent to a shared/mutable Object.prototype; '
        . 'also needs the real Context from k16 -- see comment above';
      ok( 0, 'should not read variables property from Object.prototype' );
    }
  };

};

done_testing;

#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use Scalar::Util qw( blessed );
use FindBin;
use lib "$FindBin::Bin/../lib";

# Port of upstream/nunjucks/tests/tests.js (describe('tests', ...)), k35.
# One subtest per upstream it(), same title, same order. 28 it() upstream,
# 28 it() subtests here.
#
# TODO scheme (as t/upstream/filters.t, k34): an it() that fails today is
# marked TODO through the %TODO table, keyed by the upstream it() title; every
# assertion runs, so a TODO that starts passing shows up as "unexpectedly
# succeeded" and the entry is dropped. Nested TODO blocks inside an it() mark
# single assertions that wait on something other than the port, with the
# blocker named in the reason (Map/Set/generator values: k44).
#
# util.js notes: as in filters.t, a local non-dying equal() (render with
# noThrow, then is()) replaces Test::Nunjucks::Util::equal; finish(done) is
# never ported.
#
# JS -> Perl value mapping:
#   null (context)  -> Text::Nunjucks::Runtime->None         (ADR 0006)
#   function(){..}  -> sub { ... }
#   {}              -> {}   (same reference for the sameas test)
#   new Map()/Set()/generator -> no Perl image: nested TODO + fail() (k44)

plan skip_all => 'Text::Nunjucks::Environment not available'
  unless eval { require Text::Nunjucks::Environment; 1 };

require Test::Nunjucks::Util;
Test::Nunjucks::Util->import('render');
require Text::Nunjucks::Runtime;

sub err_message {
  my ($err) = @_;
  return '' unless defined $err;
  return ( blessed($err) && $err->can('message') ) ? $err->message : "$err";
}

sub equal {
  my ( $template, @rest ) = @_;
  my ( $ctx, $opts, $expected );
  if    ( @rest == 1 ) { ($expected)                = @rest }
  elsif ( @rest == 2 ) { ( $ctx, $expected )        = @rest }
  elsif ( @rest == 3 ) { ( $ctx, $opts, $expected ) = @rest }
  else                 { die 'equal: wrong number of arguments' }
  my ( $err, $res ) = render( $template, $ctx, { %{ $opts // {} }, noThrow => 1 } );
  diag( 'render error: ' . err_message($err) ) if $err;
  return is( $res, $expected, $template =~ s/\n/\\n/gr );
}

# render() that never dies: the output, undef on error (expect(render(..)))
sub rendered {
  my ( $template, $ctx ) = @_;
  my ( $err, $res ) = render( $template, $ctx, { noThrow => 1 } );
  diag( 'render error: ' . err_message($err) ) if $err;
  return $res;
}

# TODO table: upstream it() title => reason. Remove an entry when it passes.
my %TODO;

sub it {
  my ( $title, $code ) = @_;
  subtest $title => sub {
    local $TODO = $TODO{$title};
    $code->();
  };
}

sub describe { my ( $title, $code ) = @_; subtest $title => $code }

sub none { Text::Nunjucks::Runtime->None }

describe 'tests' => sub {

  it 'callable should detect callability' => sub {
    my $callable = rendered( '{{ foo is callable }}', { foo => sub { '!!!' } } );
    my $uncallable = rendered( '{{ foo is not callable }}', { foo => '!!!' } );
    is( $callable,   'true' );
    is( $uncallable, 'true' );
  };

  it 'defined should detect definedness' => sub {
    is( rendered('{{ foo is defined }}'),     'false' );
    is( rendered('{{ foo is not defined }}'), 'true' );
    is( rendered( '{{ foo is defined }}',     { foo => none() } ), 'true' );
    is( rendered( '{{ foo is not defined }}', { foo => none() } ), 'false' );
  };

  it 'should support "is defined" in {% if %} expressions' => sub {
    is( rendered( '{% if foo is defined %}defined{% else %}undefined{% endif %}', {} ),
      'undefined' );
    is( rendered( '{% if foo is defined %}defined{% else %}undefined{% endif %}', { foo => none() } ),
      'defined' );
  };

  it 'should support "is not defined" in {% if %} expressions' => sub {
    is( rendered( '{% if foo is not defined %}undefined{% else %}defined{% endif %}', {} ),
      'undefined' );
    is( rendered( '{% if foo is not defined %}undefined{% else %}defined{% endif %}', { foo => none() } ),
      'defined' );
  };

  it 'undefined should detect undefinedness' => sub {
    is( rendered('{{ foo is undefined }}'),     'true' );
    is( rendered('{{ foo is not undefined }}'), 'false' );
    is( rendered( '{{ foo is undefined }}',     { foo => none() } ), 'false' );
    is( rendered( '{{ foo is not undefined }}', { foo => none() } ), 'true' );
  };

  it 'none/null should detect strictly null values' => sub {

    # required a change in lexer.js @ 220
    is( rendered('{{ null is null }}'),  'true' );
    is( rendered('{{ none is none }}'),  'true' );
    is( rendered('{{ none is null }}'),  'true' );
    is( rendered('{{ foo is null }}'),   'false' );
    is( rendered( '{{ foo is not null }}', { foo => none() } ), 'false' );
  };

  it 'divisibleby should detect divisibility' => sub {
    my $divisible    = rendered('{{ "6" is divisibleby(3) }}');
    my $notDivisible = rendered('{{ 3 is not divisibleby(2) }}');
    is( $divisible,    'true' );
    is( $notDivisible, 'true' );
  };

  it 'escaped should test whether or not something is escaped' => sub {
    my $escaped    = rendered( '{{ (foo | safe) is escaped }}', { foo => 'foobarbaz' } );
    my $notEscaped = rendered( '{{ foo is escaped }}',          { foo => 'foobarbaz' } );
    is( $escaped,    'true' );
    is( $notEscaped, 'false' );
  };

  it 'even should detect whether or not a number is even' => sub {
    my $fiveEven    = rendered('{{ "5" is even }}');
    my $fourNotEven = rendered('{{ 4 is not even }}');
    is( $fiveEven,    'false' );
    is( $fourNotEven, 'false' );
  };

  it 'odd should detect whether or not a number is odd' => sub {
    my $fiveOdd    = rendered('{{ "5" is odd }}');
    my $fourNotOdd = rendered('{{ 4 is not odd }}');
    is( $fiveOdd,    'true' );
    is( $fourNotOdd, 'true' );
  };

  it 'mapping should detect Maps or hashes' => sub {
    # upstream order: render map1 (Map), render map2 ({}), expect one, expect two
    my $mapTwoIsMapping = rendered( '{{ map is mapping }}', { map => {} } );
  TODO: {
      local $TODO = 'JS Map (new Map()) has no Perl image (k44)';
      fail('{{ map is mapping }} with new Map()');
    }
    is( $mapTwoIsMapping, 'true' );
  };

  it 'falsy should detect whether or not a value is falsy' => sub {
    my $zero     = rendered('{{ 0 is falsy }}');
    my $pancakes = rendered('{{ "pancakes" is not falsy }}');
    is( $zero,     'true' );
    is( $pancakes, 'true' );
  };

  it 'truthy should detect whether or not a value is truthy' => sub {
    my $nullTruthy        = rendered('{{ null is truthy }}');
    my $pancakesNotTruthy = rendered('{{ "pancakes" is not truthy }}');
    is( $nullTruthy,        'false' );
    is( $pancakesNotTruthy, 'false' );
  };

  it 'greaterthan than should detect whether or not a value is less than another' => sub {
    my $fiveGreaterThanFour     = rendered('{{ "5" is greaterthan(4) }}');
    my $fourNotGreaterThanTwo   = rendered('{{ 4 is not greaterthan(2) }}');
    is( $fiveGreaterThanFour,   'true' );
    is( $fourNotGreaterThanTwo, 'false' );
  };

  it 'ge should detect whether or not a value is greater than or equal to another' => sub {
    my $fiveGreaterThanEqualToFive      = rendered('{{ "5" is ge(5) }}');
    my $fourNotGreaterThanEqualToTwo    = rendered('{{ 4 is not ge(2) }}');
    is( $fiveGreaterThanEqualToFive,   'true' );
    is( $fourNotGreaterThanEqualToTwo, 'false' );
  };

  it 'lessthan than should detect whether or not a value is less than another' => sub {
    my $fiveLessThanFour   = rendered('{{ "5" is lessthan(4) }}');
    my $fourNotLessThanTwo = rendered('{{ 4 is not lessthan(2) }}');
    is( $fiveLessThanFour,   'false' );
    is( $fourNotLessThanTwo, 'true' );
  };

  it 'le should detect whether or not a value is less than or equal to another' => sub {
    my $fiveLessThanEqualToFive   = rendered('{{ "5" is le(5) }}');
    my $fourNotLessThanEqualToTwo = rendered('{{ 4 is not le(2) }}');
    is( $fiveLessThanEqualToFive,   'true' );
    is( $fourNotLessThanEqualToTwo, 'true' );
  };

  it 'ne should detect whether or not a value is not equal to another' => sub {
    my $five = rendered('{{ 5 is ne(5) }}');
    my $four = rendered('{{ 4 is not ne(2) }}');
    is( $five, 'false' );
    is( $four, 'false' );
  };

  it 'iterable should detect that a generator is iterable' => sub {
  TODO: {
      local $TODO = 'JS generator object has no Perl image (k44)';
      fail('{{ fn is iterable }} with a generator');
    }
  };

  it 'iterable should detect that an Array is not non-iterable' => sub {
    equal( '{{ arr is not iterable }}', { arr => [] }, 'false' );
  };

  it 'iterable should detect that a Map is iterable' => sub {
  TODO: {
      local $TODO = 'JS Map (new Map()) has no Perl image (k44)';
      fail('{{ map is iterable }} with new Map()');
    }
  };

  it 'iterable should detect that a Set is not non-iterable' => sub {
  TODO: {
      local $TODO = 'JS Set (new Set()) has no Perl image (k44)';
      fail('{{ set is not iterable }} with new Set()');
    }
  };

  it 'number should detect whether a value is numeric' => sub {
    my $num = rendered('{{ 5 is number }}');
    my $str = rendered('{{ "42" is number }}');
    is( $num, 'true' );
    is( $str, 'false' );
  };

  it 'string should detect whether a value is a string' => sub {
    my $num = rendered('{{ 5 is string }}');
    my $str = rendered('{{ "42" is string }}');
    is( $num, 'false' );
    is( $str, 'true' );
  };

  it 'equalto should detect value equality' => sub {
    my $same    = rendered('{{ 1 is equalto(2) }}');
    my $notSame = rendered('{{ 2 is not equalto(2) }}');
    is( $same,    'false' );
    is( $notSame, 'false' );
  };

  it 'sameas should alias to equalto' => sub {
    my $obj  = {};
    my $same = rendered( '{{ obj1 is sameas(obj2) }}', { obj1 => $obj, obj2 => $obj } );
    is( $same, 'true' );
  };

  it 'lower should detect whether or not a string is lowercased' => sub {
    is( rendered('{{ "foobar" is lower }}'), 'true' );
    is( rendered('{{ "Foobar" is lower }}'), 'false' );
  };

  it 'upper should detect whether or not a string is uppercased' => sub {
    is( rendered('{{ "FOOBAR" is upper }}'), 'true' );
    is( rendered('{{ "Foobar" is upper }}'), 'false' );
  };
};

done_testing;

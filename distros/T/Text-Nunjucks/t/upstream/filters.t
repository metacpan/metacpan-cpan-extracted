#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use Scalar::Util qw( blessed );
use builtin qw( true false );
use Hash::Ordered;
use FindBin;
use lib "$FindBin::Bin/../lib";

no warnings 'experimental::builtin';

# Port of upstream/nunjucks/tests/filters.js (describe('filter', ...)).
# One subtest per upstream it(), same title, same order, describe nesting kept
# (k34). 64 it() upstream (48 directly under describe('filter') plus the 16 in
# describe('the length filter')), 64 it() subtests here.
#
# TODO scheme (k34): each it() was marked TODO through the %TODO table below,
# keyed by the upstream it() title, until its filter landed (k17); every filter
# has, so the table is empty. Every assertion runs; a TODO that starts passing
# shows up as "unexpectedly succeeded" -- drop it then. Nested TODO blocks
# inside an it() are NOT in %TODO: they mark individual assertions that wait on
# something other than a filter and stay until that blocker (named in the
# reason) is decided/fixed. The four length
# it()s with no Perl image (new String, array with properties, Map, Set) are
# such nested TODO blocks with fail(), as in t/upstream/compiler.t (k44).
#
# util.js notes. equal()/render() come from Test::Nunjucks::Util (t/lib);
# finish(done) is mocha async plumbing and is never ported (see that module).
# The shared equal() croaks on a render error, and a die inside a subtest aborts
# the whole file, so this file defines a local non-dying equal() with the same
# argument convention (render with noThrow, then is()); an error is diag'd.
#
# JS -> Perl value mapping used here:
#   r.markSafe(s)      -> Text::Nunjucks::Runtime->mark_safe(s)
#   null (context)     -> Text::Nunjucks::Runtime->None            (ADR 0006)
#   true / false       -> builtin::true / builtin::false           (ADR 0001)
#   {a:1, ...} whose iteration order the test observes
#                      -> Hash::Ordered (insertion order)          (ADR 0011)
#   [0,,2] sparse      -> [0, undef, 2]
#   lib.repeat(' ', n) -> ' ' x n
# Values with no Perl image are TODO'd where they occur, citing open decision
# k44: JS wrapper objects (new String), Map/Set, arrays with extra properties,
# objects with a custom toString.

plan skip_all => 'Text::Nunjucks::Environment not available'
  unless eval { require Text::Nunjucks::Environment; 1 };

require Test::Nunjucks::Util;
Test::Nunjucks::Util->import('render');
require Text::Nunjucks::Runtime;

sub none      { Text::Nunjucks::Runtime->None }
sub mark_safe { Text::Nunjucks::Runtime->mark_safe( $_[0] ) }

sub err_message {
  my ($err) = @_;
  return '' unless defined $err;
  return ( blessed($err) && $err->can('message') ) ? $err->message : "$err";
}

# equal(str, [ctx, [opts,]] expected) -- arity dispatch as in Util::equal, but
# never dies.
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

# TODO table: upstream it() title => reason. Remove an entry when it passes.
# Empty since k17 job 5: every filter it() passes.
my %TODO;

# it(title, sub) -- one subtest, TODO'd from %TODO.
sub it {
  my ( $title, $code ) = @_;
  subtest $title => sub {
    local $TODO = $TODO{$title};
    $code->();
  };
}

sub describe { my ( $title, $code ) = @_; subtest $title => $code }

describe 'filter' => sub {

  it 'abs' => sub {
    equal( '{{ -3|abs }}',     '3' );
    equal( '{{ -3.456|abs }}', '3.456' );
  };

  it 'batch' => sub {
    equal(
      join( '',
        '{% for a in [1,2,3,4,5,6]|batch(2) %}',
        '-{% for b in a %}',
        '{{ b }}',
        '{% endfor %}-',
        '{% endfor %}' ),
      '-12--34--56-'
    );
  };

  it 'capitalize' => sub {
    equal( '{{ "foo" | capitalize }}', 'Foo' );
    equal( '{{ str | capitalize }}', { str => mark_safe('foo') }, 'Foo' );
    equal( '{{ undefined | capitalize }}', '' );
    equal( '{{ null | capitalize }}',      '' );
    equal( '{{ nothing | capitalize }}',   '' );
  };

  it 'center' => sub {
    equal( '{{ "fooo" | center }}', ( ' ' x 38 ) . 'fooo' . ( ' ' x 38 ) );

    equal( '{{ str | center }}', { str => mark_safe('fooo') },
      ( ' ' x 38 ) . 'fooo' . ( ' ' x 38 ) );

    equal( '{{ undefined | center }}', ( ' ' x 40 ) . '' . ( ' ' x 40 ) );

    equal( '{{ null | center }}', ( ' ' x 40 ) . '' . ( ' ' x 40 ) );

    equal( '{{ nothing | center }}', ( ' ' x 40 ) . '' . ( ' ' x 40 ) );

    equal( '{{ "foo" | center }}', ( ' ' x 38 ) . 'foo' . ( ' ' x 39 ) );
  };

  it 'default' => sub {
    equal( '{{ undefined | default("foo") }}', 'foo' );
    equal( '{{ bar | default("foo") }}', { bar => none() }, '' );
    equal( '{{ false | default("foo") }}',       'false' );
    equal( '{{ false | default("foo", true) }}', 'foo' );
    equal( '{{ bar | default("foo") }}',         'foo' );
    equal( '{{ "bar" | default("foo") }}',       'bar' );
  };

  it 'dump' => sub {
    equal( "{{ ['a', 1, {b: true}] | dump  }}",
      '[&quot;a&quot;,1,{&quot;b&quot;:true}]' );
    equal( "{{ ['a', 1, {b: true}] | dump(2) }}",
      "[\n  &quot;a&quot;,\n  1,\n  {\n    &quot;b&quot;: true\n  }\n]" );
    equal( "{{ ['a', 1, {b: true}] | dump(4) }}",
      "[\n    &quot;a&quot;,\n    1,\n    {\n        &quot;b&quot;: true\n    }\n]" );
    equal( "{{ ['a', 1, {b: true}] | dump('\t') }}",
      "[\n\t&quot;a&quot;,\n\t1,\n\t{\n\t\t&quot;b&quot;: true\n\t}\n]" );
  };

  it 'escape' => sub {
    equal( '{{ "<html>\\\\" | escape }}', {}, { autoescape => false },
      '&lt;html&gt;&#92;' );
  };

  it 'escape skip safe' => sub {
    equal( '{{ "<html>" | safe | escape }}', {}, { autoescape => false }, '<html>' );
  };

  it 'should not double escape strings' => sub {
    equal( '{{ "<html>" | escape | escape }}', {}, { autoescape => false },
      '&lt;html&gt;' );
  };

  it 'should not double escape with autoescape on' => sub {
    equal( '{% set val = "<html>" | escape %}{{ val }}', {}, { autoescape => true },
      '&lt;html&gt;' );
  };

  it 'should work with non-string values' => sub {
    equal( '{{ foo | escape }}', { foo => ['<html>'] }, { autoescape => false },
      '&lt;html&gt;' );

    # JS: { foo: { toString: function() { return '<html>'; } } }. The mapping is
    # open (k44); an overloaded-"" object is only a placeholder pending that
    # decision, TODO'd until then.
    {
      package Test::Filters::ToStringObj;
      use overload '""' => sub { '<html>' }, fallback => 1;
      sub new { bless {}, shift }
    }
    TODO: {
      local $TODO = 'JS object with custom toString: placeholder overload object, mapping pending k44';
      equal( '{{ foo | escape }}', { foo => Test::Filters::ToStringObj->new },
        { autoescape => false }, '&lt;html&gt;' );
    }

    equal( '{{ foo | escape }}', { foo => none() }, { autoescape => false }, '' );
  };

  it 'should not escape safe strings with autoescape on' => sub {
    equal( '{{ "<html>" | safe | escape }}', {}, { autoescape => true }, '<html>' );

    equal( '{% set val = "<html>" | safe | e %}{{ val }}', {}, { autoescape => true },
      '<html>' );
  };

  it 'should keep strings escaped after they have been escaped' => sub {
    equal( '{% set val = "<html>" | e | safe %}{{ val }}', {}, { autoescape => false },
      '&lt;html&gt;' );
  };

  it 'dictsort' => sub {
    # no params - should be case insensitive, by key
    equal(
      '{% for item in items | dictsort %}' . '{{ item[0] }}{% endfor %}',
      { items => Hash::Ordered->new( e => 1, d => 2, c => 3, a => 4, f => 5, b => 6 ) },
      'abcdef'
    );

    # case sensitive = true
    equal(
      '{% for item in items | dictsort(true) %}{{ item[0] }},{% endfor %}',
      { items => Hash::Ordered->new( ABC => 6, ABc => 5, Abc => 1, abc => 2 ) },
      'ABC,ABc,Abc,abc,'
    );

    # use values for sort
    equal(
      '{% for item in items | dictsort(false, "value") %}{{ item[0] }}{% endfor %}',
      { items => Hash::Ordered->new( a => 6, b => 5, c => 1, d => 2 ) },
      'cdba'
    );
  };

  it 'first' => sub {
    equal( '{{ [1,2,3] | first }}', '1' );
  };

  it 'float' => sub {
    equal( '{{ "3.5" | float }}', '3.5' );
    equal( '{{ "0" | float }}',   '0' );
  };

  it 'forceescape' => sub {
    equal( '{{ str | forceescape }}', { str => mark_safe('<html>') }, '&lt;html&gt;' );
    equal( '{{ "<html>" | safe | forceescape }}', '&lt;html&gt;' );
  };

  it 'int' => sub {
    equal( '{{ "3.5" | int }}',            '3' );
    equal( '{{ "0" | int }}',              '0' );
    equal( '{{ "foobar" | int("42") }}',   '42' );
    equal( '{{ "0x4d32" | int(base=16) }}', '19762' );
    equal( '{{ "011" | int(base=8) }}',    '9' );
  };

  it 'int (default value)' => sub {
    equal( '{{ "bob" | int("cat") }}', 'cat' );
  };

  it 'float (default value)' => sub {
    equal( '{{ "bob" | float("cat") }}', 'cat' );
  };

  it 'groupby' => sub {
    my $names_context = {
      items => [
        { name => 'james',  type => 'green' },
        { name => 'john',   type => 'blue' },
        { name => 'jim',    type => 'blue' },
        { name => 'jessie', type => 'green' },
      ]
    };
    equal(
      '{% for type, items in items | groupby("type") %}'
        . ':{{ type }}:'
        . '{% for item in items %}'
        . '{{ item.name }}'
        . '{% endfor %}'
        . '{% endfor %}',
      $names_context,
      ':green:jamesjessie:blue:johnjim'
    );

    equal(
      '{% for type, items in items | groupby("type") %}'
        . ':{{ type }}:'
        . '{% for item in items %}'
        . '{{ item.name }}'
        . '{% endfor %}'
        . '{% endfor %}',
      {
        items => [
          { name => 'james',  type  => 'green' },
          { name => 'john',   type  => 'blue' },
          { name => 'jim',    type  => 'blue' },
          { name => 'jessie', color => 'green' },
        ]
      },
      ':green:james:blue:johnjim:undefined:jessie'
    );

    # The next two expect JS's integer-key ordering of the engine-built result
    # object (2018 before 2019 although 2019 is inserted first; 'undefined'
    # after the integer keys). ADR 0011 makes engine-built objects 1:1 with JS
    # (k51: Lib keys, Lib group_by's ordered result).
    equal(
      '{% for year, posts in posts | groupby("date.year") %}'
        . ':{{ year }}:'
        . '{% for post in posts %}'
        . '{{ post.title }}'
        . '{% endfor %}'
        . '{% endfor %}',
      {
        posts => [
          { date => { year => 2019 }, title => 'Post 1' },
          { date => { year => 2018 }, title => 'Post 2' },
          { date => { year => 2019 }, title => 'Post 3' },
        ]
      },
      ':2018:Post 2:2019:Post 1Post 3'
    );

    equal(
      '{% for year, posts in posts | groupby("date.year") %}'
        . ':{{ year }}:'
        . '{% for post in posts %}'
        . '{{ post.title }}'
        . '{% endfor %}'
        . '{% endfor %}',
      {
        posts => [
          { date => { year => 2019 }, title => 'Post 1' },
          { date => { year => 2018 }, title => 'Post 2' },
          { meta => { month => 2 },   title => 'Post 3' },
        ]
      },
      ':2018:Post 2:2019:Post 1:undefined:Post 3'
    );

    equal(
      '{% for type, items in items | groupby({}) %}'
        . ':{{ type }}:'
        . '{% for item in items %}'
        . '{{ item.name }}'
        . '{% endfor %}'
        . '{% endfor %}',
      $names_context,
      ':undefined:jamesjohnjimjessie'
    );

    my $undefined_template =
        '{% for type, items in items | groupby("a.b.c") %}'
      . ':{{ type }}:'
      . '{% for item in items %}'
      . '{{ item.name }}'
      . '{% endfor %}'
      . '{% endfor %}';
    equal( $undefined_template, $names_context, ':undefined:jamesjohnjimjessie' );

    my ($err) = render( $undefined_template, $names_context,
      { throwOnUndefined => true, noThrow => 1 } );
    like( err_message($err), qr/groupby: attribute "a\.b\.c" resolved to undefined/,
      'groupby throws on undefined attribute with throwOnUndefined' );
  };

  it 'indent' => sub {
    equal( "{{ \"one\ntwo\nthree\" | indent }}",       "one\n    two\n    three" );
    equal( "{{ \"one\ntwo\nthree\" | indent(2) }}",    "one\n  two\n  three" );
    equal( "{{ \"one\ntwo\nthree\" | indent(2, true) }}", "  one\n  two\n  three" );

    equal( '{{ str | indent }}', { str => mark_safe("one\ntwo\nthree") },
      "one\n    two\n    three" );
    equal( '{{ "" | indent }}',                 '' );
    equal( '{{ undefined | indent }}',          '' );
    equal( '{{ undefined | indent(2) }}',       '' );
    equal( '{{ undefined | indent(2, true) }}', '' );

    equal( '{{ null | indent }}',          '' );
    equal( '{{ null | indent(2) }}',       '' );
    equal( '{{ null | indent(2, true) }}', '' );

    equal( '{{ nothing | indent }}',          '' );
    equal( '{{ nothing | indent(2) }}',       '' );
    equal( '{{ nothing | indent(2, true) }}', '' );
  };

  it 'join' => sub {
    equal( '{{ items | join }}', { items => [ 1, 2, 3 ] }, '123' );

    equal( '{{ items | join(",") }}', { items => [ 'foo', 'bar', 'bear' ] },
      'foo,bar,bear' );

    equal(
      '{{ items | join(",", "name") }}',
      { items => [ { name => 'foo' }, { name => 'bar' }, { name => 'bear' } ] },
      'foo,bar,bear'
    );
  };

  it 'last' => sub {
    equal( '{{ [1,2,3] | last }}', '3' );
  };

  describe 'the length filter' => sub {
    it 'should return length of a list literal' => sub {
      equal( '{{ [1,2,3] | length }}', '3' );
    };
    it 'should output 0 for a missing context variable' => sub {
      equal( '{{ blah|length }}', '0' );
    };
    it 'should output string length for string variables' => sub {
      equal( '{{ str | length }}', { str => 'blah' }, '4' );
    };
    it 'should output string length for a SafeString variable' => sub {
      equal( '{{ str | length }}', { str => mark_safe('<blah>') }, '6' );
    };
    it 'should output the correct length of a string created with new String()' => sub {
      # JS: new String('blah') -- a String wrapper object. No ADR maps JS
      # wrapper objects; there is no Perl value to hand in that is not just a
      # plain string (which would pass for the wrong reason).
      TODO: {
        local $TODO = 'JS String wrapper object (new String) (k44)';
        fail('JS String wrapper object (new String)');
      }
    };
    it 'should output 0 for a literal "undefined"' => sub {
      equal( '{{ undefined | length }}', '0' );
    };
    it 'should output 0 for a literal "null"' => sub {
      equal( '{{ null | length }}', '0' );
    };
    it 'should output 0 for an Object with no properties' => sub {
      equal( '{{ obj | length }}', { obj => {} }, '0' );
    };
    it 'should output 1 for an Object with 1 property' => sub {
      equal( '{{ obj | length }}', { obj => { key => 'value' } }, '1' );
    };
    it 'should output the number of properties for a plain Object, not the value of its length property' => sub {
      equal( '{{ obj | length }}', { obj => { key => 'value', length => 5 } }, '2' );
    };
    it 'should output the length of an array' => sub {
      equal( '{{ arr | length }}', { arr => [ 0, 1 ] }, '2' );
    };
    it 'should output the full length of a sparse array' => sub {
      equal( '{{ arr | length }}', { arr => [ 0, undef, 2 ] }, '3' );
    };
    it 'should output the length of an array created with "new Array"' => sub {
      equal( '{{ arr | length }}', { arr => [ 0, 1 ] }, '2' );
    };
    it 'should output the length of an array created with "new Array" with user-defined properties' => sub {
      # JS: arr.key = 'value' on an array. A Perl array cannot carry extra
      # properties; no ADR maps it.
      TODO: {
        local $TODO = 'JS array with user-defined properties (k44)';
        fail('JS array with user-defined properties');
      }
    };
    it 'should output the length of a Map' => sub {
      TODO: {
        local $TODO = 'JS Map (k44)';
        fail('JS Map');
      }
    };
    it 'should output the length of a Set' => sub {
      TODO: {
        local $TODO = 'JS Set (k44)';
        fail('JS Set');
      }
    };
  };

  it 'list' => sub {
    my $person = Hash::Ordered->new( name => 'Joe', age => 83 );    # ADR 0011: JS insertion order
    equal( '{% for i in "foobar" | list %}{{ i }},{% endfor %}', 'f,o,o,b,a,r,' );
    equal(
      '{% for pair in person | list %}{{ pair.key }}: {{ pair.value }} - {% endfor %}',
      { person => $person },
      'name: Joe - age: 83 - '
    );
    equal( '{% for i in [1, 2] | list %}{{ i }}{% endfor %}', '12' );
  };

  it 'lower' => sub {
    equal( '{{ "fOObAr" | lower }}', 'foobar' );
    equal( '{{ str | lower }}', { str => mark_safe('fOObAr') }, 'foobar' );
    equal( '{{ null | lower }}',      '' );
    equal( '{{ undefined | lower }}', '' );
    equal( '{{ nothing | lower }}',   '' );
  };

  it 'nl2br' => sub {
    equal( '{{ null | nl2br }}',      '' );
    equal( '{{ undefined | nl2br }}', '' );
    equal( '{{ nothing | nl2br }}',   '' );
    equal( '{{ str | nl2br }}', { str => mark_safe("foo\r\nbar") },   "foo<br />\nbar" );
    equal( '{{ str | nl2br }}', { str => mark_safe("foo\nbar") },     "foo<br />\nbar" );
    equal( '{{ str | nl2br }}', { str => mark_safe("foo\n\nbar") },   "foo<br />\n<br />\nbar" );
    equal( "{{ \"foo\nbar\" | nl2br }}", "foo&lt;br /&gt;\nbar" );
  };

  it 'random' => sub {
    for my $i ( 0 .. 99 ) {
      my ( $err, $res ) = render( '{{ [1,2,3,4,5,6,7,8,9] | random }}', undef, { noThrow => 1 } );
      my $val = defined $res ? ( $res =~ /^\s*(-?\d+)/ ? $1 : undef ) : undef;
      ok( defined $val && $val >= 1 && $val <= 9, "random #$i within 1..9" )
        or diag( 'got: ' . ( $res // err_message($err) ) );
    }
  };

  it 'reject' => sub {
    my $context = { numbers => [ 0, 1, 2, 3, 4, 5 ] };

    equal( '{{ numbers | reject("odd") | join }}',            $context, '024' );
    equal( '{{ numbers | reject("even") | join }}',           $context, '135' );
    equal( '{{ numbers | reject("divisibleby", 3) | join }}', $context, '1245' );
    equal( '{{ numbers | reject() | join }}',                 $context, '0' );
  };

  it 'rejectattr' => sub {
    my $foods = [ { tasty => true }, { tasty => false }, { tasty => true } ];
    equal( '{{ foods | rejectattr("tasty") | length }}', { foods => $foods }, '1' );
  };

  it 'select' => sub {
    my $context = { numbers => [ 0, 1, 2, 3, 4, 5 ] };

    equal( '{{ numbers | select("odd") | join }}',            $context, '135' );
    equal( '{{ numbers | select("even") | join }}',           $context, '024' );
    equal( '{{ numbers | select("divisibleby", 3) | join }}', $context, '03' );
    equal( '{{ numbers | select() | join }}',                 $context, '12345' );
  };

  it 'selectattr' => sub {
    my $foods = [ { tasty => true }, { tasty => false }, { tasty => true } ];
    equal( '{{ foods | selectattr("tasty") | length }}', { foods => $foods }, '2' );
  };

  it 'replace' => sub {
    equal( '{{ 123456 | replace("4", ".") }}',    '123.56' );
    equal( '{{ 123456 | replace("4", ".") }}',    '123.56' );
    equal( '{{ 12345.6 | replace("4", ".") }}',   '123.5.6' );
    equal( '{{ 12345.6 | replace(4, ".") }}',     '123.5.6' );
    equal( '{{ 12345.6 | replace("4", "7") }}',   '12375.6' );
    equal( '{{ 12345.6 | replace(4, 7) }}',       '12375.6' );
    equal( '{{ 123450.6 | replace(0, 7) }}',      '123457.6' );
    equal( '{{ "aaabbbccc" | replace("", ".") }}', '.a.a.a.b.b.b.c.c.c.' );
    equal( '{{ "aaabbbccc" | replace(null, ".") }}',      'aaabbbccc' );
    equal( '{{ "aaabbbccc" | replace(undefined, ".") }}', 'aaabbbccc' );
    equal( '{{ "aaabbbccc" | replace({}, ".") }}',        'aaabbbccc' );
    equal( '{{ "aaabbbccc" | replace(true, ".") }}',      'aaabbbccc' );
    equal( '{{ "aaabbbccc" | replace(false, ".") }}',     'aaabbbccc' );
    equal( '{{ "aaabbbccc" | replace(["wrong"], ".") }}', 'aaabbbccc' );
    equal( '{{ "aaabbbccc" | replace("a", "x") }}',       'xxxbbbccc' );
    equal( '{{ "aaabbbccc" | replace("a", "x", 2) }}',    'xxabbbccc' );
    equal( '{{ "aaabbbbbccc" | replace("b", "y", 4) }}',   'aaayyyybccc' );
    equal( '{{ "aaabbbbbccc" | replace("", "") }}',       'aaabbbbbccc' );
    equal( '{{ "aaabbbbbccc" | replace("b", "") }}',      'aaaccc' );
    equal( '{{ "aaabbbbbccc" | replace("b", "", 4) }}',   'aaabccc' );
    equal( '{{ "aaabbbbbccc" | replace("ab", "y", 4) }}', 'aaybbbbccc' );
    equal( '{{ "aaabbbbbccc" | replace("b", "y", 4) }}',  'aaayyyybccc' );
    equal( '{{ "aaabbbbbccc" | replace("d", "y", 4) }}',  'aaabbbbbccc' );
    equal( '{{ "aaabbcccbbb" | replace("b", "y", 4) }}',  'aaayycccyyb' );

    # Bad initial inputs
    equal( '{{ undefined | replace("b", "y", 4) }}', '' );
    equal( '{{ null | replace("b", "y", 4) }}',      '' );
    equal( '{{ {} | replace("b", "y", 4) }}', '[object Object]' )
      ;    # End up with the object passed out of replace, then toString called on it
    equal( '{{ [] | replace("b", "y", 4) }}',                 '' );
    equal( '{{ true | replace("rue", "afafasf", 4) }}',       'true' );
    equal( '{{ false | replace("rue", "afafasf", 4) }}',      'false' );

    # Will result in an infinite loop if unbounded otherwise test will pass
    equal( '{{ "<img src=" | replace("<img", "<img alt=val") | safe }}',
      '<img alt=val src=' );
    equal(
      '{{ "<img src=\\"http://www.example.com\\" />" | replace("<img", "replacement text") | safe }}',
      'replacement text src="http://www.example.com" />'
    );

    # Regex
    equal( '{{ "aabbbb" | replace(r/ab{2}/, "z") }}', 'azbb' );
    equal( '{{ "aaaAAA" | replace(r/a/i, "z") }}',    'zaaAAA' );
    equal( '{{ "aaaAAA" | replace(r/a/g, "z") }}',    'zzzAAA' );
    equal( '{{ "aaaAAA" | replace(r/a/gi, "z") }}',   'zzzzzz' );
    equal( '{{ str | replace("a", "x") }}', { str => mark_safe('aaabbbccc') }, 'xxxbbbccc' );
  };

  it 'reverse' => sub {
    equal( '{{ "abcdef" | reverse }}', 'fedcba' );
    equal( '{% for i in [1, 2, 3, 4] | reverse %}{{ i }}{% endfor %}', '4321' );
  };

  it 'round' => sub {
    equal( '{{ 4.5 | round }}',             '5' );
    equal( '{{ 4.5 | round(0, "floor") }}', '4' );
    equal( '{{ 4.12345 | round(4) }}',      '4.1235' );
    equal( '{{ 4.12344 | round(4) }}',      '4.1234' );
  };

  it 'slice' => sub {
    my $tmpl =
        '{% for items in arr | slice(3) %}'
      . '--'
      . '{% for item in items %}'
      . '{{ item }}'
      . '{% endfor %}'
      . '--'
      . '{% endfor %}';

    equal( $tmpl, { arr => [ 1, 2, 3, 4, 5, 6, 7, 8, 9 ] }, '--123----456----789--' );
    equal( $tmpl, { arr => [ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10 ] }, '--1234----567----8910--' );
  };

  it 'sum' => sub {
    equal( '{{ items | sum }}', { items => [ 1, 2, 3 ] }, '6' );

    equal( '{{ items | sum("value") }}',
      { items => [ { value => 1 }, { value => 2 }, { value => 3 } ] }, '6' );

    equal( '{{ items | sum("value", 10) }}',
      { items => [ { value => 1 }, { value => 2 }, { value => 3 } ] }, '16' );
  };

  it 'sort' => sub {
    equal( '{% for i in [3,5,2,1,4,6] | sort %}{{ i }}{% endfor %}', '123456' );

    equal( '{% for i in ["fOo", "Foo"] | sort %}{{ i }}{% endfor %}', 'fOoFoo' );

    equal( '{% for i in [1,6,3,7] | sort(true) %}{{ i }}{% endfor %}', '7631' );

    equal( '{% for i in ["fOo", "Foo"] | sort(false, true) %}{{ i }}{% endfor %}', 'FoofOo' );

    equal(
      '{% for item in items | sort(false, false, "name") %}{{ item.name }}{% endfor %}',
      { items => [ { name => 'james' }, { name => 'fred' }, { name => 'john' } ] },
      'fredjamesjohn'
    );

    equal( '{% for i in [ {n:3},{n:5},{n:2},{n:1},{n:4},{n:6}] | sort(attribute="n") %}{{ i.n }}{% endfor %}',
      '123456' );

    my $nested_attribute_sort_template =
      '{% for item in items | sort(attribute="meta.age") %}{{ item.name }}{% endfor %}';
    equal(
      $nested_attribute_sort_template,
      {
        items => [
          { name => 'james', meta => { age => 25 } },
          { name => 'fred',  meta => { age => 18 } },
          { name => 'john',  meta => { age => 19 } },
        ]
      },
      'fredjohnjames'
    );

    my ($err) = render(
      $nested_attribute_sort_template,
      {
        items => [
          { name => 'james', meta => { age   => 25 } },
          { name => 'fred',  meta => { age   => 18 } },
          { name => 'john',  meta => { title => 'Developer' } },
        ]
      },
      { throwOnUndefined => true, noThrow => 1 }
    );
    like( err_message($err), qr/sort: attribute "meta\.age" resolved to undefined/,
      'sort throws on undefined attribute with throwOnUndefined' );
  };

  it 'string' => sub {
    equal( '{% for i in 1234 | string | list %}{{ i }},{% endfor %}', '1,2,3,4,' );
  };

  it 'striptags' => sub {
    equal( '{{ html | striptags }}', { html => '<foo>bar' }, 'bar' );
    equal(
      '{{ html | striptags }}',
      {
        html => "  <p>an  \n <a href=\"#\">example</a> link</p>\n<p>to a webpage</p> "
          . '<!-- <p>and some comments</p> -->'
      },
      'an example link to a webpage'
    );
    equal( '{{ undefined | striptags }}', '' );
    equal( '{{ null | striptags }}',      '' );
    equal( '{{ nothing | striptags }}',   '' );
    equal(
      '{{ html | striptags(true) }}',
      {
        html => "<div>\n  row1\nrow2  \n  <strong>row3</strong>\n</div>\n\n"
          . " HEADER \n\n<ul>\n  <li>option  1</li>\n<li>option  2</li>\n</ul>"
      },
      "row1\nrow2\nrow3\n\nHEADER\n\noption 1\noption 2"
    );
  };

  it 'title' => sub {
    equal( '{{ "foo bar baz" | title }}', 'Foo Bar Baz' );
    equal( '{{ str | title }}', { str => mark_safe('foo bar baz') }, 'Foo Bar Baz' );
    equal( '{{ undefined | title }}', '' );
    equal( '{{ null | title }}',      '' );
    equal( '{{ nothing | title }}',   '' );
  };

  it 'trim' => sub {
    equal( '{{ "  foo " | trim }}', 'foo' );
    equal( '{{ str | trim }}', { str => mark_safe('  foo ') }, 'foo' );
  };

  it 'truncate' => sub {
    equal( '{{ "foo bar" | truncate(3) }}',            'foo...' );
    equal( '{{ "foo bar baz" | truncate(6) }}',        'foo...' );
    equal( '{{ "foo bar baz" | truncate(7) }}',        'foo bar...' );
    equal( '{{ "foo bar baz" | truncate(5, true) }}',  'foo b...' );
    equal( '{{ "foo bar baz" | truncate(6, true, "?") }}', 'foo ba?' );
    equal( '{{ "foo bar" | truncate(3) }}', { str => mark_safe('foo bar') }, 'foo...' );

    equal( '{{ undefined | truncate(3) }}',            '' );
    equal( '{{ undefined | truncate(6) }}',            '' );
    equal( '{{ undefined | truncate(7) }}',            '' );
    equal( '{{ undefined | truncate(5, true) }}',      '' );
    equal( '{{ undefined | truncate(6, true, "?") }}', '' );

    equal( '{{ null | truncate(3) }}',            '' );
    equal( '{{ null | truncate(6) }}',            '' );
    equal( '{{ null | truncate(7) }}',            '' );
    equal( '{{ null | truncate(5, true) }}',      '' );
    equal( '{{ null | truncate(6, true, "?") }}', '' );

    equal( '{{ nothing | truncate(3) }}',            '' );
    equal( '{{ nothing | truncate(6) }}',            '' );
    equal( '{{ nothing | truncate(7) }}',            '' );
    equal( '{{ nothing | truncate(5, true) }}',      '' );
    equal( '{{ nothing | truncate(6, true, "?") }}', '' );
  };

  it 'upper' => sub {
    equal( '{{ "foo" | upper }}', 'FOO' );
    equal( '{{ str | upper }}', { str => mark_safe('foo') }, 'FOO' );
    equal( '{{ null | upper }}',      '' );
    equal( '{{ undefined | upper }}', '' );
    equal( '{{ nothing | upper }}',   '' );
  };

  it 'urlencode' => sub {
    equal( '{{ "&" | urlencode }}', '%26' );
    equal( '{{ arr | urlencode | safe }}', { arr => [ [ 1, 2 ], [ '&1', '&2' ] ] },
      '1=2&%261=%262' );
    # JS: {1: 2, '&1': '&2'} -- integer key 1 enumerates first; insertion order
    # (1, '&1') gives the same order (ADR 0011, Hash::Ordered).
    equal( '{{ obj | urlencode | safe }}',
      { obj => Hash::Ordered->new( 1 => 2, '&1' => '&2' ) }, '1=2&%261=%262' );
  };

  it 'urlencode - object without prototype' => sub {
    # JS: Object.create(null) -- prototype-less; in Perl an (ordered) hash has no
    # prototype to lack (ADR 0014: own-key lookup), so it is the same value as above.
    my $obj = Hash::Ordered->new( '1' => 2, '&1' => '&2' );
    equal( '{{ obj | urlencode | safe }}', { obj => $obj }, '1=2&%261=%262' );
  };

  it 'urlize' => sub {
    # from jinja test suite:
    # https://github.com/mitsuhiko/jinja2/blob/8db47916de0e888dd8664b2511e220ab5ecf5c15/jinja2/testsuite/filters.py#L236-L239
    equal( '{{ "foo http://www.example.com/ bar" | urlize | safe }}',
      'foo <a href="http://www.example.com/">' . 'http://www.example.com/</a> bar' );

    # additional tests
    equal( '{{ "" | urlize }}',    '' );
    equal( '{{ "foo" | urlize }}', 'foo' );

    # http
    equal( '{{ "http://jinja.pocoo.org/docs/templates/" | urlize | safe }}',
      '<a href="http://jinja.pocoo.org/docs/templates/">http://jinja.pocoo.org/docs/templates/</a>' );

    # https
    equal( '{{ "https://jinja.pocoo.org/docs/templates/" | urlize | safe }}',
      '<a href="https://jinja.pocoo.org/docs/templates/">https://jinja.pocoo.org/docs/templates/</a>' );

    # www without protocol
    equal( '{{ "www.pocoo.org/docs/templates/" | urlize | safe }}',
      '<a href="http://www.pocoo.org/docs/templates/">www.pocoo.org/docs/templates/</a>' );

    # .org, .net, .com without protocol or www
    equal( '{{ "pocoo.org/docs/templates/" | urlize | safe }}',
      '<a href="http://pocoo.org/docs/templates/">pocoo.org/docs/templates/</a>' );
    equal( '{{ "pocoo.net/docs/templates/" | urlize | safe }}',
      '<a href="http://pocoo.net/docs/templates/">pocoo.net/docs/templates/</a>' );
    equal( '{{ "pocoo.com/docs/templates/" | urlize | safe }}',
      '<a href="http://pocoo.com/docs/templates/">pocoo.com/docs/templates/</a>' );
    equal( '{{ "pocoo.com:80" | urlize | safe }}',
      '<a href="http://pocoo.com:80">pocoo.com:80</a>' );
    equal( '{{ "pocoo.com" | urlize | safe }}',
      '<a href="http://pocoo.com">pocoo.com</a>' );
    equal( '{{ "pocoo.commune" | urlize | safe }}', 'pocoo.commune' );

    # truncate the printed URL
    equal( '{{ "http://jinja.pocoo.org/docs/templates/" | urlize(12, true) | safe }}',
      '<a href="http://jinja.pocoo.org/docs/templates/" rel="nofollow">http://jinja</a>' );

    # punctuation on the beginning of line.
    equal( '{{ "(http://jinja.pocoo.org/docs/templates/" | urlize | safe }}',
      '<a href="http://jinja.pocoo.org/docs/templates/">http://jinja.pocoo.org/docs/templates/</a>' );
    equal( '{{ "<http://jinja.pocoo.org/docs/templates/" | urlize | safe }}',
      '<a href="http://jinja.pocoo.org/docs/templates/">http://jinja.pocoo.org/docs/templates/</a>' );
    equal( '{{ "&lt;http://jinja.pocoo.org/docs/templates/" | urlize | safe }}',
      '<a href="http://jinja.pocoo.org/docs/templates/">http://jinja.pocoo.org/docs/templates/</a>' );

    # punctuation on the end of line
    equal( '{{ "http://jinja.pocoo.org/docs/templates/," | urlize | safe }}',
      '<a href="http://jinja.pocoo.org/docs/templates/">http://jinja.pocoo.org/docs/templates/</a>' );
    equal( '{{ "http://jinja.pocoo.org/docs/templates/." | urlize | safe }}',
      '<a href="http://jinja.pocoo.org/docs/templates/">http://jinja.pocoo.org/docs/templates/</a>' );
    equal( '{{ "http://jinja.pocoo.org/docs/templates/)" | urlize | safe }}',
      '<a href="http://jinja.pocoo.org/docs/templates/">http://jinja.pocoo.org/docs/templates/</a>' );
    equal( "{{ \"http://jinja.pocoo.org/docs/templates/\n\" | urlize | safe }}",
      "<a href=\"http://jinja.pocoo.org/docs/templates/\">http://jinja.pocoo.org/docs/templates/</a>\n" );
    equal( '{{ "http://jinja.pocoo.org/docs/templates/&gt;" | urlize | safe }}',
      '<a href="http://jinja.pocoo.org/docs/templates/">http://jinja.pocoo.org/docs/templates/</a>' );

    # http url with username
    equal( '{{ "http://testuser@testuser.com" | urlize | safe }}',
      '<a href="http://testuser@testuser.com">http://testuser@testuser.com</a>' );

    # email addresses
    equal( '{{ "testuser@testuser.com" | urlize | safe }}',
      '<a href="mailto:testuser@testuser.com">testuser@testuser.com</a>' );

    # periods in the text
    equal( '{{ "foo." | urlize }}',    'foo.' );
    equal( '{{ "foo.foo" | urlize }}', 'foo.foo' );

    # markup in the text
    equal( '{{ "<b>what up</b>" | urlize | safe }}', '<b>what up</b>' );

    # breaklines and tabs in the text
    equal( "{{ \"what\nup\" | urlize | safe }}", "what\nup" );
    equal( "{{ \"what\tup\" | urlize | safe }}", "what\tup" );
  };

  it 'wordcount' => sub {
    equal( '{{ "foo bar baz" | wordcount }}', '3' );
    equal( '{{ str | wordcount }}', { str => mark_safe('foo bar baz') }, '3' );
    equal( '{{ null | wordcount }}',      '' );
    equal( '{{ undefined | wordcount }}', '' );
    equal( '{{ nothing | wordcount }}',   '' );
  };

};

done_testing;

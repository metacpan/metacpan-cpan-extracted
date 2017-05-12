######################################################################
# Test suite for YAML::Logic
# by Mike Schilli <cpan@perlmeister.com>
######################################################################
use warnings;
use strict;
use YAML::Syck qw(Load Dump);
use YAML::Logic;
use Test::More qw(no_plan);
use Data::Dumper;
use Log::Log4perl qw(:easy);

# Log::Log4perl->easy_init( {level => $DEBUG, layout => "%F{1}:%L: %m%n" } );

  # Not equal
eval_test("rule:
  - foo
  - bar
", {}, 0, "equal");

  # Equal
eval_test("rule:
  - foo
  - foo
", {}, 1, "equal");

  # Equal with interpolation (left)
eval_test('rule:
  - $var
  - foo
', { var => "foo" }, 1, "interpolation");

  # Equal with interpolation (right)
eval_test('rule:
  - foo
  - $var
', { var => "foo" }, 1, "interpolation");


  # Equal with interpolation (both)
eval_test('rule:
  - $var1
  - $var2
', { var1 => "foo", var2 => "foo" }, 1, "interpolation");

  # op: eq
eval_test('rule:
  - foo
  - eq: bar
', {}, 0, "eq op");

  # op: ==
eval_test('rule:
  - 5
  - ==: 13
', {}, 0, "== op");

  # op: ==
eval_test('rule:
  - 13
  - ==: 13
', {}, 1, "== op");

  # op: ne
eval_test('rule:
  - foo
  - ne: bar
', {}, 1, "ne op");

  # op: lt
eval_test('rule:
  - abc
  - lt: def
', {}, 1, "lt op");

  # op: gt
eval_test('rule:
  - abc
  - gt: def
', {}, 0, "gt op");

  # op: gt
eval_test('rule:
  - 123
  - gt: 456
', {}, 0, "gt op");

  # op: gt
eval_test('rule:
  - 456
  - gt: 123
', {}, 1, "gt op");

  # op: <
eval_test(q{rule:
  - 456
  - '>': 123
}, {}, 1, "> op");

  # op: <
eval_test(q{rule:
  - 123
  - '>': 456
}, {}, 0, "> op");

  # op: <
eval_test(q{rule:
  - 456
  - '<=': 123
}, {}, 0, "<= op");

  # op: <=
eval_test(q{rule:
  - 45
  - '<=': 123
}, {}, 1, "<= op");

  # op: <
eval_test(q{rule:
  - 456
  - '<': 123
}, {}, 0, "< op");

  # op: <
eval_test(q{rule:
  - 123
  - '<': 456
}, {}, 1, "< op");

  # op: regex
eval_test('rule:
  - 456
  - like: "\d+"
', {}, 1, "regex");

  # op: slash escapes
eval_test('rule:
  - /foo/bar
  - like: "/foo/bar"
', {}, 1, "regex with / chars");

  # op: slash escapes
eval_test('rule:
  - /foo\/bar
  - like: "/foo\/bar"
', {}, 1, "regex with / chars");

  # op: slash escapes
eval_test('rule:
  - /foo\/bar
  - like: "/foo\\/bar"
', {}, 1, "regex with / chars");

  # op: slash escapes
eval_test('rule:
  - /foo\/bar
  - like: "/foo\\\/bar"
', {}, 1, "regex with / chars");

  # op: slash escapes
eval_test('rule:
  - /foo\/bar
  - like: "/foo\\\\/bar"
', {}, 1, "regex with / chars");

  # op: slash escapes
eval_test('rule:
  - /foo\/bar
  - like: "/foo\/bar"
', {}, 1, "regex with / chars");

  # op: regex
eval_test('rule:
  - 456
  - =~: "\d+"
', {}, 1, "regex");

  # op: regex
eval_test('rule:
  - 456
  - =~: "\d+"
', {}, 1, "regex");

eval_test('rule:
  - aBc
  - like: "(?i)abc"
', {}, 1, "regex /i");

eval_test('rule:
  - aBc
  - like: (?i)abc
', {}, 1, "regex /i");

eval_test('rule:
  - aBc
  - like: "^aBc$"
', {}, 1, "anchored match");

eval {
eval_test(q#rule:
  - aBc
  - like: "?{ unlink '/tmp/foo' }"
#, {}, 1, "regex code trap");
};

like $@, qr/Trapped \?\{ in regex/, "trap code";

  # Not
eval_test(q{rule:
  - '!foo'
  - bar
}, {}, 1, "not");

  # Not with variable
eval_test(q{rule:
  - '!$var'
  - bar
}, {var => "bar"}, 0, "not with var");

  # Neither match
eval_test(q{rule:
  - '!$var'
  - like: "foo"
  - '!$var'
  - like: "bar"
}, {var => "abc"}, 1, "neither of two matches");

  # Neither match
eval_test(q{rule:
  - '!$var'
  - like: "foo"
  - '!$var'
  - like: "bar"
}, {var => "foo"}, 0, "neither of two matches, false");

  # Both sides interpolated
eval_test(q{rule:
  - $var1
  - '$var2'
}, {var1 => "foo", var2 => "foo"}, 1, "both sides interpolated");

  # Hash interpolation
eval_test(q{rule:
  - $var.somekey
  - foo
}, {var => { somekey => 'foo' }}, 1, "hash interpolation");

  # Array interpolation
eval_test(q{rule:
  - $var.1
  - el2
}, {var => [ 'el1', 'el2' ] }, 1, "array interpolation");

  # Logical or
eval_test(q{rule:
  - or
  -
    - $var
    - foo
    - $var
    - bar
}, {var => "bar"}, 1, "logical or");

  # Logical or
eval_test(q{rule:
  - or
  -
    - $var
    - foo
    - $var
    - bar
}, {var => "foo"}, 1, "logical or");

  # Logical or
eval_test(q{rule:
  - or
  -
    - $var
    - foo
    - $var
    - bar
}, {var => "abc"}, 0, "logical or");

  # Logical or
eval_test(q{rule:
  - or
  -
    - "!$var"
    - foo
    - $var
    - bar
}, {var => "abc"}, 1, "logical or");

  # Undef
eval_test(q{rule:
    - "$var.defined"
    - ""
}, { var => undef }, 1, "undef");

eval_test(q{rule:
    - "!$var.defined"
    - 1
}, { var => undef }, 1, "undef");

eval_test(q{rule:
    - $var.defined
    - 1
}, { var => 0 }, 1, "undef");

eval_test(q{rule:
    - "!$var.defined"
    - 1
}, { var => 0 }, 0, "undef");

eval_test(q{rule:
    - "!${var.defined}"
    - 1
}, { var => 0 }, 0, "undef");

eval_test(q{rule:
    - "foo$var"
    - "bar$var"
}, { var => 0 }, 0, "double interpolation");

eval_test(q{rule:
    - "foo$var"
    - "foo$var"
}, { var => 1 }, 1, "double interpolation");

eval_test(q{rule:
    - "$var"
    - like: "\\w"
}, { var => "a\\\"" }, 1, "backslash/quote madness");

eval_test(q{rule:
    - $var
    - like: "\\w"
}, { var => "a\\\"" }, 1, "backslash/quote madness");

eval_test(q{rule:
    - $var
    - like: "\\w"
}, { var => "a" }, 1, "backslash/quote madness");

eval_test(q{rule:
    - "$var"
    - like: "\\w"
}, { var => "a" }, 1, "backslash/quote madness");

eval_test(q{rule:
  - or
  -
    - 1
    - 2
    - 3
    - 3
}, {}, 1, "simple or");

eval_test(q{rule:
  - or
  -
    - 1
    - 2
    - 3
    - 4
}, {}, 0, "simple or");

eval_test(q{rule:
  - or
  -
    - 1
    - 2
    - and
    -
      - 4
      - 4
      - 5
      - 5
}, {}, 1, "or-and");

eval_test(q{rule:
  - or
  -
    - and
    -
      - 4
      - 4
      - 5
      - 5
    - 1
    - 2
}, {}, 1, "or-and");

eval_test(q{rule:
  - or
  -
    - and
    -
      - 4
      - 4
      - 5
      - 6
    - 1
    - 1
}, {}, 1, "or-and");

eval_test(q{rule:
  - or
  -
    - and
    - 
      - 2
      - 3
      - 3
      - 4
    - and
    - 
      - 2
      - 2
      - 3
      - 3
}, {}, 1, "or-and-and");

eval_test(q{rule:
  - or
  -
    - and
    - 
      - 2
      - 3
      - 3
      - 4
    - or
    - 
      - $foo
      - $bar
      - $foo
      - $foo
}, { foo => "1", bar => "2" }, 1, "or-and-or");

eval_test(q{rule:
  - or
  -
    - or
    - 
      - 1
      - 2
      - 3
      - 4
    - or
    - 
      - 5
      - 6
      - 7
      - 8
}, {}, 0, "or-or-or");

eval_test(q{rule:
  - or
  -
    - or
    - 
      - 1
      - 2
      - 3
      - 4
    - or
    - 
      - 5
      - 6
      - 8
      - 8
}, {}, 1, "or-or-or");

eval_test(q{rule:
  - and
  -
    - 1
    - 1
    - 2
    - 2
    - 3
    - 3
}, {}, 1, "and");

eval_test(q{rule:
  - and
  -
    - 1
    - 1
    - 2
    - 2
    - 3
    - 4
}, {}, 0, "and");

###########################################
sub eval_test {
###########################################
    my($yml, $vars, $expected, $descr) = @_;

    my $logic = YAML::Logic->new();

    my $data = Load $yml;
    my $res = $logic->evaluate( $data->{rule}, $vars );
    is($res, $expected, $descr );

    if( $res != $expected ) {
        print $logic->error();
    }
}

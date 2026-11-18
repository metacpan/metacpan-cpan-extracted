#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Scalar::Util qw( blessed );
use Carp qw( croak );
use builtin qw( true false );
use Hash::Ordered;
use FindBin;
use lib "$FindBin::Bin/../lib";

no warnings 'experimental::builtin';

# Port of upstream/nunjucks/tests/compiler.js: describe('compiler', ...) and
# describe('the filter tag', ...). One subtest per upstream it(), same title,
# same order (k21).
#
# util.js's render()/equal() now build a real Environment + Template (k16)
# through an in-memory loader seeded from committed copies of the actual
# upstream template files (t/upstream/templates/ -- see Test::Nunjucks::Util's
# header for why). `finish(done)` is pure mocha async plumbing and is never
# ported, matching t/upstream/runtime.t's precedent -- Perl callbacks in this
# port run synchronously (ADR 0003) and render()/equal() simply return once
# fired.
#
# Filters.pm exists (k17); every filter this file uses is ported, so no it() here is TODO
# for a missing filter. compile_filter's own comment
# marks two further upstream behaviours as ADR 0009 (accepted 2026-09-22)
# *decided divergences*, not bugs: a bare/member user coderef gets no JS-style `this` binding, and a sync
# filter is called with plain (@args), not (context, @args) -- both are TODO'd
# citing ADR 0009, not fixed here.
plan skip_all => 'Text::Nunjucks::Environment not available'
  unless eval { require Text::Nunjucks::Environment; 1 };

require Test::Nunjucks::Util;
Test::Nunjucks::Util->import(qw( render equal ));

# expect(err).to.match(/regex/) -- err is a blessed error; match its message.
sub err_message {
  my ($err) = @_;
  return '' unless defined $err;
  return ( blessed($err) && $err->can('message') ) ? $err->message : "$err";
}

# err.toString() -- JS's default Error.prototype.toString: "name: message".
sub err_to_string {
  my ($err) = @_;
  return blessed($err) && $err->can('name') && $err->can('message')
    ? $err->name . ': ' . $err->message
    : "$err";
}

# equal(), but the render is known to die (an unported feature or a decided divergence) --
# render with noThrow + a direct is() under TODO instead of relying on subtest
# to isolate a die from equal()'s croak. It does not: in this Test::More/Test2
# version a die inside a subtest still aborts the whole file (verified while
# writing this suite -- t/upstream/runtime.t's noThrow pattern is the same
# fix), so every assertion expected to error must go through render(noThrow)
# rather than equal().
sub todo_equal {
  my ( $reason, $template, @rest ) = @_;
  my ( $ctx, $opts, $expected );
  if ( @rest == 1 )    { ($expected)                = @rest; }
  elsif ( @rest == 2 ) { ( $ctx, $expected )        = @rest; }
  elsif ( @rest == 3 ) { ( $ctx, $opts, $expected ) = @rest; }
  else                 { croak 'todo_equal: wrong number of arguments' }
  $opts = { %{ $opts // {} }, noThrow => 1 };
TODO: {
    local $TODO = $reason;
    my ( undef, $res ) = render( $template, $ctx, $opts );
    is( $res, $expected );
  }
}

subtest 'compiler' => sub {

  subtest 'should compile templates' => sub {
    equal( 'Hello world', 'Hello world' );
    equal( 'Hello world, {{ name }}',
      { name => 'James' },
      'Hello world, James' );
    equal( 'Hello world, {{name}}{{suffix}}, how are you',
      { name => 'James', suffix => ' Long' },
      'Hello world, James Long, how are you' );
  };

  subtest 'should escape newlines' => sub {
    equal( 'foo\\nbar', 'foo\\nbar' );
  };

  subtest 'should escape Unicode line seperators' => sub {
    equal( "\x{2028}", "\x{2028}" );
  };

  subtest 'should compile references' => sub {
    equal( '{{ foo.bar }}', { foo => { bar => 'baz' } }, 'baz' );
    equal( '{{ foo["bar"] }}', { foo => { bar => 'baz' } }, 'baz' );
  };

  subtest 'should compile references - object without prototype' => sub {
    # JS: `Object.create(null)` -- a bare object with no prototype methods.
    # Perl hashrefs already carry no prototype chain, so a plain hashref is
    # the equivalent context (no lookup-vs-inherited-method distinction to
    # reproduce).
    my $context = { foo => { bar => 'baz' } };
    equal( '{{ foo.bar }}', $context, 'baz' );
    equal( '{{ foo["bar"] }}', $context, 'baz' );
  };

  subtest 'should fail silently on undefined values' => sub {
    equal( '{{ foo }}', '' );
    equal( '{{ foo.bar }}', '' );
    equal( '{{ foo.bar.baz }}', '' );
    equal( '{{ foo.bar.baz["biz"].mumble }}', '' );
  };

  subtest 'should not treat falsy values the same as undefined' => sub {
    equal( '{{ foo }}', { foo => 0 }, '0' );
    equal( '{{ foo }}', { foo => false }, 'false' );    # ADR 0001: builtin false
  };

  subtest 'should display none as empty string' => sub {
    equal( '{{ none }}', '' );
  };

  subtest 'should compile none as falsy' => sub {
    equal( '{% if not none %}yes{% endif %}', 'yes' );
  };

  subtest 'should compile none as null, not undefined' => sub {
    my ( $err, $res ) = render( '{{ none|default("d", false) }}', undef, { noThrow => 1 } );
    is( $res, '', 'default filter distinguishes null from undefined' );
  };

  subtest 'should compile function calls' => sub {
    equal( '{{ foo("msg") }}',
      { foo => sub { return $_[0] . 'hi' } },
      'msghi' );
  };

  subtest 'should compile function calls with correct scope' => sub {
  TODO: {
      local $TODO = 'ADR 0009: a bare/member user coderef gets no this-binding '
        . '("$obj->bar()" cannot see "$obj->{baz}" the way JS this.baz does)';
      equal( '{{ foo.bar() }}',
        { foo => { bar => sub { return $_[0]->{baz} }, baz => 'hello' } },
        'hello' );
    }
  };

  subtest 'should compile switch statements' => sub {
    # standard switches
    my $tpl1 = '{% switch foo %}{% case "bar" %}BAR{% case "baz" %}BAZ{% default %}NEITHER FOO NOR BAR{% endswitch %}';
    # test no-default switches
    my $tpl2 = '{% switch foo %}{% case "bar" %}BAR{% case "baz" %}BAZ{% endswitch %}';
    # test fall-through cases
    my $tpl3 = '{% switch foo %}{% case "bar" %}{% case "baz" %}BAR{% endswitch %}';
    equal( $tpl1, 'NEITHER FOO NOR BAR' );
    equal( $tpl1, { foo => 'bar' }, 'BAR' );
    equal( $tpl1, { foo => 'baz' }, 'BAZ' );
    equal( $tpl2, '' );
    equal( $tpl3, { foo => 'bar' }, 'BAR' );
    equal( $tpl3, { foo => 'baz' }, 'BAR' );
  };

  subtest 'should compile if blocks' => sub {
    my $tmpl = 'Give me some {% if hungry %}pizza{% else %}water{% endif %}';

    equal( $tmpl, { hungry => true }, 'Give me some pizza' );
    equal( $tmpl, { hungry => false }, 'Give me some water' );
    equal( '{% if not hungry %}good{% endif %}', { hungry => false }, 'good' );

    equal( '{% if hungry and like_pizza %}good{% endif %}',
      { hungry => true, like_pizza => true }, 'good' );

    equal( '{% if hungry or like_pizza %}good{% endif %}',
      { hungry => false, like_pizza => true }, 'good' );

    equal( '{% if (hungry or like_pizza) and anchovies %}good{% endif %}',
      { hungry => false, like_pizza => true, anchovies => true }, 'good' );

    equal(
      '{% if food == "pizza" %}pizza{% endif %}' .
      '{% if food =="beer" %}beer{% endif %}',
      { food => 'beer' }, 'beer' );

    equal( '{% if "pizza" in food %}yum{% endif %}',
      { food => { pizza => true } }, 'yum' );

    equal( '{% if pizza %}yum{% elif anchovies %}yuck{% endif %}',
      { pizza => true }, 'yum' );

    equal( '{% if pizza %}yum{% elseif anchovies %}yuck{% endif %}',
      { pizza => true }, 'yum' );

    equal( '{% if pizza %}yum{% elif anchovies %}yuck{% endif %}',
      { anchovies => true }, 'yuck' );

    equal( '{% if pizza %}yum{% elseif anchovies %}yuck{% endif %}',
      { anchovies => true }, 'yuck' );

    equal(
      '{% if topping == "pepperoni" %}yum{% elseif topping == "anchovies" %}' .
      'yuck{% else %}hmmm{% endif %}',
      { topping => 'sausage' }, 'hmmm' );
  };

  subtest 'should compile the ternary operator' => sub {
    equal( '{{ "foo" if bar else "baz" }}', 'baz' );
    equal( '{{ "foo" if bar else "baz" }}', { bar => true }, 'foo' );
  };

  subtest 'should compile inline conditionals' => sub {
    my $tmpl = 'Give me some {{ "pizza" if hungry else "water" }}';

    equal( $tmpl, { hungry => true }, 'Give me some pizza' );
    equal( $tmpl, { hungry => false }, 'Give me some water' );
    equal( '{{ "good" if not hungry }}', { hungry => false }, 'good' );
    equal( '{{ "good" if hungry and like_pizza }}',
      { hungry => true, like_pizza => true }, 'good' );
    equal( '{{ "good" if hungry or like_pizza }}',
      { hungry => false, like_pizza => true }, 'good' );
    equal( '{{ "good" if (hungry or like_pizza) and anchovies }}',
      { hungry => false, like_pizza => true, anchovies => true }, 'good' );
    equal(
      '{{ "pizza" if food == "pizza" }}' .
      '{{ "beer" if food == "beer" }}',
      { food => 'beer' }, 'beer' );
  };

  #### the for / asyncEach / asyncAll tag -- runLoopTests(block) in upstream
  sub run_loop_tests {
    my ($block) = @_;
    my $end = { asyncAll => 'endall', asyncEach => 'endeach', for => 'endfor' }->{$block};

    subtest "the $block tag" => sub {
      subtest 'should loop over simple arrays' => sub {
        equal( "{% $block i in arr %}{{ i }}{% $end %}",
          { arr => [ 1, 2, 3, 4, 5 ] }, '12345' );
      };
      subtest 'should loop normally with an {% else %} tag and non-empty array' => sub {
        equal( "{% $block i in arr %}{{ i }}{% else %}empty{% $end %}",
          { arr => [ 1, 2, 3, 4, 5 ] }, '12345' );
      };
      subtest 'should execute the {% else %} block when looping over an empty array' => sub {
        equal( "{% $block i in arr %}{{ i }}{% else %}empty{% $end %}",
          { arr => [] }, 'empty' );
      };
      subtest 'should support destructured looping' => sub {
        equal( "{% $block a, b, c in arr %}" .
          "{{ a }},{{ b }},{{ c }}.{% $end %}",
          { arr => [ [ 'x', 'y', 'z' ], [ '1', '2', '3' ] ] },
          'x,y,z.1,2,3.' );
      };
      subtest 'should do loop over key-values of a literal in-template Object' => sub {
        # ADR 0011: a template dict literal is a Hash::Ordered (insertion order);
        # Lib::async_for and Runtime::async_all now read its values through the
        # Hash::Ordered branch / member_lookup seam, so this iterates the same
        # way for all three tags -- one pinned test per branch.
        equal( "{% $block k, v in { one: 1, two: 2 } %}" .
          "-{{ k }}:{{ v }}-{% $end %}", '-one:1--two:2-' );
      };
      subtest 'should support loop.index' => sub {
        equal( "{% $block i in [7,3,6] %}{{ loop.index }}{% $end %}", '123' );
      };
      subtest 'should support loop.index0' => sub {
        equal( "{% $block i in [7,3,6] %}{{ loop.index0 }}{% $end %}", '012' );
      };
      subtest 'should support loop.revindex' => sub {
        equal( "{% $block i in [7,3,6] %}{{ loop.revindex }}{% $end %}", '321' );
      };
      subtest 'should support loop.revindex0' => sub {
        equal( "{% $block i in [7,3,6] %}{{ loop.revindex0 }}{% $end %}", '210' );
      };
      subtest 'should support loop.first' => sub {
        equal( "{% $block i in [7,3,6] %}" .
          "{% if loop.first %}{{ i }}{% endif %}" .
          "{% $end %}", '7' );
      };
      subtest 'should support loop.last' => sub {
        equal( "{% $block i in [7,3,6] %}" .
          "{% if loop.last %}{{ i }}{% endif %}" .
          "{% $end %}", '6' );
      };
      subtest 'should support loop.length' => sub {
        equal( "{% $block i in [7,3,6] %}{{ loop.length }}{% $end %}", '333' );
      };
      subtest 'should fail silently when looping over an undefined variable' => sub {
        equal( "{% $block i in foo %}{{ i }}{% $end %}", '' );
      };
      subtest 'should fail silently when looping over an undefined property' => sub {
        equal( "{% $block i in foo.bar %}{{ i }}{% $end %}", { foo => {} }, '' );
      };
      # TODO: this behavior differs from jinja2
      subtest 'should fail silently when looping over a null variable' => sub {
        equal( "{% $block i in foo %}{{ i }}{% $end %}", { foo => undef }, '' );
      };
      subtest 'should loop over two-dimensional arrays' => sub {
        equal( "{% $block x, y in points %}[{{ x }},{{ y }}]{% $end %}",
          { points => [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ] ] },
          '[1,2][3,4][5,6]' );
      };
      subtest 'should loop over four-dimensional arrays' => sub {
        equal( "{% $block a, b, c, d in arr %}[{{ a }},{{ b }},{{ c }},{{ d }}]{% $end%}",
          { arr => [ [ 1, 2, 3, 4 ], [ 5, 6, 7, 8 ] ] },
          '[1,2,3,4][5,6,7,8]' );
      };
      subtest 'should support loop.index with two-dimensional loops' => sub {
        equal( "{% $block x, y in points %}{{ loop.index }}{% $end %}",
          { points => [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ] ] }, '123' );
      };
      subtest 'should support loop.revindex with two-dimensional loops' => sub {
        equal( "{% $block x, y in points %}{{ loop.revindex }}{% $end %}",
          { points => [ [ 1, 2 ], [ 3, 4 ], [ 5, 6 ] ] }, '321' );
      };
      subtest 'should support key-value looping over an Object variable' => sub {
        # ADR 0011: a caller-supplied Hash::Ordered is honoured in its own
        # order, matching JS insertion order byte-for-byte (a plain hashref
        # would iterate key-sorted instead -- a documented divergence, not
        # exercised here since Hash::Ordered gets full fidelity).
        my $items = Hash::Ordered->new( foo => 1, bar => 2 );
        equal( "{% $block k, v in items %}({{ k }},{{ v }}){% $end %}",
          { items => $items }, '(foo,1)(bar,2)' );
      };
      subtest "should support loop.index when looping over an Object's key-value pairs" => sub {
        equal( "{% $block k, v in items %}{{ loop.index }}{% $end %}",
          { items => { foo => 1, bar => 2 } }, '12' );
      };
      subtest "should support loop.revindex when looping over an Object's key-value pairs" => sub {
        equal( "{% $block k, v in items %}{{ loop.revindex }}{% $end %}",
          { items => { foo => 1, bar => 2 } }, '21' );
      };
      subtest "should support loop.length when looping over an Object's key-value pairs" => sub {
        equal( "{% $block k, v in items %}{{ loop.length }}{% $end %}",
          { items => { foo => 1, bar => 2 } }, '22' );
      };
      subtest 'should support include tags in the body of the loop' => sub {
        # ADR 0011: plain caller hashes are key-sorted by Lib::keys -- still
        # {foo, bar} in that order, so a plain hashref would render identically
        # here. We use Hash::Ordered because the upstream it() is also
        # asserting the JS-fidelity (insertion) path, and one pinned instance
        # per branch is enough.
        my $items = Hash::Ordered->new( foo => 1, bar => 2 );
        equal( "{% $block item, v in items %}{% include \"item.njk\" %}{% $end %}",
          { items => $items }, 'showing fooshowing bar' );
      };
      subtest 'should work with {% set %} and {% include %} tags' => sub {
        equal(
          '{% set item = passed_var %}' .
          '{% include "item.njk" %}' . "\n" .
          "{% $block i in passed_iter %}" .
          '{% set item = i %}' .
          '{% include "item.njk" %}' . "\n" .
          "{% $end %}",
          { passed_var => 'test', passed_iter => [ '1', '2', '3' ] },
          "showing test\nshowing 1\nshowing 2\nshowing 3\n" );
      };
      subtest 'should work with Set builtin' => sub {
      TODO: {
          local $TODO = 'no Perl analogue for a JS ES6 Set context value (no ADR)';
          fail('Set builtin iteration');
        }
      };
      subtest 'should work with Map builtin' => sub {
      TODO: {
          local $TODO = 'no Perl analogue for a JS ES6 Map context value (no ADR)';
          fail('Map builtin iteration');
        }
      };
    };
  }

  run_loop_tests('for');
  run_loop_tests('asyncEach');
  run_loop_tests('asyncAll');

  subtest 'should allow overriding var with none inside nested scope' => sub {
    equal(
      '{% set var = "foo" %}' .
      '{% for i in [1] %}{% set var = none %}{{ var }}{% endfor %}',
      '' );
  };

  subtest 'should compile async control' => sub {
    # JS reads the real file with fs.readFile; `this.skip()` only fires in a
    # browser bundle (no `fs`), which node (and this port) never is. Ported
    # with Path::Tiny reading the committed fixture directly -- see
    # Test::Nunjucks::Util's header for why the fixture lives under
    # t/upstream/templates/ rather than the gitignored upstream/ tree; the
    # exact path string differs from upstream's 'tests/templates/...' (an
    # adaptation, not a behaviour difference: only its content is asserted).
    require Path::Tiny;
    my $tmpl_path = Path::Tiny::path('t/upstream/templates/for-async-content.njk')->absolute->stringify;
    my $opts = {
      asyncFilters => {
        getContents => sub {
          my ( $tmpl, $cb ) = @_;
          my $content = eval { Path::Tiny::path($tmpl)->slurp_raw };
          $cb->( $@ || undef, $content );
        },
        getContentsArr => sub {
          my ( $arr, $cb ) = @_;
          my $content = eval { Path::Tiny::path( $arr->[0] )->slurp_raw };
          $cb->( $@ || undef, [$content] );
        },
      },
    };

    is( ( render( '{{ tmpl | getContents }}', { tmpl => $tmpl_path }, $opts ) )[1],
      'somecontenthere' );

    is( ( render( '{% if tmpl %}{{ tmpl | getContents }}{% endif %}',
        { tmpl => $tmpl_path }, $opts ) )[1],
      'somecontenthere' );

    is( ( render( '{% if tmpl | getContents %}yes{% endif %}',
        { tmpl => $tmpl_path }, $opts ) )[1],
      'yes' );

    is( ( render( '{% for t in [tmpl, tmpl] %}{{ t | getContents }}*{% endfor %}',
        { tmpl => $tmpl_path }, $opts ) )[1],
      'somecontenthere*somecontenthere*' );

    is( ( render( '{% for t in [tmpl, tmpl] | getContentsArr %}{{ t }}{% endfor %}',
        { tmpl => $tmpl_path }, $opts ) )[1],
      'somecontenthere' );

    is( ( render( '{% if test %}{{ tmpl | getContents }}{% endif %}oof',
        { tmpl => $tmpl_path }, $opts ) )[1],
      'oof' );

    is( ( render(
        '{% if tmpl %}' .
        '{% for i in [0, 1] %}{{ tmpl | getContents }}*{% endfor %}' .
        '{% endif %}',
        { tmpl => $tmpl_path }, $opts ) )[1],
      'somecontenthere*somecontenthere*' );

    is( ( render( '{% block content %}{{ tmpl | getContents }}{% endblock %}',
        { tmpl => $tmpl_path }, $opts ) )[1],
      'somecontenthere' );

    is( ( render( '{% block content %}hello{% endblock %} {{ tmpl | getContents }}',
        { tmpl => $tmpl_path }, $opts ) )[1],
      'hello somecontenthere' );

    is( ( render( '{% block content %}{% set foo = tmpl | getContents %}{{ foo }}{% endblock %}',
        { tmpl => $tmpl_path }, $opts ) )[1],
      'somecontenthere' );

    is( ( render( '{% block content %}{% include "async.njk" %}{% endblock %}',
        { tmpl => $tmpl_path }, $opts ) )[1],
      "somecontenthere\n" );

    is( ( render( '{% asyncEach i in [0, 1] %}{% include "async.njk" %}{% endeach %}',
        { tmpl => $tmpl_path }, $opts ) )[1],
      "somecontenthere\nsomecontenthere\n" );

    is( ( render( '{% asyncAll i in [0, 1, 2, 3, 4] %}-{{ i }}:{% include "async.njk" %}-{% endall %}',
        { tmpl => $tmpl_path }, $opts ) )[1],
      '-0:somecontenthere' . "\n" . '-' .
      '-1:somecontenthere' . "\n" . '-' .
      '-2:somecontenthere' . "\n" . '-' .
      '-3:somecontenthere' . "\n" . '-' .
      '-4:somecontenthere' . "\n" . '-' );
  };

  subtest 'should compile basic arithmetic operators' => sub {
    equal( '{{ 3 + 4 - 5 * 6 / 10 }}', '4' );
  };

  subtest 'should compile the exponentiation (**) operator' => sub {
    equal( '{{ 4**5 }}', '1024' );
  };

  subtest 'should compile the integer division (//) operator' => sub {
    equal( '{{ 9//5 }}', '1' );
  };

  subtest 'should compile the modulus operator' => sub {
    equal( '{{ 9%5 }}', '4' );
  };

  subtest 'should compile numeric negation operator' => sub {
    equal( '{{ -5 }}', '-5' );
  };

  subtest 'should compile comparison operators' => sub {
    equal( '{% if 3 < 4 %}yes{% endif %}', 'yes' );
    equal( '{% if 3 > 4 %}yes{% endif %}', '' );
    equal( '{% if 9 >= 10 %}yes{% endif %}', '' );
    equal( '{% if 10 >= 10 %}yes{% endif %}', 'yes' );
    equal( '{% if 9 <= 10 %}yes{% endif %}', 'yes' );
    equal( '{% if 10 <= 10 %}yes{% endif %}', 'yes' );
    equal( '{% if 11 <= 10 %}yes{% endif %}', '' );

    equal( '{% if 10 != 10 %}yes{% endif %}', '' );
    equal( '{% if 10 == 10 %}yes{% endif %}', 'yes' );

    equal( '{% if "0" == 0 %}yes{% endif %}', 'yes' );
    equal( '{% if "0" === 0 %}yes{% endif %}', '' );
    equal( '{% if "0" !== 0 %}yes{% endif %}', 'yes' );
    equal( '{% if 0 == false %}yes{% endif %}', 'yes' );
    equal( '{% if 0 === false %}yes{% endif %}', '' );

    equal( '{% if foo(20) > bar %}yes{% endif %}',
      { foo => sub { return $_[0] - 1 }, bar => 15 },
      'yes' );
  };

  subtest 'should compile python-style ternary operators' => sub {
    equal( '{{ "yes" if 1 is odd else "no"  }}', 'yes' );
    equal( '{{ "yes" if 2 is even else "no"  }}', 'yes' );
    equal( '{{ "yes" if 2 is odd else "no"  }}', 'no' );
    equal( '{{ "yes" if 1 is even else "no"  }}', 'no' );
  };

  subtest 'should compile the "in" operator for Arrays' => sub {
    equal( '{% if 1 in [1, 2] %}yes{% endif %}', 'yes' );
    equal( '{% if 1 in [2, 3] %}yes{% endif %}', '' );
    equal( '{% if 1 not in [1, 2] %}yes{% endif %}', '' );
    equal( '{% if 1 not in [2, 3] %}yes{% endif %}', 'yes' );
    equal( '{% if "a" in vals %}yes{% endif %}',
      { vals => [ 'a', 'b' ] }, 'yes' );
  };

  subtest 'should compile the "in" operator for objects' => sub {
    equal( '{% if "a" in obj %}yes{% endif %}', { obj => { a => true } }, 'yes' );
    equal( '{% if "a" in obj %}yes{% endif %}', { obj => { b => true } }, '' );
  };

  subtest 'should compile the "in" operator for strings' => sub {
    equal( '{% if "foo" in "foobar" %}yes{% endif %}', 'yes' );
  };

  subtest 'should throw an error when using the "in" operator on unexpected types' => sub {
    my ( $err, $res ) = render(
      '{% if "a" in 1 %}yes{% endif %}', {}, { noThrow => 1 } );
    is( $res, undef );
    like( err_message($err),
      qr/Cannot use "in" operator to search for "a" in unexpected types\./ );

    ( $err, $res ) = render(
      '{% if "a" in obj %}yes{% endif %}', {}, { noThrow => 1 } );
    is( $res, undef );
    like( err_message($err),
      qr/Cannot use "in" operator to search for "a" in unexpected types\./ );
  };

  # isSlim tests are JS-bundle-only (no `fs`/direct classes in the browser
  # slim build); this port is never "slim", so they are ported unconditionally.
  subtest 'should throw exceptions when called synchronously' => sub {
    my $tmpl = Text::Nunjucks::Template->new( '{% from "doesnotexist" import foo %}' );
    my $ok = eval { $tmpl->render; 1 };
    ok( !$ok, 'render dies' );
    like( err_message($@), qr/template not found: doesnotexist/ );
  };

  subtest 'should include error line in raised TemplateError' => sub {
    my $tmpl_str = join( "\n",
      '{% set items = ["a", "b",, "c"] %}',
      '{{ items | join(",") }}' );

    # JS builds `new Loader('tests/templates')` for the Environment, but this
    # template neither includes nor extends anything, so no loader is needed:
    # the Environment keeps its default FileSystemLoader('views'), which it
    # never asks -- the same env-without-loader adaptation as the two
    # isSlim-gated tests around this one.
    my $env  = Text::Nunjucks::Environment->new;
    my $tmpl = Text::Nunjucks::Template->new( $tmpl_str, $env, 'parse-error.njk' );

    my ( $err, $res );
    $tmpl->render( {}, sub { ( $err, $res ) = @_ } );
    is( $res, undef );
    is( err_to_string($err), join( "\n",
        'Template render error: (parse-error.njk) [Line 1, Column 26]',
        '  unexpected token: ,' ) );
  };

  subtest 'should include error line when exception raised in user function' => sub {
    my $tmpl_str = join( "\n",
      '{% block content %}',
      '<div>{{ foo() }}</div>',
      '{% endblock %}' );
    my $env  = Text::Nunjucks::Environment->new;
    my $tmpl = Text::Nunjucks::Template->new( $tmpl_str, $env, 'user-error.njk' );

    # JS: function foo() { throw new Error('ERROR'); } -- a blessed Lib::Error
    # is this port's "new Error(...)" (ADR 0010), so TemplateError's own
    # "message instanceof Error" branch fires the same way on the way back up.
    my ( $err, $res );
    $tmpl->render( { foo => sub { die Text::Nunjucks::Lib::Error->new('ERROR') } },
      sub { ( $err, $res ) = @_ } );
    is( $res, undef );
    is( err_to_string($err), join( "\n",
        'Template render error: (user-error.njk) [Line 1, Column 11]',
        '  Error: ERROR' ) );
  };

  subtest 'should throw exceptions from included templates when called synchronously' => sub {
    my $ok = eval { render( '{% include "broken-import.njk" %}', { str => 'abc' } ); 1 };
    ok( !$ok, 'render dies' );
    like( err_message($@), qr/template not found: doesnotexist/ );
  };

  subtest 'should pass errors from included templates to callback when async' => sub {
    my ( $err, $res ) = render(
      '{% include "broken-import.njk" %}', { str => 'abc' }, { noThrow => 1 } );
    like( err_message($err), qr/template not found: doesnotexist/ );
    is( $res, undef );
  };

  subtest 'should compile string concatenations with tilde' => sub {
    equal( "{{ 4 ~ 'hello' }}", '4hello' );
    equal( '{{ 4 ~ 5 }}', '45' );
    equal( "{{ 'a' ~ 'b' ~ 5 }}", 'ab5' );
  };

  subtest 'should compile macros' => sub {
    equal(
      '{% macro foo() %}This is a macro{% endmacro %}' .
      '{{ foo() }}',
      'This is a macro' );
  };

  subtest 'should compile macros with optional args' => sub {
    equal(
      '{% macro foo(x, y) %}{{ y }}{% endmacro %}' .
      '{{ foo(1) }}',
      '' );
  };

  subtest 'should compile macros with args that can be passed to filters' => sub {
    equal(
      '{% macro foo(x) %}{{ x|title }}{% endmacro %}' .
      '{{ foo("foo") }}',
      'Foo' );
  };

  subtest 'should compile macros with positional args' => sub {
    equal(
      '{% macro foo(x, y) %}{{ y }}{% endmacro %}' .
      '{{ foo(1, 2) }}',
      '2' );
  };

  subtest 'should compile macros with arg defaults' => sub {
    equal(
      '{% macro foo(x, y, z=5) %}{{ y }}{% endmacro %}' .
      '{{ foo(1, 2) }}',
      '2' );
    equal(
      '{% macro foo(x, y, z=5) %}{{ z }}{% endmacro %}' .
      '{{ foo(1, 2) }}',
      '5' );
  };

  subtest 'should compile macros with keyword args' => sub {
    equal(
      '{% macro foo(x, y, z=5) %}{{ y }}{% endmacro %}' .
      '{{ foo(1, y=2) }}',
      '2' );
  };

  subtest 'should compile macros with only keyword args' => sub {
    equal(
      '{% macro foo(x, y, z=5) %}{{ x }}{{ y }}{{ z }}' .
      '{% endmacro %}' .
      '{{ foo(x=1, y=2) }}',
      '125' );
  };

  subtest 'should compile macros with keyword args overriding defaults' => sub {
    equal(
      '{% macro foo(x, y, z=5) %}{{ x }}{{ y }}{{ z }}' .
      '{% endmacro %}' .
      '{{ foo(x=1, y=2, z=3) }}',
      '123' );
  };

  subtest 'should compile macros with out-of-order keyword args' => sub {
    equal(
      '{% macro foo(x, y=2, z=5) %}{{ x }}{{ y }}{{ z }}' .
      '{% endmacro %}' .
      '{{ foo(1, z=3) }}',
      '123' );
  };

  subtest 'should compile macros' => sub {    # upstream reuses this title (2nd occurrence)
    equal(
      '{% macro foo(x, y=2, z=5) %}{{ x }}{{ y }}{{ z }}' .
      '{% endmacro %}' .
      '{{ foo(1) }}',
      '125' );
  };

  subtest 'should compile macros with multiple overridden arg defaults' => sub {
    equal(
      '{% macro foo(x, y=2, z=5) %}{{ x }}{{ y }}{{ z }}' .
      '{% endmacro %}' .
      '{{ foo(1, 10, 20) }}',
      '11020' );
  };

  subtest 'should compile macro calls inside blocks' => sub {
    equal(
      '{% extends "base.njk" %}' .
      '{% macro foo(x, y=2, z=5) %}{{ x }}{{ y }}{{ z }}' .
      '{% endmacro %}' .
      '{% block block1 %}' .
      '{{ foo(1) }}' .
      '{% endblock %}',
      'Foo125BazFizzle' );
  };

  subtest 'should compile macros defined in one block and called in another' => sub {
    equal(
      '{% block bar %}' .
      '{% macro foo(x, y=2, z=5) %}{{ x }}{{ y }}{{ z }}' .
      '{% endmacro %}' .
      '{% endblock %}' .
      '{% block baz %}' .
      '{{ foo(1) }}' .
      '{% endblock %}',
      '125' );
  };

  subtest 'should compile macros that include other templates' => sub {
    equal(
      '{% macro foo() %}{% include "include.njk" %}{% endmacro %}' .
      '{{ foo() }}',
      { name => 'james' },
      'FooInclude james' );
  };

  subtest 'should compile macros that set vars' => sub {
    equal(
      '{% macro foo() %}{% set x = "foo"%}{{ x }}{% endmacro %}' .
      '{% set x = "bar" %}' .
      '{{ x }}' .
      '{{ foo() }}' .
      '{{ x }}',
      'barfoobar' );
  };

  subtest 'should not leak variables set in macro to calling scope' => sub {
    equal(
      '{% macro setFoo() %}' .
      '{% set x = "foo" %}' .
      '{{ x }}' .
      '{% endmacro %}' .
      '{% macro display() %}' .
      '{% set x = "bar" %}' .
      '{{ setFoo() }}' .
      '{{ x }}' .
      '{% endmacro %}' .
      '{{ display() }}',
      'foobar' );
  };

  subtest 'should not leak variables set in nested scope within macro out to calling scope' => sub {
    equal(
      '{% macro setFoo() %}' .
      '{% for y in [1] %}{% set x = "foo" %}{{ x }}{% endfor %}' .
      '{% endmacro %}' .
      '{% macro display() %}' .
      '{% set x = "bar" %}' .
      '{{ setFoo() }}' .
      '{{ x }}' .
      '{% endmacro %}' .
      '{{ display() }}',
      'foobar' );
  };

  subtest 'should compile macros without leaking set to calling scope' => sub {
    # This test checks that the issue #577 is resolved.
    # If the bug is not fixed, and set variables leak into the
    # caller scope, there will be too many "foo"s here ("foofoofoo"),
    # because each recursive call will append a "foo" to the
    # variable x in its caller's scope, instead of just its own.
    equal(
      '{% macro foo(topLevel, prefix="") %}' .
      '{% if topLevel %}' .
      '{% set x = "" %}' .
      '{% for i in [1,2] %}' .
      '{{ foo(false, x) }}' .
      '{% endfor %}' .
      '{% else %}' .
      '{% set x = prefix + "foo" %}' .
      '{{ x }}' .
      '{% endif %}' .
      '{% endmacro %}' .
      '{{ foo(true) }}',
      'foofoo' );
  };

  subtest 'should compile macros that cannot see variables in caller scope' => sub {
    equal(
      '{% macro one(var) %}{{ two() }}{% endmacro %}' .
      '{% macro two() %}{{ var }}{% endmacro %}' .
      '{{ one("foo") }}',
      '' );
  };

  subtest 'should compile call blocks' => sub {
    equal(
      '{% macro wrap(el) %}' .
      '<{{ el }}>{{ caller() }}</{{ el }}>' .
      '{% endmacro %}' .
      '{% call wrap("div") %}Hello{% endcall %}',
      '<div>Hello</div>' );
  };

  subtest 'should compile call blocks with args' => sub {
    equal(
      '{% macro list(items) %}' .
      '<ul>{% for i in items %}' .
      '<li>{{ caller(i) }}</li>' .
      '{% endfor %}</ul>' .
      '{% endmacro %}' .
      '{% call(item) list(["a", "b"]) %}{{ item }}{% endcall %}',
      '<ul><li>a</li><li>b</li></ul>' );
  };

  subtest 'should compile call blocks using imported macros' => sub {
    equal(
      '{% import "import.njk" as imp %}' .
      '{% call imp.wrap("span") %}Hey{% endcall %}',
      '<span>Hey</span>' );
  };

  subtest 'should import templates' => sub {
    equal(
      '{% import "import.njk" as imp %}' .
      '{{ imp.foo() }} {{ imp.bar }}',
      "Here's a macro baz" );

    equal(
      '{% from "import.njk" import foo as baz, bar %}' .
      '{{ bar }} {{ baz() }}',
      "baz Here's a macro" );

    # TODO: Should the for loop create a new frame for each
    # iteration? As it is, `num` is set on all iterations after
    # the first one sets it
    equal(
      '{% for i in [1,2] %}' .
      'start: {{ num }}' .
      '{% from "import.njk" import bar as num %}' .
      'end: {{ num }}' .
      '{% endfor %}' .
      'final: {{ num }}',
      'start: end: bazstart: bazend: bazfinal: ' );
  };

  subtest 'should import templates with context' => sub {
    equal(
      '{% set bar = "BAR" %}' .
      '{% import "import-context.njk" as imp with context %}' .
      '{{ imp.foo() }}',
      "Here's BAR" );

    equal(
      '{% set bar = "BAR" %}' .
      '{% from "import-context.njk" import foo with context %}' .
      '{{ foo() }}',
      "Here's BAR" );

    equal(
      '{% set bar = "BAR" %}' .
      '{% import "import-context-set.njk" as imp %}' .
      '{{ bar }}',
      'BAR' );

    equal(
      '{% set bar = "BAR" %}' .
      '{% import "import-context-set.njk" as imp %}' .
      '{{ imp.bar }}',
      'FOO' );

    equal(
      '{% set bar = "BAR" %}' .
      '{% import "import-context-set.njk" as imp with context %}' .
      '{{ bar }}{{ buzz }}',
      'FOO' );

    equal(
      '{% set bar = "BAR" %}' .
      '{% import "import-context-set.njk" as imp with context %}' .
      '{{ imp.bar }}{{ buzz }}',
      'FOO' );
  };

  subtest 'should import templates without context' => sub {
    equal(
      '{% set bar = "BAR" %}' .
      '{% import "import-context.njk" as imp without context %}' .
      '{{ imp.foo() }}',
      "Here's " );

    equal(
      '{% set bar = "BAR" %}' .
      '{% from "import-context.njk" import foo without context %}' .
      '{{ foo() }}',
      "Here's " );
  };

  subtest 'should default to importing without context' => sub {
    equal(
      '{% set bar = "BAR" %}' .
      '{% import "import-context.njk" as imp %}' .
      '{{ imp.foo() }}',
      "Here's " );

    equal(
      '{% set bar = "BAR" %}' .
      '{% from "import-context.njk" import foo %}' .
      '{{ foo() }}',
      "Here's " );
  };

  subtest 'should inherit templates' => sub {
    equal( '{% extends "base.njk" %}', 'FooBarBazFizzle' );
    equal( 'hola {% extends "base.njk" %} hizzle mumble', 'FooBarBazFizzle' );

    equal( '{% extends "base.njk" %}{% block block1 %}BAR{% endblock %}',
      'FooBARBazFizzle' );

    equal(
      '{% extends "base.njk" %}' .
      '{% block block1 %}BAR{% endblock %}' .
      '{% block block2 %}BAZ{% endblock %}',
      'FooBARBAZFizzle' );

    equal( 'hola {% extends tmpl %} hizzle mumble',
      { tmpl => 'base.njk' },
      'FooBarBazFizzle' );
  };

  subtest 'should not call blocks not defined from template inheritance' => sub {
    my $count = 0;
    render(
      '{% extends "base.njk" %}' .
      '{% block notReal %}{{ foo() }}{% endblock %}',
      { foo => sub { $count++ } } );
    is( $count, 0 );
  };

  subtest 'should conditionally inherit templates' => sub {
    equal(
      '{% if false %}{% extends "base.njk" %}{% endif %}' .
      '{% block block1 %}BAR{% endblock %}',
      'BAR' );

    equal(
      '{% if true %}{% extends "base.njk" %}{% endif %}' .
      '{% block block1 %}BAR{% endblock %}',
      'FooBARBazFizzle' );

    equal(
      '{% if true %}' .
      '{% extends "base.njk" %}' .
      '{% else %}' .
      '{% extends "base2.njk" %}' .
      '{% endif %}' .
      '{% block block1 %}HELLO{% endblock %}',
      'FooHELLOBazFizzle' );

    equal(
      '{% if false %}' .
      '{% extends "base.njk" %}' .
      '{% else %}' .
      '{% extends "base2.njk" %}' .
      '{% endif %}' .
      '{% block item %}hello{{ item }}{% endblock %}',
      'hello1hello2' );
  };

  subtest 'should error if same block is defined multiple times' => sub {
    my $ok = eval {
      render(
        '{% extends "simple-base.njk" %}' .
        '{% block test %}{% endblock %}' .
        '{% block test %}{% endblock %}' );
      1;
    };
    ok( !$ok, 'render dies' );
    like( err_message($@), qr/Block "test" defined more than once\./ );
  };

  subtest 'should render nested blocks in child template' => sub {
    equal(
      '{% extends "base.njk" %}' .
      '{% block block1 %}{% block nested %}BAR{% endblock %}{% endblock %}',
      'FooBARBazFizzle' );
  };

  subtest 'should render parent blocks with super()' => sub {
    equal(
      '{% extends "base.njk" %}' .
      '{% block block1 %}{{ super() }}BAR{% endblock %}',
      'FooBarBARBazFizzle' );

    # two levels of `super` should work
    equal(
      '{% extends "base-inherit.njk" %}' .
      '{% block block1 %}*{{ super() }}*{% endblock %}',
      'Foo**Bar**BazFizzle' );
  };

  subtest 'should let super() see global vars from child template' => sub {
    equal(
      '{% extends "base-show.njk" %}{% set var = "child" %}' .
      '{% block main %}{{ super() }}{% endblock %}',
      'child' );
  };

  subtest 'should not let super() see vars from child block' => sub {
    equal(
      '{% extends "base-show.njk" %}' .
      '{% block main %}{% set var = "child" %}{{ super() }}{% endblock %}',
      '' );
  };

  subtest 'should let child templates access parent global scope' => sub {
    equal(
      '{% extends "base-set.njk" %}' .
      '{% block main %}{{ var }}{% endblock %}',
      'parent' );
  };

  subtest 'should not let super() modify calling scope' => sub {
    equal(
      '{% extends "base-set-inside-block.njk" %}' .
      '{% block main %}{{ super() }}{{ var }}{% endblock %}',
      '' );
  };

  subtest 'should not let child templates set vars in parent scope' => sub {
    equal(
      '{% extends "base-set-and-show.njk" %}' .
      '{% block main %}{% set var = "child" %}{% endblock %}',
      'parent' );
  };

  subtest 'should render blocks in their own scope' => sub {
    equal(
      '{% set var = "parent" %}' .
      '{% block main %}{% set var = "inner" %}{% endblock %}' .
      '{{ var }}',
      'parent' );
  };

  subtest 'should include templates' => sub {
    equal( 'hello world {% include "include.njk" %}',
      'hello world FooInclude ' );
  };

  subtest 'should include 130 templates without call stack size exceed' => sub {
    # JS: new Array(131).join('FooInclude \n') -- that string repeated 130
    # times. Perl's core recursion-depth warning (deep recursion on
    # Lib::async_iter, >100 frames) fires on STDERR for this one but does not
    # affect the result -- see the report for why that is noted, not TODO'd.
    my $one = 'FooInclude ' . "\n";
    equal( '{% include "includeMany.njk" %}', $one x 130 );
  };

  subtest 'should include templates with context' => sub {
    equal( 'hello world {% include "include.njk" %}',
      { name => 'james' },
      'hello world FooInclude james' );
  };

  subtest 'should include templates that can see including scope, but not write to it' => sub {
    equal( '{% set var = 1 %}{% include "include-set.njk" %}{{ var }}', "12\n1" );
  };

  subtest 'should include templates dynamically' => sub {
    equal( 'hello world {% include tmpl %}',
      { name => 'thedude', tmpl => 'include.njk' },
      'hello world FooInclude thedude' );
  };

  subtest 'should include templates dynamically based on a set var' => sub {
    equal( 'hello world {% set tmpl = "include.njk" %}{% include tmpl %}',
      { name => 'thedude' },
      'hello world FooInclude thedude' );
  };

  subtest 'should include templates dynamically based on an object attr' => sub {
    equal( 'hello world {% include data.tmpl %}',
      { name => 'thedude', data => { tmpl => 'include.njk' } },
      'hello world FooInclude thedude' );
  };

  subtest 'should throw an error when including a file that does not exist' => sub {
    my ( $err, $res ) = render(
      '{% include "missing.njk" %}', {}, { noThrow => 1 } );
    is( $res, undef );
    like( err_message($err), qr/template not found: missing\.njk/ );
  };

  subtest 'should fail silently on missing templates if requested' => sub {
    equal( 'hello world {% include "missing.njk" ignore missing %}',
      'hello world ' );

    equal( 'hello world {% include "missing.njk" ignore missing %}',
      { name => 'thedude' },
      'hello world ' );
  };

  # This test checks that this issue is resolved:
  # http://stackoverflow.com/questions/21777058/loop-index-in-included-nunjucks-file
  subtest 'should have access to "loop" inside an include' => sub {
    equal( '{% for item in [1,2,3] %}{% include "include-in-loop.njk" %}{% endfor %}',
      "1,0,true\n2,1,false\n3,2,false\n" );

    equal( '{% for k,v in items %}{% include "include-in-loop.njk" %}{% endfor %}',
      { items => { a => 'A', b => 'B' } },
      "1,0,true\n2,1,false\n" );
  };

  subtest 'should maintain nested scopes' => sub {
    equal(
      '{% for i in [1,2] %}' .
      '{% for i in [3,4] %}{{ i }}{% endfor %}' .
      '{{ i }}{% endfor %}',
      '341342' );
  };

  subtest 'should allow blocks in for loops' => sub {
    equal(
      '{% extends "base2.njk" %}' .
      '{% block item %}hello{{ item }}{% endblock %}',
      'hello1hello2' );
  };

  subtest 'should make includes inherit scope' => sub {
    equal(
      '{% for item in [1,2] %}' .
      '{% include "item.njk" %}' .
      '{% endfor %}',
      'showing 1showing 2' );
  };

  subtest 'should compile a set block' => sub {
    equal( '{% set username = "foo" %}{{ username }}',
      { username => 'james' },
      'foo' );

    equal( '{% set x, y = "foo" %}{{ x }}{{ y }}',
      'foofoo' );

    equal( '{% set x = 1 + 2 %}{{ x }}',
      '3' );

    equal( '{% for i in [1] %}{% set foo=1 %}{% endfor %}{{ foo }}',
      { foo => 2 },
      '2' );

    equal( '{% include "set.njk" %}{{ foo }}',
      { foo => 'bar' },
      'bar' );

    equal( '{% set username = username + "pasta" %}{{ username }}',
      { username => 'basta' },
      'bastapasta' );

    # `set` should only set within its current scope
    equal(
      '{% for i in [1] %}{% set val=5 %}{% endfor %}' .
      '{{ val }}',
      '' );

    equal(
      '{% for i in [1,2,3] %}' .
      '{% if not val %}{% set val=5 %}{% endif %}' .
      '{% set val=val+1 %}{{ val }}' .
      '{% endfor %}' .
      'afterwards: {{ val }}',
      '678afterwards: ' );

    # however, like Python, if a variable has been set in an
    # above scope, any other set should correctly resolve to
    # that frame
    equal(
      '{% set val=1 %}' .
      '{% for i in [1] %}{% set val=5 %}{% endfor %}' .
      '{{ val }}',
      '5' );

    equal(
      '{% set val=5 %}' .
      '{% for i in [1,2,3] %}' .
      '{% set val=val+1 %}{{ val }}' .
      '{% endfor %}' .
      'afterwards: {{ val }}',
      '678afterwards: 8' );
  };

  subtest 'should compile set with frame references' => sub {
    equal( '{% set username = user.name %}{{ username }}',
      { user => { name => 'james' } },
      'james' );
  };

  subtest 'should compile set assignments of the same variable' => sub {
    equal(
      '{% set x = "hello" %}' .
      '{% if false %}{% set x = "world" %}{% endif %}' .
      '{{ x }}',
      'hello' );

    equal(
      '{% set x = "blue" %}' .
      '{% if true %}{% set x = "green" %}{% endif %}' .
      '{{ x }}',
      'green' );
  };

  subtest 'should compile block-set' => sub {
    equal(
      '{% set block_content %}{% endset %}' .
      '{{ block_content }}',
      '' );

    # Capture blocks inside macros were printing to the main buffer instead of
    # the temporary one, see https://github.com/mozilla/nunjucks/issues/914.
    equal(
      '{%- macro foo(bar) -%}' .
      '{%- set test -%}foo{%- endset -%}' .
      '{{ bar }}{{ test }}' .
      '{%- endmacro -%}' .
      '{{ foo("bar") }}',
      'barfoo' );

    equal(
      '{% set block_content %}test string{% endset %}' .
      '{{ block_content }}',
      'test string' );

    equal(
      '{% set block_content %}' .
      '{% for item in [1, 2, 3] %}' .
      '{% include "item.njk" %} ' .
      '{% endfor %}' .
      '{% endset %}' .
      '{{ block_content }}',
      'showing 1 showing 2 showing 3 ' );

    my ( $err, $res ) = render(
      '{% set block_content %}' .
      '{% set inner_block_content %}' .
      '{% for i in [1, 2, 3] %}' .
      'item {{ i }} ' .
      '{% endfor %}' .
      '{% endset %}' .
      '{% for i in [1, 2, 3] %}' .
      'inner {{i}}: "{{ inner_block_content }}" ' .
      '{% endfor %}' .
      '{% endset %}' .
      '{{ block_content | safe }}',
      undef, { noThrow => 1 } );
    is( $res,
      'inner 1: "item 1 item 2 item 3 " ' .
      'inner 2: "item 1 item 2 item 3 " ' .
      'inner 3: "item 1 item 2 item 3 " ' );

    equal(
      '{% set x,y,z %}' .
      'cool' .
      '{% endset %}' .
      '{{ x }} {{ y }} {{ z }}',
      'cool cool cool' );
  };

  subtest 'should compile block-set wrapping an inherited block' => sub {
    equal(
      '{% extends "base-set-wraps-block.njk" %}' .
      '{% block somevar %}foo{% endblock %}',
      "foo\n" );
  };

  subtest 'should throw errors' => sub {
    my ( $err, $res ) = render(
      '{% from "import.njk" import boozle %}', {}, { noThrow => 1 } );
    like( err_message($err), qr/cannot import 'boozle'/ );
  };

  subtest 'should allow custom tag compilation' => sub {
    # JS: function TestExtension() { this.tags = ['test']; this.parse = ...;
    # this.run = ...; } -- see Test::Nunjucks::Util::_Extension's header for
    # the this-less-closure bridge this and the extension tests below use.
    my $ext;
    $ext = Test::Nunjucks::Util::_Extension->new(
      tags  => ['test'],
      parse => sub {
        my ( $self, $parser, $nodes ) = @_;
        $parser->advance_after_block_end;
        my $content = $parser->parse_until_blocks('endtest');
        my $tag = "${nodes}::CallExtension"->new( $self, 'run', undef, [$content] );
        $parser->advance_after_block_end;
        return $tag;
      },
      run => sub {
        my ( $self, $context, $content ) = @_;
        # Reverse the string
        return join( '', reverse split //, $content->() );
      },
    );

    equal( '{% test %}123456789{% endtest %}', undef,
      { extensions => { TestExtension => $ext } },
      '987654321' );
  };

  subtest 'should allow custom tag compilation without content' => sub {
    my $ext;
    $ext = Test::Nunjucks::Util::_Extension->new(
      tags  => ['test'],
      parse => sub {
        my ( $self, $parser, $nodes ) = @_;
        my $tok  = $parser->next_token;
        my $args = $parser->parse_signature( undef, 1 );    # tolerate no args
        $parser->advance_after_block_end( $tok->value );
        return "${nodes}::CallExtension"->new( $self, 'run', $args, undef );
      },
      run => sub {
        my ( $self, $context, $arg1 ) = @_;
        # Reverse the string
        return join( '', reverse split //, $arg1 );
      },
    );

    equal( '{% test "123456" %}', undef,
      { extensions => { TestExtension => $ext } },
      '654321' );
  };

  subtest 'should allow complicated custom tag compilation' => sub {
    my $ext;
    $ext = Test::Nunjucks::Util::_Extension->new(
      tags  => ['test'],
      parse => sub {
        my ( $self, $parser, $nodes, $lexer ) = @_;
        my $intermediate;

        $parser->advance_after_block_end;
        my $body = $parser->parse_until_blocks( 'intermediate', 'endtest' );

        if ( $parser->skip_symbol('intermediate') ) {
          $parser->skip( $lexer->TOKEN_BLOCK_END );
          $intermediate = $parser->parse_until_blocks('endtest');
        }

        $parser->advance_after_block_end;
        return "${nodes}::CallExtension"->new( $self, 'run', undef, [ $body, $intermediate ] );
      },
      run => sub {
        my ( $self, $context, $body, $intermediate ) = @_;
        my $output = join( ',', split //, $body->() );
        if ($intermediate) {
          # Reverse the string.
          $output .= join( '', reverse split //, $intermediate->() );
        }
        return $output;
      },
    );

    equal( '{% test %}abcdefg{% endtest %}', undef,
      { extensions => { TestExtension => $ext } },
      'a,b,c,d,e,f,g' );

    equal( '{% test %}abcdefg{% intermediate %}second half{% endtest %}',
      undef,
      { extensions => { TestExtension => $ext } },
      'a,b,c,d,e,f,gflah dnoces' );
  };

  subtest 'should allow custom tag with args compilation' => sub {
    my $ext;
    $ext = Test::Nunjucks::Util::_Extension->new(
      tags  => ['test'],
      parse => sub {
        my ( $self, $parser, $nodes ) = @_;
        my $tok = $parser->next_token;

        # passing true makes it tolerate when no args exist
        my $args = $parser->parse_signature(1);
        $parser->advance_after_block_end( $tok->value );

        my $body = $parser->parse_until_blocks('endtest');
        $parser->advance_after_block_end;

        return "${nodes}::CallExtension"->new( $self, 'run', $args, [$body] );
      },
      run => sub {
        my ( $self, $context, $prefix, $kwargs, $body ) = @_;
        if ( ref($prefix) eq 'CODE' ) {
          $body   = $prefix;
          $prefix = '';
          $kwargs = {};
        }
        elsif ( ref($kwargs) eq 'CODE' ) {
          $body   = $kwargs;
          $kwargs = {};
        }

        my $output = $prefix . join( '', reverse split //, $body->() );
        if ( $kwargs->{cutoff} ) {
          $output = substr( $output, 0, $kwargs->{cutoff} );
        }

        return $output;
      },
    );

    my $opts = { extensions => { TestExtension => $ext } };

    equal( '{% test %}foobar{% endtest %}', undef, $opts, 'raboof' );

    equal( '{% test("biz") %}foobar{% endtest %}', undef, $opts, 'bizraboof' );

    equal( '{% test("biz", cutoff=5) %}foobar{% endtest %}', undef, $opts, 'bizra' );
  };

  subtest 'should autoescape by default' => sub {
    equal( '{{ foo }}', { foo => q{"'<>&} }, '&quot;&#39;&lt;&gt;&amp;' );
  };

  subtest 'should autoescape if autoescape is on' => sub {
    equal( '{{ foo }}',
      { foo => q{"'<>&} },
      { autoescape => true },
      '&quot;&#39;&lt;&gt;&amp;' );

    equal( '{{ foo|reverse }}',
      { foo => q{"'<>&} },
      { autoescape => true },
      '&amp;&gt;&lt;&#39;&quot;' );

    equal( '{{ foo|reverse|safe }}',
      { foo => q{"'<>&} },
      { autoescape => true },
      q{&><'"} );

    equal( '{{ foo }}',
      { foo => undef },
      { autoescape => true },
      '' );

    equal( '{{ foo }}',
      { foo => ['<p>foo</p>'] },
      { autoescape => true },
      '&lt;p&gt;foo&lt;/p&gt;' );

    todo_equal( 'no ADR for JS-style toString() coercion of a plain hashref value',
      '{{ foo }}',
      { foo => { toString => sub { return '<p>foo</p>' } } },
      { autoescape => true },
      '&lt;p&gt;foo&lt;/p&gt;' );

    equal( '{{ foo | safe }}',
      { foo => Text::Nunjucks::Runtime->None },
      { autoescape => true },
      '' );

    equal( '{{ foo | safe }}',
      { foo => '<p>foo</p>' },
      { autoescape => true },
      '<p>foo</p>' );

    equal( '{{ foo | safe }}',
      { foo => ['<p>foo</p>'] },
      { autoescape => true },
      '<p>foo</p>' );

    todo_equal( 'JS object with custom toString: mapping pending k44',
      '{{ foo | safe }}',
      { foo => { toString => sub { return '<p>foo</p>' } } },
      { autoescape => true },
      '<p>foo</p>' );
  };

  subtest 'should not autoescape safe strings' => sub {
    equal( '{{ foo|safe }}',
      { foo => q{"'<>&} },
      { autoescape => true },
      q{"'<>&} );
  };

  subtest 'should not autoescape macros' => sub {
    is( ( render(
          '{% macro foo(x, y) %}{{ x }} and {{ y }}{% endmacro %}' .
          '{{ foo("<>&", "<>") }}',
          undef, { autoescape => true } ) )[1],
      '&lt;&gt;&amp; and &lt;&gt;' );

    my ( undef, $res ) = render(
      '{% macro foo(x, y) %}{{ x|safe }} and {{ y }}{% endmacro %}' .
      '{{ foo("<>&", "<>") }}',
      undef, { autoescape => true, noThrow => 1 } );
    is( $res, '<>& and &lt;&gt;' );
  };

  subtest 'should not autoescape super()' => sub {
    is( ( render(
          '{% extends "base3.njk" %}' .
          '{% block block1 %}{{ super() }}{% endblock %}',
          undef, { autoescape => true } ) )[1],
      '<b>Foo</b>' );
  };

  subtest 'should autoescape backslashes' => sub {
    equal( '{{ foo }}',
      { foo => "foo \\' bar" },
      { autoescape => true },
      'foo &#92;&#39; bar' );
  };

  subtest 'should not autoescape when extension set false' => sub {
    my $ext;
    $ext = Test::Nunjucks::Util::_Extension->new(
      tags       => ['test'],
      autoescape => false,
      parse      => sub {
        my ( $self, $parser, $nodes ) = @_;
        my $tok  = $parser->next_token;
        my $args = $parser->parse_signature( undef, 1 );
        $parser->advance_after_block_end( $tok->value );
        return "${nodes}::CallExtension"->new( $self, 'run', $args, undef );
      },
      run => sub {
        # Reverse the string
        return '<b>Foo</b>';
      },
    );

    is( ( render( '{% test "123456" %}', undef,
          { extensions => { TestExtension => $ext }, autoescape => true } ) )[1],
      '<b>Foo</b>' );
  };

  subtest 'should pass context as this to filters' => sub {
  TODO: {
      # ADR 0009: a sync filter is called (@args), no this/context -- the
      # closest faithful port of `function(foo) { return foo + this.lookup
      # ('bar'); }` has no `this` to reach for, so it fails outright rather
      # than silently computing the right number a different way.
      local $TODO = "ADR 0009: sync filters get no Context this-binding (this.lookup('bar') is unreachable)";
      my ( undef, $res ) = render( '{{ foo | hallo }}',
        { foo => 1, bar => 2 },
        {
          filters => {
            hallo => sub {
              my ( $foo, $context ) = @_;
              return $foo + $context->lookup('bar');
            },
          },
          noThrow => 1,
        } );
      is( $res, '3' );
    }
  };

  subtest 'should render regexs' => sub {
    # ADR 0013 / k43: the template `/.../flags` literal compiles to
    # $runtime->make_regex(body, flags); the resulting Regex object's
    # stringification is /body/flags (RegExp.prototype.toString). Auto-escape
    # must NOT touch a literal regex's slashes/backslashes; the cases here
    # cover the two upstream mocha assertions verbatim.
    equal( '{{ r/name [0-9] \\// }}', {}, { autoescape => false },
      '/name [0-9] \\//' );

    equal( '{{ r/x/gi }}',
      '/x/gi' );
  };

  subtest 'should throw an error when {% call %} is passed an object that is not a function' => sub {
    my ( $err, $res ) = render(
      '{% call foo() %}{% endcall %}',
      { foo => 'bar' }, { noThrow => 1 } );
    is( $res, undef );
    like( err_message($err), qr/Unable to call `\w+`, which is not a function/ );
  };

  subtest 'should throw an error when including a file that calls an undefined macro' => sub {
    my ( $err, $res ) = render(
      '{% include "undefined-macro.njk" %}',
      {}, { noThrow => 1 } );
    is( $res, undef );
    like( err_message($err), qr/Unable to call `\w+`, which is undefined or falsey/ );
  };

  subtest 'should throw an error when including a file that calls an undefined macro even inside {% if %} tag' => sub {
    my ( $err, $res ) = render(
      '{% if true %}{% include "undefined-macro.njk" %}{% endif %}',
      {}, { noThrow => 1 } );
    is( $res, undef );
    like( err_message($err), qr/Unable to call `\w+`, which is undefined or falsey/ );
  };

  subtest 'should throw an error when including a file that imports macro that calls an undefined macro' => sub {
    my ( $err, $res ) = render(
      '{% include "import-macro-call-undefined-macro.njk" %}',
      { list => [ 1, 2, 3 ] }, { noThrow => 1 } );
    is( $res, undef );
    like( err_message($err), qr/Unable to call `\w+`, which is undefined or falsey/ );
  };

  subtest 'should control whitespaces correctly' => sub {
    equal(
      '{% if true -%}{{"hello"}} {{"world"}}{% endif %}',
      'hello world' );

    equal(
      '{% if true -%}{% if true %} {{"hello"}} {{"world"}}'
      . '{% endif %}{% endif %}',
      ' hello world' );

    equal(
      '{% if true -%}{# comment #} {{"hello"}}{% endif %}',
      ' hello' );
  };

  subtest 'should control expression whitespaces correctly' => sub {
    equal( "Well, {{- ' hello, ' -}} my friend",
      'Well, hello, my friend' );

    equal( ' {{ 2 + 2 }} ', ' 4 ' );

    equal( ' {{-2 + 2 }} ', '4 ' );

    equal( ' {{ -2 + 2 }} ', ' 0 ' );

    equal( ' {{ 2 + 2 -}} ', ' 4' );
  };

  subtest 'should get right value when macro parameter conflict with global macro name' => sub {
    my ( undef, $res ) = render(
      '{# macro1 and macro2 definition #}' .
      '{% macro macro1() %}' .
      '{% endmacro %}' .
      '' .
      '{% macro macro2(macro1="default") %}' .
      '{{macro1}}' .
      '{% endmacro %}' .
      '' .
      '{# calling macro2 #}' .
      '{{macro2("this should be outputted") }}' );
    ( my $trimmed = $res ) =~ s/^\s+|\s+$//g;
    is( $trimmed, 'this should be outputted' );
  };

  subtest 'should get right value when macro include macro' => sub {
    my ( undef, $res ) = render(
      '{# macro1 and macro2 definition #}' .
      '{% macro macro1() %} foo' .
      '{% endmacro %}' .
      '' .
      '{% macro macro2(text="default") %}' .
      '{{macro1()}}' .
      '{% endmacro %}' .
      '' .
      '{# calling macro2 #}' .
      '{{macro2("this should not be outputted") }}' );
    ( my $trimmed = $res ) =~ s/^\s+|\s+$//g;
    is( $trimmed, 'foo' );
  };

  subtest 'should allow access to outer scope in call blocks' => sub {
    my ( undef, $res ) = render(
      '{% macro inside() %}' .
      '{{ caller() }}' .
      '{% endmacro %}' .
      '{% macro outside(var) %}' .
      '{{ var }}' . "\n" .
      '{% call inside() %}' .
      '{{ var }}' .
      '{% endcall %}' .
      '{% endmacro %}' .
      '{{ outside("foobar") }}' );
    ( my $trimmed = $res ) =~ s/^\s+|\s+$//g;
    is( $trimmed, "foobar\nfoobar" );
  };

  subtest 'should not leak scope from call blocks to parent' => sub {
    my ( undef, $res ) = render(
      '{% set var = "expected" %}' .
      '{% macro inside() %}' .
      '{% set var = "incorrect-value" %}' .
      '{{ caller() }}' .
      '{% endmacro %}' .
      '{% macro outside() %}' .
      '{% call inside() %}' .
      '{% endcall %}' .
      '{% endmacro %}' .
      '{{ outside() }}' .
      '{{ var }}' );
    ( my $trimmed = $res ) =~ s/^\s+|\s+$//g;
    is( $trimmed, 'expected' );
  };

  # isSlim tests -- see the earlier note; this port is never "slim".
  subtest 'should import template objects' => sub {
    my $tmpl = Text::Nunjucks::Template->new(
      '{% macro foo() %}Inside a macro{% endmacro %}' .
      '{% set bar = "BAZ" %}' );

    equal(
      '{% import tmpl as imp %}' .
      '{{ imp.foo() }} {{ imp.bar }}',
      { tmpl => $tmpl },
      'Inside a macro BAZ' );

    equal(
      '{% from tmpl import foo as baz, bar %}' .
      '{{ bar }} {{ baz() }}',
      { tmpl => $tmpl },
      'BAZ Inside a macro' );
  };

  subtest 'should inherit template objects' => sub {
    my $tmpl = Text::Nunjucks::Template->new(
      'Foo{% block block1 %}Bar{% endblock %}' .
      '{% block block2 %}Baz{% endblock %}Whizzle' );

    equal( 'hola {% extends tmpl %} fizzle mumble',
      { tmpl => $tmpl },
      'FooBarBazWhizzle' );

    equal(
      '{% extends tmpl %}' .
      '{% block block1 %}BAR{% endblock %}' .
      '{% block block2 %}BAZ{% endblock %}',
      { tmpl => $tmpl },
      'FooBARBAZWhizzle' );
  };

  subtest 'should include template objects' => sub {
    my $tmpl = Text::Nunjucks::Template->new('FooInclude {{ name }}');

    equal( 'hello world {% include tmpl %}',
      { name => 'thedude', tmpl => $tmpl },
      'hello world FooInclude thedude' );
  };

  subtest 'should throw an error when invalid expression whitespaces are used' => sub {
    my ( $err, $res ) = render(
      ' {{ 2 + 2- }}', {}, { noThrow => 1 } );
    is( $res, undef );
    like( err_message($err), qr/unexpected token: \}\}/ );
  };

};

subtest 'the filter tag' => sub {

  subtest 'should apply the title filter to the body' => sub {
    equal( '{% filter title %}may the force be with you{% endfilter %}',
      'May The Force Be With You' );
  };

  subtest 'should apply the replace filter to the body' => sub {
    equal( '{% filter replace("force", "forth") %}may the force be with you{% endfilter %}',
      'may the forth be with you' );
  };

  subtest 'should work with variables in the body' => sub {
    equal( '{% set foo = "force" %}{% filter replace("force", "forth") %}may the {{ foo }} be with you{% endfilter %}',
      'may the forth be with you' );
  };

  subtest 'should work with blocks in the body' => sub {
    equal( '{% extends "filter-block.html" %}' .
      '{% block block1 %}force{% endblock %}',
      "may the forth be with you\n" );
  };

};

done_testing;

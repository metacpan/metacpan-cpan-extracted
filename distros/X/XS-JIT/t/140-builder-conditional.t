#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use XS::JIT;
use XS::JIT::Builder;

my $cache_dir = tempdir(CLEANUP => 1);

subtest 'if/else with gt' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('check_positive')
      ->xs_preamble
      ->declare_sv('arg', 'ST(0)')
      ->conditional({
          if => {
              key => 'arg',
              gt  => '0',
              then => { line => 'XSRETURN_IV(1);' }
          },
          else => {
              then => { line => 'XSRETURN_IV(0);' }
          }
      })
      ->xs_end;

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'TestGt',
        cache_dir => $cache_dir,
        functions => { 'TestGt::check' => { source => 'check_positive', is_xs_native => 1 } }
    ), 'compile gt conditional');

    is(TestGt::check(5), 1, 'positive returns 1');
    is(TestGt::check(-3), 0, 'negative returns 0');
    is(TestGt::check(0), 0, 'zero returns 0');
};

subtest 'if/elsif/else chain' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('classify')
      ->xs_preamble
      ->declare_sv('arg', 'ST(0)')
      ->conditional({
          if => {
              key => 'arg',
              gt  => '0',
              then => { line => 'XSRETURN_IV(1);' }
          },
          elsif => {
              key => 'arg',
              lt  => '0',
              then => { line => 'XSRETURN_IV(-1);' }
          },
          else => {
              then => { line => 'XSRETURN_IV(0);' }
          }
      })
      ->xs_end;

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'TestElsif',
        cache_dir => $cache_dir,
        functions => { 'TestElsif::classify' => { source => 'classify', is_xs_native => 1 } }
    ), 'compile elsif conditional');

    is(TestElsif::classify(10), 1, 'positive returns 1');
    is(TestElsif::classify(-5), -1, 'negative returns -1');
    is(TestElsif::classify(0), 0, 'zero returns 0');
};

subtest 'string eq comparison' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('check_type')
      ->xs_preamble
      ->declare_sv('type', 'ST(0)')
      ->conditional({
          if => {
              key => 'type',
              eq  => 'int',
              then => { line => 'XSRETURN_IV(1);' }
          },
          elsif => {
              key => 'type',
              eq  => 'str',
              then => { line => 'XSRETURN_IV(2);' }
          },
          else => {
              then => { line => 'XSRETURN_IV(0);' }
          }
      })
      ->xs_end;

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'TestEq',
        cache_dir => $cache_dir,
        functions => { 'TestEq::check' => { source => 'check_type', is_xs_native => 1 } }
    ), 'compile eq conditional');

    is(TestEq::check('int'), 1, 'int returns 1');
    is(TestEq::check('str'), 2, 'str returns 2');
    is(TestEq::check('other'), 0, 'other returns 0');
};

subtest 'given/when hash style' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('dispatch_type')
      ->xs_preamble
      ->declare_sv('type', 'ST(0)')
      ->conditional({
          given => {
              key => 'type',
              when => {
                  int     => { line => 'XSRETURN_IV(1);' },
                  str     => { line => 'XSRETURN_IV(2);' },
                  array   => { line => 'XSRETURN_IV(3);' },
                  default => { line => 'XSRETURN_IV(0);' }
              }
          }
      })
      ->xs_end;

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'TestGiven',
        cache_dir => $cache_dir,
        functions => { 'TestGiven::dispatch' => { source => 'dispatch_type', is_xs_native => 1 } }
    ), 'compile given/when');

    is(TestGiven::dispatch('int'), 1, 'int');
    is(TestGiven::dispatch('str'), 2, 'str');
    is(TestGiven::dispatch('array'), 3, 'array');
    is(TestGiven::dispatch('other'), 0, 'default');
};

subtest 'given/when array style' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('match_pattern')
      ->xs_preamble
      ->declare_sv('val', 'ST(0)')
      ->conditional({
          given => {
              key => 'val',
              when => [
                  { m => 'foo', then => { line => 'XSRETURN_IV(1);' } },
                  { m => 'bar', then => { line => 'XSRETURN_IV(2);' } },
              ],
              default => { line => 'XSRETURN_IV(0);' }
          }
      })
      ->xs_end;

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'TestGivenArray',
        cache_dir => $cache_dir,
        functions => { 'TestGivenArray::match' => { source => 'match_pattern', is_xs_native => 1 } }
    ), 'compile given/when array');

    is(TestGivenArray::match('foobar'), 1, 'matches foo');
    is(TestGivenArray::match('barbaz'), 2, 'matches bar');  # changed from barfoo which also matches foo
    is(TestGivenArray::match('xyz'), 0, 'default');
};

subtest 'ne (not equal)' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('not_admin')
      ->xs_preamble
      ->declare_sv('role', 'ST(0)')
      ->conditional({
          if => {
              key => 'role',
              ne  => 'admin',
              then => { line => 'XSRETURN_IV(1);' }
          },
          else => {
              then => { line => 'XSRETURN_IV(0);' }
          }
      })
      ->xs_end;

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'TestNe',
        cache_dir => $cache_dir,
        functions => { 'TestNe::check' => { source => 'not_admin', is_xs_native => 1 } }
    ), 'compile ne conditional');

    is(TestNe::check('user'), 1, 'user is not admin');
    is(TestNe::check('admin'), 0, 'admin is admin');
};

subtest 'lt (less than)' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('is_negative')
      ->xs_preamble
      ->declare_sv('arg', 'ST(0)')
      ->conditional({
          if => {
              key => 'arg',
              lt  => '0',
              then => { line => 'XSRETURN_IV(1);' }
          },
          else => {
              then => { line => 'XSRETURN_IV(0);' }
          }
      })
      ->xs_end;

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'TestLt',
        cache_dir => $cache_dir,
        functions => { 'TestLt::check' => { source => 'is_negative', is_xs_native => 1 } }
    ), 'compile lt conditional');

    is(TestLt::check(-5), 1, 'negative');
    is(TestLt::check(0), 0, 'zero');
    is(TestLt::check(5), 0, 'positive');
};

subtest 'multiple elsif (array)' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('grade')
      ->xs_preamble
      ->declare_sv('arg', 'ST(0)')
      ->conditional({
          if => {
              key => 'arg',
              gt  => '89',
              then => { line => 'XSRETURN_PV("A");' }
          },
          elsif => [
              { key => 'arg', gt => '79', then => { line => 'XSRETURN_PV("B");' } },
              { key => 'arg', gt => '69', then => { line => 'XSRETURN_PV("C");' } },
              { key => 'arg', gt => '59', then => { line => 'XSRETURN_PV("D");' } },
          ],
          else => {
              then => { line => 'XSRETURN_PV("F");' }
          }
      })
      ->xs_end;

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'TestGrade',
        cache_dir => $cache_dir,
        functions => { 'TestGrade::get' => { source => 'grade', is_xs_native => 1 } }
    ), 'compile multiple elsif');

    is(TestGrade::get(95), 'A', '95 is A');
    is(TestGrade::get(85), 'B', '85 is B');
    is(TestGrade::get(75), 'C', '75 is C');
    is(TestGrade::get(65), 'D', '65 is D');
    is(TestGrade::get(50), 'F', '50 is F');
};

subtest 'return_iv action' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('double_if_positive')
      ->xs_preamble
      ->declare_sv('arg', 'ST(0)')
      ->declare_iv('num', 'SvIV(arg)')
      ->conditional({
          if => {
              key => 'arg',
              gt  => '0',
              then => { return_iv => 'num * 2' }
          },
          else => {
              then => { return_iv => '0' }
          }
      })
      ->xs_end;

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'TestReturnIv',
        cache_dir => $cache_dir,
        functions => { 'TestReturnIv::calc' => { source => 'double_if_positive', is_xs_native => 1 } }
    ), 'compile return_iv action');

    is(TestReturnIv::calc(5), 10, '5 doubled');
    is(TestReturnIv::calc(-3), 0, 'negative returns 0');
};

subtest 'exists expression' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('check_defined')
      ->xs_preamble
      ->declare_sv('val', 'ST(0)')
      ->conditional({
          if => {
              key    => 'val',
              exists => 1,
              then   => { line => 'XSRETURN_IV(1);' }
          },
          else => {
              then => { line => 'XSRETURN_IV(0);' }
          }
      })
      ->xs_end;

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'TestExists',
        cache_dir => $cache_dir,
        functions => { 'TestExists::check' => { source => 'check_defined', is_xs_native => 1 } }
    ), 'compile exists conditional');

    is(TestExists::check('hello'), 1, 'defined string');
    is(TestExists::check(42), 1, 'defined number');
    is(TestExists::check(undef), 0, 'undef');
};

# Complex nested example: classify_point(x, y)
# Returns:
#   1 = first quadrant (x > 0 AND y > 0)
#   2 = second quadrant (x < 0 AND y > 0)
#   3 = third quadrant (x < 0 AND y < 0)
#   4 = fourth quadrant (x > 0 AND y < 0)
#   5 = positive x-axis (x > 0 AND y == 0)
#   6 = negative x-axis (x < 0 AND y == 0)
#   7 = positive y-axis (x == 0 AND y > 0)
#   8 = negative y-axis (x == 0 AND y < 0)
#   0 = origin (x == 0 AND y == 0)
subtest 'complex nested: quadrant classifier with AND chaining' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('classify_point')
      ->xs_preamble
      ->declare_sv('x_sv', 'ST(0)')
      ->declare_sv('y_sv', 'ST(1)')
      ->declare_iv('x', 'SvIV(x_sv)')
      ->declare_iv('y', 'SvIV(y_sv)')
      # First quadrant: x > 0 AND y > 0
      ->conditional({
          if => {
              key => 'x_sv',
              gt  => '0',
              and => {
                  key => 'y_sv',
                  gt  => '0'
              },
              then => { return_iv => '1' }
          }
      })
      # Second quadrant: x < 0 AND y > 0
      ->conditional({
          if => {
              key => 'x_sv',
              lt  => '0',
              and => {
                  key => 'y_sv',
                  gt  => '0'
              },
              then => { return_iv => '2' }
          }
      })
      # Third quadrant: x < 0 AND y < 0
      ->conditional({
          if => {
              key => 'x_sv',
              lt  => '0',
              and => {
                  key => 'y_sv',
                  lt  => '0'
              },
              then => { return_iv => '3' }
          }
      })
      # Fourth quadrant: x > 0 AND y < 0
      ->conditional({
          if => {
              key => 'x_sv',
              gt  => '0',
              and => {
                  key => 'y_sv',
                  lt  => '0'
              },
              then => { return_iv => '4' }
          }
      })
      # Positive x-axis: x > 0 (y must be 0 at this point)
      ->conditional({
          if => {
              key => 'x_sv',
              gt  => '0',
              then => { return_iv => '5' }
          }
      })
      # Negative x-axis: x < 0
      ->conditional({
          if => {
              key => 'x_sv',
              lt  => '0',
              then => { return_iv => '6' }
          }
      })
      # Positive y-axis: y > 0 (x must be 0 at this point)
      ->conditional({
          if => {
              key => 'y_sv',
              gt  => '0',
              then => { return_iv => '7' }
          }
      })
      # Negative y-axis: y < 0
      ->conditional({
          if => {
              key => 'y_sv',
              lt  => '0',
              then => { return_iv => '8' }
          }
      })
      # Origin
      ->line('XSRETURN_IV(0);')
      ->xs_end;

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'TestQuadrant',
        cache_dir => $cache_dir,
        functions => { 'TestQuadrant::classify' => { source => 'classify_point', is_xs_native => 1 } }
    ), 'compile quadrant classifier');

    # Test all quadrants
    is(TestQuadrant::classify(5, 3), 1, 'first quadrant (5,3)');
    is(TestQuadrant::classify(-2, 4), 2, 'second quadrant (-2,4)');
    is(TestQuadrant::classify(-3, -7), 3, 'third quadrant (-3,-7)');
    is(TestQuadrant::classify(8, -2), 4, 'fourth quadrant (8,-2)');

    # Test axes
    is(TestQuadrant::classify(5, 0), 5, 'positive x-axis (5,0)');
    is(TestQuadrant::classify(-3, 0), 6, 'negative x-axis (-3,0)');
    is(TestQuadrant::classify(0, 7), 7, 'positive y-axis (0,7)');
    is(TestQuadrant::classify(0, -4), 8, 'negative y-axis (0,-4)');

    # Test origin
    is(TestQuadrant::classify(0, 0), 0, 'origin (0,0)');
};

# Complex example with OR chaining: HTTP status classifier
# Returns category based on status code OR specific status strings
subtest 'complex OR chaining: HTTP status classifier' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('http_category')
      ->xs_preamble
      ->declare_sv('status', 'ST(0)')
      # Check for string status names first using OR
      ->conditional({
          if => {
              key => 'status',
              eq  => 'ok',
              or  => {
                  key => 'status',
                  eq  => 'success'
              },
              then => { return_pv => '"2xx"' }
          }
      })
      ->conditional({
          if => {
              key => 'status',
              eq  => 'redirect',
              or  => {
                  key => 'status',
                  eq  => 'moved'
              },
              then => { return_pv => '"3xx"' }
          }
      })
      ->conditional({
          if => {
              key => 'status',
              eq  => 'not_found',
              or  => {
                  key => 'status',
                  eq  => 'forbidden',
                  or  => {
                      key => 'status',
                      eq  => 'unauthorized'
                  }
              },
              then => { return_pv => '"4xx"' }
          }
      })
      ->conditional({
          if => {
              key => 'status',
              eq  => 'error',
              or  => {
                  key => 'status',
                  eq  => 'internal_error'
              },
              then => { return_pv => '"5xx"' }
          }
      })
      # Numeric status codes - use array for multiple elsif clauses
      ->conditional({
          if => {
              key  => 'status',
              gte  => '200',
              and  => {
                  key => 'status',
                  lt  => '300'
              },
              then => { return_pv => '"2xx"' }
          },
          elsif => [
              {
                  key  => 'status',
                  gte  => '300',
                  and  => {
                      key => 'status',
                      lt  => '400'
                  },
                  then => { return_pv => '"3xx"' }
              },
              {
                  key  => 'status',
                  gte  => '400',
                  and  => {
                      key => 'status',
                      lt  => '500'
                  },
                  then => { return_pv => '"4xx"' }
              },
              {
                  key  => 'status',
                  gte  => '500',
                  and  => {
                      key => 'status',
                      lt  => '600'
                  },
                  then => { return_pv => '"5xx"' }
              },
          ],
          else => {
              then => { return_pv => '"unknown"' }
          }
      })
      ->xs_end;

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'TestHttp',
        cache_dir => $cache_dir,
        functions => { 'TestHttp::category' => { source => 'http_category', is_xs_native => 1 } }
    ), 'compile HTTP status classifier');

    # Test string statuses with OR
    is(TestHttp::category('ok'), '2xx', 'ok -> 2xx');
    is(TestHttp::category('success'), '2xx', 'success -> 2xx');
    is(TestHttp::category('redirect'), '3xx', 'redirect -> 3xx');
    is(TestHttp::category('moved'), '3xx', 'moved -> 3xx');
    is(TestHttp::category('not_found'), '4xx', 'not_found -> 4xx');
    is(TestHttp::category('forbidden'), '4xx', 'forbidden -> 4xx');
    is(TestHttp::category('unauthorized'), '4xx', 'unauthorized -> 4xx');
    is(TestHttp::category('error'), '5xx', 'error -> 5xx');
    is(TestHttp::category('internal_error'), '5xx', 'internal_error -> 5xx');

    # Test numeric codes with AND range checks
    is(TestHttp::category(200), '2xx', '200 -> 2xx');
    is(TestHttp::category(201), '2xx', '201 -> 2xx');
    is(TestHttp::category(299), '2xx', '299 -> 2xx');
    is(TestHttp::category(301), '3xx', '301 -> 3xx');
    is(TestHttp::category(404), '4xx', '404 -> 4xx');
    is(TestHttp::category(500), '5xx', '500 -> 5xx');
    is(TestHttp::category(503), '5xx', '503 -> 5xx');
    is(TestHttp::category(100), 'unknown', '100 -> unknown');
    is(TestHttp::category(600), 'unknown', '600 -> unknown');
};

# Complex example: permission checker with multiple conditions
# check_access(role, resource, action)
# Returns 1 if allowed, 0 if denied
subtest 'complex multi-arg: permission checker' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('check_access')
      ->xs_preamble
      ->declare_sv('role', 'ST(0)')
      ->declare_sv('resource', 'ST(1)')
      ->declare_sv('action', 'ST(2)')
      # Admin can do anything
      ->conditional({
          if => {
              key  => 'role',
              eq   => 'admin',
              then => { return_iv => '1' }
          }
      })
      # Editor can read/write articles
      ->conditional({
          if => {
              key => 'role',
              eq  => 'editor',
              and => {
                  key => 'resource',
                  eq  => 'article',
                  and => {
                      key => 'action',
                      eq  => 'read',
                      or  => {
                          key => 'action',
                          eq  => 'write'
                      }
                  }
              },
              then => { return_iv => '1' }
          }
      })
      # Editor can read comments
      ->conditional({
          if => {
              key => 'role',
              eq  => 'editor',
              and => {
                  key => 'resource',
                  eq  => 'comment',
                  and => {
                      key => 'action',
                      eq  => 'read'
                  }
              },
              then => { return_iv => '1' }
          }
      })
      # User can read articles and comments
      ->conditional({
          if => {
              key => 'role',
              eq  => 'user',
              and => {
                  key => 'action',
                  eq  => 'read'
              },
              then => { return_iv => '1' }
          }
      })
      # Guest can only read articles
      ->conditional({
          if => {
              key => 'role',
              eq  => 'guest',
              and => {
                  key => 'resource',
                  eq  => 'article',
                  and => {
                      key => 'action',
                      eq  => 'read'
                  }
              },
              then => { return_iv => '1' }
          }
      })
      # Default deny
      ->line('XSRETURN_IV(0);')
      ->xs_end;

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => 'TestPerm',
        cache_dir => $cache_dir,
        functions => { 'TestPerm::check' => { source => 'check_access', is_xs_native => 1 } }
    ), 'compile permission checker');

    # Admin tests
    is(TestPerm::check('admin', 'article', 'read'), 1, 'admin can read article');
    is(TestPerm::check('admin', 'article', 'delete'), 1, 'admin can delete article');
    is(TestPerm::check('admin', 'user', 'write'), 1, 'admin can write user');

    # Editor tests
    is(TestPerm::check('editor', 'article', 'read'), 1, 'editor can read article');
    is(TestPerm::check('editor', 'article', 'write'), 1, 'editor can write article');
    is(TestPerm::check('editor', 'article', 'delete'), 0, 'editor cannot delete article');
    is(TestPerm::check('editor', 'comment', 'read'), 1, 'editor can read comment');
    is(TestPerm::check('editor', 'comment', 'write'), 0, 'editor cannot write comment');

    # User tests
    is(TestPerm::check('user', 'article', 'read'), 1, 'user can read article');
    is(TestPerm::check('user', 'comment', 'read'), 1, 'user can read comment');
    is(TestPerm::check('user', 'article', 'write'), 0, 'user cannot write article');

    # Guest tests
    is(TestPerm::check('guest', 'article', 'read'), 1, 'guest can read article');
    is(TestPerm::check('guest', 'article', 'write'), 0, 'guest cannot write article');
    is(TestPerm::check('guest', 'comment', 'read'), 0, 'guest cannot read comment');
};

done_testing;

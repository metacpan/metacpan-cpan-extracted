#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use XS::JIT;
use XS::JIT::Builder;

my $cache_dir = tempdir(CLEANUP => 1);

# Test counter for unique package names
my $test_num = 0;

subtest 'basic string switch' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('get_type_id')
      ->xs_preamble
      ->declare_sv('type', 'ST(0)')
      ->switch('type', [
          { eq => 'int',   then => { return_iv => '1' } },
          { eq => 'str',   then => { return_iv => '2' } },
          { eq => 'array', then => { return_iv => '3' } },
      ], { return_iv => '0' })
      ->xs_end;

    my $pkg = 'TestSwStr' . ++$test_num;
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => { "${pkg}::get" => { source => 'get_type_id', is_xs_native => 1 } }
    ), 'compile basic string switch');

    no strict 'refs';
    is(&{"${pkg}::get"}('int'), 1, 'int returns 1');
    is(&{"${pkg}::get"}('str'), 2, 'str returns 2');
    is(&{"${pkg}::get"}('array'), 3, 'array returns 3');
    is(&{"${pkg}::get"}('unknown'), 0, 'unknown returns default 0');
    is(&{"${pkg}::get"}(''), 0, 'empty string returns default 0');
};

subtest 'string switch without default' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('color_code')
      ->xs_preamble
      ->declare_sv('color', 'ST(0)')
      ->switch('color', [
          { eq => 'red',   then => { return_iv => '1' } },
          { eq => 'green', then => { return_iv => '2' } },
          { eq => 'blue',  then => { return_iv => '3' } },
      ])
      ->line('XSRETURN_IV(-1);')
      ->xs_end;

    my $pkg = 'TestSwStrNoDefault' . ++$test_num;
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => { "${pkg}::code" => { source => 'color_code', is_xs_native => 1 } }
    ), 'compile string switch without default');

    no strict 'refs';
    is(&{"${pkg}::code"}('red'), 1, 'red returns 1');
    is(&{"${pkg}::code"}('green'), 2, 'green returns 2');
    is(&{"${pkg}::code"}('blue'), 3, 'blue returns 3');
    is(&{"${pkg}::code"}('yellow'), -1, 'unmatched falls through to -1');
};

subtest 'numeric eq switch' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('http_status')
      ->xs_preamble
      ->declare_sv('code', 'ST(0)')
      ->switch('code', [
          { eq => '200', then => { return_pv => '"OK"' } },
          { eq => '404', then => { return_pv => '"Not Found"' } },
          { eq => '500', then => { return_pv => '"Server Error"' } },
      ], { return_pv => '"Unknown"' })
      ->xs_end;

    my $pkg = 'TestSwNumEq' . ++$test_num;
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => { "${pkg}::status" => { source => 'http_status', is_xs_native => 1 } }
    ), 'compile numeric eq switch');

    no strict 'refs';
    is(&{"${pkg}::status"}(200), 'OK', '200 returns OK');
    is(&{"${pkg}::status"}(404), 'Not Found', '404 returns Not Found');
    is(&{"${pkg}::status"}(500), 'Server Error', '500 returns Server Error');
    is(&{"${pkg}::status"}(301), 'Unknown', '301 returns Unknown');
};

subtest 'numeric gt/lt switch' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('classify_age')
      ->xs_preamble
      ->declare_sv('age', 'ST(0)')
      ->switch('age', [
          { lt  => '0',  then => { return_pv => '"invalid"' } },
          { lt  => '13', then => { return_pv => '"child"' } },
          { lt  => '20', then => { return_pv => '"teen"' } },
          { lt  => '65', then => { return_pv => '"adult"' } },
      ], { return_pv => '"senior"' })
      ->xs_end;

    my $pkg = 'TestSwNumGtLt' . ++$test_num;
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => { "${pkg}::classify" => { source => 'classify_age', is_xs_native => 1 } }
    ), 'compile numeric gt/lt switch');

    no strict 'refs';
    is(&{"${pkg}::classify"}(-1), 'invalid', 'negative is invalid');
    is(&{"${pkg}::classify"}(5), 'child', '5 is child');
    is(&{"${pkg}::classify"}(12), 'child', '12 is child');
    is(&{"${pkg}::classify"}(15), 'teen', '15 is teen');
    is(&{"${pkg}::classify"}(19), 'teen', '19 is teen');
    is(&{"${pkg}::classify"}(30), 'adult', '30 is adult');
    is(&{"${pkg}::classify"}(64), 'adult', '64 is adult');
    is(&{"${pkg}::classify"}(65), 'senior', '65 is senior');
    is(&{"${pkg}::classify"}(80), 'senior', '80 is senior');
};

subtest 'numeric gte/lte switch' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('grade')
      ->xs_preamble
      ->declare_sv('score', 'ST(0)')
      ->switch('score', [
          { gte => '90', then => { return_pv => '"A"' } },
          { gte => '80', then => { return_pv => '"B"' } },
          { gte => '70', then => { return_pv => '"C"' } },
          { gte => '60', then => { return_pv => '"D"' } },
      ], { return_pv => '"F"' })
      ->xs_end;

    my $pkg = 'TestSwNumGteLte' . ++$test_num;
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => { "${pkg}::grade" => { source => 'grade', is_xs_native => 1 } }
    ), 'compile numeric gte/lte switch');

    no strict 'refs';
    is(&{"${pkg}::grade"}(95), 'A', '95 is A');
    is(&{"${pkg}::grade"}(90), 'A', '90 is A');
    is(&{"${pkg}::grade"}(85), 'B', '85 is B');
    is(&{"${pkg}::grade"}(80), 'B', '80 is B');
    is(&{"${pkg}::grade"}(75), 'C', '75 is C');
    is(&{"${pkg}::grade"}(70), 'C', '70 is C');
    is(&{"${pkg}::grade"}(65), 'D', '65 is D');
    is(&{"${pkg}::grade"}(60), 'D', '60 is D');
    is(&{"${pkg}::grade"}(55), 'F', '55 is F');
    is(&{"${pkg}::grade"}(0), 'F', '0 is F');
};

subtest 'string ne comparison' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('not_admin')
      ->xs_preamble
      ->declare_sv('role', 'ST(0)')
      ->switch('role', [
          { ne => 'admin', then => { return_iv => '1' } },
      ], { return_iv => '0' })
      ->xs_end;

    my $pkg = 'TestSwStrNe' . ++$test_num;
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => { "${pkg}::check" => { source => 'not_admin', is_xs_native => 1 } }
    ), 'compile string ne switch');

    no strict 'refs';
    is(&{"${pkg}::check"}('user'), 1, 'user is not admin');
    is(&{"${pkg}::check"}('guest'), 1, 'guest is not admin');
    is(&{"${pkg}::check"}('admin'), 0, 'admin falls through to default');
};

subtest 'exists check switch' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('check_defined')
      ->xs_preamble
      ->declare_sv('val', 'ST(0)')
      ->switch('val', [
          { exists => '1', then => { return_iv => '1' } },
      ], { return_iv => '0' })
      ->xs_end;

    my $pkg = 'TestSwExists' . ++$test_num;
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => { "${pkg}::check" => { source => 'check_defined', is_xs_native => 1 } }
    ), 'compile exists switch');

    no strict 'refs';
    is(&{"${pkg}::check"}('hello'), 1, 'defined string returns 1');
    is(&{"${pkg}::check"}(42), 1, 'defined number returns 1');
    is(&{"${pkg}::check"}(0), 1, 'zero returns 1 (defined)');
    is(&{"${pkg}::check"}(''), 1, 'empty string returns 1 (defined)');
    is(&{"${pkg}::check"}(undef), 0, 'undef returns 0');
};

subtest 'true check switch' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('check_true')
      ->xs_preamble
      ->declare_sv('val', 'ST(0)')
      ->switch('val', [
          { true => '1', then => { return_iv => '1' } },
      ], { return_iv => '0' })
      ->xs_end;

    my $pkg = 'TestSwTrue' . ++$test_num;
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => { "${pkg}::check" => { source => 'check_true', is_xs_native => 1 } }
    ), 'compile true switch');

    no strict 'refs';
    is(&{"${pkg}::check"}('hello'), 1, 'non-empty string is true');
    is(&{"${pkg}::check"}(42), 1, 'positive number is true');
    is(&{"${pkg}::check"}(-1), 1, 'negative number is true');
    is(&{"${pkg}::check"}(0), 0, 'zero is false');
    is(&{"${pkg}::check"}(''), 0, 'empty string is false');
    is(&{"${pkg}::check"}(undef), 0, 'undef is false');
};

subtest 'many cases string switch' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('day_number')
      ->xs_preamble
      ->declare_sv('day', 'ST(0)')
      ->switch('day', [
          { eq => 'Monday',    then => { return_iv => '1' } },
          { eq => 'Tuesday',   then => { return_iv => '2' } },
          { eq => 'Wednesday', then => { return_iv => '3' } },
          { eq => 'Thursday',  then => { return_iv => '4' } },
          { eq => 'Friday',    then => { return_iv => '5' } },
          { eq => 'Saturday',  then => { return_iv => '6' } },
          { eq => 'Sunday',    then => { return_iv => '7' } },
      ], { return_iv => '0' })
      ->xs_end;

    my $pkg = 'TestSwManyStr' . ++$test_num;
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => { "${pkg}::day" => { source => 'day_number', is_xs_native => 1 } }
    ), 'compile many cases string switch');

    no strict 'refs';
    is(&{"${pkg}::day"}('Monday'), 1, 'Monday is 1');
    is(&{"${pkg}::day"}('Tuesday'), 2, 'Tuesday is 2');
    is(&{"${pkg}::day"}('Wednesday'), 3, 'Wednesday is 3');
    is(&{"${pkg}::day"}('Thursday'), 4, 'Thursday is 4');
    is(&{"${pkg}::day"}('Friday'), 5, 'Friday is 5');
    is(&{"${pkg}::day"}('Saturday'), 6, 'Saturday is 6');
    is(&{"${pkg}::day"}('Sunday'), 7, 'Sunday is 7');
    is(&{"${pkg}::day"}('Invalid'), 0, 'Invalid returns 0');
};

subtest 'many cases numeric switch' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('month_name')
      ->xs_preamble
      ->declare_sv('month', 'ST(0)')
      ->switch('month', [
          { eq => '1',  then => { return_pv => '"January"' } },
          { eq => '2',  then => { return_pv => '"February"' } },
          { eq => '3',  then => { return_pv => '"March"' } },
          { eq => '4',  then => { return_pv => '"April"' } },
          { eq => '5',  then => { return_pv => '"May"' } },
          { eq => '6',  then => { return_pv => '"June"' } },
          { eq => '7',  then => { return_pv => '"July"' } },
          { eq => '8',  then => { return_pv => '"August"' } },
          { eq => '9',  then => { return_pv => '"September"' } },
          { eq => '10', then => { return_pv => '"October"' } },
          { eq => '11', then => { return_pv => '"November"' } },
          { eq => '12', then => { return_pv => '"December"' } },
      ], { return_pv => '"Unknown"' })
      ->xs_end;

    my $pkg = 'TestSwManyNum' . ++$test_num;
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => { "${pkg}::month" => { source => 'month_name', is_xs_native => 1 } }
    ), 'compile many cases numeric switch');

    no strict 'refs';
    is(&{"${pkg}::month"}(1), 'January', '1 is January');
    is(&{"${pkg}::month"}(6), 'June', '6 is June');
    is(&{"${pkg}::month"}(12), 'December', '12 is December');
    is(&{"${pkg}::month"}(0), 'Unknown', '0 is Unknown');
    is(&{"${pkg}::month"}(13), 'Unknown', '13 is Unknown');
};

subtest 'switch with croak action' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('strict_type')
      ->xs_preamble
      ->declare_sv('type', 'ST(0)')
      ->switch('type', [
          { eq => 'valid', then => { return_iv => '1' } },
      ], { croak => 'Invalid type provided' })
      ->xs_end;

    my $pkg = 'TestSwCroak' . ++$test_num;
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => { "${pkg}::check" => { source => 'strict_type', is_xs_native => 1 } }
    ), 'compile switch with croak');

    no strict 'refs';
    is(&{"${pkg}::check"}('valid'), 1, 'valid returns 1');
    eval { &{"${pkg}::check"}('invalid') };
    like($@, qr/Invalid type provided/, 'invalid croaks with message');
};

subtest 'switch with multiple actions in then' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('process')
      ->xs_preamble
      ->declare('int', 'result', '0')
      ->declare_sv('action', 'ST(0)')
      ->switch('action', [
          { eq => 'double', then => [
              { line => 'result = 2;' },
              { return_iv => 'result' }
          ]},
          { eq => 'triple', then => [
              { line => 'result = 3;' },
              { return_iv => 'result' }
          ]},
      ], { return_iv => '1' })
      ->xs_end;

    my $pkg = 'TestSwMultiAction' . ++$test_num;
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => { "${pkg}::process" => { source => 'process', is_xs_native => 1 } }
    ), 'compile switch with multiple actions');

    no strict 'refs';
    is(&{"${pkg}::process"}('double'), 2, 'double returns 2');
    is(&{"${pkg}::process"}('triple'), 3, 'triple returns 3');
    is(&{"${pkg}::process"}('other'), 1, 'other returns default 1');
};

subtest 'switch with return_sv action' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('get_value')
      ->xs_preamble
      ->declare_sv('key', 'ST(0)')
      ->switch('key', [
          { eq => 'pi',  then => { return_nv => '3.14159' } },
          { eq => 'e',   then => { return_nv => '2.71828' } },
          { eq => 'phi', then => { return_nv => '1.61803' } },
      ], { return_nv => '0.0' })
      ->xs_end;

    my $pkg = 'TestSwReturnNv' . ++$test_num;
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => { "${pkg}::get" => { source => 'get_value', is_xs_native => 1 } }
    ), 'compile switch with return_nv');

    no strict 'refs';
    cmp_ok(abs(&{"${pkg}::get"}('pi') - 3.14159), '<', 0.0001, 'pi returns ~3.14159');
    cmp_ok(abs(&{"${pkg}::get"}('e') - 2.71828), '<', 0.0001, 'e returns ~2.71828');
    cmp_ok(abs(&{"${pkg}::get"}('phi') - 1.61803), '<', 0.0001, 'phi returns ~1.61803');
    cmp_ok(abs(&{"${pkg}::get"}('unknown') - 0.0), '<', 0.0001, 'unknown returns 0.0');
};

subtest 'empty switch (edge case)' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('empty_switch')
      ->xs_preamble
      ->declare_sv('val', 'ST(0)')
      ->switch('val', [], { return_iv => '42' })
      ->xs_end;

    my $pkg = 'TestSwEmpty' . ++$test_num;
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => { "${pkg}::check" => { source => 'empty_switch', is_xs_native => 1 } }
    ), 'compile empty switch');

    no strict 'refs';
    is(&{"${pkg}::check"}('anything'), 42, 'empty switch always returns default');
};

subtest 'switch with special characters in strings' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('special_chars')
      ->xs_preamble
      ->declare_sv('input', 'ST(0)')
      ->switch('input', [
          { eq => 'hello world', then => { return_iv => '1' } },
          { eq => 'foo-bar',     then => { return_iv => '2' } },
          { eq => 'test_value',  then => { return_iv => '3' } },
          { eq => 'item.name',   then => { return_iv => '4' } },
      ], { return_iv => '0' })
      ->xs_end;

    my $pkg = 'TestSwSpecial' . ++$test_num;
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => { "${pkg}::check" => { source => 'special_chars', is_xs_native => 1 } }
    ), 'compile switch with special chars');

    no strict 'refs';
    is(&{"${pkg}::check"}('hello world'), 1, 'space in string works');
    is(&{"${pkg}::check"}('foo-bar'), 2, 'hyphen in string works');
    is(&{"${pkg}::check"}('test_value'), 3, 'underscore in string works');
    is(&{"${pkg}::check"}('item.name'), 4, 'dot in string works');
    is(&{"${pkg}::check"}('other'), 0, 'unmatched returns default');
};

subtest 'switch optimization: all string eq (memEQ)' => sub {
    # This test verifies that the optimization path for string eq is taken
    my $b = XS::JIT::Builder->new;
    $b->xs_function('str_opt')
      ->xs_preamble
      ->declare_sv('s', 'ST(0)')
      ->switch('s', [
          { eq => 'alpha',   then => { return_iv => '1' } },
          { eq => 'beta',    then => { return_iv => '2' } },
          { eq => 'gamma',   then => { return_iv => '3' } },
          { eq => 'delta',   then => { return_iv => '4' } },
          { eq => 'epsilon', then => { return_iv => '5' } },
      ], { return_iv => '0' })
      ->xs_end;

    my $pkg = 'TestSwStrOpt' . ++$test_num;
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => { "${pkg}::check" => { source => 'str_opt', is_xs_native => 1 } }
    ), 'compile optimized string switch');

    # Verify generated code contains optimization markers
    like($b->code, qr/_sw_str|_sw_len/, 'code contains string optimization vars');
    like($b->code, qr/memEQ/, 'code uses memEQ for string comparison');

    no strict 'refs';
    is(&{"${pkg}::check"}('alpha'), 1, 'alpha returns 1');
    is(&{"${pkg}::check"}('epsilon'), 5, 'epsilon returns 5');
    is(&{"${pkg}::check"}('zeta'), 0, 'zeta returns default');
};

subtest 'switch optimization: all numeric (cached SvIV)' => sub {
    # This test verifies that the optimization path for numeric is taken
    my $b = XS::JIT::Builder->new;
    $b->xs_function('num_opt')
      ->xs_preamble
      ->declare_sv('n', 'ST(0)')
      ->switch('n', [
          { gt => '100', then => { return_pv => '"large"' } },
          { gt => '50',  then => { return_pv => '"medium"' } },
          { gt => '10',  then => { return_pv => '"small"' } },
      ], { return_pv => '"tiny"' })
      ->xs_end;

    my $pkg = 'TestSwNumOpt' . ++$test_num;
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => { "${pkg}::check" => { source => 'num_opt', is_xs_native => 1 } }
    ), 'compile optimized numeric switch');

    # Verify generated code contains optimization markers
    like($b->code, qr/_sw_iv/, 'code contains numeric optimization var');

    no strict 'refs';
    is(&{"${pkg}::check"}(150), 'large', '150 is large');
    is(&{"${pkg}::check"}(75), 'medium', '75 is medium');
    is(&{"${pkg}::check"}(25), 'small', '25 is small');
    is(&{"${pkg}::check"}(5), 'tiny', '5 is tiny');
};

subtest 'HTTP status code classifier (comprehensive)' => sub {
    my $b = XS::JIT::Builder->new;
    $b->xs_function('http_classifier')
      ->xs_preamble
      ->declare_sv('code', 'ST(0)')
      ->switch('code', [
          # Specific codes
          { eq => '200', then => { return_pv => '"OK"' } },
          { eq => '201', then => { return_pv => '"Created"' } },
          { eq => '204', then => { return_pv => '"No Content"' } },
          { eq => '301', then => { return_pv => '"Moved Permanently"' } },
          { eq => '302', then => { return_pv => '"Found"' } },
          { eq => '304', then => { return_pv => '"Not Modified"' } },
          { eq => '400', then => { return_pv => '"Bad Request"' } },
          { eq => '401', then => { return_pv => '"Unauthorized"' } },
          { eq => '403', then => { return_pv => '"Forbidden"' } },
          { eq => '404', then => { return_pv => '"Not Found"' } },
          { eq => '405', then => { return_pv => '"Method Not Allowed"' } },
          { eq => '500', then => { return_pv => '"Internal Server Error"' } },
          { eq => '502', then => { return_pv => '"Bad Gateway"' } },
          { eq => '503', then => { return_pv => '"Service Unavailable"' } },
      ], { return_pv => '"Unknown"' })
      ->xs_end;

    my $pkg = 'TestSwHTTP' . ++$test_num;
    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => { "${pkg}::status" => { source => 'http_classifier', is_xs_native => 1 } }
    ), 'compile HTTP status switch');

    no strict 'refs';
    is(&{"${pkg}::status"}(200), 'OK', '200 is OK');
    is(&{"${pkg}::status"}(201), 'Created', '201 is Created');
    is(&{"${pkg}::status"}(204), 'No Content', '204 is No Content');
    is(&{"${pkg}::status"}(301), 'Moved Permanently', '301 is Moved Permanently');
    is(&{"${pkg}::status"}(302), 'Found', '302 is Found');
    is(&{"${pkg}::status"}(304), 'Not Modified', '304 is Not Modified');
    is(&{"${pkg}::status"}(400), 'Bad Request', '400 is Bad Request');
    is(&{"${pkg}::status"}(401), 'Unauthorized', '401 is Unauthorized');
    is(&{"${pkg}::status"}(403), 'Forbidden', '403 is Forbidden');
    is(&{"${pkg}::status"}(404), 'Not Found', '404 is Not Found');
    is(&{"${pkg}::status"}(405), 'Method Not Allowed', '405 is Method Not Allowed');
    is(&{"${pkg}::status"}(500), 'Internal Server Error', '500 is Internal Server Error');
    is(&{"${pkg}::status"}(502), 'Bad Gateway', '502 is Bad Gateway');
    is(&{"${pkg}::status"}(503), 'Service Unavailable', '503 is Service Unavailable');
    is(&{"${pkg}::status"}(418), 'Unknown', '418 (teapot) is Unknown');
};

subtest 'switch vs conditional: same behavior' => sub {
    # Build with switch
    my $b1 = XS::JIT::Builder->new;
    $b1->xs_function('switch_impl')
      ->xs_preamble
      ->declare_sv('val', 'ST(0)')
      ->switch('val', [
          { eq => 'a', then => { return_iv => '1' } },
          { eq => 'b', then => { return_iv => '2' } },
          { eq => 'c', then => { return_iv => '3' } },
      ], { return_iv => '0' })
      ->xs_end;

    # Build with conditional given/when
    my $b2 = XS::JIT::Builder->new;
    $b2->xs_function('cond_impl')
      ->xs_preamble
      ->declare_sv('val', 'ST(0)')
      ->conditional({
          given => {
              key => 'val',
              when => {
                  a => { return_iv => '1' },
                  b => { return_iv => '2' },
                  c => { return_iv => '3' },
                  default => { return_iv => '0' }
              }
          }
      })
      ->xs_end;

    my $pkg1 = 'TestSwVsCond1_' . ++$test_num;
    my $pkg2 = 'TestSwVsCond2_' . ++$test_num;

    ok(XS::JIT->compile(
        code      => $b1->code,
        name      => $pkg1,
        cache_dir => $cache_dir,
        functions => { "${pkg1}::check" => { source => 'switch_impl', is_xs_native => 1 } }
    ), 'compile switch version');

    ok(XS::JIT->compile(
        code      => $b2->code,
        name      => $pkg2,
        cache_dir => $cache_dir,
        functions => { "${pkg2}::check" => { source => 'cond_impl', is_xs_native => 1 } }
    ), 'compile conditional version');

    no strict 'refs';
    for my $input ('a', 'b', 'c', 'd', 'xyz') {
        my $sw_result = &{"${pkg1}::check"}($input);
        my $cond_result = &{"${pkg2}::check"}($input);
        is($sw_result, $cond_result, "switch and conditional agree on '$input'");
    }
};

done_testing;

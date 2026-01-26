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

subtest 'basic enum generation' => sub {
    my $b = XS::JIT::Builder->new;
    $b->enum('Status', [qw(PENDING ACTIVE INACTIVE DELETED)]);

    my $pkg = 'TestEnum' . ++$test_num;
    my $functions = $b->enum_functions('Status', $pkg);

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => $functions,
    ), 'compile basic enum');

    no strict 'refs';

    # Test constants
    is(&{"${pkg}::STATUS_PENDING"}(), 0, 'STATUS_PENDING is 0');
    is(&{"${pkg}::STATUS_ACTIVE"}(), 1, 'STATUS_ACTIVE is 1');
    is(&{"${pkg}::STATUS_INACTIVE"}(), 2, 'STATUS_INACTIVE is 2');
    is(&{"${pkg}::STATUS_DELETED"}(), 3, 'STATUS_DELETED is 3');

    # Test is_valid_status
    ok(&{"${pkg}::is_valid_status"}(0), 'is_valid_status(0) is true');
    ok(&{"${pkg}::is_valid_status"}(1), 'is_valid_status(1) is true');
    ok(&{"${pkg}::is_valid_status"}(2), 'is_valid_status(2) is true');
    ok(&{"${pkg}::is_valid_status"}(3), 'is_valid_status(3) is true');
    ok(!&{"${pkg}::is_valid_status"}(-1), 'is_valid_status(-1) is false');
    ok(!&{"${pkg}::is_valid_status"}(4), 'is_valid_status(4) is false');
    ok(!&{"${pkg}::is_valid_status"}(100), 'is_valid_status(100) is false');

    # Test status_name
    is(&{"${pkg}::status_name"}(0), 'PENDING', 'status_name(0) is PENDING');
    is(&{"${pkg}::status_name"}(1), 'ACTIVE', 'status_name(1) is ACTIVE');
    is(&{"${pkg}::status_name"}(2), 'INACTIVE', 'status_name(2) is INACTIVE');
    is(&{"${pkg}::status_name"}(3), 'DELETED', 'status_name(3) is DELETED');
    is(&{"${pkg}::status_name"}(-1), '', 'status_name(-1) is empty');
    is(&{"${pkg}::status_name"}(99), '', 'status_name(99) is empty');
};

subtest 'enum with custom start value' => sub {
    my $b = XS::JIT::Builder->new;
    $b->enum('Priority', [qw(LOW MEDIUM HIGH CRITICAL)], { start => 1 });

    my $pkg = 'TestEnumStart' . ++$test_num;
    my $functions = $b->enum_functions('Priority', $pkg);

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => $functions,
    ), 'compile enum with custom start');

    no strict 'refs';

    # Test constants start at 1
    is(&{"${pkg}::PRIORITY_LOW"}(), 1, 'PRIORITY_LOW is 1');
    is(&{"${pkg}::PRIORITY_MEDIUM"}(), 2, 'PRIORITY_MEDIUM is 2');
    is(&{"${pkg}::PRIORITY_HIGH"}(), 3, 'PRIORITY_HIGH is 3');
    is(&{"${pkg}::PRIORITY_CRITICAL"}(), 4, 'PRIORITY_CRITICAL is 4');

    # Test is_valid_priority with custom range
    ok(!&{"${pkg}::is_valid_priority"}(0), 'is_valid_priority(0) is false');
    ok(&{"${pkg}::is_valid_priority"}(1), 'is_valid_priority(1) is true');
    ok(&{"${pkg}::is_valid_priority"}(4), 'is_valid_priority(4) is true');
    ok(!&{"${pkg}::is_valid_priority"}(5), 'is_valid_priority(5) is false');

    # Test priority_name
    is(&{"${pkg}::priority_name"}(1), 'LOW', 'priority_name(1) is LOW');
    is(&{"${pkg}::priority_name"}(4), 'CRITICAL', 'priority_name(4) is CRITICAL');
    is(&{"${pkg}::priority_name"}(0), '', 'priority_name(0) is empty');
};

subtest 'enum with custom prefix' => sub {
    my $b = XS::JIT::Builder->new;
    $b->enum('Color', [qw(RED GREEN BLUE)], { prefix => 'CLR_' });

    my $pkg = 'TestEnumPrefix' . ++$test_num;
    my $functions = $b->enum_functions('Color', $pkg);

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => $functions,
    ), 'compile enum with custom prefix');

    no strict 'refs';

    # Test constants with custom prefix
    is(&{"${pkg}::CLR_RED"}(), 0, 'CLR_RED is 0');
    is(&{"${pkg}::CLR_GREEN"}(), 1, 'CLR_GREEN is 1');
    is(&{"${pkg}::CLR_BLUE"}(), 2, 'CLR_BLUE is 2');

    # is_valid and name functions still use lowercase enum name
    ok(&{"${pkg}::is_valid_color"}(0), 'is_valid_color(0) is true');
    is(&{"${pkg}::color_name"}(1), 'GREEN', 'color_name(1) is GREEN');
};

subtest 'enum with both custom start and prefix' => sub {
    my $b = XS::JIT::Builder->new;
    $b->enum('HttpMethod', [qw(GET POST PUT DELETE PATCH)], {
        start  => 100,
        prefix => 'HTTP_',
    });

    my $pkg = 'TestEnumBoth' . ++$test_num;
    my $functions = $b->enum_functions('HttpMethod', $pkg);

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => $functions,
    ), 'compile enum with both options');

    no strict 'refs';

    # Test constants
    is(&{"${pkg}::HTTP_GET"}(), 100, 'HTTP_GET is 100');
    is(&{"${pkg}::HTTP_POST"}(), 101, 'HTTP_POST is 101');
    is(&{"${pkg}::HTTP_PUT"}(), 102, 'HTTP_PUT is 102');
    is(&{"${pkg}::HTTP_DELETE"}(), 103, 'HTTP_DELETE is 103');
    is(&{"${pkg}::HTTP_PATCH"}(), 104, 'HTTP_PATCH is 104');

    # Test validation
    ok(!&{"${pkg}::is_valid_httpmethod"}(99), 'is_valid_httpmethod(99) is false');
    ok(&{"${pkg}::is_valid_httpmethod"}(100), 'is_valid_httpmethod(100) is true');
    ok(&{"${pkg}::is_valid_httpmethod"}(104), 'is_valid_httpmethod(104) is true');
    ok(!&{"${pkg}::is_valid_httpmethod"}(105), 'is_valid_httpmethod(105) is false');

    # Test name lookup
    is(&{"${pkg}::httpmethod_name"}(100), 'GET', 'httpmethod_name(100) is GET');
    is(&{"${pkg}::httpmethod_name"}(103), 'DELETE', 'httpmethod_name(103) is DELETE');
};

subtest 'single value enum' => sub {
    my $b = XS::JIT::Builder->new;
    $b->enum('Singleton', ['ONLY']);

    my $pkg = 'TestEnumSingle' . ++$test_num;
    my $functions = $b->enum_functions('Singleton', $pkg);

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => $functions,
    ), 'compile single value enum');

    no strict 'refs';

    is(&{"${pkg}::SINGLETON_ONLY"}(), 0, 'SINGLETON_ONLY is 0');
    ok(&{"${pkg}::is_valid_singleton"}(0), 'is_valid_singleton(0) is true');
    ok(!&{"${pkg}::is_valid_singleton"}(1), 'is_valid_singleton(1) is false');
    is(&{"${pkg}::singleton_name"}(0), 'ONLY', 'singleton_name(0) is ONLY');
};

subtest 'multiple enums in same builder' => sub {
    my $b = XS::JIT::Builder->new;
    $b->enum('Day', [qw(MON TUE WED THU FRI SAT SUN)]);
    $b->enum('Month', [qw(JAN FEB MAR APR MAY JUN JUL AUG SEP OCT NOV DEC)], { start => 1 });

    my $pkg = 'TestEnumMulti' . ++$test_num;
    my $day_functions = $b->enum_functions('Day', $pkg);
    my $month_functions = $b->enum_functions('Month', $pkg);

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => { %$day_functions, %$month_functions },
    ), 'compile multiple enums');

    no strict 'refs';

    # Test Day enum
    is(&{"${pkg}::DAY_MON"}(), 0, 'DAY_MON is 0');
    is(&{"${pkg}::DAY_SUN"}(), 6, 'DAY_SUN is 6');
    ok(&{"${pkg}::is_valid_day"}(0), 'is_valid_day(0) is true');
    ok(&{"${pkg}::is_valid_day"}(6), 'is_valid_day(6) is true');
    ok(!&{"${pkg}::is_valid_day"}(7), 'is_valid_day(7) is false');
    is(&{"${pkg}::day_name"}(4), 'FRI', 'day_name(4) is FRI');

    # Test Month enum
    is(&{"${pkg}::MONTH_JAN"}(), 1, 'MONTH_JAN is 1');
    is(&{"${pkg}::MONTH_DEC"}(), 12, 'MONTH_DEC is 12');
    ok(!&{"${pkg}::is_valid_month"}(0), 'is_valid_month(0) is false');
    ok(&{"${pkg}::is_valid_month"}(1), 'is_valid_month(1) is true');
    ok(&{"${pkg}::is_valid_month"}(12), 'is_valid_month(12) is true');
    ok(!&{"${pkg}::is_valid_month"}(13), 'is_valid_month(13) is false');
    is(&{"${pkg}::month_name"}(7), 'JUL', 'month_name(7) is JUL');
};

subtest 'enum with lowercase values' => sub {
    my $b = XS::JIT::Builder->new;
    $b->enum('Level', [qw(debug info warn error fatal)]);

    my $pkg = 'TestEnumLower' . ++$test_num;
    my $functions = $b->enum_functions('Level', $pkg);

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => $functions,
    ), 'compile enum with lowercase values');

    no strict 'refs';

    # Constants are uppercased
    is(&{"${pkg}::LEVEL_DEBUG"}(), 0, 'LEVEL_DEBUG is 0');
    is(&{"${pkg}::LEVEL_FATAL"}(), 4, 'LEVEL_FATAL is 4');

    # Name returns original case
    is(&{"${pkg}::level_name"}(0), 'debug', 'level_name(0) is debug');
    is(&{"${pkg}::level_name"}(2), 'warn', 'level_name(2) is warn');
};

subtest 'enum with mixed case values' => sub {
    my $b = XS::JIT::Builder->new;
    $b->enum('EventType', [qw(OnClick OnHover OnScroll OnKeyPress)]);

    my $pkg = 'TestEnumMixed' . ++$test_num;
    my $functions = $b->enum_functions('EventType', $pkg);

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => $functions,
    ), 'compile enum with mixed case values');

    no strict 'refs';

    # Constants are uppercased
    is(&{"${pkg}::EVENTTYPE_ONCLICK"}(), 0, 'EVENTTYPE_ONCLICK is 0');
    is(&{"${pkg}::EVENTTYPE_ONKEYPRESS"}(), 3, 'EVENTTYPE_ONKEYPRESS is 3');

    # Name returns original case
    is(&{"${pkg}::eventtype_name"}(1), 'OnHover', 'eventtype_name(1) is OnHover');
};

subtest 'enum error handling' => sub {
    my $b = XS::JIT::Builder->new;

    # Test missing name
    eval { $b->enum(undef, ['A', 'B']) };
    like($@, qr/enum requires a name/, 'dies without name');

    # Test missing values - XS checks type
    eval { $b->enum('Test', undef) };
    like($@, qr/not an ARRAY reference/, 'dies without values');

    # Test empty values
    eval { $b->enum('Test', []) };
    like($@, qr/non-empty values/, 'dies with empty values');

    # Test non-arrayref values
    eval { $b->enum('Test', 'not_array') };
    like($@, qr/not an ARRAY reference/, 'dies with non-arrayref values');

    # Test unknown enum name for enum_functions
    $b->enum('Valid', ['A']);
    eval { $b->enum_functions('Unknown', 'Pkg') };
    like($@, qr/No enum named 'Unknown' found/, 'dies with unknown enum name');
};

subtest 'practical usage: HTTP status categories' => sub {
    my $b = XS::JIT::Builder->new;
    $b->enum('HttpCategory', [qw(INFORMATIONAL SUCCESS REDIRECT CLIENT_ERROR SERVER_ERROR)]);

    my $pkg = 'TestHttpCat' . ++$test_num;
    my $functions = $b->enum_functions('HttpCategory', $pkg);

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => $functions,
    ), 'compile HTTP category enum');

    no strict 'refs';

    # Simulate categorizing HTTP status codes
    my $categorize = sub {
        my ($code) = @_;
        return &{"${pkg}::HTTPCATEGORY_INFORMATIONAL"}() if $code >= 100 && $code < 200;
        return &{"${pkg}::HTTPCATEGORY_SUCCESS"}()       if $code >= 200 && $code < 300;
        return &{"${pkg}::HTTPCATEGORY_REDIRECT"}()      if $code >= 300 && $code < 400;
        return &{"${pkg}::HTTPCATEGORY_CLIENT_ERROR"}()  if $code >= 400 && $code < 500;
        return &{"${pkg}::HTTPCATEGORY_SERVER_ERROR"}()  if $code >= 500 && $code < 600;
        return -1;
    };

    # Test categorization
    my $cat_200 = $categorize->(200);
    my $cat_404 = $categorize->(404);
    my $cat_500 = $categorize->(500);

    is($cat_200, &{"${pkg}::HTTPCATEGORY_SUCCESS"}(), '200 is SUCCESS category');
    is($cat_404, &{"${pkg}::HTTPCATEGORY_CLIENT_ERROR"}(), '404 is CLIENT_ERROR category');
    is($cat_500, &{"${pkg}::HTTPCATEGORY_SERVER_ERROR"}(), '500 is SERVER_ERROR category');

    # Validate and get names
    ok(&{"${pkg}::is_valid_httpcategory"}($cat_404), 'category is valid');
    is(&{"${pkg}::httpcategory_name"}($cat_404), 'CLIENT_ERROR', 'category name is CLIENT_ERROR');
};

subtest 'practical usage: state machine' => sub {
    my $b = XS::JIT::Builder->new;
    $b->enum('OrderState', [qw(PENDING PROCESSING SHIPPED DELIVERED CANCELLED)]);

    my $pkg = 'TestOrderState' . ++$test_num;
    my $functions = $b->enum_functions('OrderState', $pkg);

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => $functions,
    ), 'compile order state enum');

    no strict 'refs';

    # Define valid transitions
    my %transitions = (
        &{"${pkg}::ORDERSTATE_PENDING"}()    => [&{"${pkg}::ORDERSTATE_PROCESSING"}(), &{"${pkg}::ORDERSTATE_CANCELLED"}()],
        &{"${pkg}::ORDERSTATE_PROCESSING"}() => [&{"${pkg}::ORDERSTATE_SHIPPED"}(), &{"${pkg}::ORDERSTATE_CANCELLED"}()],
        &{"${pkg}::ORDERSTATE_SHIPPED"}()    => [&{"${pkg}::ORDERSTATE_DELIVERED"}()],
        &{"${pkg}::ORDERSTATE_DELIVERED"}()  => [],
        &{"${pkg}::ORDERSTATE_CANCELLED"}()  => [],
    );

    my $can_transition = sub {
        my ($from, $to) = @_;
        return 0 unless &{"${pkg}::is_valid_orderstate"}($from);
        return 0 unless &{"${pkg}::is_valid_orderstate"}($to);
        return grep { $_ == $to } @{$transitions{$from} // []};
    };

    # Test valid transitions
    ok($can_transition->(&{"${pkg}::ORDERSTATE_PENDING"}(), &{"${pkg}::ORDERSTATE_PROCESSING"}()),
       'PENDING -> PROCESSING is valid');
    ok($can_transition->(&{"${pkg}::ORDERSTATE_PENDING"}(), &{"${pkg}::ORDERSTATE_CANCELLED"}()),
       'PENDING -> CANCELLED is valid');

    # Test invalid transitions
    ok(!$can_transition->(&{"${pkg}::ORDERSTATE_PENDING"}(), &{"${pkg}::ORDERSTATE_DELIVERED"}()),
       'PENDING -> DELIVERED is invalid');
    ok(!$can_transition->(&{"${pkg}::ORDERSTATE_DELIVERED"}(), &{"${pkg}::ORDERSTATE_PENDING"}()),
       'DELIVERED -> PENDING is invalid');

    # Test terminal states have no transitions
    is(scalar(@{$transitions{&{"${pkg}::ORDERSTATE_DELIVERED"}()}}), 0,
       'DELIVERED is terminal state');
    is(scalar(@{$transitions{&{"${pkg}::ORDERSTATE_CANCELLED"}()}}), 0,
       'CANCELLED is terminal state');
};

subtest 'enum with negative start value' => sub {
    my $b = XS::JIT::Builder->new;
    $b->enum('Direction', [qw(LEFT CENTER RIGHT)], { start => -1 });

    my $pkg = 'TestEnumNeg' . ++$test_num;
    my $functions = $b->enum_functions('Direction', $pkg);

    ok(XS::JIT->compile(
        code      => $b->code,
        name      => $pkg,
        cache_dir => $cache_dir,
        functions => $functions,
    ), 'compile enum with negative start');

    no strict 'refs';

    is(&{"${pkg}::DIRECTION_LEFT"}(), -1, 'DIRECTION_LEFT is -1');
    is(&{"${pkg}::DIRECTION_CENTER"}(), 0, 'DIRECTION_CENTER is 0');
    is(&{"${pkg}::DIRECTION_RIGHT"}(), 1, 'DIRECTION_RIGHT is 1');

    ok(&{"${pkg}::is_valid_direction"}(-1), 'is_valid_direction(-1) is true');
    ok(&{"${pkg}::is_valid_direction"}(0), 'is_valid_direction(0) is true');
    ok(&{"${pkg}::is_valid_direction"}(1), 'is_valid_direction(1) is true');
    ok(!&{"${pkg}::is_valid_direction"}(-2), 'is_valid_direction(-2) is false');
    ok(!&{"${pkg}::is_valid_direction"}(2), 'is_valid_direction(2) is false');

    is(&{"${pkg}::direction_name"}(-1), 'LEFT', 'direction_name(-1) is LEFT');
    is(&{"${pkg}::direction_name"}(0), 'CENTER', 'direction_name(0) is CENTER');
    is(&{"${pkg}::direction_name"}(1), 'RIGHT', 'direction_name(1) is RIGHT');
};

done_testing;

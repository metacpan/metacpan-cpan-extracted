use Test2::V0;
use Path::Tiny;
use Test2::Aggregate::Helper;

subtest 'setup_options with include/exclude inputs' => sub {
    my $list = Path::Tiny->tempfile;
    $list->spew_utf8(join "\n",
        "# comment",
        "xt/aggregate/check_env.t",
        "./xt/aggregate/check_plan.t",
        ""
    );

    my %opt = (
        prove         => 1,
        event_timeout => 10,
        include_regex => 'check_',
        exclude_regex => 'fail',
        exclude_list  => "$list",
    );

    local @ARGV = ();
    Test2::Aggregate::Helper::setup_options(\%opt);

    is($opt{test_bundle}, 'Test::More', 'default test bundle with --prove');
    ok(!exists $opt{event_timeout}, 'event timeout removed when using --prove');
    is($opt{root}, './', 'default root set');
    ok($opt{relative_root}, 'relative_root enabled by default');
    ok($opt{include_pattern}, 'include pattern created');
    ok($opt{exclude_pattern}, 'exclude pattern created');

    my $in = qr/$opt{include_pattern}/;
    ok('xt/aggregate/check_env.t' =~ $in, 'include regex included');

    my $ex = qr/$opt{exclude_pattern}/;
    ok('my/fail_test.t' =~ $ex, 'exclude regex included');
    ok('xt/aggregate/check_env.t' !~ $ex, 'exclude list is not part of the regex');

    my $excluded = sub { Test2::Aggregate::Helper::is_excluded(\%opt, shift) };
    ok($excluded->('xt/aggregate/check_env.t'), 'exclude list entry matched');
    ok($excluded->('./xt/aggregate/check_env.t'), 'leading ./ is normalized');
    ok($excluded->('xt/aggregate/check_plan.t'), 'list entry with ./ matched');
    ok($excluded->(path('xt/aggregate/check_plan.t')->absolute), 'absolute path matched');
    ok($excluded->('t/../xt/aggregate/check_plan.t'), 'path with .. matched');
    ok(!$excluded->('t/00-load.t'), 'other tests not excluded');
};

subtest 'exclude list relative to --root' => sub {
    my $list = Path::Tiny->tempfile;
    $list->spew_utf8("check_env.t\n");
    local @ARGV = ();
    my %opt = (prove => 1, root => 'xt/aggregate', exclude_list => "$list");
    Test2::Aggregate::Helper::setup_options(\%opt);
    ok(Test2::Aggregate::Helper::is_excluded(\%opt, 'xt/aggregate/check_env.t'),
        'entry resolved against root');
    ok(!Test2::Aggregate::Helper::is_excluded(\%opt, 'check_env.t'),
        'entry not resolved against cwd');
};

subtest 'setup_options validation' => sub {
    my %opt = (
        prove        => 1,
        exclude_list => '/tmp/definitely-not-a-real-list-for-test2-aggregate',
    );

    local @ARGV = ();
    like(
        dies { Test2::Aggregate::Helper::setup_options(\%opt) },
        qr/Specified --exclude_list does not exist/,
        'invalid exclude list path dies'
    );

    my %opt2 = (
        prove         => 1,
        include_regex => '(unterminated',
    );

    like(
        dies { Test2::Aggregate::Helper::setup_options(\%opt2) },
        qr/Invalid --include_regex/,
        'invalid include regex dies'
    );
};

subtest 'generate_code renders include/exclude and quoted strings' => sub {
    my $input = 'xt/aggregate';
    my %opt = (
        prove         => 1,
        test_bundle   => 'Test::More',
        root          => './',
        relative_root => 1,
        include_pattern => q{bar'baz},
        exclude_pattern => q{foo'bar},
        file          => path('t', 'tmp-helper.t'),
    );

    my $code = Test2::Aggregate::Helper::generate_code(\%opt, $input);

    ok(index($code, "exclude => 'foo\\'bar',") >= 0, 'exclude is quoted in generated code');
    ok(index($code, "include => 'bar\\'baz',") >= 0, 'include is quoted in generated code');
    ok(index($code, "done_testing();") >= 0, 'generated code includes done_testing');
};

subtest 'create_command output' => sub {
    my %opt = (
        prove         => 0,
        event_timeout => 9,
        include       => 'lib',
        verbose       => 1,
    );

    my @cmd = Test2::Aggregate::Helper::create_command(\%opt, 'sample.t');
    is(
        \@cmd,
        ['yath', 'test', '--et', 9, '-Ilib', '-v', 'sample.t'],
        'full command for yath mode'
    );

    my @args = Test2::Aggregate::Helper::create_command(\%opt, 'sample.t', 1);
    is(
        \@args,
        ['--et', 9, '-Ilib', '-v', 'sample.t'],
        'args_only omits command and yath subcommand'
    );

    $opt{prove} = 1;
    is([Test2::Aggregate::Helper::create_command(\%opt, 'sample.t')],
        ['prove', '-Ilib', '-v', 'sample.t'], 'prove never receives --et');
    is([Test2::Aggregate::Helper::create_command({%opt, include => ['lib', 't/lib']}, 'sample.t')],
        ['prove', '-Ilib', '-It/lib', '-v', 'sample.t'], 'multiple include paths kept in order');
    $opt{prove} = 0;
    $opt{event_timeout} = 0;
    is([Test2::Aggregate::Helper::create_command(\%opt, 'sample.t')],
        ['yath', 'test', '--et', 0, '-Ilib', '-v', 'sample.t'], 'zero timeout is preserved');
};

subtest 'automatic fallback normalizes runner defaults' => sub {
    local %INC = %INC;
    delete $INC{'Test2/Harness.pm'};
    local @INC = (sub {
        die "Harness unavailable\n" if $_[1] eq 'Test2/Harness.pm';
        return;
    }, @INC);
    local @ARGV;
    my %opt = (event_timeout => 10);
    Test2::Aggregate::Helper::setup_options(\%opt);
    ok($opt{prove}, 'falls back to prove');
    is($opt{test_bundle}, 'Test::More', 'fallback uses prove bundle');
    ok(!exists $opt{event_timeout}, 'fallback removes timeout');
    is([Test2::Aggregate::Helper::create_command(\%opt, 'sample.t')],
        ['prove', 'sample.t'], 'fallback command has no yath arguments');
    my %custom = (test_bundle => 'Test2::V0');
    Test2::Aggregate::Helper::setup_options(\%custom);
    is($custom{test_bundle}, 'Test2::V0', 'explicit bundle survives fallback');
};

subtest 'absolute inputs and explicit roots' => sub {
    local @ARGV;
    my %opt = (prove => 1, absolute => 1, file => path('/tmp/generated.t'));
    Test2::Aggregate::Helper::setup_options(\%opt);
    my $code = Test2::Aggregate::Helper::generate_code(\%opt, 'xt/aggregate/check_env.t');
    ok(index($code, "" . path('xt/aggregate/check_env.t')->absolute) >= 0,
        'relative input becomes absolute');
    my $input = 'xt/aggregate/check_env.t';
    Test2::Aggregate::Helper::generate_code(\%opt, $input);
    is($input, 'xt/aggregate/check_env.t', 'normalization does not mutate caller input');
    local @ARGV = ("" . path('xt/aggregate/check_env.t')->absolute);
    my %root = (prove => 1, root => 'xt/aggregate');
    Test2::Aggregate::Helper::setup_options(\%root);
    is($root{root}, "" . path('xt/aggregate')->absolute, 'explicit root is absolute');
};

done_testing;

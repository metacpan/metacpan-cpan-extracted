use Test::More tests => 47;

system("echo foo");

use Test::Carp;

BEGIN {
    use_ok( 'Test::Mock::Cmd', sub { 1 } );
    use_ok( 'Test::Mock::Cmd', sub { 1 }, sub { 2 }, sub { 3 } );
    use_ok( 'Test::Mock::Cmd', 'system' => sub { 1 }, 'exec' => sub { 2 }, 'qx' => sub { 3 } );

    use_ok( 'Test::Mock::Cmd', {} );
    use_ok( 'Test::Mock::Cmd', {}, {}, {} );
    use_ok( 'Test::Mock::Cmd', 'system' => {}, 'exec' => {}, 'qx' => {} );

    # basic permutations of mixed args, no need to go crazy eh?
    use_ok( 'Test::Mock::Cmd', sub { 1 }, {}, {} );
    use_ok( 'Test::Mock::Cmd', 'system' => sub { 1 }, 'exec' => {}, 'qx' => {} );

    use_ok( 'Test::Mock::Cmd', {}, sub { 2 }, {} );
    use_ok( 'Test::Mock::Cmd', 'system' => {}, 'exec' => sub { 2 }, 'qx' => {} );

    use_ok( 'Test::Mock::Cmd', {}, {}, sub { 3 } );
    use_ok( 'Test::Mock::Cmd', 'system' => {}, 'exec' => {}, 'qx' => sub { 3 } );

    use_ok( 'Test::Mock::Cmd', {}, sub { 2 }, sub { 3 } );
    use_ok( 'Test::Mock::Cmd', 'system' => {}, 'exec' => sub { 2 }, 'qx' => sub { 3 } );

    use_ok( 'Test::Mock::Cmd', sub { 1 }, {}, sub { 3 } );
    use_ok( 'Test::Mock::Cmd', 'system' => sub { 1 }, 'exec' => {}, 'qx' => sub { 3 } );

    use_ok( 'Test::Mock::Cmd', sub { 1 }, sub { 2 }, {} );
    use_ok( 'Test::Mock::Cmd', 'system' => sub { 1 }, 'exec' => sub { 2 }, 'qx' => {} );
}

diag("Testing Test::Mock::Cmd $Test::Mock::Cmd::VERSION");

my $import     = sub { require Test::Mock::Cmd; Test::Mock::Cmd->import(@_) };
my $arg_regex  = qr/import\(\) requires a 1-3 key hash, 1 code\/hash reference, or 3 code\/hash references as arguments/;
my $code_regex = qr/Not a CODE or HASH reference/;
my $key_regex  = qr/Key is not system\, exec\, or qx/;

does_croak_that_matches( $import, $arg_regex );
does_croak_that_matches( $import, sub { 1 }, sub { 2 }, $key_regex );
does_croak_that_matches( $import, sub { 1 }, sub { 2 }, sub { 3 }, sub { 4 }, $key_regex );
does_croak_that_matches( $import, {}, {}, $key_regex );
does_croak_that_matches( $import, {}, {}, {}, {}, $key_regex );

does_croak_that_matches( $import, 1, $code_regex );
does_croak_that_matches( $import, 1, sub { 2 }, sub { 3 }, $code_regex );
does_croak_that_matches( $import, sub { 1 }, 2, sub { 3 }, $code_regex );
does_croak_that_matches( $import, sub { 1 }, sub { 2 }, 3, $code_regex );
does_croak_that_matches( $import, 1, {}, {}, $code_regex );
does_croak_that_matches( $import, {}, 2, {}, $code_regex );
does_croak_that_matches( $import, {}, {}, 3, $code_regex );

does_croak_that_matches( $import, 'system' => sub { 1 }, 'exec' => '2', 'qx' => sub { 3 }, $code_regex );
does_croak_that_matches( $import, 'sytsem' => sub { 1 }, 'exec' => sub { 2 }, $key_regex );
does_croak_that_matches( $import, 'system' => {}, 'exec' => '2', 'qx' => {}, $code_regex );
does_croak_that_matches( $import, 'sytsem' => {}, 'exec' => {}, $key_regex );

my $cr = Test::Mock::Cmd::_transmogrify_to_code(
    {
        "foo" => sub { return "FOO" }
    },
    sub { return "BAR" }
);

is( ref($cr),             'CODE', "transmogrify returns CODE when given a hash" );
is( $cr->("foo"),         "FOO",  "transmogrify given known key does key CODE" );
is( $cr->("not in hash"), "BAR",  "transmogrify given unknown key does given default CODE" );

my $cr2 = Test::Mock::Cmd::_transmogrify_to_code(
    {
        "baz" => sub { return "BAZ" }
    },
    sub { return "WOP" }
);

is( ref($cr2),             'CODE', "subsequent transmogrify returns CODE when given a hash" );
is( $cr2->("baz"),         "BAZ",  "subsequent transmogrify given known key does key CODE" );
is( $cr2->("not in hash"), "WOP",  "subsequent transmogrify given unknown key does given default CODE" );

is( ref($cr),             'CODE', "transmogrify not changed by subsequent: returns CODE when given a hash" );
is( $cr->("foo"),         "FOO",  "transmogrify not changed by subsequent: given known key does key CODE" );
is( $cr->("not in hash"), "BAR",  "transmogrify not changed by subsequent: given unknown key does given default CODE" );

my $cre = Test::Mock::Cmd::_transmogrify_to_code(
    {},
    sub { return "ZIG" }
);

is( ref($cre),             'CODE', "transmogrify returns CODE when given empty hash" );
is( $cre->("foo"),         "ZIG",  "transmogrify: given key in other check does its own CODE" );
is( $cre->("baz"),         "ZIG",  "transmogrify: given key in other check does its own CODE" );
is( $cre->("not in hash"), "ZIG",  "transmogrify emptyhash: given unknown key does given default CODE" );

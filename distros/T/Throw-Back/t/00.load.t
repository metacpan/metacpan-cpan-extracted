use Test::More;
use Test::Deep;

BEGIN {
    use_ok('Throw::Back');
}

diag("Testing Throw::Back $Throw::Back::VERSION");

{
    local $@;
    eval { Foo->throw::back(); };
    isa_ok( $@, 'Throw::Back', 'void context croak’s w/ exception object' );
}

my $obj = Foo->throw::back();
isa_ok( $obj, 'Throw::Back', 'non-void context returns exception object' );
cmp_deeply(
    { %{$obj} },
    {
        'type'   => 'Foo',
        'string' => 'Foo Exception Thrown',
        'file'   => code( sub { defined $_[0] && length $_[0] } ),
        'line'   => 16,
    },
    'unloadable NS w/ no arg'
);

$obj = Foo->throw::back('Meep!');
cmp_deeply(
    { %{$obj} },
    {
        'type'   => 'Foo',
        'string' => 'Meep!',
        'file'   => code( sub { defined $_[0] && length $_[0] } ),
        'line'   => 29,
    },
    'unloadable NS w/ arg'
);

# TODO: loadable NS w/out new

# TODO: loadable NS w/ new

# TODO: previous exception

my $newline = Foo->throw::back("my error\n");
is( $newline, "my error\n", "trailing newline does not contain line/file" );
my $no_newline = Foo->throw::back("my error");
is( $no_newline, "my error (file: $no_newline->{file}, line: $no_newline->{line})\n", "no trailing newline does contain line/file" );

#### as function ##

my $no_arg = throw::back();
isa_ok( $no_arg, 'Throw::Back', 'throw::back() no arg function return correct obj' );
cmp_deeply(
    { %{$no_arg} },
    {
        'type'   => 'Throw::Back',
        'string' => 'Exception Thrown',
        'file'   => code( sub { defined $_[0] && length $_[0] } ),
        'line'   => __LINE__ - 8,
    },
    'throw::back() no arg'
);

my $str_arg = throw::back("Error Message");
isa_ok( $str_arg, 'Throw::Back', 'throw::back() string arg function return correct obj' );
cmp_deeply(
    { %{$str_arg} },
    {
        'type'   => 'Throw::Back',
        'string' => 'Error Message',
        'file'   => code( sub { defined $_[0] && length $_[0] } ),
        'line'   => __LINE__ - 8,
    },
    'throw::back() string arg'
);

my $ref_arg = throw::back( { foo => 42 } );
isa_ok( $ref_arg, 'Throw::Back', 'throw::back() ref function return correct obj' );
cmp_deeply(
    { %{$ref_arg} },
    {
        'type'      => 'HASH',
        'exception' => { foo => 42 },
        'file'      => code( sub { defined $_[0] && length $_[0] } ),
        'line'      => __LINE__ - 8,
        'string'    => 'HASH Exception Thrown'
    },
    'throw::back() ref arg'
);

#### TODO cmp_deeply ##

my $st = Bar->throw::stack;
is( $st->{line}, __LINE__ - 1, 'throw::stack() does correct line #' );
ok( exists $st->{call_stack}, 'throw::stack() has call_stack key' );

my $tx = Bar->throw::text("foo bar");
is( $tx->{line}, __LINE__ - 1, 'throw::text() does correct line #' );
ok( !exists $tx->{call_stack}, 'throw::text() does not have call_stack key' );

my $sttx = Bar->throw::stack::text("bar baz");
is( $sttx->{line}, __LINE__ - 1, 'throw::stack::text() does correct line #' );
ok( exists $sttx->{call_stack}, 'throw::stack::text() has call_stack key' );

#### caller persepctive ##

sub foo {
    throw::back();
}

sub bar {
    throw::stack();
}

my $fc = foo();
is( $fc->{line}, __LINE__ - 1, 'throw::back line is from caller perspective' );

my $bc = bar();
is( $bc->{line}, __LINE__ - 1, 'throw::* line is from caller perspective' );

#### deeper caller perpective ##

sub baz {
    bar();
}

sub wap {
    baz();
}

my $wap = wap;
is( $wap->{line}, __LINE__ - 1, 'depth reported at correct frame' );

done_testing;

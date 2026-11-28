use strict;
use Test::More;

# The connection charset can only be chosen when connecting: check the
# attributes given to DBI, without a server
plan skip_all => "DBI is needed for this test" unless ( eval { require DBI } );

my $class = 'Web::Session::MariaDBJSON';
my $store = 'Web::Session::Store::MariaDBJSON';
plan skip_all => "$class can't be loaded" unless ( eval "require $class" );

my @calls;
{
    no warnings 'redefine';
    *DBI::connect = sub {
        my ( $c, @a ) = @_;
        push @calls, [ connect => @a ];
        return bless {}, 'FakeDbh';
    };
    *DBI::connect_cached = sub {
        my ( $c, @a ) = @_;
        push @calls, [ connect_cached => @a ];
        return bless {}, 'FakeDbh';
    };
}

foreach my $dsn ( 'dbi:mysql:database=s', 'DBI:mysql:database=s' ) {
    is( $store->connectAttributes($dsn)->{mysql_enable_utf8mb4},
        1, "utf8mb4 requested with DBD::mysql ($dsn)" );
}
ok(
    !exists $store->connectAttributes('dbi:MariaDB:database=s')
      ->{mysql_enable_utf8mb4},
    'no mysql_* attribute with DBD::MariaDB'
);

# Class-level handle (searchOn, deleteIfLowerThan...)
my $args =
  { DataSource => 'dbi:mysql:database=s', UserName => 'u', Password => 'p' };
@calls = ();
$class->_classDbh($args);
is( $calls[0]->[0], 'connect_cached', 'class handle uses connect_cached' );
is_deeply(
    [ @{ $calls[0] }[ 1 .. 3 ] ],
    [ 'dbi:mysql:database=s', 'u', 'p' ],
    'connection parameters'
);
is( $calls[0]->[4]->{mysql_enable_utf8mb4}, 1, 'class handle: utf8mb4' );
ok( $calls[0]->[4]->{RaiseError} && $calls[0]->[4]->{AutoCommit},
    'class handle: RaiseError and AutoCommit' );

@calls = ();
$class->_classDbh( { %$args, DataSource => 'dbi:MariaDB:database=s' } );
ok(
    !exists $calls[0]->[4]->{mysql_enable_utf8mb4},
    'class handle with DBD::MariaDB: no mysql_* attribute'
);

# Store: the connection is reused by default
my $s = bless {}, $store;
@calls = ();
$s->connection( { args => { %$args, TableName => 't' } } );
is( $calls[0]->[0], 'connect_cached', 'store reuses its connection' );
is( $calls[0]->[4]->{mysql_enable_utf8mb4}, 1, 'store: utf8mb4' );
ok( !$s->{disconnect}, 'store keeps the reused connection' );
is( $s->{table_name}, 't', 'store: table name' );

# noreuse: the store opens and closes its own connection
$s     = bless {}, $store;
@calls = ();
$s->connection( { args => { %$args, TableName => 't', noreuse => 1 } } );
is( $calls[0]->[0],                         'connect', 'noreuse: store connects' );
is( $calls[0]->[4]->{mysql_enable_utf8mb4}, 1,         'noreuse: utf8mb4' );
ok( $s->{disconnect}, 'noreuse: store closes the connection it opens' );

# A given handle is used as is
my $h = bless {}, 'FakeDbh';
$s = bless {}, $store;
@calls = ();
$s->connection( { args => { Handle => $h } } );
is( scalar @calls, 0,  'given handle: no new connection' );
is( $s->{dbh},     $h, 'given handle is used' );

done_testing();

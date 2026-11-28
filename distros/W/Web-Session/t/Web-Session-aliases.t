use strict;
use Test::More;

# Postgres, MySQL and MariaDB are aliases of the JSON backends
foreach (
    [ Postgres => 'PgJSON' ],
    [ MySQL    => 'MySQLJSON' ],
    [ MariaDB  => 'MariaDBJSON' ],
  )
{
    my ( $alias, $target ) = map { "Web::Session::$_" } @$_;
  SKIP: {
        skip "$alias can't be loaded", 2 unless ( eval "require $alias" );
        ok( $alias->isa($target), "$alias is a $target" );
        my $self = do { no strict 'refs'; &{"${alias}::populate"}() };
        my $ref  = do { no strict 'refs'; &{"${target}::populate"}() };
        is(
            ref( $self->{object_store} ),
            ref( $ref->{object_store} ),
            "$alias uses the store of $target"
        );
    }
}

done_testing();

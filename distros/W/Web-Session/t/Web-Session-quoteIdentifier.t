use strict;
use warnings;
use Test::More;
use Web::Session::_common;

# Table and column names inserted into SQL queries
{

    package FakeDbh;

    # Quote characters of the real drivers
    my %quote = ( Pg => '"', SQLite => '"', mysql => '`', MariaDB => '`' );
    sub new { bless { Driver => { Name => $_[1] } }, $_[0] }

    sub quote_identifier {
        my ( $self, $name ) = @_;
        my $q = $quote{ $self->{Driver}->{Name} };
        $name =~ s/$q/$q$q/g;
        return "$q$name$q";
    }
}

my $class = 'Web::Session::_common';
foreach (
    [ Pg       => 'sessions',        '"sessions"' ],
    [ Pg       => 'Sessions',        '"sessions"' ],
    [ Pg       => '_whatToTrace',    '"_whattotrace"' ],
    [ Pg       => 'order',           '"order"' ],
    [ Pg       => 'Public.Sessions', '"public"."sessions"' ],
    [ Pg       => 'a"b',             'a"b' ],
    [ mysql    => '_whatToTrace',    '`_whatToTrace`' ],
    [ mysql    => 'db.Sessions',     '`db`.`Sessions`' ],
    [ mysql    => '`sessions`',      '`sessions`' ],
    [ MariaDB  => 'order',           '`order`' ],
    [ SQLite   => '_whatToTrace',    '"_whatToTrace"' ],
    [ Oracle   => '_whatToTrace',    '_whatToTrace' ],
    [ Sybase   => "a'b",             "a''b" ],
    [ Informix => 'sessions',        'sessions' ],
  )
{
    my ( $driver, $name, $expected ) = @$_;
    is( $class->_quoteIdentifier( FakeDbh->new($driver), $name ),
        $expected, "$driver: $name" );
}

is( $class->_tableName( FakeDbh->new('Pg'), { TableName => 'Sessions' } ),
    '"sessions"', '_tableName with TableName' );
{
    no warnings 'once';
    local $Apache::Session::Store::DBI::TableName = 'sessions';
    is( $class->_tableName( FakeDbh->new('mysql'), {} ),
        '`sessions`', '_tableName without TableName' );
}

# With a real driver
SKIP: {
    skip 'DBD::SQLite is needed', 1
      unless eval { require DBI; require DBD::SQLite; 1 };
    my $dbh = DBI->connect( 'dbi:SQLite:dbname=:memory:', '', '' );
    is( $class->_quoteIdentifier( $dbh, 'a"b' ),
        'a"b', 'SQLite: name with quotes unchanged' );
    is( $class->_quoteIdentifier( $dbh, 'order' ),
        '"order"', 'SQLite: real quote_identifier()' );
}

done_testing();

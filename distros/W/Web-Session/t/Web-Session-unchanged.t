# Unchanged sessions are not rewritten: SQL stores skip the UPDATE when the
# serialized data is the one the database holds (see Web::Session::Store::DBI)

use strict;
use warnings;
use Test::More;
use File::Temp qw(mktemp);
use JSON;
use Storable qw(freeze);

plan skip_all => "DBD::SQLite is needed for this test"
  unless eval {
    require DBI;
    require DBD::SQLite;
    1;
  };

use_ok('Web::Session::SQLite');
use_ok('Web::Session::Serialize::JSON');

my $dbfile = mktemp('tmp.db_XXXX');
END { unlink $dbfile if ( defined $dbfile ) }

my $dbh = DBI->connect( "dbi:SQLite:dbname=$dbfile", '', '',
    { RaiseError => 1, PrintError => 0, sqlite_unicode => 1 } );
$dbh->do( 'CREATE TABLE sessions(id char(64) not null primary key,'
      . 'a_session text,uid text)' );

# Statements really executed on the sessions table (FOR EACH ROW triggers)
$dbh->do('CREATE TABLE counts(op text primary key, n int)');
$dbh->do(q{INSERT INTO counts VALUES ('insert', 0), ('update', 0)});
foreach my $op (qw(insert update)) {
    $dbh->do( "CREATE TRIGGER count_$op AFTER "
          . uc($op)
          . " ON sessions BEGIN UPDATE counts SET n = n + 1"
          . " WHERE op = '$op'; END" );
}

sub counts {
    return { map { @$_ }
          @{ $dbh->selectall_arrayref('SELECT op, n FROM counts') } };
}

# Changes of the counters done by $code
sub ops {
    my ($code) = @_;
    my $before = counts();
    $code->();
    my $after = counts();
    return join ',',
      map { "$_=" . ( $after->{$_} - $before->{$_} ) } qw(insert update);
}

my $class = 'Web::Session::SQLite';
my $args  = {
    DataSource => "dbi:SQLite:$dbfile",
    Index      => 'uid',
};

my $wide = "\x{c9}lodie \x{3a9}";
my %data = (
    uid  => 'dwho',
    cn   => $wide,
    list => [ 1, 2, { b => 1, a => 2 } ],
    map { ( "k$_" => $_ ) } 1 .. 20
);

sub row {
    my ($id) = @_;
    return $dbh->selectrow_arrayref(
        'SELECT a_session, uid FROM sessions WHERE id = ?',
        undef, $id );
}

# Creation: INSERT at tie, then UPDATE of the data stored
my $id;
is(
    ops(
        sub {
            my %s;
            tie %s, $class, undef, $args;
            $s{$_} = $data{$_} foreach ( keys %data );
            $id = $s{_session_id};
            untie %s;
        }
    ),
    'insert=1,update=1',
    'New session: INSERT, then UPDATE'
);
is( row($id)->[1], 'dwho', 'Index column written' );

is(
    ops(
        sub {
            my %s;
            tie %s, $class, $id, $args;
            my $tmp = $s{uid};
            untie %s;
        }
    ),
    'insert=0,update=0',
    'Read only: no UPDATE'
);

my $stored = row($id)->[0];
is(
    ops(
        sub {
            my %s;
            tie %s, $class, $id, $args;
            my @keys = keys %s;
            $s{$_} = $s{$_} foreach (@keys);
            untie %s;
        }
    ),
    'insert=0,update=0',
    'Same values stored back: no UPDATE'
);
is( row($id)->[0], $stored, 'Row unchanged' );

is(
    ops(
        sub {
            my %s;
            tie %s, $class, $id, $args;
            my %copy = %s;
            %s = ();
            $s{$_} = $copy{$_} foreach ( reverse sort keys %copy );
            untie %s;
        }
    ),
    'insert=0,update=0',
    'Same data, keys inserted in another order: no UPDATE'
);

is(
    ops(
        sub {
            my %s;
            tie %s, $class, $id, $args;
            $s{uid} = 'rtyler';
            untie %s;
        }
    ),
    'insert=0,update=1',
    'Real change: UPDATE'
);
is( row($id)->[1], 'rtyler', 'Index column updated' );

is(
    ops(
        sub {
            my %s;
            tie %s, $class, $id, $args;
            $s{cn} = "$wide!";
            untie %s;
        }
    ),
    'insert=0,update=1',
    'Change of a non-ASCII value: UPDATE'
);
{
    my %s;
    tie %s, $class, $id, $args;
    is( $s{cn}, "$wide!", 'Non-ASCII value written' );
    $s{cn} = $wide;
    untie %s;
}

# Several saves in one tie: each one is compared with the last data written
{
    my $ops = ops(
        sub {
            my %s;
            tie %s, $class, $id, $args;
            $s{uid} = 'other';
            tied(%s)->save;
            $s{uid} = 'other';
            tied(%s)->save;
            untie %s;
        }
    );
    is( $ops, 'insert=0,update=1', 'Second save of the same data skipped' );
    is( row($id)->[1], 'other',    'First save written' );

    $ops = ops(
        sub {
            my %s;
            tie %s, $class, $id, $args;
            $s{uid} = 'tmp';
            tied(%s)->save;

            # Back to the value read at tie: the database holds "tmp"
            $s{uid} = 'other';
            untie %s;
        }
    );
    is( $ops,          'insert=0,update=2', 'Back to the data read: UPDATE' );
    is( row($id)->[1], 'other',             'Last save written' );
}

# Rows written by previous versions (keys in random order) or normalized by
# the database (jsonb): same data, no UPDATE
{
    my $j = JSON->new->allow_nonref;
    my $s = do {
        my %s;
        tie %s, $class, $id, $args;
        my %copy = %s;
        untie %s;
        \%copy;
    };
    my $text = '{'
      . join( ', ',
        map { $j->encode($_) . ': ' . $j->encode( $s->{$_} ) }
          reverse sort keys %$s ) . '}';
    $dbh->do( 'UPDATE sessions SET a_session = ? WHERE id = ?',
        undef, $text, $id );
    is(
        ops(
            sub {
                my %s;
                tie %s, $class, $id, $args;
                my @keys = keys %s;
                $s{$_} = $s{$_} foreach (@keys);
                untie %s;
            }
        ),
        'insert=0,update=0',
        'Non canonical row, same data: no UPDATE'
    );
    is( row($id)->[0], $text, 'Non canonical row kept' );
    is(
        ops(
            sub {
                my %s;
                tie %s, $class, $id, $args;
                $s{uid} = 'dwho';
                untie %s;
            }
        ),
        'insert=0,update=1',
        'Non canonical row, real change: UPDATE'
    );
    like( row($id)->[0], qr/^\{"_session_id":/, 'Row now canonical' );
}

# A handle without sqlite_unicode returns the stored text as UTF-8 bytes,
# while the serializer produces characters: they must be compared as bytes
{
    my $bdbh = DBI->connect( "dbi:SQLite:dbname=$dbfile", '', '',
        { RaiseError => 1, PrintError => 0, AutoCommit => 0 } );
    my $bargs = { %$args, Handle => $bdbh };
    my $read;
    is(
        ops(
            sub {
                my %s;
                tie %s, $class, $id, $bargs;
                $read = tied(%s)->{object_store}->{stored_serialized};
                is( $s{cn}, $wide, 'Bytes handle: non-ASCII value read' );
                my @keys = keys %s;
                $s{$_} = $s{$_} foreach (@keys);
                untie %s;
            }
        ),
        'insert=0,update=0',
        'Bytes handle, same values stored back: no UPDATE'
    );
    ok( !utf8::is_utf8($read) && $read =~ /[\x80-\xff]/,
        'Bytes handle: row read as UTF-8 bytes' );
    is(
        ops(
            sub {
                my %s;
                tie %s, $class, $id, $bargs;
                $s{cn} = "\x{e9}";
                untie %s;
            }
        ),
        'insert=0,update=1',
        'Bytes handle, change of a non-ASCII value: UPDATE'
    );
    is(
        ops(
            sub {
                my %s;
                tie %s, $class, $id, $bargs;
                $s{cn} = "\x{e9}";
                untie %s;
            }
        ),
        'insert=0,update=0',
        'Bytes handle, same Latin-1 character stored back: no UPDATE'
    );
    {
        my %s;
        tie %s, $class, $id, $args;
        is( $s{cn}, "\x{e9}", 'Bytes handle: value written' );
        $s{cn} = $wide;
        untie %s;
    }
    $bdbh->disconnect;
}

is(
    ops(
        sub {
            my %s;
            tie %s, $class, $id, { %$args, RewriteUnchanged => 1 };
            $s{uid} = $s{uid};
            untie %s;
        }
    ),
    'insert=0,update=1',
    'RewriteUnchanged: UPDATE'
);

# _unchanged() cases that SQLite can't produce
{
    my $store   = bless {}, 'Web::Session::Store::DBI';
    my $data    = { uid => 'dwho', cn => $wide, n => 1 };
    my $session = {
        args        => {},
        data        => $data,
        serialize   => \&Web::Session::Serialize::JSON::serialize,
        unserialize => \&Web::Session::Serialize::JSON::unserialize,
    };
    Web::Session::Serialize::JSON::serialize($session);
    my $new = $session->{serialized};

    sub unchanged {
        my ( $store, $session, $old ) = @_;
        $store->{stored_serialized} = $old;
        return Web::Session::Store::DBI::_unchanged( $store, $session );
    }

    ok( !unchanged( $store, $session, undef ), 'Nothing read: write' );
    ok( unchanged( $store,  $session, $new ),  'Same characters' );
    my $bytes = $new;
    utf8::encode($bytes);
    ok(
        unchanged( $store, $session, $bytes ),
        'Same data returned as UTF-8 bytes'
    );

    # As PostgreSQL returns a jsonb column
    my $jsonb = qq'{"n": 1, "cn": "$wide", "uid": "dwho"}';
    ok( unchanged( $store, $session, $jsonb ), 'Normalized JSON, same data' );
    ok(
        !unchanged( $store, $session, qq'{"n": 1, "cn": "$wide", "uid": "x"}' ),
        'Normalized JSON, other data'
    );
    ok(
        !unchanged(
            $store, $session, qq'{"n": "1", "cn": "$wide", "uid": "dwho"}'
        ),
        'Number read as a string: write'
    );
    ok(
        !unchanged( $store, $session, freeze($data) ),
        'Storable row, same data: rewritten as JSON'
    );
    {
        local $@ = 'kept';
        ok( !unchanged( $store, $session, '{invalid' ), 'Invalid row: write' );
        is( $@, 'kept', '$@ kept' );
    }
    {
        local $session->{args} = { RewriteUnchanged => 1 };
        ok( !unchanged( $store, $session, $new ), 'RewriteUnchanged: write' );
    }

    # Stores that don't inherit from Web::Session::Store::DBI
    no warnings qw(redefine once);
    my @calls;
    my $db   = $jsonb;
    my $fake = sub {
        my ( $op, $session ) = @_;
        push @calls, $op;
        if ( $op eq 'materialize' ) {
            $session->{serialized} = $db;
        }
        else {
            $db = $session->{serialized};
        }
        return 1;
    };
    my $check = sub {
        my ($store) = @_;
        my $name = ref $store;
        @calls = ();
        my $s = { %$session, serialized => undef, data => undef };
        $store->materialize($s);
        Web::Session::Serialize::JSON::unserialize($s);
        Web::Session::Serialize::JSON::serialize($s);
        $store->update($s);
        $s->{data}->{uid} = 'other';
        Web::Session::Serialize::JSON::serialize($s);
        $store->update($s);
        $store->update($s);
        is(
            "@calls",
            'materialize update',
            "$name: unchanged data not written"
        );

        # New session: insert() doesn't keep what it wrote
        @calls = ();
        $store = ref($store)->new;
        $store->insert($s);
        $store->update($s);
        is(
            "@calls",
            "insert update",
            "$name: insert unchanged, then update writes"
        );
    };

  SKIP: {
        skip 'Web::Session::Store::Patroni needs DBD::Pg', 2
          unless eval { require Web::Session::Store::Patroni; 1 };
        local *Web::Session::Store::Patroni::_try = sub {
            my ( $self, $op, $session ) = @_;
            return $fake->( $op, $session );
        };
        $db = $jsonb;
        $check->( Web::Session::Store::Patroni->new );
    }
    {
        require Web::Session::Store::MariaDBJSON;
        local *Apache::Session::Store::DBI::materialize =
          sub { $fake->( 'materialize', $_[1] ) };
        local *Apache::Session::Store::DBI::update =
          sub { $fake->( 'update', $_[1] ) };
        local *Apache::Session::Store::DBI::insert =
          sub { $fake->( 'insert', $_[1] ) };
        $db = $jsonb;
        $check->( Web::Session::Store::MariaDBJSON->new );
    }
}

done_testing();

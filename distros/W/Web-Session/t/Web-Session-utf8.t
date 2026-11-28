use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

# Non-ASCII values must survive a round trip through each backend
my $latin = "\x{c9}lodie";            # Latin-1 range
my $wide  = "\x{c9}lodie \x{3a9}";    # beyond Latin-1

sub roundTrip {
    my ( $label, $class, $args, @values ) = @_;
    foreach my $v (@values) {
        ( my $l = $v ) =~ s/[^ -~]/?/g;
        $l = "$label: $l";
        my %session;
        tie %session, $class, undef, $args;
        $session{uid}  = 'u8';
        $session{cn}   = $v;
        $session{list} = [$v];
        my $id = $session{_session_id};
        untie %session;

        my $check = sub {
            my ($step) = @_;
            my $l = "$l$step";
            tie %session, $class, $id, $args;
            is( $session{cn}, $v, "$l retrieved" );
            is_deeply( $session{list}, [$v], "$l in array retrieved" );
            untie %session;
            my $r = $class->get_key_from_all_sessions($args);
            is( $r->{$id}->{cn}, $v, "$l: get_key_from_all_sessions" );
            $r = $class->get_key_from_all_sessions( $args, sub { $_[0]->{cn} } );
            is( $r->{$id}, $v, "$l: get_key_from_all_sessions with a code ref" );
            $r = $class->get_key_from_all_sessions( $args, ['cn'] );
            is( $r->{$id}->{cn}, $v, "$l: get_key_from_all_sessions with fields" );
            $r = $class->searchOn( $args, 'uid', 'u8' );
            is( $r->{$id}->{cn}, $v, "$l: searchOn" );
            $r = $class->searchOn( $args, 'uid', 'u8', 'cn' );
            is( $r->{$id}->{cn}, $v, "$l: searchOn with fields" );
        };
        $check->('');

        # Update the session: the stores rewrite the non-ASCII values
        tie %session, $class, $id, $args;
        $session{x} = 1;
        untie %session;
        $check->(' after update');

        tie %session, $class, $id, $args;
        tied(%session)->delete;
    }
}

my $dir = tempdir( CLEANUP => 1 );

# File: the serialized session is always written as UTF-8
{
    local $SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /^Wide character/ };
    require Web::Session::File;
    roundTrip(
        'File',
        'Web::Session::File',
        { Directory => $dir, LockDirectory => $dir },
        $latin, $wide
    );

    # Latin-1 range characters that also form a valid UTF-8 sequence: the
    # session must survive, which needs the file to hold UTF-8
    my $ambiguous = "\x{c3}\x{a9}lodie";
    my %session;
    tie %session, 'Web::Session::File', undef,
      { Directory => $dir, LockDirectory => $dir };
    $session{uid} = 'u8';
    $session{cn}  = $ambiguous;
    my $id = $session{_session_id};
    untie %session;

    my $raw;
    {
        local $/;
        open my $fh, '<:raw', "$dir/$id" or die $!;
        $raw = <$fh>;
        close $fh;
    }
    my $decoded = $raw;
    ok( utf8::decode($decoded), 'File: session file is valid UTF-8' );
    like( $decoded, qr/\Q$ambiguous\E/,
        'File: Latin-1 range value is stored as UTF-8' );

    tie %session, 'Web::Session::File', $id,
      { Directory => $dir, LockDirectory => $dir };
    is( $session{cn}, $ambiguous,
        'File: Latin-1 value valid as UTF-8 is read back unchanged' );
    tied(%session)->delete;
    untie %session;
}

SKIP: {
    skip 'DBD::SQLite is needed', 56
      unless eval { require DBI; require DBD::SQLite; 1 };
    require Web::Session::SQLite;
    my $ds  = "dbi:SQLite:$dir/sessions.db";
    my $dbh = DBI->connect( $ds, '', '', { RaiseError => 1 } );
    $dbh->do( 'CREATE TABLE sessions (id char(64) not null primary key,'
          . ' a_session text, uid text)' );
    roundTrip(
        'SQLite',
        'Web::Session::SQLite',
        { DataSource => $ds, Index => 'uid' },
        $latin, $wide
    );

    # Handle without sqlite_unicode: UTF-8 bytes are returned
    roundTrip(
        'SQLite handle',
        'Web::Session::SQLite',
        { DataSource => $ds, Handle => $dbh, Commit => 0, Index => 'uid' },
        $latin, $wide
    );
}

# Redis can't store characters above U+00FF. It stores Latin-1, so
# "\x{c3}\x{a9}" is stored as valid UTF-8: it must not be read as "\x{e9}"
SKIP: {
    skip 'Set REDIS_URL to run Redis tests', 37 unless $ENV{REDIS_URL};
    skip 'Redis module is needed', 37
      unless eval { require Web::Session::Redis; 1 };
    my $class = 'Web::Session::Redis';
    my $args  = {
        server => $ENV{REDIS_URL},

        # Not the database of the other Redis tests, which flush theirs: they
        # can run in parallel
        database => ( ( $ENV{REDIS_DBNUM} || 15 ) + 11 ) % 16,
        Index    => 'uid'
    };
    roundTrip( 'Redis', $class, $args, $latin, "\x{c3}\x{a9}" );

    # Index entry of the previous value must be removed on update
    my $redis = $class->_getRedis($args);
    foreach my $t (
        [ "m\x{e9}", 'toto' ],
        [ 'dwho',    'rtyler' ],
        [ 'dwho',    'rtyler', cn => $latin ],
      )
    {
        my ( $old, $new, %data ) = @$t;
        ( my $l = "$old -> $new" ) =~ s/[^ -~]/?/g;
        $l .= ' with non-ASCII data' if (%data);
        my @warn;
        local $SIG{__WARN__} = sub { push @warn, @_ };
        my %session;
        tie %session, $class, undef, $args;
        $session{uid} = $old;
        $session{$_} = $data{$_} foreach ( keys %data );
        my $id = $session{_session_id};
        untie %session;
        tie %session, $class, $id, $args;
        $session{uid} = $new;
        untie %session;
        ok( !$redis->sismember( "uid_$old", $id ), "Index $l: old removed" );
        ok( $redis->sismember( "uid_$new",  $id ), "Index $l: new added" );
        is_deeply( \@warn, [], "Index $l: no warning" );
        tie %session, $class, $id, $args;
        tied(%session)->delete;
    }
}

done_testing();

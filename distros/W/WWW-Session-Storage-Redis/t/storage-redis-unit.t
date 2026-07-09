#!perl

use strict;
use warnings;

use File::Temp ();
use Test::More;
use Test::Exception;

# Inline mock of Cache::Redis that records every call, so the adapter
# logic can be tested without the real Cache::Redis or a redis server.
BEGIN {
    package Cache::Redis;

    our @calls;

    sub new {
        my ( $class, %args ) = @_;
        return bless { args => \%args, store => {} }, $class;
    }

    sub set {
        my ( $self, $key, $value, $expire ) = @_;
        push @calls, [ set => $key, $value, $expire ];
        $self->{store}{$key} = $value;
        return 1;
    }

    sub get {
        my ( $self, $key ) = @_;
        push @calls, [ get => $key ];
        return $self->{store}{$key};
    }

    sub remove {
        my ( $self, $key ) = @_;
        push @calls, [ remove => $key ];
        return delete $self->{store}{$key} ? 1 : 0;
    }

    $INC{'Cache/Redis.pm'} = __FILE__;
}

use WWW::Session::Storage::Redis;

my $TEN_YEARS = 60 * 60 * 24 * 365 * 10;

subtest 'new() forwards options to Cache::Redis' => sub {
    my $storage =
        WWW::Session::Storage::Redis->new( { server => '127.0.0.1:6379' } );

    isa_ok( $storage, 'WWW::Session::Storage::Redis' );
    is( $storage->{redis}{args}{server},
        '127.0.0.1:6379', 'server option forwarded' );
};

subtest 'new() requires the server option' => sub {
    throws_ok { WWW::Session::Storage::Redis->new( {} ) }
        qr/server/, 'croaks when the server option is missing';
    throws_ok { WWW::Session::Storage::Redis->new() }
        qr/server/, 'croaks when no options are given';
};

subtest 'save() forwards the expiration time' => sub {
    my $storage =
        WWW::Session::Storage::Redis->new( { server => '127.0.0.1:6379' } );

    ok( $storage->save( 'sid1', 600, 'data1' ), 'save returns true' );

    is_deeply(
        $Cache::Redis::calls[-1],
        [ set => 'sid1', 'data1', 600 ],
        'set called with the given TTL'
    );
};

subtest 'save() with expires = -1 uses an explicit long TTL' => sub {
    my $storage =
        WWW::Session::Storage::Redis->new( { server => '127.0.0.1:6379' } );

    $storage->save( 'sid2', -1, 'data2' );

    my $ttl = $Cache::Redis::calls[-1][3];
    ok( defined $ttl,
        'TTL is defined (not left to Cache::Redis default_expires_in)' );
    cmp_ok( $ttl, '>=', $TEN_YEARS, 'TTL is at least ten years' );
};

subtest 'retrieve() returns the stored data' => sub {
    my $storage =
        WWW::Session::Storage::Redis->new( { server => '127.0.0.1:6379' } );

    $storage->save( 'sid3', 600, 'data3' );
    is( $storage->retrieve('sid3'), 'data3', 'stored data returned' );
    is( $storage->retrieve('no-such-sid'), undef, 'undef for unknown sid' );
};

subtest 'delete() removes the data and reports success' => sub {
    my $storage =
        WWW::Session::Storage::Redis->new( { server => '127.0.0.1:6379' } );

    $storage->save( 'sid4', 600, 'data4' );
    ok( $storage->delete('sid4'), 'delete returns true' );
    is( $storage->retrieve('sid4'), undef, 'data gone after delete' );
};

subtest 'new() fails clearly when Cache::Redis is not installed' => sub {

    # The mock is already loaded in this process, so exercise the
    # missing-module path in a child perl with Cache/Redis.pm blocked.
    my $code = <<'EOF';
unshift @INC, sub {
    die "Cache::Redis blocked for test\n" if $_[1] eq 'Cache/Redis.pm';
    return;
};
require WWW::Session::Storage::Redis;
eval { WWW::Session::Storage::Redis->new( { server => 'localhost:6379' } ) };
print $@ ? "DIED: $@" : "LIVED";
EOF

    my ( $fh, $tmpfile ) = File::Temp::tempfile( UNLINK => 1 );
    print {$fh} $code;
    close $fh;

    my $out = `"$^X" -Ilib $tmpfile 2>&1`;

    like( $out, qr/^DIED: /, 'new() dies when Cache::Redis is missing' );
    like(
        $out,
        qr/install the Cache::Redis module/,
        'error message says to install Cache::Redis'
    );
};

done_testing();

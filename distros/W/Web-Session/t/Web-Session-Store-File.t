use strict;
use warnings;
use File::Temp qw(tempdir);
use Test::More;

use_ok('Web::Session::Store::File');

my $dir = tempdir( CLEANUP => 1 );

sub store {
    my ( $method, $serialized ) = @_;
    my $store = Web::Session::Store::File->new;
    my $session = {
        args       => { Directory => $dir },
        data       => { _session_id => 'abc' },
        serialized => $serialized,
    };
    my $ok = eval { $store->$method($session); 1 };
    my $err = $@;
    $store->close;
    return ( $ok, $err );
}

sub content {
    local $/;
    open my $fh, '<:raw', "$dir/abc" or die $!;
    return <$fh>;
}

# Like Apache::Session::Store::File, insert() must not overwrite an existing
# session: a shorter session would otherwise leave the end of the old one
my ( $ok, $err ) = store( insert => '{"long":"xxxxxxxxxxxxxxxx"}' );
ok( $ok, 'First insert succeeds' ) or diag $err;
( $ok, $err ) = store( insert => '{}' );
ok( !$ok, 'Second insert with the same id fails' );
like( $err, qr/Object already exists in the data store/,
    'Second insert: same error as the parent store' );
is( content(), '{"long":"xxxxxxxxxxxxxxxx"}', 'Existing session unchanged' );

# update() truncates
( $ok, $err ) = store( update => '{}' );
ok( $ok, 'Update succeeds' ) or diag $err;
is( content(), '{}', 'Update replaces the whole file' );

done_testing();

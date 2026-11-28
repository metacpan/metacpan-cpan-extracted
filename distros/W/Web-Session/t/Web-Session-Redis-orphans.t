use strict;
use warnings;
use Test::More;

my $class = 'Web::Session::Redis';

plan skip_all => 'Redis module is needed' unless eval "require $class";

# Orphan removal without Lua
{

    package FakeRedis;
    our @log;
    our $lua    = 0;
    our $exists = 0;
    sub new { bless {}, shift }

    sub eval {
        die "ERR unknown command 'eval'\n" unless $lua;
        push @log, 'eval';
        1;
    }
    sub watch   { push @log, 'watch' }
    sub unwatch { push @log, 'unwatch' }
    sub exists  { push @log, 'exists'; $exists }
    sub multi   { push @log, 'multi' }
    sub srem    { shift; push @log, join ' ', 'srem', @_ }
    sub exec    { push @log, 'exec' }
    sub discard { push @log, 'discard' }
}
{
    my $err = '';
    local *STDERR;
    open STDERR, '>', \$err;
    my $r = FakeRedis->new;
    $class->_removeOrphan( $r, 'uid_x', 'k' );
    is_deeply(
        \@FakeRedis::log,
        [ 'watch', 'exists', 'multi', 'srem uid_x k', 'exec' ],
        'fallback: WATCH/MULTI/EXEC'
    );
    like( $err, qr/^Redis EVAL failed/, 'fallback: error printed' );
    @FakeRedis::log    = ();
    $err               = '';
    $FakeRedis::exists = 1;
    $class->_removeOrphan( $r, 'uid_x', 'k' );
    is_deeply(
        \@FakeRedis::log,
        [ 'watch', 'exists', 'unwatch' ],
        'fallback: existing session is kept'
    );
    is( $err, '', 'fallback: error printed once' );
    @FakeRedis::log = ();
    $FakeRedis::lua = 1;
    $class->_removeOrphan( $r, 'uid_x', 'k' );
    is_deeply( \@FakeRedis::log, ['eval'], 'Lua used when available' );
}

done_testing();

use strict;
use warnings;
use Test::More;

# Store::Redis::update with a mock Redis object (no server needed)
package MockRedis;
sub new { bless { calls => [] }, shift }

sub AUTOLOAD {
    my $self = shift;
    our $AUTOLOAD;
    ( my $m = $AUTOLOAD ) =~ s/.*:://;
    return if $m eq 'DESTROY';
    push @{ $self->{calls} }, [ $m, @_ ];
    return;
}

package main;

plan skip_all => 'Redis module is needed'
  unless eval { require Web::Session::Store::Redis; 1 };

sub run {
    my ( $index, %extra ) = @_;
    my $store = bless { cache => MockRedis->new },
      'Web::Session::Store::Redis';
    my $unserialized = 0;
    $store->update(
        {
            data       => { _session_id => 'id1', uid => 'dwho' },
            serialized => '{}',
            args       => { Index => $index, %extra },
            unserialize => sub { $unserialized++ },
        }
    );
    return ( $store->{cache}->{calls}, $unserialized );
}

my ( $calls, $unser ) = run('');
is_deeply( $calls, [ [ 'set', 'id1', '{}' ] ],
    'Without index: session written, no read' );
is( $unser, 0, 'Without index: old session not decoded' );

( $calls, $unser ) = run( '', TTL => 10 );
is_deeply( $calls, [ [ 'set', 'id1', '{}', 'EX', 10 ] ],
    'Without index: TTL is kept' );

( $calls, $unser ) = run( [] );
is_deeply( $calls, [ [ 'set', 'id1', '{}' ] ], 'Empty index list' );

( $calls, $unser ) = run('uid');
is_deeply(
    [ map { $_->[0] } @$calls ],
    [qw(get set sadd)],
    'With index: old session read, index updated'
);

done_testing();

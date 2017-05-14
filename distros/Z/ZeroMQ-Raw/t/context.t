use strict;
use warnings;
use Test::More;
use Test::Exception;
use POSIX qw(EINVAL);

use ZeroMQ::Raw;


my $ctx;
lives_ok {
    $ctx = ZeroMQ::Raw::Context->new( threads => 1 );
} 'created context ok';

ok $ctx, 'has some value';

lives_ok {
    undef $ctx;
} 'undef lives';

throws_ok {
    $ctx = ZeroMQ::Raw::Context->new( threads => -1 );
} qr/Invalid number of threads \(-1\) passed to zmq_init/,
    'dies when you try to allocate -1 threads';

is 0+$!, 0+EINVAL, "got EINVAL in \$! ($!)";

done_testing;

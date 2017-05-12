use strict;
use utf8;
use warnings;

sub {
    return unless ( my $drv = shift )->capabilities->{webStorageEnabled};

    is_deeply scalar $drv->storage, {};
    is_deeply [ $drv->storage ], [];

    eval { $drv->storage( foo => [] ) };
    like $@, qr/^unknown error: 'value' must be a string/;

    $drv->storage( foo => 'bar' );

    is_deeply scalar $drv->storage, { foo => 'bar' };
    is_deeply [ $drv->storage ], ['foo'];

    is $drv->storage('foo'), 'bar';

    $drv->storage( foo => '☃' );

    is_deeply scalar $drv->storage, { foo => '☃' };

    is $drv->storage('foo'), '☃';
}

use lib 't';
use t   '3';

$content = '{"value":["foo"]}';

my @keys = $drv->storage;

reqs_are [ [ GET => '/local_storage' ] ], '->storage (list)';

my $storage = $drv->storage;

reqs_are [ [ GET => '/local_storage' ], [ GET => '/local_storage/key/foo' ] ],
    '->storage (scalar)';

$content = '{}';

$drv->storage( foo => 'bar' );

reqs_are [ [ POST => '/local_storage', {qw/key foo value bar/} ] ],
    '->storage( foo => "bar" )';

use Test::More tests => 9;

use_ok('YAWF::Object::MongoDB');

is_deeply(
    [ YAWF::Object::MongoDB->_resolv_sort('foo') ],
    [ { foo => 1 } ],
    'simplest asc'
);

is_deeply(
    [ YAWF::Object::MongoDB->_resolv_sort( { -asc => 'foo' } ) ],
    [ { foo => 1 } ],
    'simple asc'
);
is_deeply(
    [ YAWF::Object::MongoDB->_resolv_sort( { -desc => 'foo' } ) ],
    [ { foo => -1 } ],
    'simple desc'
);

is_deeply(
    [YAWF::Object::MongoDB->_resolv_sort( [ 'foo', 'bar' ] )],
    [ { foo => 1 }, { bar => 1 } ],
    'multi key asc'
);
is_deeply(
    [YAWF::Object::MongoDB->_resolv_sort( { -desc => [ 'foo', 'bar' ] } )],
    [ { foo => -1 }, { bar => -1 } ],
    'multi key desc'
);

is_deeply(
    [YAWF::Object::MongoDB->_resolv_sort( [ 'bar', { -asc => 'foo' } ] )],
    [ { bar => 1 }, { foo => 1 } ],
    'complex 1'
);
is_deeply(
    
        [YAWF::Object::MongoDB->_resolv_sort(
            [ 'bar', { -desc => [ 'foo', 'baz' ] } ]
        )]
    ,
    [ { bar => 1 }, { foo => -1 }, { baz => -1 } ],
    'complex 2'
);

is_deeply(
    
        [YAWF::Object::MongoDB->_resolv_sort(
            [
                { -desc => [ 'foo1', 'bar1' ] },
                { -asc  => [ 'foo2', 'bar2' ] },
                'foo3',
                { -desc => 'bar3' },
            ]
        )]
    ,
    [
        { foo1 => -1 },
        { bar1 => -1 },
        { foo2 => 1 },
        { bar2 => 1 },
        { foo3 => 1 },
        { bar3 => -1 },
    ],
    'complex 3'
);

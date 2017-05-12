use strict;
use warnings;

use Test::More tests => 20;

use URI::Builder;

my $uri = URI::Builder->new(uri => '?foo=1;foo=2;foo=3');

is_deeply(
    [ $uri->query_param ],
    [ qw( foo )],
    'query_param() returns unique keys',
);

is_deeply(
    [ $uri->query_param('foo') ],
    [ 1, 2, 3 ],
    'query_param(key) returns values',
);

is scalar $uri->query_param('foo'), 1,
   'scalar query_param(key) returns first value';

$uri->query_param_append(bar => 1, 2, 3, 4);
is(
    $uri->as_string,
    '?foo=1;foo=2;foo=3;bar=1;bar=2;bar=3;bar=4',
    'query_param_append puts new parameters at the end',
);

# New 'foo' values should appear after the last foo parameter
is_deeply(
    [ $uri->query_param('foo', $uri->query_param('foo'), 4) ],
    [ 1, 2, 3 ],
    'query_param(key, values) returns the old values',
);
is(
    $uri->as_string,
    '?foo=1;foo=2;foo=3;foo=4;bar=1;bar=2;bar=3;bar=4',
    'query_param(key, values) inlines new values with existing ones'
);

is(
    $uri->query('foo=1&bar=2'),
    'foo=1;foo=2;foo=3;foo=4;bar=1;bar=2;bar=3;bar=4',
    'query(new_query) returns the old query'
);

is_deeply(
    [ $uri->query_form ],
    [ foo => 1, bar => 2 ],
    'query(new_query) overwrites the query_form',
);

is_deeply(
    $uri->query_form_hash({ foo => 1, bar => [ 2, 3 ], baz => [ 4, 5, 6 ] }),
    { foo => 1, bar => 2 },
    'query_form_hash(hash) returns the old hash',
);

is_deeply(
    [ $uri->query_param_delete('bar') ],
    [ 2, 3 ],
    'query_param_delete(key) returns deleted values',
);

is_deeply(
    $uri->query_form_hash,
    { foo => 1, baz => [ 4, 5, 6 ]},
    'query_form_hash() collects multiple values in an array',
);

$uri->query_form_hash({ foo => [ 1, 2, 3, 4 ] });
is_deeply(
    $uri->query_form_hash,
    { foo => [1, 2, 3, 4] },
    'setting query_form_hash works the same in void context',
);

$uri->query_form_hash(foo => [ 1, 2, 3, 4 ]);
is_deeply(
    $uri->query_form_hash,
    { foo => [1, 2, 3, 4] },
    'setting query_form_hash works the same in void context without ref',
);

is $uri->path_query('/foo/bar?x=y'), '?foo=1;foo=2;foo=3;foo=4',
   'path_query returns old value when setting new value';

is $uri->path_query, '/foo/bar?x=y', 'path_query round-trip';
is $uri->path, '/foo/bar', 'path set by path_query';
is $uri->query, 'x=y', 'query set by path_query';

$uri = URI::Builder->new(query_form => [ a => 'b', 'c' ] );
is $uri->as_string, '?a=b;c=', 'odd-sized query_form lists get a blank value';

is( URI::Builder->new(query_form => [ a => ';' ])->query, 'a=%3B' );

# Edge-case behaviour, some of which causes warnings but represents light
# interface abuse which deserves warnings in real life but doesn't justify
# warnings appearing in tests.
local $SIG{__WARN__} = sub {};

$uri->query_form_hash('foo');
is_deeply(
    $uri->query_form_hash,
    { foo => '' },
    'setting query_form_hash with one non-hashref argument makes an empty key',
);

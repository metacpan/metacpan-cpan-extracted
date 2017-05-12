#!/usr/bin/env perl
use strict;
use warnings;
use lib 'lib';
use Test::More;
use XML::LibXML::jQuery;
use Data::Dumper;
use JSON;

my $html = '<div><p data-role="page" data-last-value="42" data-hidden="true" data-extra="null" data-options=\'{"name":"John"}\'></p></div>';
my $p = j($html)->find('p');

my $data = $p->data;

is_deeply $data, {
    role => 'page',
    hidden => JSON::true,
    lastValue => 42,
    options => { name => 'John' },
    extra => undef
}, 'data()';

is $p->data('extra', 42), $p, 'data(key, val)';
is $p->data('extra', undef), $p, 'data(key, undef)';
is $p->data('bar', { count => 40, some => 'thing' }), $p, 'data(key, obj)';

is_deeply $data, {
    role => 'page',
    hidden => JSON::true,
    lastValue => 42,
    options => { name => 'John' },
    extra => 42,
    bar => { count => 40, some => 'thing' }
}, 'data was set';


is $p->data('extra'), 42, 'data(key)';

my $new_data = { baz => [1, 2, 3] };
is $p->data($new_data), $p, 'data(obj)';

is_deeply $p->data, $new_data, 'data replaced';

is $p->data, $new_data, 'data hashref replaced';


# data-*
$p = j($html)->find('p');

is $p->data('role'), 'page', 'data(key) - data-role';
is $p->data('extra'), undef, 'data(key) - data-extra null';
is $p->data('hidden'), JSON::true, 'data(key) - data-hidden (boolean)';
is $p->data('lastValue'), 42, 'data(key) - data-last-value (decamelize)';
is_deeply $p->data('options'), { name => 'John' }, 'data(key) - data-options (JSON)';


#diag Dumper(XML::LibXML::jQuery->data);
undef $p;
is_deeply "XML::LibXML::jQuery"->data, {}, 'data storage empty after document is destructed';


done_testing;


sub diag_refcount {

    my $data = "XML::LibXML::jQuery"->data;

    foreach (sort keys %$data) {
        printf "document(%s) %1 refs\n"
    }
}

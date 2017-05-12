#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Exception;

use_ok 'WebService::Box::Types::By';

throws_ok { WebService::Box::Types::By->new }
    qr/Missing .* id, login, name, type/,
    'new object without params dies';

throws_ok { WebService::Box::Types::By->new( id => 123 ) }
    qr/Missing .* login, name, type/,
    'new object with id only dies';

throws_ok {
        WebService::Box::Types::By->new(
            id   => 123,
            name => 'reneeb', 
        );
    }
    qr/Missing .* login, type/,
    'new object with id and name only dies';

my $ob = WebService::Box::Types::By->new(
    id    => 123,
    name  => 'abcdef123',
    login => 'hefe0815',
    type  => 'user',
);

isa_ok $ob, 'WebService::Box::Types::By', 'new object created';
is $ob->id, 123, 'id';
is $ob->name, 'abcdef123', 'name';
is $ob->login, 'hefe0815', 'login';
is $ob->type, 'user', 'user';


done_testing();

package MyApp {
    use Mojolicious::Lite;
    app->start;
};

use strict;
use warnings;

use Test::More;
use Test::Mojo;

plan tests => 4;

use_ok 'Test::Mojo::Role::StopOnFail';

ok my $t = Test::Mojo->with_roles('+StopOnFail')->new('MyApp');

isa_ok $t, 'Test::Mojo';

ok $t->does('Test::Mojo::Role::StopOnFail');

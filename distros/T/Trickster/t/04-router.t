use strict;
use warnings;
use Test::More;

use_ok('Trickster::Router');

my $router = Trickster::Router->new;

# Test basic routing
$router->add_route('GET', '/users', sub { 'list' });
$router->add_route('GET', '/users/:id', sub { 'show' });

my $match = $router->match('GET', '/users');
ok($match, 'Matched /users');
is($match->{route}{handler}->(), 'list', 'Correct handler');

$match = $router->match('GET', '/users/123');
ok($match, 'Matched /users/123');
is($match->{params}{id}, '123', 'Extracted param');

# Test constraints
$router->add_route('GET', '/posts/:id', sub { 'post' },
    constraints => { id => qr/^\d+$/ }
);

$match = $router->match('GET', '/posts/123');
ok($match, 'Matched with numeric constraint');

$match = $router->match('GET', '/posts/abc');
ok(!$match, 'Did not match with invalid constraint');

# Test named routes
$router->add_route('GET', '/profile/:username', sub { 'profile' },
    name => 'user_profile'
);

my $url = $router->url_for('user_profile', username => 'alice');
is($url, '/profile/alice', 'Generated URL from named route');

done_testing;

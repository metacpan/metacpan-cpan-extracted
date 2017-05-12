#!perl

use strict;
use warnings;
use Test::More;
use WWW::Shorten qw(Bitly);

my $bitly = WWW::Shorten::Bitly->new();
isa_ok($bitly, 'WWW::Shorten::Bitly', 'new: instance created successfully');


# access_token
{
    my $val = 'setting';
    $bitly->access_token($val);
    is($bitly->access_token(), $val, 'access_token: correct value');

    my $chain = $bitly->access_token($val);
    isa_ok($chain, 'WWW::Shorten::Bitly', 'access_token: mutator chainable');
    is($chain->access_token, $bitly->access_token, 'access_token: chain same');
}

# client_id
{
    my $val = 'setting';
    $bitly->client_id($val);
    is($bitly->client_id(), $val, 'client_id: correct value');

    $bitly->access_token('foo');
    is($bitly->access_token, 'foo', 'access_token: set correctly');

    $bitly->client_id($val);
    is($bitly->client_id(), $val, 'client_id: correct value');
    is($bitly->access_token, undef, 'access_token: unset correctly');

    my $chain = $bitly->client_id($val);
    isa_ok($chain, 'WWW::Shorten::Bitly', 'client_id: mutator chainable');
    is($chain->client_id, $bitly->client_id, 'client_id: chain same');
}

# client_secret
{
    my $val = 'setting';
    $bitly->client_secret($val);
    is($bitly->client_secret(), $val, 'client_secret: correct value');

    $bitly->access_token('foo');
    is($bitly->access_token, 'foo', 'access_token: set correctly');

    $bitly->client_secret($val);
    is($bitly->client_secret(), $val, 'client_secret: correct value');
    is($bitly->access_token, undef, 'access_token: unset correctly');

    my $chain = $bitly->client_secret($val);
    isa_ok($chain, 'WWW::Shorten::Bitly', 'client_secret: mutator chainable');
    is($chain->client_secret, $bitly->client_secret, 'client_secret: chain same');
}

# password
{
    my $val = 'setting';
    $bitly->password($val);
    is($bitly->password(), $val, 'password: correct value');

    $bitly->access_token('foo');
    is($bitly->access_token, 'foo', 'access_token: set correctly');

    $bitly->password($val);
    is($bitly->password(), $val, 'password: correct value');
    is($bitly->access_token, undef, 'access_token: unset correctly');

    my $chain = $bitly->password($val);
    isa_ok($chain, 'WWW::Shorten::Bitly', 'password: mutator chainable');
    is($chain->password, $bitly->password, 'password: chain same');
}

# username
{
    my $val = 'setting';
    $bitly->username($val);
    is($bitly->username(), $val, 'username: correct value');

    $bitly->access_token('foo');
    is($bitly->access_token, 'foo', 'access_token: set correctly');

    $bitly->username($val);
    is($bitly->username(), $val, 'username: correct value');
    is($bitly->access_token, undef, 'access_token: unset correctly');

    my $chain = $bitly->username($val);
    isa_ok($chain, 'WWW::Shorten::Bitly', 'username: mutator chainable');
    is($chain->username, $bitly->username, 'username: chain same');
}


done_testing();

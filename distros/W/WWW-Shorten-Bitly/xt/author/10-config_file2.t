#!perl

use strict;
use warnings;
use Test::More;
use File::HomeDir ();
use File::Spec ();
use Path::Tiny qw(path);
use WWW::Shorten::Bitly;

BEGIN {
    # now we're looking for ~/[._]bitly_test
    # instead of just ~/[._]bitly
    $ENV{BITLY_TEST_CONFIG} = 1;
}
# config gets read lazily upon object creation.  It should only run once.
my $file = File::Spec->catfile(
    File::HomeDir->my_home(),
    ($^O eq 'MSWin32'? '_bitly_test': '.bitly_test')
);
{
    path($file)->spew_utf8(join($/,(
        'access_token=tokentest',
        'client_id=clientidtest',
        'client_secret=clientsecrettest',
        'password=passwordtest',
        'username=usernametest',
    )));
}

# defaults
{
    my $bitly = WWW::Shorten::Bitly->new();
    isa_ok($bitly, 'WWW::Shorten::Bitly', 'new: instance created successfully');
    is($bitly->access_token(), 'tokentest', 'access_token: correct default value');
    is($bitly->client_id(), 'clientidtest', 'client_id: correct default value');
    is($bitly->client_secret(), 'clientsecrettest', 'client_secret: correct default value');
    is($bitly->password(), 'passwordtest', 'password: correct default value');
    is($bitly->username(), 'usernametest', 'username: correct default value');
}

# access_token overridden
{
    my $bitly = WWW::Shorten::Bitly->new(access_token=>'haha');
    isa_ok($bitly, 'WWW::Shorten::Bitly', 'new: instance created successfully');
    is($bitly->access_token(), 'haha', 'access_token: correct overridden value');
    is($bitly->client_id(), 'clientidtest', 'client_id: correct default value');
    is($bitly->client_secret(), 'clientsecrettest', 'client_secret: correct default value');
    is($bitly->password(), 'passwordtest', 'password: correct default value');
    is($bitly->username(), 'usernametest', 'username: correct default value');
}

# client_id overridden
{
    my $bitly = WWW::Shorten::Bitly->new(client_id=>'foobar');
    isa_ok($bitly, 'WWW::Shorten::Bitly', 'new: instance created successfully');
    is($bitly->access_token(), 'tokentest', 'access_token: correct default value');
    is($bitly->client_id(), 'foobar', 'client_id: correct overridden value');
    is($bitly->client_secret(), 'clientsecrettest', 'client_secret: correct default value');
    is($bitly->password(), 'passwordtest', 'password: correct default value');
    is($bitly->username(), 'usernametest', 'username: correct default value');
}

# client_secret overridden
{
    my $bitly = WWW::Shorten::Bitly->new(client_secret=>'foobar');
    isa_ok($bitly, 'WWW::Shorten::Bitly', 'new: instance created successfully');
    is($bitly->access_token(), 'tokentest', 'access_token: correct default value');
    is($bitly->client_id(), 'clientidtest', 'client_id: correct default value');
    is($bitly->client_secret(), 'foobar', 'client_secret: correct overridden value');
    is($bitly->password(), 'passwordtest', 'password: correct default value');
    is($bitly->username(), 'usernametest', 'username: correct default value');
}

# password overridden
{
    my $bitly = WWW::Shorten::Bitly->new(password=>'foobar');
    isa_ok($bitly, 'WWW::Shorten::Bitly', 'new: instance created successfully');
    is($bitly->access_token(), 'tokentest', 'access_token: correct default value');
    is($bitly->client_id(), 'clientidtest', 'client_id: correct default value');
    is($bitly->client_secret(), 'clientsecrettest', 'client_secret: correct default value');
    is($bitly->password(), 'foobar', 'password: correct overridden value');
    is($bitly->username(), 'usernametest', 'username: correct default value');
}

# username overridden
{
    my $bitly = WWW::Shorten::Bitly->new(username=>'foobar');
    isa_ok($bitly, 'WWW::Shorten::Bitly', 'new: instance created successfully');
    is($bitly->access_token(), 'tokentest', 'access_token: correct default value');
    is($bitly->client_id(), 'clientidtest', 'client_id: correct default value');
    is($bitly->client_secret(), 'clientsecrettest', 'client_secret: correct default value');
    is($bitly->password(), 'passwordtest', 'password: correct default value');
    is($bitly->username(), 'foobar', 'username: correct overridden value');
}

path($file)->remove();
done_testing();

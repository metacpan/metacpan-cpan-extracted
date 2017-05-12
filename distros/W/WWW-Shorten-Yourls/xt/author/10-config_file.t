#!perl

use strict;
use warnings;
use Test::More;
use File::HomeDir ();
use File::Spec ();
use Path::Tiny qw(path);
use WWW::Shorten qw(Yourls);

BEGIN {
    # now we're looking for ~/[._]yourls_test
    # instead of just ~/[._]yourls
    $ENV{YOURLS_TEST_CONFIG} = 1;
}
# config gets read lazily upon object creation.  It should only run once.
my $file = File::Spec->catfile(
    File::HomeDir->my_home(),
    ($^O eq 'MSWin32'? '_yourls_test': '.yourls_test')
);
{
    path($file)->spew_utf8(join($/,(
        'server=http://yourls.org/yourls-api.php',
        'signature=signaturetest',
        'password=passwordtest',
        'username=usernametest',
    )));
}
#ok("yay");done_testing();
#exit();
# defaults
{
    my $yourls = WWW::Shorten::Yourls->new();
    isa_ok($yourls, 'WWW::Shorten::Yourls', 'new: instance created successfully');
    is($yourls->password(), 'passwordtest', 'password: correct default value');
    is($yourls->server(), 'http://yourls.org/yourls-api.php', 'server: correct default value');
    is($yourls->signature(), 'signaturetest', 'signature: correct default value');
    is($yourls->username(), 'usernametest', 'username: correct default value');
}

# password overridden
{
    my $yourls = WWW::Shorten::Yourls->new(password=>'foobar');
    isa_ok($yourls, 'WWW::Shorten::Yourls', 'new: instance created successfully');
    is($yourls->password(), 'foobar', 'password: correct overridden value');
    is($yourls->server(), 'http://yourls.org/yourls-api.php', 'server: correct default value');
    is($yourls->signature(), 'signaturetest', 'signature: correct default value');
    is($yourls->username(), 'usernametest', 'username: correct default value');
}

# server overridden
{
    my $yourls = WWW::Shorten::Yourls->new(server=>'https://www.example.com');
    isa_ok($yourls, 'WWW::Shorten::Yourls', 'new: instance created successfully');
    is($yourls->password(), 'passwordtest', 'password: correct default value');
    is($yourls->server(), 'https://www.example.com', 'server: correct default value');
    is($yourls->signature(), 'signaturetest', 'signature: correct default value');
    is($yourls->username(), 'usernametest', 'username: correct default value');
}

# signature overridden
{
    my $yourls = WWW::Shorten::Yourls->new(signature=>'foobar');
    isa_ok($yourls, 'WWW::Shorten::Yourls', 'new: instance created successfully');
    is($yourls->password(), 'passwordtest', 'password: correct default value');
    is($yourls->server(), 'http://yourls.org/yourls-api.php', 'server: correct default value');
    is($yourls->signature(), 'foobar', 'signature: correct overridden value');
    is($yourls->username(), 'usernametest', 'username: correct default value');
}

# username overridden
{
    my $yourls = WWW::Shorten::Yourls->new(username=>'foobar');
    isa_ok($yourls, 'WWW::Shorten::Yourls', 'new: instance created successfully');
    is($yourls->password(), 'passwordtest', 'password: correct default value');
    is($yourls->server(), 'http://yourls.org/yourls-api.php', 'server: correct default value');
    is($yourls->signature(), 'signaturetest', 'signature: correct default value');
    is($yourls->username(), 'foobar', 'username: correct overridden value');
}

path($file)->remove();
done_testing();

#!perl

use strict;
use warnings;
use Test::More;
use Try::Tiny qw(try catch);
use URI ();
use WWW::Shorten::Yourls;

my $yourls = WWW::Shorten::Yourls->new();
isa_ok($yourls, 'WWW::Shorten::Yourls', 'new: instance created successfully');


# password
{
    $yourls->password(undef);
    is($yourls->password(), undef, 'password: correct value from undef');

    $yourls->password('');
    is($yourls->password(), '', 'password: correct value from empty string');

    my $val = 'setting';
    $yourls->password($val);
    is($yourls->password(), $val, 'password: correct value');

    my $chain = $yourls->password($val);
    isa_ok($chain, 'WWW::Shorten::Yourls', 'password: mutator chainable');
    is($chain->password, $yourls->password, 'password: chain same');
}

# server
{
    $yourls->server(undef);
    is($yourls->server(), undef, 'server: correct value from undef');

    $yourls->server('');
    is($yourls->server(), undef, 'server: correct value from empty string');

    my $val = 'setting';
    $yourls->server($val);
    is($yourls->server(), $val, 'server: correct value from string');

    $val = 'http://www.example.com/yourls-api.php';
    $yourls->server($val);
    is($yourls->server(), $val, 'server: correct value from string FQDN');

    my $error;
    try {
        $yourls->server({hash=>'ref'});
    }
    catch {
        $error = $_;
    };
    like($error, qr/^The server attribute must be set to a URI/, 'server: invalid type passed');

    $val = URI->new('http://www.example.com/yourls-api.php');
    $yourls->server($val);
    is($yourls->server(), $val, 'server: correct value from URI object');

    my $chain = $yourls->server($val);
    isa_ok($chain, 'WWW::Shorten::Yourls', 'server: mutator chainable');
    is($chain->server, $yourls->server, 'server: chain same');
}

# signature
{
    $yourls->signature(undef);
    is($yourls->signature(), undef, 'signature: correct value from undef');

    $yourls->signature('');
    is($yourls->signature(), '', 'signature: correct value from empty string');

    my $val = 'setting';
    $yourls->signature($val);
    is($yourls->signature(), $val, 'signature: correct value');

    my $chain = $yourls->signature($val);
    isa_ok($chain, 'WWW::Shorten::Yourls', 'signature: mutator chainable');
    is($chain->signature, $yourls->signature, 'signature: chain same');
}

# username
{
    $yourls->username(undef);
    is($yourls->username(), undef, 'username: correct value from undef');

    $yourls->username('');
    is($yourls->username(), '', 'username: correct value from empty string');

    my $val = 'setting';
    $yourls->username($val);
    is($yourls->username(), $val, 'username: correct value');

    my $chain = $yourls->username($val);
    isa_ok($chain, 'WWW::Shorten::Yourls', 'username: mutator chainable');
    is($chain->username, $yourls->username, 'username: chain same');
}


done_testing();

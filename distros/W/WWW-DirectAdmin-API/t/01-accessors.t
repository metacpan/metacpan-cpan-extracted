#!perl 

use Test::More tests => 14;
use Test::Exception;

BEGIN {
    use_ok( 'WWW::DirectAdmin::API' ) || print "Bail out!\n";
}

{
    my $da;

    throws_ok {
        $da = WWW::DirectAdmin::API->new(
            host     => 'example.com',
            username => 'username'
        );
    } qr/Missing required 'password' parameter/, 'missing parameters';
   
    my %params = (
        host     => 'example.com',
        username => 'username',
        password => 'password'
    ); 

    lives_ok {
        $da = WWW::DirectAdmin::API->new( %params );
    } 'new';

    foreach my $p ( keys %params ) {
        is $da->{$p}, $params{$p}, $p;
    } 

    is $da->{scheme}, 'http', 'scheme';

    # check returned uri
    isa_ok $da->uri, 'URI';
    is $da->uri->as_string, 'http://example.com', 'uri matches';
}

# test with https and port
{
    my $da;

    lives_ok {
        $da = WWW::DirectAdmin::API->new(
            host => 'example.com',
            username => 'username',
            password => 'password',
            port     => 2222
        );
    } 'new w/port';

    is $da->{port}, 2222, 'port';
    is $da->uri->as_string, 'http://example.com:2222', 'uri with port';

    # https
    lives_ok {
        $da = WWW::DirectAdmin::API->new(
            host => 'example.com',
            username => 'username',
            password => 'password',
            port     => 2222
        );
    } 'new w/port';

    is $da->uri->as_string, 'http://example.com:2222', 'https uri with port';
}

exit;


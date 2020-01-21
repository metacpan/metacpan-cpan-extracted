use strict;
use warnings;
use Test::More;
use Test::Exception;
use URI::XS qw/uri :const/;

my $wrong_scheme = qr/panda::uri::WrongScheme/;

sub test {
    my ($name, $url, $port, $secure, $friend_scheme) = @_;
    my $class = "URI::XS::$name";
    my $sign = $friend_scheme && substr($friend_scheme, 0, 1, '');
    
    subtest $name => sub {
        local $Test::Builder::Level = $Test::Builder::Level + 5;
        my $uri = $class->new($url);
        is ref($uri), $class, "class: $class";
        is ref(uri($url)), $class, "alternate ctor";
        is $uri->port, $port, "port: $port";
        is !!$uri->secure, !!$secure, "secure: ".($secure ? "yes" : "no");
        
        if ($friend_scheme) {
            if ($sign eq '+') {
                $uri->scheme($friend_scheme);
                is $uri->scheme, $friend_scheme, "friend scheme: $friend_scheme";
            } else {
                throws_ok { $uri->scheme($friend_scheme) } $wrong_scheme, "friend scheme not allowed: $friend_scheme";
            }
        }
   };
}

test 'http',   "http://ya.ru",     80, 0, '+https';
test 'https',  "https://ya.ru",   443, 1, '-http';
test 'ftp',    "ftp://ya.ru",      21, 0;
test 'socks',  "socks5://ya.ru", 1080, 0;
test 'ws',     "ws://ya.ru",       80, 0, '+wss';
test 'wss',    "wss://ya.ru",     443, 1, '-ws';
test 'ssh',    "ssh://server",     22, 1;
test 'telnet', "telnet://server",  23, 0;
test 'sftp',   "sftp://server",    22, 1;

done_testing();

use 5.012;
use URI::Router;
use Benchmark qw/timethis timethese/;

say $$;

my $r = URI::Router->new(
    "/asdf/1234/5678" => 1,
    "/asdf/*/5678"    => 2,
    "/asdf/1234/*"    => 3,
    "/*/*/foo"        => 4,
    qr#/asdf/1234/5678#      => 1,
    qr#/asdf/([^/]+)/5678#   => 2,
    qr#/asdf/1234/([^/]+)#   => 3,
    qr#/([^/]+)/([^/]+)/foo# => 4,
    qr#/(css|img|js|flv|swf)/(.+)#       => 10,
    qr#/.+\.php#                         => 20,
    qr#/blog/(.+)#                      => 3,
    qr#/#                               => 4,
    qr#/wordpress#                      => 5,
    qr#/anotherapp#                     => 6,
    qr#.+\.(gif|jpg|jpeg|png|css|js)#   => 7,
    qr#/.*blogs.*#                      => 8,
    qr#/blogsin#                        => 9,
    qr#/blogsinphp#                     => 10,
    qr#/cgi-bin/(?:.+)#                 => 11,
);

say URI::Router::route($r, '/asdf/1234/5678');
say URI::Router::route($r, '/asdf//1234//5678');
say URI::Router::route($r, '/asdf/xxxx/5678');
say URI::Router::route($r, '/asdf/1234/xxxx');
say URI::Router::route($r, '/xxxx/xxxx/foo');
say URI::Router::route($r, '/asdf/xxxx/foo');

#URI::Router::bench($r, '/asdf/xxxx/5678') while 1;

timethese(-1, {
    #st  => sub { URI::Router::route($r, '/asdf/1234/5678') },
    #st2 => sub { URI::Router::route($r, '/asdf//1234//5678') },
    a1  => sub { URI::Router::route($r, '/asdf/xxxx/5678') },
    a2  => sub { URI::Router::route($r, '/asdf/1234/xxxx') },
    a3  => sub { URI::Router::route($r, '/xxxx/xxxx/foo') },
    a3a => sub { URI::Router::route($r, '/asdf/xxxx/foo') },
    #bst  => sub { URI::Router::bench($r, '/asdf/1234/5678') },
    #bst2 => sub { URI::Router::bench($r, '/asdf//1234//5678') },
    ba1  => sub { URI::Router::bench($r, '/asdf/xxxx/5678') },
    ba2  => sub { URI::Router::bench($r, '/asdf/1234/xxxx') },
    ba3  => sub { URI::Router::bench($r, '/xxxx/xxxx/foo') },
    ba3a => sub { URI::Router::bench($r, '/asdf/xxxx/foo') },
});

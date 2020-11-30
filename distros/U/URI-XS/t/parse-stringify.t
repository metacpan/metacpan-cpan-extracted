use 5.012;
use warnings;
use Test::More;
use URI::XS qw/:const/;

our $flags;

subtest 'empty' => sub {
    test();
};

subtest 'scheme' => sub {
    subtest 'scheme -> authority' => sub {
        test('http://host', 'http', '', 'host');
        test('ws://host', 'ws', '', 'host');
    };
    subtest 'scheme -> path' => sub {
        test('mailto:syber@crazypanda.ru', 'mailto', '', '', 0, 'syber@crazypanda.ru');
        test('a:b:c:d:e:f', 'a', '', '', 0, 'b:c:d:e:f');
        test('cp:/jopa', 'cp', '', '', 0, '/jopa');
    };
    subtest 'scheme-relative' => sub {
        test('//ya.ru', '', '', 'ya.ru');
    };
    subtest 'scheme alias' => sub {
        my $uri = URI::XS->new('https://host');
        is $uri->proto, 'https';
        is $uri->protocol, 'https';
    };
};

subtest 'user info' => sub {
    test('http://user@ya.ru', 'http', 'user', 'ya.ru');
    test('http://user:pass@ya.ru', 'http', 'user:pass', 'ya.ru');
    test('http://user:@ya.ru', 'http', 'user:', 'ya.ru');
    ok !URI::XS->new('http://cool@user@ya.ru'), 'invalid chars';
};

subtest 'host' => sub {
    subtest 'reg name' => sub {
        test('http://ya.ru', 'http', '', 'ya.ru');
    };
    subtest 'IPv4' => sub {
        test('http://1.10.100.255', 'http', '', '1.10.100.255');
        test('http://0.0.0.0', 'http', '', '0.0.0.0');
    };
    subtest 'IPv6' => sub {
        test('http://[aa:bb:cc:dd::ee:ff]', 'http', '', '[aa:bb:cc:dd::ee:ff]');
        test('http://[aa:bb:cc:dd::]', 'http', '', '[aa:bb:cc:dd::]');
        test('http://user@[::ee:ff]', 'http', 'user', '[::ee:ff]');
        ok !URI::XS->new('http://[aa:bb:cc:dd:ee:ff]'), 'wrong address';
        ok !URI::XS->new('http://[aa:bb:cc:dd::ee:ff'), 'wrong address';
        ok !URI::XS->new('http://[aa:bb:cc:dd:ee:::ff]'), 'wrong address';
    };
};

subtest 'port' => sub {
    subtest 'explicit' => sub {
        test('http://ya.ru', 'http', '', 'ya.ru', 0);
        test('abc://ya.ru:80', 'abc', '', 'ya.ru', 80);
        test('def://ya.ru:443', 'def', '', 'ya.ru', 443);
    };
    subtest 'implicit' => sub {
        my $uri = URI::XS->new('http://ya.ru');
        is $uri->port, 80;
        $uri->set('http://ya.ru:81');
        is $uri->port, 81;
        $uri->set('https://ya.ru');
        is $uri->port, 443;
        $uri->set('https://ya.ru:444');
        is $uri->port, 444;
        $uri->set('hz://ya.ru');
        is $uri->port, 0;
    };
};

subtest 'location' => sub {
    subtest 'explicit' => sub {
        my $uri = URI::XS->new('http://ya.ru');
        is $uri->explicit_location, 'ya.ru';
        $uri->set('http://ya.ru:81');
        is $uri->explicit_location, 'ya.ru:81';
    };
    subtest 'implicit' => sub {
        my $uri = URI::XS->new('http://ya.ru');
        is $uri->location, "ya.ru:80";
        $uri->set('http://ya.ru:81');
        is $uri->location, "ya.ru:81";
        $uri->set('https://ya.ru');
        is $uri->location, "ya.ru:443";
        $uri->set('https://ya.ru:444');
        is $uri->location, "ya.ru:444";
        $uri->set('hz://ya.ru');
        is $uri->location, "ya.ru:0";
    };
};

subtest 'path' => sub {
    subtest 'absolute' => sub {
        test('http://host', 'http', '', 'host', 0, '');
        test('http://host/', 'http', '', 'host', 0, '/');
        test('http://host/path', 'http', '', 'host', 0, '/path');
    };
    subtest 'scheme-relative' => sub {
        test('//host', '', '', 'host', 0, '');
        test('//host/', '', '', 'host', 0, '/');
        test('//host/path', '', '', 'host', 0, '/path');
    };
    subtest 'scheme->path' => sub {
        test('about:', 'about', '', '', 0, '');
        test('about:/', 'about', '', '', 0, '/');
        test('about:/path', 'about', '', '', 0, '/path');
        test('about:path', 'about', '', '', 0, 'path');
        test('about:path/', 'about', '', '', 0, 'path/');
    };
    subtest 'relative' => sub {
        test('a', '', '', '', 0, 'a');
        test('/', '', '', '', 0, '/');
        test('/abc', '', '', '', 0, '/abc');
        
        # according to RFC, 'ya.ru' is not a host, it's a part of the path
        # to parse 'ya.ru' as host (like browsers), we need to enable special mode ALLOW_SUFFIX_REFERENCE
        test('ya.ru/abc', '', '', '', 0, 'ya.ru/abc');
        
        is(URI::XS->new("http://ya.ru")->relative, "/"); # not empty relative path
        is(URI::XS->new("http://ya.ru?p1=v1&p2=v2#myhash")->relative, '/?p1=v1&p2=v2#myhash');
    };
};

subtest 'query string' => sub {
    test('http://ya.ru?sukastring', 'http', '', 'ya.ru', 0, '', 'sukastring');
    my $uri = test('http://ya.ru?suka%20string+nah', 'http', '', 'ya.ru', 0, '', 'suka%20string+nah');
    is $uri->raw_query, 'suka string nah';
};

subtest 'fragment' => sub {
    test('http://ya.ru#frag', 'http', '', 'ya.ru', 0, '', '', 'frag');
    test('http://ya.ru#my%23frag', 'http', '', 'ya.ru', 0, '', '', 'my%23frag');
    test('http://ya.ru?p1=v1#myhash', 'http', '', 'ya.ru', 0, '', 'p1=v1', 'myhash');
    test('https://jopa.com#a?b?c', 'https', '', 'jopa.com', 0, '', '', 'a?b?c');
    ok !URI::XS->new('http://ya.ru#my#frag'), 'invalid chars in fragment';
};

subtest 'leading authority euristics' => sub {
    local $flags = ALLOW_SUFFIX_REFERENCE;
    test('ya.ru:8080', '', '', 'ya.ru', 8080, '', '', '', '//ya.ru:8080');
    test('ya.ru', '', '', 'ya.ru', 0, '', '', '', '//ya.ru');
    test('ya.ru:', 'ya.ru', '', '', 0);
    test('ya.ru:80a', 'ya.ru', '', '', 0, '80a');
    test('ya.ru:8080/a/b', '', '', 'ya.ru', 8080, '/a/b', '', '', '//ya.ru:8080/a/b');
    test('ya.ru/a/b', '', '', 'ya.ru', 0, '/a/b', '', '', '//ya.ru/a/b');
    test('ya.ru:/a/b', 'ya.ru', '', '', 0, '/a/b');
    test('ya.ru:80a/a/b', 'ya.ru', '', '', 0, '80a/a/b');
};

subtest 'allow extended chars' => sub {
    my $uri = URI::XS->new('http://jopa.com?"key"="val"&param={"key","val"}', ALLOW_EXTENDED_CHARS);
    is $uri->query_string, '%22key%22=%22val%22&param=%7B%22key%22%2C%22val%22%7D';
    is $uri->to_string, 'http://jopa.com?%22key%22=%22val%22&param=%7B%22key%22%2C%22val%22%7D';
    is_deeply $uri->query, {
        '"key"' => '"val"',
        param   => '{"key","val"}',
    };
};

subtest 'secure' => sub {
    ok(URI::XS->new("https://ya.ru")->secure);
    ok(!URI::XS->new("http://ya.ru")->secure);
    ok(!URI::XS->new("//ya.ru")->secure);
    ok(!URI::XS->new("ya.ru")->secure);
};

subtest 'misc' => sub {
    test('mailto:syber@crazypanda.ru?a=b#dada', 'mailto', '', '', 0, 'syber@crazypanda.ru', 'a=b', 'dada');
    test('http://user@ya.ru:2345/my/path?p1=v1&p2=v2#myhash', 'http', 'user', 'ya.ru', 2345, '/my/path', 'p1=v1&p2=v2', 'myhash');
    test('http://user:pass@ya.ru:2345/my/path?p1=v1&p2=v2#myhash', 'http', 'user:pass', 'ya.ru', 2345, '/my/path', 'p1=v1&p2=v2', 'myhash');
    test('http://user:@ya.ru:2345/my/path?p1=v1&p2=v2#myhash', 'http', 'user:', 'ya.ru', 2345, '/my/path', 'p1=v1&p2=v2', 'myhash');
    test('http://1.10.100.255:2345/my/path?p1=v1&p2=v2#myhash', 'http', '', '1.10.100.255', 2345, '/my/path', 'p1=v1&p2=v2', 'myhash');
    test('http://hi@1.10.100.255:2345/my/path?p1=v1&p2=v2#myhash', 'http', 'hi', '1.10.100.255', 2345, '/my/path', 'p1=v1&p2=v2', 'myhash');
    test('http://[aa:bb:cc:dd::ee:ff]/my/path?p1=v1&p2=v2#myhash', 'http', '', '[aa:bb:cc:dd::ee:ff]', 0, '/my/path', 'p1=v1&p2=v2', 'myhash');
    test('http://[aa:bb:cc:dd::]:2345/my/path?p1=v1&p2=v2#myhash', 'http', '', '[aa:bb:cc:dd::]', 2345, '/my/path', 'p1=v1&p2=v2', 'myhash');
    test('http://user@[::ee:ff]:2345/my/path?p1=v1&p2=v2#myhash', 'http', 'user', '[::ee:ff]', 2345, '/my/path', 'p1=v1&p2=v2', 'myhash');
    test('//sss@ya.ru:2345/my/path?p1=v1&p2=v2#myhash', '', 'sss', 'ya.ru', 2345, '/my/path', 'p1=v1&p2=v2', 'myhash');
    test('//[aa:bb:cc:dd::ee:ff]/my/path?p1=v1&p2=v2#myhash', '', '', '[aa:bb:cc:dd::ee:ff]', 0, '/my/path', 'p1=v1&p2=v2', 'myhash');
};

subtest 'bad' => sub {
    ok !URI::XS->new("http://api.odnokl\x5C\x00\x03\x06\x00\x00\x00\x00\x00\x00\x00\x23\xC3\xABlq\x1B\x00\x02"), 'null byte in uri. should NOT core dump. Stop parsing url on null byte';
    ok !URI::XS->new('https://jopa.com:123/://asd/?:hello?://yo?u/#lalala://hello/?a=b&jopa=#privet');
};

sub test {
    my ($url, $scheme, $uinfo, $host, $port, $path, $qstr, $frag, $str) = @_;
    my $uri;
    $url //= '';
    my $testname = "test url $url";
    $testname .= " (flags=$flags)" if $flags;
    
    subtest $testname => sub {
        $uri = URI::XS->new($url, $flags ? $flags : ());
    
        $str //= $url;
        $scheme //= '';
        $uinfo //= '';
        $host //= '';
        $port //= 0;
        $path //= '';
        $qstr //= '';
        $frag //= '';
        
        is($uri->scheme, $scheme, "scheme: $scheme") if defined $scheme;
        is($uri->user_info, $uinfo, "user info: $uinfo") if defined $uinfo;
        is($uri->host, $host, "host: $host") if defined $host;
        is($uri->explicit_port, $port, "explicit port: $port") if defined $port;
        is($uri->path, $path, "path: $path") if defined $path;
        is($uri->query_string, $qstr, "qstr: $qstr") if defined $qstr;
        is($uri->fragment, $frag, "frag: $frag") if defined $frag;
        is($uri->to_string, $str, "tostring: $str");
        
        is_deeply([$uri, $uri.'', $uri->as_string, $uri->url], [$str, $str, $str, $str], "tostring aliases");
        is($uri->hash, $frag, "frag alias");
    };
    return $uri;
}

done_testing();

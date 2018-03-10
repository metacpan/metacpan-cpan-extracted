use utf8;
use Test2::V0;
use Test::LeakTrace qw(no_leaks_ok);
use URI::Encode::XS qw(uri_encode_utf8 uri_decode_utf8);
use URI::Fast qw(uri uri_split);
use URI::Split qw();

my @uris = (
  '/foo/bar/baz',
  'http://www.test.com',
  'https://test.com/some/path?aaaa=bbbb&cccc=dddd&eeee=ffff',
  'https://user:pwd@192.168.0.1:8000/foo/bar?baz=bat&slack=fnord&asdf=the+quick%20brown+fox+%26+hound#foofrag',
);

subtest 'implicit file path' => sub{
  ok my $uri = uri($uris[0]), 'ctor';
  is $uri->scheme, 'file', 'scheme';
  ok !$uri->auth, 'auth';
  is $uri->path, '/foo/bar/baz', 'path';
  is [$uri->path], ['foo', 'bar', 'baz'], 'path';
  ok !$uri->query, 'query';
  ok !$uri->frag, 'frag';

  ok !$uri->usr, 'usr';
  ok !$uri->pwd, 'pwd';
  ok !$uri->host, 'host';
  ok !$uri->port, 'port';
};

subtest 'simple' => sub{
  ok my $uri = uri($uris[1]), 'ctor';
  is $uri->scheme, 'http', 'scheme';
  is $uri->auth, 'www.test.com', 'auth';
  ok !$uri->path, 'path';
  is [$uri->path], [], 'path';
  ok !$uri->query, 'query';
  ok !$uri->frag, 'frag';

  ok !$uri->usr, 'usr';
  ok !$uri->pwd, 'pwd';
  is $uri->host, 'www.test.com', 'host';
  ok !$uri->port, 'port';
};

subtest 'complete' => sub{
  ok my $uri = uri($uris[3]), 'ctor';
  is $uri->scheme, 'https', 'scheme';
  is $uri->auth, 'user:pwd@192.168.0.1:8000', 'auth';
  is $uri->path, '/foo/bar', 'path';
  is [$uri->path], ['foo', 'bar'], 'path';
  is $uri->query, 'baz=bat&slack=fnord&asdf=the+quick%20brown+fox+%26+hound', 'query';
  is $uri->frag, 'foofrag', 'frag';

  is $uri->usr, 'user', 'usr';
  is $uri->pwd, 'pwd', 'pwd';
  is $uri->host, '192.168.0.1', 'host';
  is $uri->port, '8000', 'port';

  is $uri->param('baz'), 'bat', 'param';
  is $uri->param('slack'), 'fnord', 'param';
  is $uri->param('asdf'), 'the quick brown fox & hound', 'param';
};

subtest 'scheme' => sub{
  my $uri = uri $uris[3];
  is $uri->scheme, 'https', 'get';
  is $uri->scheme('http'), 'http', 'set';
  is $uri->scheme, 'http', 'get';
};

subtest 'auth' => sub{
  my $uri = uri $uris[3];
  is $uri->auth, 'user:pwd@192.168.0.1:8000', 'get';

  subtest 'scalar' => sub{
    my $uri = uri $uris[3];
    is $uri->auth('some:one@www.test.com:1234'), 'some:one@www.test.com:1234', 'set';
    is $uri->auth('some:one@www.test.com:1234'), 'some:one@www.test.com:1234', 'get';
    is $uri->usr, 'some', 'updated: usr';
    is $uri->pwd, 'one', 'updated: pwd';
    is $uri->host, 'www.test.com', 'updated: hsot';
    is $uri->port, '1234', 'updated: port';
  };

  subtest 'hash' => sub{
    my $uri = uri $uris[3];
    is $uri->auth({usr => 'some', pwd => 'one', host => 'www.test.com', port => '1234'}), 'some:one@www.test.com:1234', 'set';
    is $uri->auth('some:one@www.test.com:1234'), 'some:one@www.test.com:1234', 'get';
    is $uri->usr, 'some', 'updated: usr';
    is $uri->pwd, 'one', 'updated: pwd';
    is $uri->host, 'www.test.com', 'updated: hsot';
    is $uri->port, '1234', 'updated: port';
  };

  subtest 'usr' => sub {
    my $uri = uri $uris[1];
    is $uri->usr, '', 'get (empty)';
    is $uri->usr('foo'), 'foo', 'set';
    is $uri->usr, 'foo', 'get';
    is $uri->auth, 'foo@www.test.com', 'updated: auth';
  };

  subtest 'pwd' => sub {
    my $uri = uri $uris[1];
    is $uri->pwd, '', 'get (empty)';
    is $uri->pwd('foo'), 'foo', 'set';
    is $uri->pwd, 'foo', 'get';
    is $uri->auth, 'www.test.com', 'auth has no pwd w/o host';
    $uri->usr('bar');
    is $uri->auth, 'bar:foo@www.test.com', 'auth has pwd w/ host';
  };

  subtest 'host' => sub {
    my $uri = uri $uris[1];
    is $uri->host, 'www.test.com', 'get';
    is $uri->host('foo'), 'foo', 'set';
    is $uri->host, 'foo', 'get';
    is $uri->auth, 'foo', 'updated: auth';
  };

  subtest 'port' => sub {
    my $uri = uri $uris[1];
    is $uri->port, '', 'get (empty)';
    is $uri->port('1234'), '1234', 'set';
    is $uri->port, '1234', 'get';
    is $uri->auth, 'www.test.com:1234', 'updated: auth';
  };
};

subtest 'path' => sub{
  ok my $uri = uri($uris[2]), 'ctor';
  is $uri->path, '/some/path', 'get (scalar)';
  is [$uri->path], [qw(some path)], 'get (list)';

  is $uri->path('/foo/bar'), '/foo/bar', 'set (scalar)';
  is $uri->path, '/foo/bar', 'get (scalar)';
  is [$uri->path], [qw(foo bar)], 'get (list)';

  is $uri->path([qw(baz bat)]), '/baz/bat', 'set (array)';
  is $uri->path, '/baz/bat', 'get (scalar)';
  is [$uri->path], [qw(baz bat)], 'get (list)';
};

subtest 'query' => sub{
  ok my $uri = uri($uris[2]), 'ctor';
  is $uri->query, 'aaaa=bbbb&cccc=dddd&eeee=ffff', 'get (scalar)';
  is { $uri->query }, {aaaa => ['bbbb'], cccc => ['dddd'], eeee => ['ffff']}, 'get (list)';

  is $uri->query('foo=bar'), 'foo=bar', 'set (scalar)';
  is $uri->query, 'foo=bar', 'get (scalar)';
  is { $uri->query }, {foo => ['bar']}, 'get (list)';

  is $uri->query({baz => 'bat'}), 'baz=bat', 'set (hash ref)';
  is $uri->query, 'baz=bat', 'get (scalar)';
  is { $uri->query }, {baz => ['bat']}, 'set (scalar)';

  is $uri->query({fnord => [qw(foo bar)]}), 'fnord=foo&fnord=bar', 'set (hash ref w/ multiple values per key)';
  is $uri->query, 'fnord=foo&fnord=bar', 'get (scalar)';
  is { $uri->query }, {fnord => [qw(foo bar)]}, 'get (list)';

  subtest 'param' => sub{
    my $uri = uri 'http://www.test.com?foo=bar&foo=baz&fnord=slack';
    is $uri->param('foo'), [qw(bar baz)], 'get (scalar): multiple values as array ref';
    is $uri->param('fnord'), 'slack', 'get (scalar): single value as scalar';
    is [$uri->param('foo')], [qw(bar baz)], 'get (list)';

    subtest 'unset' => sub {
      is $uri->param('foo', undef), U, 'set';
      is $uri->param('foo'), U, 'get';
      is $uri->query, 'fnord=slack', 'updated: query';
    };

    subtest 'set: string' => sub {
      is $uri->param('foo', 'bar'), 'bar', 'set (scalar, single value)';
      is $uri->param('foo'), 'bar', 'get';
      is $uri->query, 'fnord=slack&foo=bar', 'updated: query';
    };

    subtest 'set: array ref' => sub {
      is $uri->param('foo', [qw(bar baz)]), [qw(bar baz)], 'set (scalar, array ref)';
      is $uri->param('foo'), [qw(bar baz)], 'get';
      is $uri->query, 'fnord=slack&foo=bar&foo=baz', 'updated: query';
    };

    subtest 'edge cases' => sub {
      subtest 'unset only parameter' => sub {
        my $uri = uri 'http://www.test.com?foo=bar';
        $uri->param('foo', undef);
        is $uri->query, '', 'expected query valuee';
      };

      subtest 'unset final parameter' => sub {
        my $uri = uri 'http://www.test.com?bar=bat&foo=bar';
        $uri->param('foo', undef);
        is $uri->query, 'bar=bat', 'expected query valuee';
      };

      subtest 'unset initial parameter' => sub {
        my $uri = uri 'http://www.test.com?bar=bat&foo=bar';
        $uri->param('bar', undef);
        is $uri->query, 'foo=bar', 'expected query value';
      };

      subtest 'update initial parameter' => sub {
        my $uri = uri 'http://www.test.com?bar=bat&foo=bar';
        $uri->param('bar', 'blah');
        is $uri->query, 'foo=bar&bar=blah', 'expected query value';
      };

      subtest 'update final parameter' => sub {
        my $uri = uri 'http://www.test.com?bar=bat&foo=bar';
        $uri->param('foo', 'blah');
        is $uri->query, 'bar=bat&foo=blah', 'expected query value';
      };
    };
  };
};

subtest 'frag' => sub{
  my $uri = uri $uris[3];
  is $uri->frag, 'foofrag', 'get';
  is $uri->frag('barfrag'), 'barfrag', 'set';
  is $uri->frag, 'barfrag', 'get';
};

subtest 'uri_split' => sub{
  my @uris = (
    '/foo/bar/baz',
    'file:///foo/bar/baz',
    'http://www.test.com',
    'http://www.test.com?foo=bar',
    'http://www.test.com#bar',
    'http://www.test.com/some/path',
    'https://test.com/some/path?aaaa=bbbb&cccc=dddd&eeee=ffff',
    'https://user:pwd@192.168.0.1:8000/foo/bar?baz=bat&slack=fnord&asdf=the+quick%20brown+fox+%26+hound#foofrag',
    'https://user:pwd@www.test.com:8000/foo/bar?baz=bat&slack=fnord&asdf=the+quick%20brown+fox+%26+hound#foofrag',
  );

  # From URI::Split's test suite
  subtest 'equivalence' => sub{
    is [uri_split('p')],           [U, U, 'p', U, U],          'p';
    is [uri_split('p?q')],         [U, U, 'p', 'q', U],        'p?q';
    is [uri_split('p?q/#f/?')],    [U, U, 'p', 'q/', 'f/?'],   'p?q/f/?';
    is [uri_split('s://a/p?q#f')], ['s', 'a', '/p', 'q', 'f'], 's://a/p?qf';
  };

  # Ensure identical output to URI::Split
  subtest 'parity' => sub{
    my $i = 0;
    foreach my $uri (@uris) {
      my $orig = [URI::Split::uri_split($uri)];
      my $xs   = [uri_split($uri)];
      is $xs, $orig, "uris[$i]", {orig => $orig, xs => $xs};
      ++$i;
    }
  };
};

subtest 'memory leaks' => sub{
  no_leaks_ok { my $s = URI::Fast::encode('foo') } 'encode: no memory leaks';
  no_leaks_ok { my $s = URI::Fast::decode('foo') } 'decode: no memory leaks';

  no_leaks_ok { my @parts = uri_split($uris[3]) } 'uri_split';

  no_leaks_ok { my $uri = uri($uris[3]) } 'ctor';

  my $uri = uri $uris[3];

  foreach my $acc (qw(scheme auth path query frag usr pwd host port)) {
    no_leaks_ok { $uri->$acc() } "getter: $acc";
    no_leaks_ok { $uri->$acc("foo") } "setter: $acc";
  }

  no_leaks_ok { my @parts = $uri->path } 'split path';
  no_leaks_ok { $uri->param('foo', 'bar') } 'param';
  no_leaks_ok { $uri->param('foo', ['bar', 'baz']) } 'param';
  no_leaks_ok { $uri->query_keys } 'query_keys';
  no_leaks_ok { $uri->query_hash } 'query_hash';
  no_leaks_ok { $uri->to_string } 'to_string';
};

done_testing;

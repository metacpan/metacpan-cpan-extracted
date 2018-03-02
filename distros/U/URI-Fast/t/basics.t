use Test2;
use Test2::Bundle::Extended;
use URI::Split qw();
use URI::Fast qw(uri uri_split);
use Test::LeakTrace qw(no_leaks_ok);

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
    is [uri_split('p?q/#f/?')],    [U, U, 'p', 'q/', 'f/?'],   'p?q/#f/?';
    is [uri_split('s://a/p?q#f')], ['s', 'a', '/p', 'q', 'f'], 's://a/p?q#f';
  };

  # Ensure identical output to URI::Split
  subtest 'parity' => sub{
    foreach my $uri (@uris) {
      my $orig = [URI::Split::uri_split($uri)];
      my $xs   = [uri_split($uri)];
      is $xs, $orig, $uri, {orig => $orig, xs => $xs};
    }
  };
};

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

subtest 'path & query' => sub{
  ok my $uri = uri($uris[2]), 'ctor';
  is $uri->scheme, 'https', 'scheme';
  is $uri->auth, 'test.com', 'auth';
  is $uri->path, '/some/path', 'path';
  is [$uri->path], ['some', 'path'], 'path';
  is $uri->query, 'aaaa=bbbb&cccc=dddd&eeee=ffff', 'query';
  ok !$uri->frag, 'frag';

  ok !$uri->usr, 'usr';
  ok !$uri->pwd, 'pwd';
  is $uri->host, 'test.com', 'host';
  ok !$uri->port, 'port';

  is $uri->param('aaaa'), 'bbbb', 'param';
  is $uri->param('cccc'), 'dddd', 'param';
  is $uri->param('eeee'), 'ffff', 'param';
  is $uri->param('fnord'), U, '!param';
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

subtest 'update auth' => sub{
  ok my $uri = uri($uris[1]), 'ctor';
  ok !$uri->usr, 'usr';
  ok !$uri->pwd, 'pwd';
  ok !$uri->port, 'port';

  is $uri->pwd('secret'), 'secret', 'pwd(v)';
  is $uri->auth, 'www.test.com', 'auth';
  is "$uri", 'http://www.test.com', 'string';

  is $uri->usr('someone'), 'someone', 'usr(v)';
  is $uri->auth, 'someone:secret@www.test.com', 'auth';
  is "$uri", 'http://someone:secret@www.test.com', 'string';

  is $uri->port(1234), 1234, 'port(v)';
  is $uri->auth, 'someone:secret@www.test.com:1234', 'auth';
  is "$uri", 'http://someone:secret@www.test.com:1234', 'string';

  is $uri->auth('www.nottest.com'), 'www.nottest.com', 'auth(new)';
  is $uri->host, 'www.nottest.com', 'host';
  ok !$uri->usr, 'usr';
  ok !$uri->pwd, 'pwd';
  ok !$uri->port, 'port';

  ok dies{ $uri->scheme('1foo') }, 'illegal scheme croaks';
  ok dies{ $uri->scheme('http*') }, 'illegal scheme croaks';
  ok dies{ $uri->port('asdf') }, 'illegal port croaks';
};

subtest 'update path' => sub{
  ok my $uri = uri($uris[2]), 'ctor';
  is $uri->path, '/some/path', 'scalar path';
  is [$uri->path], ['some', 'path'], 'list path';

  is $uri->path('/foo/bar'), '/foo/bar', 'scalar path(str)';
  is [$uri->path('/foo/bar')], ['foo', 'bar'], 'list path(str)';
  is "$uri", 'https://test.com/foo/bar?aaaa=bbbb&cccc=dddd&eeee=ffff', 'string';

  is $uri->path(['baz', 'bat']), '/baz/bat', 'scalar path(list)';
  is [$uri->path(['baz', 'bat'])], ['baz', 'bat'], 'scalar path(list)';
  is "$uri", 'https://test.com/baz/bat?aaaa=bbbb&cccc=dddd&eeee=ffff', 'string';
};

subtest 'update param' => sub{
  ok my $uri = uri($uris[2]), 'ctor';
  is $uri->param('cccc'), 'dddd', 'param(k)';
  is $uri->param('cccc', 'qwerty'), 'qwerty', 'param(k,v)';
  is $uri->param('cccc'), 'qwerty', 'param(k)';
  is $uri->query, 'aaaa=bbbb&eeee=ffff&cccc=qwerty', 'query';
  is "$uri", 'https://test.com/some/path?aaaa=bbbb&eeee=ffff&cccc=qwerty', 'string';

  is $uri->query('foo=bar'), 'foo=bar', 'query(new)';
  is $uri->param('foo'), 'bar', 'new query parsed';
  ok !$uri->param('cccc'), 'old parsed values removed';
};

subtest 'memory leaks' => sub{
  no_leaks_ok { my @parts = uri_split($uris[3]) } 'uri_split';
  no_leaks_ok { my $uri = uri($uris[3]) } 'ctor';
  no_leaks_ok { uri($uris[3])->scheme('stuff') } 'scheme';
  no_leaks_ok { uri($uris[3])->param('foo', 'bar') } 'param';
  no_leaks_ok { my @parts = uri($uris[3])->path } 'split path';
  no_leaks_ok { uri($uris[3])->path(['foo', 'bar']) } 'set path';
  no_leaks_ok { uri($uris[3])->usr('foo') } 'set usr/regen auth';
};

done_testing;

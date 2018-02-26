use Test2;
use Test2::Bundle::Extended;

use URI::Fast qw(uri);

my @urls = (
  '/foo/bar/baz',
  'http://www.test.com',
  'https://test.com/some/path?aaaa=bbbb&cccc=dddd&eeee=ffff',
  'https://user:pwd@192.168.0.1:8000/foo/bar?baz=bat&slack=fnord&asdf=the+quick%20brown+fox+%26+hound#foofrag',
);

subtest 'implicit file path' => sub{
  ok my $uri = uri($urls[0]), 'ctor';
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
  ok my $uri = uri($urls[1]), 'ctor';
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
  ok my $uri = uri($urls[2]), 'ctor';
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
  ok my $uri = uri($urls[3]), 'ctor';
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
  ok my $uri = uri($urls[1]), 'ctor';
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
  ok my $uri = uri($urls[2]), 'ctor';
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
  ok my $uri = uri($urls[2]), 'ctor';
  is $uri->param('cccc'), 'dddd', 'param(k)';
  is $uri->param('cccc', 'qwerty'), 'qwerty', 'param(k,v)';
  is $uri->param('cccc'), 'qwerty', 'param(k)';
  is $uri->query, 'aaaa=bbbb&eeee=ffff&cccc=qwerty', 'query';
  is "$uri", 'https://test.com/some/path?aaaa=bbbb&eeee=ffff&cccc=qwerty', 'string';

  is $uri->query('foo=bar'), 'foo=bar', 'query(new)';
  is $uri->param('foo'), 'bar', 'new query parsed';
  ok !$uri->param('cccc'), 'old parsed values removed';
};

done_testing;

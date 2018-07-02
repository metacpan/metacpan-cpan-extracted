use utf8;
use ExtUtils::testlib;
use Test2::V0;
use Test::LeakTrace qw(no_leaks_ok);
use URI::Fast qw(uri uri_split);

my $uri = 'https://user:pwd@192.168.0.1:8000/foo/bar?baz=bat&slack=fnord&asdf=the+quick%20brown+fox+%26+hound#foofrag';

subtest 'memory leaks' => sub{
  no_leaks_ok { my $s = URI::Fast::encode('foo') } 'encode: no memory leaks';
  no_leaks_ok { my $s = URI::Fast::decode('foo') } 'decode: no memory leaks';

  no_leaks_ok { my @parts = uri_split($uri) } 'uri_split';

  no_leaks_ok { my $uri = uri($uri) } 'ctor';

  my $uri = uri $uri;

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

  no_leaks_ok {
    my $uri   = uri $uri;
    my @parts = ($uri->scheme, $uri->auth, $uri->path, $uri->query, $uri->frag);
    my @auth  = ($uri->usr, $uri->pwd, $uri->host, $uri->port);
    my @path  = $uri->path;
    my @keys  = $uri->query_keys;
    my $query = $uri->query_hash;

    $uri->scheme('http');
    $uri->auth('foo:bar@test.com:101010');
    $uri->path('/asdf');
    $uri->path('/Ῥόδος¢€');
    $uri->path(['asdf', 'qwerty']);
    $uri->query('foo=Ῥόδος¢€');
    $uri->param('foo', 'bar');
    $uri->param({foo => ['bar', 'baz']});
    $uri->frag('foo');

    my $str = "$uri";

  }, 'combined';
};

subtest 'overruns' => sub{
   # scheme: 16
   # auth:   267
   # path:   256
   # query:  1024
   # frag:   32
   # usr:    64
   # pwd:    64
   # host:   128
   # port:   8
   my $uri = uri 'http://www.test.com';
   ok $uri->scheme('x' x 17), 'scheme';
   ok $uri->auth('x' x 268), 'auth';
   ok $uri->path('x' x 257), 'path';
   ok $uri->query('x' x 1025), 'query';
   ok $uri->frag('x' x 33), 'frag';
   ok $uri->usr('x' x 65), 'usr';
   ok $uri->pwd('x' x 65), 'pwd';
   ok $uri->host('x' x 129), 'host';
   ok $uri->port('1234567890'), 'port';
};

done_testing;

use utf8;
use ExtUtils::testlib;
use Test2::V0;
use Test::LeakTrace qw(no_leaks_ok);
use URI::Fast qw(uri uri_split);

SKIP: {
  skip_all 'memory tests fail when $ENV{COVERAGE} is set'
    if $ENV{COVERAGE};

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

      my $s1 = "$uri";
      my $s2 = $uri->to_string;
      my $s3 = $uri->as_string;
    } 'combined';


    no_leaks_ok {
      my $base = 'http://a/b/c/d;p?q';

      my @tests = (
        ["g"       , "http://a/b/c/g"],
        ["./g"     , "http://a/b/c/g"],
        ["g/"      , "http://a/b/c/g/"],
        ["/g"      , "http://a/g"],
        ["//g"     , "http://g"],
        ["?y"      , "http://a/b/c/d;p?y"],
        ["g?y"     , "http://a/b/c/g?y"],
        ["#s"      , "http://a/b/c/d;p?q#s"],
        ["g#s"     , "http://a/b/c/g#s"],
        ["g?y#s"   , "http://a/b/c/g?y#s"],
        [";x"      , "http://a/b/c/;x"],
        ["g;x"     , "http://a/b/c/g;x"],
        ["g;x?y#s" , "http://a/b/c/g;x?y#s"],
        [""        , "http://a/b/c/d;p?q"],
        ["."       , "http://a/b/c/"],
        ["./"      , "http://a/b/c/"],
        [".."      , "http://a/b/"],
        ["../"     , "http://a/b/"],
        ["../g"    , "http://a/b/g"],
        ["../.."   , "http://a/"],
        ["../../"  , "http://a/"],
        ["../../g" , "http://a/g"],
      );

      foreach my $test (@tests) {
        my ($rel, $exp) = @$test;
        my $abs = uri($rel)->absolute(uri($base));
      }

      my $uri = uri('some/path')->absolute('http://www.example.com/fnord');
    } 'absolute';
  };
};

done_testing;

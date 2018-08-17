use utf8;
use ExtUtils::testlib;
use Test2::V0;
use URI::Fast qw(uri);

my $E = '%3F';
my $e = '%3f';

is uri('HTTP://example.com')->normalize, 'http://example.com', 'lc scheme';
is uri('http://EXAMPLE.com')->normalize, 'http://example.com', 'lc host';
is uri('/foo/../bar')->normalize, '/bar', 'path: remove dot segments';

subtest 'uc encoded chars' => sub{
  is uri("?foo=$e")->normalize, "?foo=$E", 'query';
  is uri("?$e&$e")->normalize, "?$E&$E", 'query';
  is uri("http://foo${e}bar.com")->normalize, "http://foo${E}bar.com", 'auth';
  is uri("http://example.com/foo/$e/$e")->normalize, "http://example.com/foo/$E/$E", 'path';
};

done_testing;

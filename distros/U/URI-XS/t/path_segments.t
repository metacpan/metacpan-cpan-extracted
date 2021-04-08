use strict;
use warnings;
use Test::More;
use Test::Catch;
use lib 't/lib'; use MyTest;

catch_run("[path-segments]");

my $uri;
my @segments;

$uri = new URI::XS("https://ya.ru/my/path%2Ffak/cool/mf?a=b");
is($uri->path, '/my/path%2Ffak/cool/mf');
@segments = $uri->path_segments;
is_deeply(\@segments, [qw#my path/fak cool mf#]);

$uri = new URI::XS("https://ya.ru?a=b");
@segments = $uri->path_segments;
is_deeply(\@segments, []);

$uri = new URI::XS("https://ya.ru/?a=b");
@segments = $uri->path_segments;
is_deeply(\@segments, []);

$uri = new URI::XS("https://ya.ru/as/?a=b");
@segments = $uri->path_segments;
is_deeply(\@segments, ['as']);

$uri = new URI::XS("https://ya.ru/as?a=b");
@segments = $uri->path_segments;
is_deeply(\@segments, ['as']);

$uri->path_segments(1,2,3,4);
is($uri, "https://ya.ru/1/2/3/4?a=b");

$uri->path_segments('');
is($uri, "https://ya.ru?a=b");

$uri->path_segments('jopa popa', 'pizda/nah');
is($uri, "https://ya.ru/jopa%20popa/pizda%2Fnah?a=b");

done_testing();

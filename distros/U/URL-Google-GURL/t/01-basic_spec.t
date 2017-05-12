use strict;
use warnings;
use utf8;

use Test::More tests => 9;

use_ok('URL::Google::GURL');

_compare_spec("http://foo.bar.com:80", "http://foo.bar.com/");
_compare_spec("http://foo.bar.com:8080", "http://foo.bar.com:8080/");
_compare_spec("http://foo.bar.com?baz=1", "http://foo.bar.com/?baz=1");
_compare_spec('http://www.例子.網路.tw:80','http://www.xn--fsqu00a.xn--zf0ao64a.tw/');

sub _compare_spec
{
    my ($url, $expect) = @_;
    my $uobj = new_ok( 'URL::Google::GURL' => [$url] );
    my $spec = $uobj->spec();
    note("spec for $url is $spec");
    is($spec, $expect);
}

use strict;
use warnings;

use Test::More tests => 8;

use_ok('URL::Google::GURL');

_check_scheme('http://foo.bar.com:80', 'http', 1);
_check_scheme('https://foo.bar.com:8080', 'https', 1);
_check_scheme('ftp://user:pass@foo.bar.com', 'ftp', 1);
_check_scheme('file:///usr/local/websense/conf/foo.bar.', 'file', 1);
_check_scheme('http://foo.bar.com:80', 'ftp', 0);
_check_scheme('http://foo.bar.com:80', 'https', 0);
_check_scheme('http://foo.bar.com:80', 'file', 0);

sub _check_scheme
{
    my ($url, $expect, $is) = @_;
    my $uobj = URL::Google::GURL->new($url);
    note("scheme for $url is " . $uobj->scheme());
    is($uobj->scheme_is($expect), $is, "scheme validation for $url");
}

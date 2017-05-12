use strict;
use warnings;

use Test::More tests => 5;

{
    package MyURI;

    use base 'URI::SmartURI';

    sub mtfnpy {
        my $uri = shift;
        $uri->query_form([ $uri->query_form, qw(foo bar) ]);
        $uri
    }
}

BEGIN {
    MyURI->import('-import_uri_mods');
    use_ok('MyURI::URL')
}

is(MyURI::URL->new('http://search.cpan.org/~lwall/')->path,
    '/~lwall/', 'Magic import');

ok(my $uri = MyURI->new('http://www.catalystframework.org/calendar',
                    { reference => 'http://www.catalystframework.org/' }),
                    'new');

is($uri->mtfnpy,
   'http://www.catalystframework.org/calendar?foo=bar', 'new method');

is($uri->reference, 'http://www.catalystframework.org/', 'old method');

# vim: expandtab shiftwidth=4 ts=4 tw=80:

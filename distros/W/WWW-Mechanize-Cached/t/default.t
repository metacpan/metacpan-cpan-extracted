use strict;
use warnings;

use Test::Fatal;
use Test::More;
use Test::RequiresInternet ( 'www.wikipedia.com' => 443 );
use WWW::Mechanize::Cached;

my $mech = WWW::Mechanize::Cached->new;

is(
    exception {
        $mech->get('https://www.wikipedia.com');
    },
    undef,
    'no exceptions',
);

done_testing();

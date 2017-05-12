use warnings;
use strict;

use Test::HTTP tests => 4;

{
    my $test = Test::HTTP->new('GET basic');

    $test->get('http://www.socialtext.com/');
    $test->status_code_is(200);
}

{
    my $test = Test::HTTP->new('GET utf8-crap');
    my $uri = 'http://en.wikipedia.org/wiki/£';
    $test->get($uri);
    $test->status_code_is(200);
}

{
    my $test = Test::HTTP->new('GET json');
    $test->get( 'http://ajax.googleapis.com/ajax/services/search/news?v=1.0&q=barack%20obama',
        [ Accept => 'application/json' ] );
    $test->status_code_is(200);
    $test->header_like('Content-type', qr{text/javascript; charset=utf-8});
}

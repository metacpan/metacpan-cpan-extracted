use warnings;
use strict;

use Test::HTTP tests => 5;

{
    my $test = Test::HTTP->new('GET basic');

    $test->get('http://neverssl.com/');
    $test->status_code_is(200);
}

{
    my $test = Test::HTTP->new('GET with SSL');

    $test->get('https://www.eff.org');
    $test->status_code_is(200);
}

{
    my $test = Test::HTTP->new('GET utf8-crap');
    my $uri = 'https://en.wikipedia.org/wiki/£';
    $test->get($uri);
    $test->status_code_is(200);
}

{
    my $test = Test::HTTP->new('GET json');
    $test->get( 'https://en.wikipedia.org/w/api.php?action=query&origin=*&format=json&generator=search&gsrnamespace=0&gsrlimit=5&gsrsearch=%27New_England_Patriots%27',
        [ Accept => 'application/json' ] );
    $test->status_code_is(200);
    $test->header_like('Content-type', qr{application/json; charset=utf-8});
}

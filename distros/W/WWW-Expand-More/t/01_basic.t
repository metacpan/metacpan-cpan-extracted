use strict;
use warnings;
use Test::More;

use WWW::Expand::More;

if ($ENV{AUTHOR_TEST} || $ENV{TRAVIS}) {
    is(
        WWW::Expand::More->expand('http://bit.ly/1BPj30x'),
        'https://www.google.com/search?q=Perl',
    );

    my @urls = WWW::Expand::More->expand_all('http://bit.ly/1BPj30x');
    is $urls[0], 'http://bit.ly/1BPj30x';
    is $urls[1], 'https://goo.gl/dXwzqw';
    is $urls[2], 'https://www.google.com/search?q=Perl';

    is scalar(keys %WWW::Expand::More::CACHE), 0;

    is(
        WWW::Expand::More->expand('https://goo.gl/dXwzqw', { cache => 1 }),
        'https://www.google.com/search?q=Perl',
    );

    is(
        $WWW::Expand::More::CACHE{'https://goo.gl/dXwzqw'},
        'https://www.google.com/search?q=Perl',
    );
}
else {
    ok 1;
}

done_testing;

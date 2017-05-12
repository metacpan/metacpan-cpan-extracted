use strict;
use warnings;
use Test::Is qw/extended/;
use Test::More tests => 6;


use WWW::Pastebin::Sprunge::Create;
use WWW::Pastebin::Sprunge::Retrieve;
my $writer = WWW::Pastebin::Sprunge::Create->new();
my $reader = WWW::Pastebin::Sprunge::Retrieve->new();

my $CONTENT = rand();

SKIP: {
    my $uri1 = $writer->paste($CONTENT) or do {
        diag "Got error on ->paste($CONTENT): " . $writer->error();
        skip 'Got error', 6;
    };

    SKIP: {
        my $uri2 = $writer->paste(
            $CONTENT,
            lang => 'txt',
        ) or do {
            diag "Got error on ->paste($CONTENT, lang=>'txt'): " . $writer->error();
            skip 'Got error', 2;
        };
        isnt($uri1, $uri2, 'Should get different URLs, even for the same content');

        my $content1 = $reader->retrieve($uri1);
        my $content2 = $reader->retrieve($uri2);
        is($content1, $content2, 'Should get the same content, even for different URLs');
    }

    isa_ok( $writer->paste_uri(), 'URI::http', '->paste_uri() method' );

    like("$writer", qr{http://sprunge.us/\S+(?:\?\S+)?}, 'URL should be correctish');

    isa_ok( $writer->ua(), 'LWP::UserAgent', '->ua() method' );

    is( "$writer", $writer->paste_uri(), 'overloads');
}

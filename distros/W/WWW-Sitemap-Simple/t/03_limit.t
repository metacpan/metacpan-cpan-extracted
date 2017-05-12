use strict;
use warnings;
use Test::More;

use WWW::Sitemap::Simple;

{
    local $WWW::Sitemap::Simple::LIMIT_URL_COUNT = 10;
    my $sm = WWW::Sitemap::Simple->new;
    eval {
        for my $i (1..11) {
            $sm->add("http://rebuild.fm/$i");
        }
    };
    like $@, qr/^too many URL added: no more than \d+ URLs/, 'url count limit';
}

{
    local $WWW::Sitemap::Simple::LIMIT_URL_SIZE = 50;
    my $sm = WWW::Sitemap::Simple->new;
    eval {
        for my $i (1..5) {
            $sm->add("http://rebuild.fm/$i");
        }
        $sm->write;
    };
    like $@, qr/^too large xml: no more than \d+ bytes/, 'url size limit';
}

done_testing;

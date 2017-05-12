#!perl

use Test::More;

unless ( $ENV{XTATIK_TESTING} ) {
    diag 'Set XTATIK_TESTING env var to true, to run the tests';
    ok 1; done_testing; exit;
}

use Test::Mojo::WithRoles 'ElementCounter';
my $t = Test::Mojo::WithRoles->new('XTaTIK');

use lib 't';
eval 'use Test::XTaTIK';
use Mojo::DOM;

{
    $t->app->xtext('website_domain', 'sitemaptest.com' );
    $t->get_ok('/sitemap.xml')
        ->content_like( qr{\Qsitemaptest.com}, 'domain works', );

    $t->app->xtext('website_proto', 'https' );
    $t->get_ok('/sitemap.xml')
        ->content_like(
            qr{<url>\s*<loc>https://sitemaptest\.com/contact</loc>\s*
                <changefreq>weekly</changefreq>\s*
                <priority>0\.9</priority>\s*
                </url>}x,
            'content is sane',
        );
}

done_testing();

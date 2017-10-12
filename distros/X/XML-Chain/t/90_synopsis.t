#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use open ':std', ':encoding(utf8)';
use Test::Most;
use File::Temp qw(tempdir);
use Path::Class qw(dir file);
use DateTime;

use FindBin qw($Bin);
use lib "$Bin/lib";

use XML::Chain qw(xc);

my $tmp_dir = dir(tempdir( CLEANUP => 1 ));

subtest 'XML::Chain' => sub {
    my $div = xc('div', class => 'pretty')
                ->c('h1')->t('hello')
                ->up
                ->c('p', class => 'intro')->t('world')
                ->root
                ->a( xc('p')->t('of chained XML.') );
    is(
        $div->as_string,
        '<div class="pretty"><h1>hello</h1><p class="intro">world</p><p>of chained XML.</p></div>',
        'synopsis chunk 1',
    );

    my $sitemap =
        xc('urlset', xmlns => 'http://www.sitemaps.org/schemas/sitemap/0.9')
        ->t("\n")
        ->c('url')
            ->a('loc',        '-' => 'https://metacpan.org/pod/XML::Chain::Selector')
            ->a('lastmod',    '-' => DateTime->from_epoch(epoch => 1507451828)->strftime('%Y-%m-%d'))
            ->a('changefreq', '-' => 'monthly')
            ->a('priority',   '-' => '0.6')
        ->up->t("\n")
        ->c('url')
            ->a('loc',        '-' => 'https://metacpan.org/pod/XML::Chain::Element')
            ->a('lastmod',    '-' => DateTime->from_epoch(epoch => 1507279028)->strftime('%Y-%m-%d'))
            ->a('changefreq', '-' => 'monthly')
            ->a('priority',   '-' => '0.5')
        ->up->t("\n");
    is(
        $sitemap->root->as_string,
        qq{<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n}
        .qq{<url><loc>https://metacpan.org/pod/XML::Chain::Selector</loc><lastmod>2017-10-08</lastmod><changefreq>monthly</changefreq><priority>0.6</priority></url>\n}
        .qq{<url><loc>https://metacpan.org/pod/XML::Chain::Element</loc><lastmod>2017-10-06</lastmod><changefreq>monthly</changefreq><priority>0.5</priority></url>\n}
        .qq{</urlset>},
        'synopsis chunk 2',
    );
};

done_testing;

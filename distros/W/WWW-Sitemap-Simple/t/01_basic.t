use strict;
use warnings;
use Test::More;
use Test::Output;

use WWW::Sitemap::Simple;

{
    my $sm = WWW::Sitemap::Simple->new;
    is ref($sm), 'WWW::Sitemap::Simple';
    is $sm->count, 0;
    is $sm->indent, "\t";
    is_deeply $sm->url, +{};
    is_deeply $sm->urlset, +{
        xmlns => 'http://www.sitemaps.org/schemas/sitemap/0.9',
    };
}

{
    my $sm = WWW::Sitemap::Simple->new;
    $sm->add("http://rebuild.fm/");
    stdout_is(
        sub { $sm->write; },
        <<'_XML_',
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
	<url>
		<loc>http://rebuild.fm/</loc>
	</url>
</urlset>
_XML_
        'basic'
    );
}

{
    my $sm = WWW::Sitemap::Simple->new;
    my $id = $sm->add("http://rebuild.fm/");
    my $id_again = $sm->add("http://rebuild.fm/");
    is $id, $id_again, 'add twice';
    is $sm->count, 1, 'count up only once';
    stdout_is(
        sub { $sm->write; },
        <<'_XML_',
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
	<url>
		<loc>http://rebuild.fm/</loc>
	</url>
</urlset>
_XML_
    );
}

{
    my $sm = WWW::Sitemap::Simple->new;
    $sm->add("http://rebuild.fm/");
    my $id = $sm->add("http://rebuild.fm/64/");
    $sm->add_params($id, { priority => "0.8" });

    stdout_is(
        sub { $sm->write; },
        <<'_XML_',
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
	<url>
		<loc>http://rebuild.fm/</loc>
	</url>
	<url>
		<loc>http://rebuild.fm/64/</loc>
		<priority>0.8</priority>
	</url>
</urlset>
_XML_
        'add url'
    );

    is $sm->count, 2;
}

{
    my $sm = WWW::Sitemap::Simple->new;
    $sm->add("http://rebuild.fm/");
    my $id = $sm->add("http://rebuild.fm/63/");
    my $params = {
        changefreq => 'weekly',
        priority   => "0.1",
        lastmod    => "2014-10-25T20:49:05+00:00",
    };
    $sm->add_params($id, $params);

    stdout_is(
        sub { $sm->write; },
        <<'_XML_',
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
	<url>
		<loc>http://rebuild.fm/</loc>
	</url>
	<url>
		<loc>http://rebuild.fm/63/</loc>
		<lastmod>2014-10-25T20:49:05+00:00</lastmod>
		<changefreq>weekly</changefreq>
		<priority>0.1</priority>
	</url>
</urlset>
_XML_
        'add_params'
    );
}

{
    my $sm = WWW::Sitemap::Simple->new(
        urlset => {
            'xmlns' => "http://www.sitemaps.org/schemas/sitemap/0.9",
            'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
            'xsi:schemaLocation' => 'http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd',
        },
    );
    $sm->add("http://rebuild.fm/");

    stdout_is(
        sub { $sm->write; },
        <<'_XML_',
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd">
	<url>
		<loc>http://rebuild.fm/</loc>
	</url>
</urlset>
_XML_
        'urlset'
    );
}

{
    my $sm = WWW::Sitemap::Simple->new(indent => '  ');
    $sm->add("http://rebuild.fm/");
    stdout_is(
        sub { $sm->write; },
        <<'_XML_',
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>http://rebuild.fm/</loc>
  </url>
</urlset>
_XML_
        'indent'
    );
}

done_testing;

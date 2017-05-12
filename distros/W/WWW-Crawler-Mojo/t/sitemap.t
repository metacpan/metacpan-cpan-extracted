use strict;
use warnings;
use utf8;
use File::Basename 'dirname';
use File::Spec::Functions qw{catdir splitdir rel2abs canonpath};
use lib catdir(dirname(__FILE__), '../lib');
use lib catdir(dirname(__FILE__), 'lib');
use Test::More;
use Mojo::DOM;
use WWW::Crawler::Mojo;
use WWW::Crawler::Mojo::Job;
use Test::More tests => 6;

my @array;
my $xml;

$xml = <<EOF;
<?xml version="1.0" encoding="utf-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd">
    <url>
        <loc>http://example.com/1</loc>
    </url>
    <url>
        <loc>http://example.com/2</loc>
    </url>
</urlset>
EOF

@array = ();
{
  my $res = Mojo::Message::Response->new;
  $res->code(200);
  $res->headers->content_type('text/html');
  $res->headers->content_length(length($xml));
  $res->body(Mojo::DOM->new($xml));
  my $job = WWW::Crawler::Mojo::Job->new(url => 'http://example.com/');
  my $bot = WWW::Crawler::Mojo->new;
  for my $job ($bot->scrape($res, $job)) {
    push(@array, $job->literal_uri);
    push(@array, $job->context);
  }
}
is shift @array, 'http://example.com/1', 'right url';
is shift(@array)->tag, 'urlset', 'right type';
is shift @array, 'http://example.com/2', 'right url';
is shift(@array)->tag, 'urlset', 'right type';
is shift(@array), undef, 'right type';

$xml = <<EOF;
<?xml version="1.0" encoding="utf-8"?>
<urlset
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:schemaLocation="http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd">
    <url>
        <loc>http://example.com/1</loc>
    </url>
</urlset>
EOF

@array = ();
{
  my $res = Mojo::Message::Response->new;
  $res->code(200);
  $res->headers->content_type('text/html');
  $res->headers->content_length(length($xml));
  $res->body(Mojo::DOM->new($xml));
  my $job = WWW::Crawler::Mojo::Job->new(url => 'http://example.com/');
  my $bot = WWW::Crawler::Mojo->new;
  for my $job ($bot->scrape($res, $job)) {
    push(@array, $job->literal_uri);
    push(@array, $job->context);
  }
}
is shift(@array), undef, 'right type';

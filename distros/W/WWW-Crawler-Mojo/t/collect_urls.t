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
use Test::More tests => 50;

my @array;
my @array2;
my @array3;

my $html = <<EOF;
<html>
<head>
    <meta content="5;URL=http://example.com/no-a-redirection">
    <meta http-equiv="Refresh" content="5;URL=http://example.com/redirected">
    <link rel="stylesheet" type="text/css" href="css1.css" />
    <link rel="stylesheet" type="text/css" href="css2.css" />
    <script type="text/javascript" src="js1.js"></script>
    <script type="text/javascript" src="js2.js"></script>
    <style>
        a {
            background-image:url(http://example.com/bgimg.png);
        }
    </style>
</head>
<body>
<a href="index1.html">A</a>
<a href="index2.html">B</a>
<a href="mailto:a\@example.com">C</a>
<a href="tel:0000">D</a>
<map name="m_map" id="m_map">
    <area href="index3.html" coords="" title="E" ping="http://example.com/" />
</map>
<script>
    var a = "<a href='hoge'>F</a>";
</script>
<div id="cont1">
    <a href="escaped?foo=bar&amp;baz=yada">G</a>
</div>
<div id="cont2">
    <a href="//example.com">ommit scheme</a>
    <a href="http://doublehit.com/" style="background-image:url(http://example.com/bgimg2.png);"></a>
</div>
</body>
</html>
EOF

@array  = ();
@array2 = ();
@array3 = ();
{
  my $res = Mojo::Message::Response->new;
  $res->code(200);
  $res->headers->content_type('text/html');
  $res->headers->content_length(length($html));
  $res->body(Mojo::DOM->new($html));
  my $job = WWW::Crawler::Mojo::Job->new(url => 'http://example.com/');
  my $bot = WWW::Crawler::Mojo->new;
  for ($bot->scrape($res, $job)) {
    push(@array, $_->literal_uri);
    push(@array, $_->context);
  }
  for ($bot->scrape($res, $job, '#cont1')) {
    push(@array2, $_->literal_uri);
    push(@array2, $_->context);
  }
  for ($bot->scrape($res, $job, ['#cont1', '#cont2'])) {
    push(@array3, $_->literal_uri);
    push(@array3, $_->context);
  }
}
is shift @array, 'http://example.com/bgimg2.png', 'right url';
is shift(@array)->tag, 'a', 'right type';
is shift @array, 'index1.html', 'right url';
is shift(@array)->tag, 'a', 'right type';
is shift @array, 'index2.html', 'right url';
is shift(@array)->tag, 'a', 'right type';
is shift @array, 'escaped?foo=bar&baz=yada', 'right url';
is shift(@array)->tag, 'a', 'right type';
is shift @array, '//example.com', 'right url';
is shift(@array)->tag, 'a', 'right type';
is shift @array, 'http://doublehit.com/', 'right url';
is shift(@array)->tag, 'a', 'right type';
is shift @array, 'index3.html', 'right url';
is shift(@array)->tag, 'area', 'right type';
is shift @array, 'http://example.com/', 'right url';
is shift(@array)->tag, 'area', 'right type';
is shift @array, 'css1.css', 'right url';
is shift(@array)->tag, 'link', 'right type';
is shift @array, 'css2.css', 'right url';
is shift(@array)->tag, 'link', 'right type';
is shift @array, 'http://example.com/redirected', 'right url';
is shift(@array)->tag, 'meta', 'right type';
is shift @array, 'js1.js', 'right url';
is shift(@array)->tag, 'script', 'right type';
is shift @array, 'js2.js', 'right url';
is shift(@array)->tag, 'script', 'right type';
is shift @array, 'http://example.com/bgimg.png', 'right url';
is shift(@array)->tag, 'style', 'right type';
is shift @array, undef, 'no more urls';

is shift @array2, 'escaped?foo=bar&baz=yada', 'right url';
is shift(@array2)->tag, 'a', 'right type';
is shift @array, undef, 'no more urls';

is shift @array3, 'escaped?foo=bar&baz=yada', 'right url';
is shift(@array3)->tag, 'a', 'right type';
is shift @array3, 'http://example.com/bgimg2.png', 'right url';
is shift(@array3)->tag, 'a', 'right type';
is shift @array3, '//example.com', 'right url';
is shift(@array3)->tag, 'a', 'right type';
is shift @array3, 'http://doublehit.com/', 'right url';
is shift(@array3)->tag, 'a', 'right type';
is shift @array, undef, 'no more urls';

{
  my $css = <<EOF;
body {
    background-image:url('/image/a.png');
}
div {
    background-image:url('/image/b.png');
}
div {
    background: #fff url('/image/c.png');
}
div {
    background: #fff url(/image/d.png);
}
div {
    background: #fff url("/image/e.png");
}
div {
    background: #fff url(/image/?spring15');
}
div {
    background: #fff URL(/image/f);
}
EOF

  my @array = WWW::Crawler::Mojo::collect_urls_css($css);
  is shift @array, '/image/a.png',      'right url';
  is shift @array, '/image/b.png',      'right url';
  is shift @array, '/image/c.png',      'right url';
  is shift @array, '/image/d.png',      'right url';
  is shift @array, '/image/e.png',      'right url';
  is shift @array, "/image/?spring15'", 'right url';
  is shift @array, "/image/f",          'right url';
  is shift @array, undef,               'empty';
}

my $xhtml = <<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" lang="en" xml:lang="en">
<head>
</head>
<body>
    <script>
        var a = "<a href='hoge'>a</a>";
    </script>
</body>
</html>
EOF

@array = ();
{
  my $res = Mojo::Message::Response->new;
  $res->code(200);
  $res->headers->content_type('text/html');
  $res->headers->content_length(length($xhtml));
  $res->body(Mojo::DOM->new($xhtml));
  my $job = WWW::Crawler::Mojo::Job->new(url => 'http://example.com/');
  my $bot = WWW::Crawler::Mojo->new;
  for ($bot->scrape($res, $job)) {
    $bot->enqueue($_);
    push(@array, $job->literal_uri);
    push(@array, $job->context);
  }
}
is(scalar @array, 0, 'right length');

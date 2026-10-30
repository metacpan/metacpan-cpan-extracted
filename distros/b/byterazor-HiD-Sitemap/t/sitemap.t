#! perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use DateTime;
use Path::Tiny;

use byterazor::HiD::Sitemap;
use Test::Sitemap::Entry;
use Test::Sitemap::Site;

my $generator = byterazor::HiD::Sitemap->new;

sub make_site {
  my( %args ) = @_;

  return Test::Sitemap::Site->new({
    destination => $args{destination} // '_site' ,
    config      => $args{config} // {
      sitemap => {
        generate => 1 ,
        baseurl  => 'https://example.com' ,
      },
    },
    pages => $args{pages} // [] ,
    posts => $args{posts} // [] ,
  });
}

sub taken_object {
  my( $site , $name ) = @_;

  is( scalar @{ $site->objects } , 1 , "$name: one object generated" );
  my $object = $site->objects->[0];
  ok( $object->isa('HiD::VirtualPage') , "$name: object is a HiD::VirtualPage" );

  return $object;
}

# --- disabled -----------------------------------------------------------------

{
  my $site = make_site(
    pages  => [ Test::Sitemap::Entry->new({ url => '/' }) ] ,
    config => { sitemap => {} } ,
  );

  $generator->generate( $site );

  is( scalar @{ $site->objects } , 0 , 'disabled: no objects generated' );
}

# --- basic generation ---------------------------------------------------------

{
  my $page = Test::Sitemap::Entry->new({
    url            => '/about/' ,
    input_filename => 'about.html' ,
  });

  my $post = Test::Sitemap::Entry->new({
    url  => '/2026-01-15/hello-world/' ,
    date => DateTime->new(
      year => 2026, month => 1, day => 15,
      hour => 8, minute => 30, time_zone => 'UTC' ,
    ),
  });

  my $site = make_site( pages => [$page] , posts => [$post] );
  $generator->generate( $site );

  my $object = taken_object( $site , 'basic' );

  is( $object->output_filename , '_site/sitemap.xml' ,
    'basic: default destination' );

  like( $object->content ,
    qr{<urlset xmlns="http://www\.sitemaps\.org/schemas/sitemap/0\.9">} ,
    'basic: urlset with sitemap namespace' );

  like( $object->content ,
    qr{<loc>https://example\.com/about/</loc>} ,
    'basic: page URL' );

  like( $object->content ,
    qr{<loc>https://example\.com/2026-01-15/hello-world/</loc>} ,
    'basic: post URL' );

  like( $object->content ,
    qr{<lastmod>2026-01-15T08:30:00Z</lastmod>} ,
    'basic: post lastmod from post date' );

  is( $site->inputs->{'SITEMAP'} // '' , 'page' ,
    'basic: input registered' );
}

# --- lastmod from file mtime --------------------------------------------------

{
  my $tmp  = Path::Tiny->tempdir;
  my $file = $tmp->child( 'about.html' );
  $file->spew( 'hello' );

  utime( 1700000000 , 1700000000 , $file );

  my $page = Test::Sitemap::Entry->new({
    url            => '/about/' ,
    input_filename => $file->stringify ,
  });

  my $site = make_site( pages => [$page] );
  $generator->generate( $site );

  my $object   = taken_object( $site , 'mtime' );
  my $expected = DateTime->from_epoch(
    epoch => 1700000000 , time_zone => 'UTC' )
    ->strftime( '%Y-%m-%dT%H:%M:%SZ' );

  like( $object->content , qr{<lastmod>$expected</lastmod>} ,
    'mtime: page lastmod from input file mtime' );
}

# --- lastmod disabled ---------------------------------------------------------

{
  my $post = Test::Sitemap::Entry->new({
    url  => '/post/' ,
    date => DateTime->now( time_zone => 'UTC' ) ,
  });

  my $site = make_site(
    posts  => [$post] ,
    config => {
      sitemap => {
        generate => 1 ,
        baseurl  => 'https://example.com' ,
        lastmod  => 0 ,
      },
    },
  );

  $generator->generate( $site );

  my $object = taken_object( $site , 'no lastmod' );
  unlike( $object->content , qr{<lastmod>} , 'no lastmod elements' );
}

# --- missing input file: no lastmod, no crash ---------------------------------

{
  my $page = Test::Sitemap::Entry->new({
    url            => '/gone/' ,
    input_filename => '/nonexistent/page.html' ,
  });

  my $site = make_site( pages => [$page] );
  $generator->generate( $site );

  my $object = taken_object( $site , 'missing file' );
  like( $object->content , qr{<loc>https://example\.com/gone/</loc>} ,
    'missing file: URL still included' );
  unlike( $object->content , qr{<lastmod>} , 'missing file: no lastmod' );
}

# --- exclude ------------------------------------------------------------------

{
  my $keep    = Test::Sitemap::Entry->new({ url => '/keep/' });
  my $secret  = Test::Sitemap::Entry->new({ url => '/secret/stuff/' });

  my $site = make_site(
    pages  => [ $keep , $secret ] ,
    config => {
      sitemap => {
        generate => 1 ,
        baseurl  => 'https://example.com' ,
        exclude  => [ 'secret' ] ,
      },
    },
  );

  $generator->generate( $site );

  my $object = taken_object( $site , 'exclude' );
  like( $object->content , qr{<loc>https://example\.com/keep/</loc>} ,
    'exclude: non-matching URL kept' );
  unlike( $object->content , qr{secret} , 'exclude: matching URL dropped' );
}

# --- duplicates ---------------------------------------------------------------

{
  my $a = Test::Sitemap::Entry->new({ url => '/dup/' });
  my $b = Test::Sitemap::Entry->new({ url => '/dup/' });

  my $site = make_site( pages => [$a] , posts => [$b] );
  $generator->generate( $site );

  my $object = taken_object( $site , 'dedupe' );
  my $count  = () = $object->content =~ /<url>/g;
  is( $count , 1 , 'dedupe: identical URL listed once' );
}

# --- baseurl handling ----------------------------------------------------------

{
  # falls back to the site-wide baseurl
  my $page = Test::Sitemap::Entry->new({ url => '/' });
  my $site = make_site(
    pages  => [$page] ,
    config => { baseurl => 'https://site.example' , sitemap => { generate => 1 } },
  );

  $generator->generate( $site );

  my $object = taken_object( $site , 'fallback baseurl' );
  like( $object->content , qr{<loc>https://site\.example/</loc>} ,
    'fallback baseurl: site baseurl used' );
  is( grep( $_->[0] eq 'WARN' , @{ $site->messages } ) , 0 ,
    'fallback baseurl: no warning for absolute baseurl' );
}

{
  # trailing slash on the baseurl must not double up
  my $page = Test::Sitemap::Entry->new({ url => '/about/' });
  my $site = make_site(
    pages  => [$page] ,
    config => {
      sitemap => {
        generate => 1 ,
        baseurl  => 'https://example.com/' ,
      },
    },
  );

  $generator->generate( $site );

  my $object = taken_object( $site , 'trailing slash' );
  like( $object->content , qr{<loc>https://example\.com/about/</loc>} ,
    'trailing slash: not doubled' );
}

{
  # non-absolute baseurl still works but warns
  my $page = Test::Sitemap::Entry->new({ url => '/about/' });
  my $site = make_site(
    pages  => [$page] ,
    config => {
      sitemap => {
        generate => 1 ,
        baseurl  => '/' ,
      },
    },
  );

  $generator->generate( $site );

  my $object = taken_object( $site , 'relative baseurl' );
  like( $object->content , qr{<loc>/about/</loc>} ,
    'relative baseurl: no double slash' );
  is( grep( $_->[0] eq 'WARN' , @{ $site->messages } ) , 1 ,
    'relative baseurl: warning emitted' );
}

# --- custom destination --------------------------------------------------------

{
  my $page = Test::Sitemap::Entry->new({ url => '/' });
  my $site = make_site(
    pages  => [$page] ,
    config => {
      sitemap => {
        generate    => 1 ,
        baseurl     => 'https://example.com' ,
        destination => 'search/index.xml' ,
      },
    },
  );

  $generator->generate( $site );

  my $object = taken_object( $site , 'custom destination' );
  is( $object->output_filename , '_site/search/index.xml' ,
    'custom destination: used as-is under site destination' );
}

# --- empty site -----------------------------------------------------------------

{
  my $site = make_site();
  $generator->generate( $site );

  my $object = taken_object( $site , 'empty site' );
  is( $object->content ,
    qq{<?xml version="1.0" encoding="UTF-8"?>\n}
    . qq{<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n}
    . "</urlset>\n" ,
    'empty site: well-formed empty urlset' );
}

done_testing();

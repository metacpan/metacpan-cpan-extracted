#! perl

use strict;
use warnings;

use lib 'lib';
use lib 't/lib';

use Test::More;
use Path::Tiny;

use byterazor::HiD::BrokenLink;
use Test::BrokenLink::Site;

my $plugin = byterazor::HiD::BrokenLink->new;

# Builds a real site destination in a temp dir and returns the site mock
# and the temp dir.
sub build_site {
  my( %args ) = @_;

  my $tmp = Path::Tiny->tempdir( CLEANUP => 1 );

  for my $file ( @{ $args{files} // [] } ) {
    my $p = $tmp->child( $file->{path} );
    $p->parent->mkpath;
    $p->spew( $file->{content} // '' );
  }

  for my $dir ( @{ $args{dirs} // [] } ) {
    $tmp->child( $dir )->mkpath;
  }

  my $site = Test::BrokenLink::Site->new({
    destination => $tmp->stringify ,
    config      => $args{config} // { brokenlink => { enabled => 1 } } ,
  });

  return ( $site , $tmp );
}

sub is_broken {
  my( $result , $count , $name ) = @_;
  is( scalar @{ $result->{broken} } , $count , $name );
}

# --- basic HTML links -----------------------------------------------------------------

{
  my ( $site , $tmp ) = build_site(
    files => [
      { path => 'index.html' , content => '<a href="about.html">about</a>' } ,
      { path => 'about.html' , content => '<p>about</p>' } ,
    ],
  );

  my $result = $plugin->scan( $site );

  is_broken( $result , 0 , 'a href to existing page: not broken' );
  is( $result->{checked} , 1 , 'a href to existing page: one reference checked' );
  is_deeply( [ sort @{ $result->{files} } ] ,
    [ 'about.html' , 'index.html' ] ,
    'scan: file list' );
}

{
  my ( $site , $tmp ) = build_site(
    files => [ { path => 'index.html' , content => '<a href="missing.html">x</a>' } ],
  );

  my $result = $plugin->scan( $site );

  is_broken( $result , 1 , 'a href to missing page: broken' );
  is( $result->{broken}[0]{link} , 'missing.html' , 'missing page: link reported' );
  is( $result->{broken}[0]{src} , 'index.html' , 'missing page: source reported' );
  is( $result->{broken}[0]{resolved} , 'missing.html' ,
    'missing page: resolved path reported' );
}

# --- images ---------------------------------------------------------------------------

{
  my ( $site , $tmp ) = build_site(
    files => [
      { path => 'index.html' , content => '<img src="img/logo.png" alt="">' } ,
      { path => 'img/logo.png' , content => 'png' } ,
    ],
  );

  my $result = $plugin->scan( $site );
  is_broken( $result , 0 , 'img src to existing file: not broken' );
}

{
  my ( $site , $tmp ) = build_site(
    files => [ { path => 'index.html' , content => '<img src="img/nope.png">' } ],
  );

  my $result = $plugin->scan( $site );

  is_broken( $result , 1 , 'img src to missing file: broken' );
  is( $result->{broken}[0]{link} , 'img/nope.png' , 'img: link reported' );
  is( $result->{broken}[0]{resolved} , 'img/nope.png' ,
    'img: resolved path reported' );
}

# --- stylesheets ------------------------------------------------------------------------

{
  my ( $site , $tmp ) = build_site(
    files => [
      {
        path    => 'index.html' ,
        content => '<head><link rel="stylesheet" href="style.css"></head>' ,
      } ,
      { path => 'style.css' , content => 'body { color: red; }' } ,
    ],
  );

  my $result = $plugin->scan( $site );

  is_broken( $result , 0 , 'link rel=stylesheet to existing file: not broken' );
  is( $result->{checked} , 1 , 'link rel=stylesheet: one reference checked' );
}

# --- CSS url() ---------------------------------------------------------------------------

{
  my ( $site , $tmp ) = build_site(
    files => [
      { path => 'index.html' , content => '<link href="style.css">' } ,
      { path => 'style.css' , content => 'body { background: url(img/bg.png); }' } ,
      { path => 'img/bg.png' , content => 'png' } ,
    ],
  );

  my $result = $plugin->scan( $site );

  is_broken( $result , 0 , 'css url() to existing file: not broken' );
  is( $result->{checked} , 2 , 'css url(): two references checked' );
}

{
  my ( $site , $tmp ) = build_site(
    files => [
      { path => 'style.css' , content => 'body { background: url(img/bg.png); }' } ,
    ],
  );

  my $result = $plugin->scan( $site );

  is_broken( $result , 1 , 'css url() to missing file: broken' );
  is( $result->{broken}[0]{src} , 'style.css' , 'css: source reported' );
  is( $result->{broken}[0]{link} , 'img/bg.png' , 'css: link reported' );
}

# --- scripts --------------------------------------------------------------------------------

{
  my ( $site , $tmp ) = build_site(
    files => [
      { path => 'index.html' , content => '<script src="js/app.js"></script>' } ,
      { path => 'js/app.js' , content => 'void 0;' } ,
    ],
  );

  my $result = $plugin->scan( $site );
  is_broken( $result , 0 , 'script src to existing file: not broken' );
}

# --- external and non-file references are skipped ---------------------------------------------

{
  my ( $site , $tmp ) = build_site(
    files => [
      {
        path    => 'index.html' ,
        content => q{<a href="https://example.com/x">x</a>}
          . q{<a href="//example.com/x">y</a>} ,
      } ,
    ],
  );

  my $result = $plugin->scan( $site );

  is( $result->{checked} , 0 , 'external URLs: not checked' );
  is_broken( $result , 0 , 'external URLs: not broken' );
}

{
  my ( $site , $tmp ) = build_site(
    files => [
      {
        path    => 'index.html' ,
        content =>
          q{<a href="mailto:x@example.com">m</a>}
          . q{<a href="tel:+123">t</a>}
          . q{<a href="javascript:void(0)">j</a>}
          . q{<a href="data:text/plain,hi">d</a>} ,
      } ,
    ],
  );

  my $result = $plugin->scan( $site );
  is( $result->{checked} , 0 , 'other schemes: not checked' );
}

{
  my ( $site , $tmp ) = build_site(
    files => [ { path => 'index.html' , content => '<a href="#top">top</a>' } ],
  );

  my $result = $plugin->scan( $site );
  is( $result->{checked} , 0 , 'pure fragment: not checked' );
}

{
  my ( $site , $tmp ) = build_site(
    files => [
      { path => 'index.html' , content => '<a href="about.html?v=1">a</a>' } ,
      { path => 'about.html' , content => '<p>about</p>' } ,
    ],
  );

  my $result = $plugin->scan( $site );

  is( $result->{checked} , 1 , 'query string: stripped before checking' );
  is_broken( $result , 0 , 'query string: not broken' );
}

# --- directory links -----------------------------------------------------------------------------

{
  my ( $site , $tmp ) = build_site(
    files => [
      { path => 'index.html' , content => '<a href="/about/">about</a>' } ,
      { path => 'about/index.html' , content => '<p>about</p>' } ,
    ],
  );

  my $result = $plugin->scan( $site );

  is( $result->{checked} , 1 , 'dir with index.html: checked' );
  is_broken( $result , 0 , 'dir with index.html: not broken' );
}

{
  my ( $site , $tmp ) = build_site(
    files => [
      { path => 'index.html' , content => '<a href="/about/">about</a>' } ,
    ],
  );

  my $result = $plugin->scan( $site );

  is_broken( $result , 1 , 'missing dir: broken' );
  is( $result->{broken}[0]{link} , '/about/' , 'missing dir: link reported' );
  is( $result->{broken}[0]{resolved} , 'about/' ,
    'missing dir: resolved path reported' );
}

{
  # no trailing slash: an existing directory is enough, even without index.html
  my ( $site , $tmp ) = build_site(
    files => [ { path => 'index.html' , content => '<a href="about">about</a>' } ],
    dirs  => [ 'about' ] ,
  );

  my $result = $plugin->scan( $site );

  is_broken( $result , 0 , 'link to existing dir (no index.html): not broken' );
  is_deeply( [ sort @{ $result->{dirs} } ] , [ 'about' ] , 'scan: dir list' );
}

# --- baseurl stripping ------------------------------------------------------------------------------

{
  my ( $site , $tmp ) = build_site(
    files => [
      {
        path    => 'index.html' ,
        content => '<a href="https://example.com/about.html">a</a>' ,
      } ,
      { path => 'about.html' , content => '<p>about</p>' } ,
    ],
    config => { baseurl => 'https://example.com' , brokenlink => { enabled => 1 } } ,
  );

  my $result = $plugin->scan( $site );

  is( $result->{checked} , 1 , 'baseurl (host only): local reference checked' );
  is_broken( $result , 0 , 'baseurl (host only): not broken' );
}

{
  my ( $site , $tmp ) = build_site(
    files => [
      {
        path    => 'index.html' ,
        content =>
          q{<a href="https://example.com/blog/x.html">x</a>}
          . q{<a href="https://example.com/other.html">o</a>} ,
      } ,
      { path => 'x.html' , content => '<p>x</p>' } ,
    ],
    config => {
      baseurl    => 'https://example.com/blog' ,
      brokenlink => { enabled => 1 } ,
    } ,
  );

  my $result = $plugin->scan( $site );

  is( $result->{checked} , 1 ,
    'baseurl (with path): only same-path URL is treated as local' );
  is_broken( $result , 0 , 'baseurl (with path): not broken' );
}

{
  # with strip_baseurl disabled, the same absolute URL stays external
  my ( $site , $tmp ) = build_site(
    files => [
      {
        path    => 'index.html' ,
        content => '<a href="https://example.com/about.html">a</a>' ,
      } ,
      { path => 'about.html' , content => '<p>about</p>' } ,
    ],
    config => {
      baseurl    => 'https://example.com' ,
      brokenlink => { enabled => 1 , strip_baseurl => 0 } ,
    } ,
  );

  my $result = $plugin->scan( $site );
  is( $result->{checked} , 0 , 'strip_baseurl 0: absolute URL not checked' );
}

# --- exclude ---------------------------------------------------------------------------------------------

{
  my ( $site , $tmp ) = build_site(
    files => [
      {
        path    => 'index.html' ,
        content =>
          q{<a href="skipme.html">s</a>}
          . q{<a href="also-missing.html">a</a>} ,
      } ,
    ],
    config => { brokenlink => { enabled => 1 , exclude => [ '^skipme' ] } } ,
  );

  my $result = $plugin->scan( $site );

  is( $result->{checked} , 1 , 'exclude: non-matching reference checked' );
  is( $result->{broken}[0]{link} , 'also-missing.html' ,
    'exclude: only the matching reference is skipped' );
}

# --- relative references in subdirectories ---------------------------------------------------------------

{
  my ( $site , $tmp ) = build_site(
    files => [
      { path => 'index.html' , content => '<p>root</p>' } ,
      {
        path    => 'blog/post.html' ,
        content => q{<a href="other.html">o</a><a href="../index.html">r</a>} ,
      } ,
      { path => 'blog/other.html' , content => '<p>other</p>' } ,
    ],
  );

  my $result = $plugin->scan( $site );

  is( $result->{checked} , 2 , 'subdir: two references checked' );
  is_broken( $result , 0 , 'subdir: relative and parent references not broken' );
}

{
  my ( $site , $tmp ) = build_site(
    files => [
      { path => 'a/b/c.html' , content => '<a href="../../../outside.html">o</a>' } ,
    ],
  );

  my $result = $plugin->scan( $site );

  is_broken( $result , 1 , 'escaping reference: broken' );
  is( $result->{broken}[0]{reason} , 'escapes destination' ,
    'escaping reference: reason' );

  $plugin->after_publish( $site );
  my @warn = grep { $_->[0] eq 'WARN' } @{ $site->messages };
  is( $warn[0][1] ,
    'brokenlink: a/b/c.html: ../../../outside.html -> missing '
    . '../../../outside.html (escapes destination)' ,
    'escaping reference: warning format with reason' );
}

# --- check_css / check_js flags -----------------------------------------------------------------------------

{
  my ( $site , $tmp ) = build_site(
    files => [
      { path => 'index.html' , content => '<p>hi</p>' } ,
      { path => 'style.css' , content => 'body { background: url(img/nope.png); }' } ,
    ],
    config => { brokenlink => { enabled => 1 , check_css => 0 } } ,
  );

  my $result = $plugin->scan( $site );

  is( $result->{files_checked} , 1 , 'check_css 0: only the html file scanned' );
  is( $result->{checked} , 0 , 'check_css 0: no references checked' );
}

{
  my ( $site , $tmp ) = build_site(
    files => [
      {
        path    => 'app.js' ,
        content => q{var a = '/js/data.json'; var b = '/img/pix.png';}
          . q{var c = 'https://x.com/y.png'; var d = '/rel/nope.js';} ,
      } ,
      { path => 'js/data.json' , content => '{}' } ,
      { path => 'img/pix.png' , content => 'png' } ,
    ],
    config => { brokenlink => { enabled => 1 , check_js => 1 } } ,
  );

  my $result = $plugin->scan( $site );

  is( $result->{checked} , 3 , 'check_js 1: three root-relative refs checked' );
  is_broken( $result , 1 , 'check_js 1: only the missing ref broken' );
  is( $result->{broken}[0]{link} , '/rel/nope.js' ,
    'check_js 1: broken link reported' );
}

{
  # JavaScript is not scanned by default
  my ( $site , $tmp ) = build_site(
    files => [ { path => 'app.js' , content => q{var a = '/nope.js';} } ],
  );

  my $result = $plugin->scan( $site );
  is( $result->{files_checked} , 0 , 'check_js default: js file not scanned' );
}

# --- <base href> --------------------------------------------------------------------------------------------------

{
  my ( $site , $tmp ) = build_site(
    files => [
      { path => 'index.html' , content => '<base href="/assets/"><img src="logo.png">' } ,
      { path => 'assets/logo.png' , content => 'png' } ,
    ],
  );

  my $result = $plugin->scan( $site );

  is( $result->{checked} , 1 , 'base href: relative ref resolved against base dir' );
  is_broken( $result , 0 , 'base href: not broken' );
}

{
  my ( $site , $tmp ) = build_site(
    files => [
      { path => 'index.html' , content => '<base href="/assets/"><img src="logo.png">' } ,
    ],
  );

  my $result = $plugin->scan( $site );

  is_broken( $result , 1 , 'base href: missing file broken' );
  is( $result->{broken}[0]{resolved} , 'assets/logo.png' ,
    'base href: resolved against base dir' );
}

{
  # an external base means nothing in the file can be resolved locally
  my ( $site , $tmp ) = build_site(
    files => [
      {
        path    => 'index.html' ,
        content => '<base href="https://cdn.example.com/"><img src="logo.png">' ,
      } ,
    ],
  );

  my $result = $plugin->scan( $site );
  is( $result->{checked} , 0 , 'external base href: nothing checked' );
}

# --- inline <style> ---------------------------------------------------------------------------------------------------

{
  my ( $site , $tmp ) = build_site(
    files => [
      {
        path    => 'index.html' ,
        content => '<style>body { background: url(img/bg.png); }</style>' ,
      } ,
      { path => 'img/bg.png' , content => 'png' } ,
    ],
  );

  my $result = $plugin->scan( $site );

  is( $result->{checked} , 1 , 'inline style url(): checked' );
  is_broken( $result , 0 , 'inline style url(): not broken' );
}

# --- after_publish messages -------------------------------------------------------------------------------------------------

{
  my ( $site , $tmp ) = build_site(
    files => [ { path => 'index.html' , content => '<a href="missing.html">x</a>' } ],
  );

  $plugin->after_publish( $site );

  my @warn = grep { $_->[0] eq 'WARN' } @{ $site->messages };
  my @info = grep { $_->[0] eq 'INFO' } @{ $site->messages };

  is( scalar @warn , 1 , 'after_publish: one warning' );
  is( $warn[0][1] ,
    'brokenlink: index.html: missing.html -> missing missing.html' ,
    'after_publish: warning format' );
  is( scalar @info , 1 , 'after_publish: one info message' );
  is( $info[0][1] ,
    'brokenlink: checked 1 reference(s) in 1 file(s); 1 broken' ,
    'after_publish: summary format' );
}

# --- fail_on_broken -----------------------------------------------------------------------------------------------------------

{
  my ( $site , $tmp ) = build_site(
    files  => [ { path => 'index.html' , content => '<a href="missing.html">x</a>' } ],
    config => { brokenlink => { enabled => 1 , fail_on_broken => 1 } } ,
  );

  my $err;
  eval { $plugin->after_publish( $site ); 1 } or $err = $@;

  like( $err , qr{\Abrokenlink: 1 broken reference\(s\) found} ,
    'fail_on_broken: dies' );
}

{
  # nothing broken: no die even with fail_on_broken
  my ( $site , $tmp ) = build_site(
    files  => [
      { path => 'index.html' , content => '<a href="about.html">a</a>' } ,
      { path => 'about.html' , content => '<p>about</p>' } ,
    ],
    config => { brokenlink => { enabled => 1 , fail_on_broken => 1 } } ,
  );

  my $ok = eval { $plugin->after_publish( $site ); 1 };
  ok( $ok , 'fail_on_broken: no die when nothing is broken' );
}

# --- disabled --------------------------------------------------------------------------------------------------------------------------

{
  my ( $site , $tmp ) = build_site(
    files  => [ { path => 'index.html' , content => '<a href="missing.html">x</a>' } ],
    config => { brokenlink => { enabled => 0 } } ,
  );

  $plugin->after_publish( $site );

  is( scalar @{ $site->messages } , 0 , 'disabled: no messages' );
}

# --- report -------------------------------------------------------------------------------------------------------------------------------

{
  my $tmp = Path::Tiny->tempdir( CLEANUP => 1 );
  $tmp->child( 'index.html' )->spew( '<a href="missing.html">x</a>' );

  my $site = Test::BrokenLink::Site->new({
    destination => $tmp->stringify ,
    config      => {
      brokenlink => {
        enabled => 1 ,
        report  => $tmp->child( 'reports' , 'brokenlinks.txt' )->stringify ,
      } ,
    } ,
  });

  $plugin->after_publish( $site );

  my $report = $tmp->child( 'reports' , 'brokenlinks.txt' )->slurp;
  like( $report ,
    qr{\Abrokenlink: checked 1 reference\(s\) in 1 file\(s\); 1 broken\n} ,
    'report: summary' );
  like( $report ,
    qr{^- index\.html: missing\.html -> missing missing\.html\n\z}m ,
    'report: broken link listed' );
}

done_testing();

#! perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;
use DateTime;

use byterazor::HiD::LLMS;
use Test::LLMS::Entry;
use Test::LLMS::Site;

my $generator = byterazor::HiD::LLMS->new;

sub make_site {
  my( %args ) = @_;

  return Test::LLMS::Site->new({
    destination => $args{destination} // '_site' ,
    config      => $args{config} // {
      llms => {
        generate => 1 ,
        title    => 'Example Site' ,
        baseurl  => 'https://example.com' ,
      },
    },
    pages => $args{pages} // [] ,
    posts => $args{posts} // [] ,
  });
}

sub two_objects {
  my( $site , $name ) = @_;

  is( scalar @{ $site->objects } , 2 , "$name: two objects generated" );
  my( $llms , $full ) = @{ $site->objects };
  ok( $llms->isa('HiD::VirtualPage') , "$name: llms.txt is a HiD::VirtualPage" );
  ok( $full->isa('HiD::VirtualPage') , "$name: llms-full.txt is a HiD::VirtualPage" );

  return ( $llms , $full );
}

sub warn_count {
  my( $site ) = @_;
  return grep { $_->[0] eq 'WARN' } @{ $site->messages };
}

sub info_count {
  my( $site ) = @_;
  return grep { $_->[0] eq 'INFO' } @{ $site->messages };
}

# --- disabled -----------------------------------------------------------------

{
  my $site = make_site(
    pages  => [ Test::LLMS::Entry->new({ url => '/' }) ] ,
    config => { llms => {} } ,
  );

  $generator->generate( $site );

  is( scalar @{ $site->objects } , 0 , 'disabled: no objects generated' );
  is( scalar @{ $site->messages } , 0 , 'disabled: no messages' );
}

# --- basic generation ---------------------------------------------------------

{
  my $page = Test::LLMS::Entry->new({
    url      => '/about/' ,
    metadata => {
      title       => 'About' ,
      description => 'All about us' ,
    },
    content  => "About us\n\nWe are example." ,
  });

  my $post = Test::LLMS::Entry->new({
    url     => '/2026-01-15/hello-world/' ,
    title   => 'Hello world' ,
    date    => DateTime->new(
      year => 2026, month => 1, day => 15,
      hour => 8, minute => 30, time_zone => 'UTC' ,
    ),
    content => 'Hello, world!' ,
  });

  my $site = make_site(
    pages  => [$page] ,
    posts  => [$post] ,
    config => {
      llms => {
        generate    => 1 ,
        title       => 'Example Site' ,
        baseurl     => 'https://example.com' ,
        description => 'An example site' ,
      },
    },
  );

  my $returned = $generator->generate( $site );

  ok( $returned->isa('HiD::VirtualPage') , 'basic: returns the llms.txt page' );

  my( $llms , $full ) = two_objects( $site , 'basic' );

  is( $llms->output_filename , '_site/llms.txt' , 'basic: default llms destination' );
  is( $full->output_filename , '_site/llms-full.txt' , 'basic: default full destination' );

  like( $llms->content ,
    qr{\A# Example Site\n\n> An example site\n} ,
    'basic: title and description header' );

  like( $llms->content ,
    qr{\n## Pages\n\n- \[About\]\(https://example\.com/about/\): All about us\n} ,
    'basic: page entry with description' );

  like( $llms->content ,
    qr{\n## Posts\n\n- \[Hello world\]\(https://example\.com/2026-01-15/hello-world/\)\n} ,
    'basic: post entry (no description)' );

  like( $llms->content ,
    qr{\n## Optional\n\n- \[llms-full\.txt\]\(https://example\.com/llms-full\.txt\): Full site content for LLMs\n\z} ,
    'basic: optional full-file link' );

  like( $full->content ,
    qr{\n## About\n\nAbout us\n\nWe are example\.\n} ,
    'basic: full page content' );

  like( $full->content ,
    qr{\n## Hello world\n\nHello, world!\n} ,
    'basic: full post content' );

  is( $site->inputs->{'LLMS'} // '' , 'page' , 'basic: input registered' );

  my @infos = info_count( $site );
  is( scalar @infos , 1 , 'basic: one INFO message' );
  like( $infos[0][1] , qr{\(1 pages, 1 posts\)} , 'basic: INFO message content' );

  is( warn_count( $site ) , 0 , 'basic: no warnings' );
}

# --- derived titles -----------------------------------------------------------

{
  my $root   = Test::LLMS::Entry->new({ url => '/' });
  my $about  = Test::LLMS::Entry->new({ url => '/about/' });
  my $doc    = Test::LLMS::Entry->new({ url => '/docs/getting-started.html' });

  my $site = make_site( pages => [ $doc , $about , $root ] );
  $generator->generate( $site );

  my( $llms ) = two_objects( $site , 'derived titles' );

  like( $llms->content , qr{- \[Home\]\(https://example\.com/\)} ,
    'derived: root URL yields Home' );

  like( $llms->content , qr{- \[About\]\(https://example\.com/about/\)} ,
    'derived: trailing-slash path yields segment' );

  like( $llms->content ,
    qr{- \[Getting started\]\(https://example\.com/docs/getting-started\.html\)} ,
    'derived: extension stripped, dash turned to space' );

  # URL order, so Home < About < Getting started
  my $i_home  = index( $llms->content , '](https://example.com/)' );
  my $i_about = index( $llms->content , '](https://example.com/about/)' );
  my $i_doc   = index( $llms->content , '](https://example.com/docs/getting-started.html)' );
  cmp_ok( $i_home , '<' , $i_about , 'derived: pages in URL order (root first)' );
  cmp_ok( $i_about , '<' , $i_doc , 'derived: pages in URL order (docs last)' );
}

# --- post order ---------------------------------------------------------------

{
  my $new = Test::LLMS::Entry->new({
    url   => '/2026-06-01/new-post/' ,
    title => 'New post' ,
    date  => DateTime->new( year => 2026, month => 6, day => 1, time_zone => 'UTC' ) ,
  });

  my $old = Test::LLMS::Entry->new({
    url   => '/2025-06-01/old-post/' ,
    title => 'Old post' ,
    date  => DateTime->new( year => 2025, month => 6, day => 1, time_zone => 'UTC' ) ,
  });

  # pass older first; the generator must reorder newest-first
  my $site = make_site( posts => [ $old , $new ] );
  $generator->generate( $site );

  my( $llms ) = two_objects( $site , 'post order' );

  my $i_new = index( $llms->content , 'https://example.com/2026-06-01/new-post/' );
  my $i_old = index( $llms->content , 'https://example.com/2025-06-01/old-post/' );
  ok( $i_new >= 0 , 'post order: new post present' );
  ok( $i_old >= 0 , 'post order: old post present' );
  cmp_ok( $i_new , '<' , $i_old , 'post order: newer post listed first' );
}

# --- description flattening ---------------------------------------------------

{
  my $page = Test::LLMS::Entry->new({
    url      => '/about/' ,
    metadata => {
      title       => 'About' ,
      description => "line one\nline two" ,
    },
  });

  my $site = make_site( pages => [$page] );
  $generator->generate( $site );

  my( $llms ) = two_objects( $site , 'flatten' );

  like( $llms->content ,
    qr{- \[About\]\(https://example\.com/about/\): line one line two\n} ,
    'flatten: multi-line description collapsed to one line' );
}

# --- exclude ------------------------------------------------------------------

{
  my $keep   = Test::LLMS::Entry->new({
    url      => '/keep/' ,
    metadata => { title => 'Keep' } ,
    content  => 'kept content' ,
  });

  my $secret = Test::LLMS::Entry->new({
    url      => '/secret/stuff/' ,
    metadata => { title => 'Secret' } ,
    content  => 'secret stuff' ,
  });

  my $site = make_site(
    pages  => [ $keep , $secret ] ,
    config => {
      llms => {
        generate => 1 ,
        title    => 'Example Site' ,
        baseurl  => 'https://example.com' ,
        exclude  => [ 'secret' ] ,
      },
    },
  );

  $generator->generate( $site );

  my( $llms , $full ) = two_objects( $site , 'exclude' );

  like( $llms->content , qr{https://example\.com/keep/} , 'exclude: non-matching URL kept' );
  unlike( $llms->content , qr{secret} , 'exclude: matching URL dropped from llms.txt' );
  unlike( $full->content , qr{secret stuff} , 'exclude: matching content dropped from full file' );
  like( $full->content , qr{kept content} , 'exclude: kept content present in full file' );
}

# --- dedupe -------------------------------------------------------------------

{
  my $page = Test::LLMS::Entry->new({
    url      => '/dup/' ,
    metadata => { title => 'Dup page' } ,
  });

  my $post = Test::LLMS::Entry->new({
    url   => '/dup/' ,
    title => 'Dup post' ,
    date  => DateTime->new( year => 2026, month => 1, day => 1, time_zone => 'UTC' ) ,
  });

  my $site = make_site( pages => [$page] , posts => [$post] );
  $generator->generate( $site );

  my( $llms ) = two_objects( $site , 'dedupe' );

  my $count = () = $llms->content =~ /https:\/\/example\.com\/dup\//g;
  is( $count , 1 , 'dedupe: identical URL listed once' );
}

# --- baseurl handling ----------------------------------------------------------

{
  # falls back to the site-wide baseurl
  my $page = Test::LLMS::Entry->new({ url => '/' });
  my $site = make_site(
    pages  => [$page] ,
    config => { baseurl => 'https://site.example' , llms => { generate => 1 , title => 'X' } },
  );

  $generator->generate( $site );

  my( $llms ) = two_objects( $site , 'fallback baseurl' );
  like( $llms->content , qr{https://site\.example/} ,
    'fallback baseurl: site baseurl used' );
  is( warn_count( $site ) , 0 , 'fallback baseurl: no warning for absolute baseurl' );
}

{
  # trailing slash on the baseurl must not double up
  my $page = Test::LLMS::Entry->new({ url => '/about/' });
  my $site = make_site(
    pages  => [$page] ,
    config => {
      llms => {
        generate => 1 ,
        title    => 'X' ,
        baseurl  => 'https://example.com/' ,
      },
    },
  );

  $generator->generate( $site );

  my( $llms ) = two_objects( $site , 'trailing slash' );
  like( $llms->content , qr{https://example\.com/about/} ,
    'trailing slash: not doubled' );
}

{
  # non-absolute baseurl still works but warns
  my $page = Test::LLMS::Entry->new({ url => '/about/' });
  my $site = make_site(
    pages  => [$page] ,
    config => {
      llms => {
        generate => 1 ,
        title    => 'X' ,
        baseurl  => '/' ,
      },
    },
  );

  $generator->generate( $site );

  my( $llms ) = two_objects( $site , 'relative baseurl' );
  like( $llms->content , qr{\]\(/about/\)} ,
    'relative baseurl: no double slash' );
  is( warn_count( $site ) , 1 , 'relative baseurl: warning emitted' );
}

# --- title fallback ------------------------------------------------------------

{
  # site-level title used when llms.title is absent
  my $site = make_site(
    config => {
      title => 'Site Title' ,
      llms  => { generate => 1 , baseurl => 'https://example.com' } ,
    },
  );

  $generator->generate( $site );

  my( $llms ) = two_objects( $site , 'title fallback' );
  like( $llms->content , qr{\A# Site Title\n} , 'title fallback: site title used' );
  is( warn_count( $site ) , 0 , 'title fallback: no warning' );
}

{
  # no title anywhere -> placeholder + warning
  my $site = make_site(
    config => {
      llms => { generate => 1 , baseurl => 'https://example.com' } ,
    },
  );

  $generator->generate( $site );

  my( $llms ) = two_objects( $site , 'no title' );
  like( $llms->content , qr{\A# Untitled\n} , 'no title: placeholder used' );
  is( warn_count( $site ) , 1 , 'no title: warning emitted' );
}

# --- site description ----------------------------------------------------------

{
  # site-level description used when llms.description is absent
  my $site = make_site(
    config => {
      description => 'Site description' ,
      llms        => {
        generate => 1 ,
        title    => 'X' ,
        baseurl  => 'https://example.com' ,
      },
    },
  );

  $generator->generate( $site );

  my( $llms ) = two_objects( $site , 'site description' );
  like( $llms->content , qr{\n> Site description\n} ,
    'site description: emitted as blockquote' );
}

# --- full disabled -------------------------------------------------------------

{
  my $page = Test::LLMS::Entry->new({
    url      => '/about/' ,
    metadata => { title => 'About' } ,
  });

  my $site = make_site(
    pages  => [$page] ,
    config => {
      llms => {
        generate => 1 ,
        title    => 'X' ,
        baseurl  => 'https://example.com' ,
        full     => 0 ,
      },
    },
  );

  $generator->generate( $site );

  is( scalar @{ $site->objects } , 1 , 'full disabled: one object generated' );
  my $llms = $site->objects->[0];
  ok( $llms->isa('HiD::VirtualPage') , 'full disabled: object is a HiD::VirtualPage' );
  unlike( $llms->content , qr{llms-full} , 'full disabled: no full-file link' );
}

# --- custom destinations -------------------------------------------------------

{
  my $page = Test::LLMS::Entry->new({
    url      => '/about/' ,
    metadata => { title => 'About' } ,
  });

  my $site = make_site(
    pages  => [$page] ,
    config => {
      llms => {
        generate         => 1 ,
        title            => 'X' ,
        baseurl          => 'https://example.com' ,
        destination      => 'search/llms.txt' ,
        full_destination => 'search/llms-full.txt' ,
      },
    },
  );

  $generator->generate( $site );

  my( $llms , $full ) = two_objects( $site , 'custom destinations' );
  is( $llms->output_filename , '_site/search/llms.txt' ,
    'custom destinations: llms destination' );
  is( $full->output_filename , '_site/search/llms-full.txt' ,
    'custom destinations: full destination' );
  like( $llms->content ,
    qr{\[llms-full\.txt\]\(https://example\.com/search/llms-full\.txt\)} ,
    'custom destinations: optional link uses full destination' );
}

# --- empty site -----------------------------------------------------------------

{
  my $site = make_site();
  $generator->generate( $site );

  my( $llms , $full ) = two_objects( $site , 'empty site' );

  is( $llms->content ,
    qq{# Example Site\n}
    . qq{\n## Optional\n\n}
    . qq{- [llms-full.txt](https://example.com/llms-full.txt): Full site content for LLMs\n} ,
    'empty site: header + optional section only' );

  is( $full->content , qq{# Example Site\n} ,
    'empty site: full file is title only' );
}

# --- escaping -------------------------------------------------------------------

{
  my $page = Test::LLMS::Entry->new({
    url      => '/faq/' ,
    metadata => { title => 'What is [X]?' } ,
    content  => 'A page with a tricky title.' ,
  });

  my $site = make_site( pages => [$page] );
  $generator->generate( $site );

  my( $llms ) = two_objects( $site , 'escaping' );

  like( $llms->content ,
    qr{- \[What is \\\[X\\\]\?\]\(https://example\.com/faq/\)\n} ,
    'escaping: brackets and backslashes escaped in link text' );
}

done_testing();

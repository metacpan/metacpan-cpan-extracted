#!/usr/bin/env perl

use strict;
use warnings;

BEGIN{
  $ENV{MOJO_NO_IPV6} = $ENV{MOJO_POLL} = 1 ;
  $ENV{MOJO_APP} = undef; # 
}
use Test::More tests => 3;
use Test::Mojo;

use Mojolicious::Lite;
plugin 'page_navigator';
get( "paginator" => sub(){
    my $self = shift;
    $self->render( text => $self->page_navigator( 10, 15 ) . "\n" );
  } );


my $t = Test::Mojo->new(  );
$t->get_ok( "/paginator" )
  ->status_is( 200 )
  ->content_is(<<EOF);
<div><a href="/paginator?page=9" class="number">&lt;&lt;</a><a href="/paginator?page=1" class="number">1</a><a href="/paginator?page=2" class="number">2</a><span class="number">..</span><a href="/paginator?page=6" class="number">6</a><a href="/paginator?page=7" class="number">7</a><a href="/paginator?page=8" class="number">8</a><a href="/paginator?page=9" class="number">9</a><span class="number">10</span><a href="/paginator?page=11" class="number">11</a><a href="/paginator?page=12" class="number">12</a><a href="/paginator?page=13" class="number">13</a><a href="/paginator?page=14" class="number">14</a><a href="/paginator?page=15" class="number">15</a><a href="/paginator?page=11" class="number">&gt;&gt;</a><span style="clear: left; width: 1px;">&nbsp;</span></div>
EOF


1;

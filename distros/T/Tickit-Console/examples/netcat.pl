#!/usr/bin/perl

use strict;
use warnings;
use 5.010;

use Tickit::Async;
use Tickit::Console;

use String::Tagged;

use IO::Async::Loop;

my $loop = IO::Async::Loop->new;

my $host    = shift @ARGV or die "Need a HOST";
my $service = shift @ARGV or die "Need a SERVICE";

my $stream;
$loop->connect(
   host     => $host,
   service  => $service,
   socktype => 'stream',
   on_stream => sub {
      ( $stream ) = @_;
   },

   on_connect_error => sub { die "Cannot connect - $_[-1]\n" },
   on_resolve_error => sub { die "Cannot resolve - $_[-1]\n" },
);

$loop->loop_once until $stream;

my $tab;
$stream->configure(
   on_read => sub {
      my ( $self, $buffref, $eof ) = @_;

      while( $$buffref =~ s/^(.*?)\r?\n// ) {
         my $line = $1;

         # Render CTRL characters as reverse-video capitals
         ( my $linetext = $line ) =~ s{([\x00-\x1f])}{chr 64 + ord $1}eg;

         my $str = String::Tagged->new( "<- $linetext" );
         $str->apply_tag( 0, 2, fg => 'green' );
         $str->apply_tag( 3 + $-[0], 1, rv => 1 ) while $line =~ m{[\x00-\x1f]}g;

         $tab->add_line( $str );
      }

      if( $eof ) {
         # TODO: partial
         my $str = String::Tagged->new( "EOF" );
         $str->apply_tag( 0, 3, fg => 'green' );
         $tab->add_line( $str );
      }

      return 0;
   },
);

$loop->add( $stream );

my $console = Tickit::Console->new(
   on_line => sub {
      my ( $self, $line ) = @_;

      if( $line =~ s{^/([a-z]+)}{}i ) {
         my $cmd = lc $1;
         given( $cmd ) {
            when( "lf" ) {
               my $str = String::Tagged->new( "-> LF" );
               $str->apply_tag( 0, 5, fg => 'red' );
               $tab->add_line( $str );

               $stream->write( "\r\n" );
            }
            when( "quit" ) {
               $loop->stop;
            }
         }
      }
      else {
         my $str = String::Tagged->new( "-> $line" );
         $str->apply_tag( 0, 2, fg => 'red' );
         $tab->add_line( $str );

         $stream->write( "$line\r\n" );
      }
   },
);

$tab = $console->add_tab(
   name => "netcat",
   timestamp_format => "[%H:%M:%S] ",
);

$loop->resolver->getnameinfo(
   addr => $stream->read_handle->peername,

   on_resolved => sub {
      my ( $rev_host, $rev_service ) = @_;
      my $str = String::Tagged->new( "Connected to $rev_host:$rev_service" );
      $str->apply_tag( -1, -1, fg => 'blue' );
      $tab->add_line( $str );
   },
   on_error => sub {
      my $str = String::Tagged->new( "Connected to $host:$service [reverse unknown]" );
      $str->apply_tag( -1, -1, fg => 'blue' );
      $tab->add_line( $str );
   },
);

my $tickit = Tickit::Async->new;
$loop->add( $tickit );

$tickit->set_root_widget( $console );

$tickit->run;

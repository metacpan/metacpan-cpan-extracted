#!/usr/bin/perl

use v5.26;
use warnings;

use Test::More;

use Tickit::Test;

use Tickit::Widget::Term;

use IO::Pty 1.12;

my $tickit = mk_tickit;
my $root = mk_window;

my $widget = Tickit::Widget::Term->new;

ok( defined $widget, 'defined $widget' );

$widget->set_window( $root );
flush_tickit;

my $pty = IO::Pty->new or plan skip_all => "Unable to create a PTY";

$widget->use_pty( $pty );

my $pts = $pty->slave;
$pts->set_raw;

# App->Term to PTY
{
   $pts->syswrite( "Hello \e[1mWorld\e[m!" );
   $tickit->tick;
   flush_tickit;

   is_display( [ [TEXT("Hello "), TEXT("World",b=>1), TEXT("!"), BLANK(68)] ],
      'Display after write via PTY' );
}

# Term->App from PTY
{
   presskey text => "1";
   presskey text => "2";
   presskey text => "3";
   presskey key => "Down";

   my $buf = "";
   $pts->sysread( $buf, 128, length $buf ) while length $buf < 6;
   is( $buf, "123\e[B", 'Keypresses written to PTY' );
}

done_testing;

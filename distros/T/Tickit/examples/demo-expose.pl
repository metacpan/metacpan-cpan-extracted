#!/usr/bin/perl

use v5.14;
use warnings;

use Tickit;
use Tickit::Rect;
use List::Util qw( min max );

my $fillchar = "1";
sub fillwin
{
   my ( $win, undef, $info ) = @_;

   my $rb   = $info->rb;
   my $rect = $info->rect;

   foreach my $line ( $rect->linerange ) {
      $rb->text_at( $line, $rect->left, $fillchar x $rect->cols );
   }
}

my $tickit = Tickit->new();

foreach ( 1 .. 9 ) {
   my $key = $_;
   $tickit->bind_key( $key => sub { $fillchar = $key } );
}

my $rootwin = $tickit->rootwin;

my @start;
$rootwin->bind_event( mouse => sub {
   my ( $self, undef, $info ) = @_;
   @start = ( $info->line, $info->col ) and return if $info->type eq "press";

   return unless $info->type eq "release";

   my $top  = min( $start[0], $info->line );
   my $left = min( $start[1], $info->col );

   my $bottom = max( $start[0], $info->line ) + 1;
   my $right  = max( $start[1], $info->col )  + 1;

   $rootwin->expose( Tickit::Rect->new(
      top   => $top,
      left  => $left,
      bottom => $bottom,
      right  => $right,
   ) );
});

my $win = $rootwin->make_sub( 5, 10, 15, 60 );
$win->pen->chattr( fg => 1 );
$win->bind_event( expose => \&fillwin );

my @subwins;

push @subwins, $win->make_sub( 0, 0, 4, 4 );
$subwins[-1]->pen->chattr( fg => 2 );
$subwins[-1]->bind_event( expose => \&fillwin );

push @subwins, $win->make_sub( 6, 40, 2, 15 );
$subwins[-1]->pen->chattr( fg => 3 );
$subwins[-1]->bind_event( expose => \&fillwin );

$tickit->watch_later( sub {
      $rootwin->expose;
} );

$tickit->run;

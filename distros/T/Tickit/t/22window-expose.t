#!/usr/bin/perl

use v5.14;
use warnings;

use Test::More;

use Tickit::Test;

my ( $term, $rootwin ) = mk_term_and_window;

my $win = $rootwin->make_sub( 3, 10, 4, 20 );

my $root_exposed;
$rootwin->bind_event( expose => sub { $root_exposed++ } );

# New RB+rect callback
{
   my $win_exposed;

   my $exposed_rb;
   my @exposed_rects;
   my $expose_cb;
   my $bind_id = $win->bind_event( expose => sub {
      my ( $win, undef, $info ) = @_;
      $exposed_rb = $info->rb;
      push @exposed_rects, $info->rect;
      $win_exposed++;
      $expose_cb->( $exposed_rb, $info->rect ) if $expose_cb;
   });

   $rootwin->expose;

   ok( !$win_exposed, 'on_expose not yet invoked' );

   flush_tickit;

   is( $root_exposed, 1, '$root expose count 1 after $rootwin->expose' );
   is( $win_exposed,  1, '$win expose count 1 after $rootwin->expose' );

   isa_ok( $exposed_rb, "Tickit::RenderBuffer", '$exposed_rb' );

   is_deeply( \@exposed_rects,
      [ Tickit::Rect->new( top => 0, left => 0, lines => 4, cols => 20 ) ],
      'Exposed regions after $rootwin->expose'
   );

   undef @exposed_rects;

   $win->expose;

   flush_tickit;

   is( $root_exposed, 2, '$root expose count 2 after $win->expose' );
   is( $win_exposed, 2, '$win expose count 2 after $win->expose' );

   is_deeply( \@exposed_rects,
      [ Tickit::Rect->new( top => 0, left => 0, lines => 4, cols => 20 ) ],
      'Exposed regions after $win->expose'
   );

   undef @exposed_rects;

   $rootwin->expose;
   $win->expose;

   flush_tickit;

   is( $root_exposed, 3, '$root expose count 3 after root-then-win' );
   is( $win_exposed, 3, '$win expose count 3 after root-then-win' );

   $win->expose;
   $rootwin->expose;

   flush_tickit;

   is( $root_exposed, 4, '$root expose count 4 after win-then-root' );
   is( $win_exposed, 4, '$win expose count 4 after win-then-root' );

   $win->hide;

   flush_tickit;

   is( $root_exposed, 5, '$root expose count 5 after $win hide' );
   is( $win_exposed, 4, '$win expose count 5 after $win hide' );

   $win->expose;

   flush_tickit;

   is( $root_exposed, 5, '$root expose count 5 after expose on hidden' );
   is( $win_exposed, 4, '$win expose count 5 after expose on hidden' );

   $win->show;

   flush_tickit;

   is( $root_exposed, 6, '$root expose count 6 after $win show' );
   is( $win_exposed, 5, '$win expose count 5 after $win show' );

   undef @exposed_rects;

   $win->expose( Tickit::Rect->new( top => 0, left => 0, lines => 1, cols => 20 ) );
   $win->expose( Tickit::Rect->new( top => 2, left => 0, lines => 1, cols => 20 ) );

   flush_tickit;

   is( $win_exposed, 7, '$win expose count 7 after expose two regions' );

   is_deeply( \@exposed_rects,
      [ Tickit::Rect->new( top => 0, left => 0, lines => 1, cols => 20 ),
        Tickit::Rect->new( top => 2, left => 0, lines => 1, cols => 20 ) ],
      'Exposed regions after expose two regions'
   );

   undef @exposed_rects;

   $rootwin->expose( Tickit::Rect->new( top => 0, left => 0, lines => 1, cols => 20 ) );
   $win->expose( Tickit::Rect->new( top => 0, left => 5, lines => 1, cols => 10 ) );

   flush_tickit;

   is( $win_exposed, 8, '$win expose count 8 after expose separate root+win' );

   is_deeply( \@exposed_rects,
      [ Tickit::Rect->new( top => 0, left => 5, lines => 1, cols => 10 ) ],
      'Exposed regions after expose separate root+win'
   );

   undef @exposed_rects;

   $win->expose( Tickit::Rect->new( top => -2, left => -2, lines => 50, cols => 200 ) );

   flush_tickit;

   is_deeply( \@exposed_rects,
      [ Tickit::Rect->new( top => 0, left => 0, lines => 4, cols => 20 ) ],
      'Exposed regions clipped by window extent'
   );

   $expose_cb = sub {
      my ( $rb, $rect ) = @_;

      $rb->text_at( 1, 1, "The text" );
      $rb->erase_at( 2, 2, 4 );
   };

   $win->expose;
   flush_tickit;

   is_termlog( [ GOTO(4,11),
                 SETPEN,
                 PRINT("The text"),
                 GOTO(5,12),
                 SETPEN,
                 ERASECH(4,0) ],
               'Termlog after Window expose with output' );

   is_display( [ BLANKLINES(4),
                 [BLANK(11), TEXT("The text")] ],
               'Display after Window expose with output' );

   $expose_cb = sub {
      my ( $rb, $rect ) = @_;
      $rb->text_at( $_, 0, "Line $_" ) for $rect->linerange;
   };

   $win->expose( Tickit::Rect->new( top => 0, left => 0, lines => 1, cols => $win->cols ) );
   $win->expose( Tickit::Rect->new( top => 2, left => 0, lines => 1, cols => $win->cols ) );
   flush_tickit;

   is_termlog( [ GOTO(3,10),
                 SETPEN,
                 PRINT("Line 0"),
                 GOTO(5,10),
                 SETPEN,
                 PRINT("Line 2") ],
               'Termlog after Window expose twice' );

   $win->pen->chattr( fg => 5 );
   $win->expose;
   flush_tickit;

   is_termlog( [
                  map { GOTO(3+$_,10), SETPEN(fg=>5), PRINT("Line $_") } 0 .. 3,
               ],
               'Termlog after Window expose with pen attrs' );

   $win->pen->chattr( fg => undef );
   $win->unbind_event_id( $bind_id );
   clear_term;
   flush_tickit;
}

# New windows get exposed immediately
{
   my @exposed;
   my $bind_id = $win->bind_event( expose => sub {
      push @exposed, $_[2]->rect;
   });

   my $subwin = $win->make_sub( 1, 4, 3, 6 );

   my $exposed;
   $subwin->bind_event( expose => sub { $exposed++ } );

   flush_tickit;

   ok( $exposed, 'New child window is immediately exposed' );
   is_deeply( \@exposed,
      [ Tickit::Rect->new( top => 1, left => 4, lines => 3, cols => 6 ) ],
      'exposed areas after child created' );

   undef @exposed;

   $subwin->close;
   flush_tickit;

   is_deeply( \@exposed,
      [ Tickit::Rect->new( top => 1, left => 4, lines => 3, cols => 6 ) ],
      'exposed areas after child destroyed' );

   $win->unbind_event_id( $bind_id );
}

{
   my $bind_id = $win->bind_event( expose => sub {
      my ( $win, undef, $info ) = @_;
      $info->rb->text_at( 0,  0, "Parent" );
      $info->rb->text_at( 0, 14, "Parent" );
   });

   $win->expose( Tickit::Rect->new( top => 0, left => 0, lines => 1, cols => 20 ) );

   my $subwin = $win->make_sub( 0, 7, 1, 7 );
   $subwin->bind_event( expose => sub {
      my ( $win, undef, $info ) = @_;
      $info->rb->text_at( 0, 0, "Child" );
   });

   flush_tickit;

   is_display( [ BLANKLINES(3),
                 [BLANK(10), TEXT("Parent Child  Parent")] ],
               'Display after simultaneous bind_event expose on parent + child' );

   $win->unbind_event_id( $bind_id );
   $subwin->close;
   flush_tickit;

   clear_term;
   flush_tickit;
   drain_termlog;
}

{
   my $subwin = $rootwin->make_sub( 2, 2, 20, 50 );

   my $exposed = 0;
   $subwin->bind_event( expose => sub { $exposed++ } );

   for ( 1 .. 100 ) {
      $subwin->expose( Tickit::Rect->new( top => 1, left => 1, lines => 3, cols => 20 ) );
      flush_tickit;
   }

   is( $exposed, 100, '$exposed 100 times' );

   $subwin->close;
   flush_tickit;
   drain_termlog;
}

# parent + child ordering
{
   my $bind_id = $win->bind_event( expose => sub {
      my ( $win, undef, $info ) = @_;
      my $rect = $info->rect;
      $info->rb->text_at( $_, $rect->left, "X" x $rect->cols ) for $rect->linerange;
   });

   my $subwin = $win->make_sub( 0, 5, 1, 10 );
   # No on_expose

   $win->expose( Tickit::Rect->new( top => 0, left => 0, lines => 1, cols => 80 ) );
   flush_tickit;

   is_termlog( [ GOTO(3,10),
                 SETPEN(),
                 PRINT("XXXXX"),
                 GOTO(3,25),
                 SETPEN(),
                 PRINT("XXXXX") ],
               'Termlog after expose parent with visible child' );

   is_display( [ BLANKLINES(3),
                 [BLANK(10), TEXT("XXXXX"), BLANK(10), TEXT("XXXXX")] ],
               'Display after expose parent with visible child' );

   $win->unbind_event_id( $bind_id );
   $subwin->close;
   flush_tickit;
}

$win->close; undef $win;
flush_tickit;
drain_termlog;

# Window ordering
{
   my $win_A = $rootwin->make_sub( 0, 0, 4, 80 );
   my $win_B = $rootwin->make_sub( 0, 0, 4, 80 );
   my $win_C = $rootwin->make_sub( 0, 0, 4, 80 );
   flush_tickit;

   $win_A->bind_event( expose => sub {
      my ( $win, undef, $info ) = @_;
      $info->rb->text_at( 0, 0, "Window A" );
   });

   $win_B->bind_event( expose => sub {
      my ( $win, undef, $info ) = @_;
      $info->rb->text_at( 0, 0, "Window B" );
   });

   $win_C->bind_event( expose => sub {
      my ( $win, undef, $info ) = @_;
      $info->rb->text_at( 0, 0, "Window C" );
   });

   $rootwin->expose;
   flush_tickit;

   is_termlog( [ GOTO(0,0),
                 SETPEN,
                 PRINT("Window A") ],
                 'Termlog for overlapping initially' );

   $win_B->raise;
   flush_tickit;

   is_termlog( [ GOTO(0,0),
                 SETPEN,
                 PRINT("Window B") ],
                 'Termlog for overlapping after $win_B->raise' );

   $win_B->lower;
   flush_tickit;

   is_termlog( [ GOTO(0,0),
                 SETPEN,
                 PRINT("Window A") ],
                 'Termlog for overlapping after $win_B->lower' );

   $win_C->raise_to_front;
   flush_tickit;

   is_termlog( [ GOTO(0,0),
                 SETPEN,
                 PRINT("Window C") ],
                 'Termlog for overlapping after $win_C->raise_to_front' );

   $win_A->close;
   $win_B->close;
   $win_C->close;
}

done_testing;

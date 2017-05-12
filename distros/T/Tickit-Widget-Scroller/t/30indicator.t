#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Tickit::Test;

use Tickit::Widget::Scroller;
use Tickit::Widget::Scroller::Item::Text;
# These tests depend on the new Window rendering behaviour added in Tickit 0.43
# but the actual functionallity will work fine before that
eval { require Tickit::Window; Tickit::Window->VERSION( '0.43' ) }
   or plan skip_all => "Tickit::Window older than 0.43; these tests won't work";

my $win = mk_window;

my $scroller = Tickit::Widget::Scroller->new(
   gen_top_indicator => sub {
      my $self = shift;
      # TODO: This is a fragile API, needs fixing
      return sprintf "-- Start{%d/%d} items{%d} --",
         $self->{start_item}, $self->{start_partial}, scalar @{ $self->{items} };
   },
);

$scroller->push(
   map { Tickit::Widget::Scroller::Item::Text->new( "Line $_ of content" ) } 1 .. 50
);

$scroller->set_window( $win );
flush_tickit;

# At Tickit::Window 0.44, rendering is done in one go.
if( $Tickit::Window::VERSION >= '0.44' ) {
   is_termlog( [ GOTO(0,0),
                 SETPEN,
                 PRINT("Line 1 of content"),
                 SETBG(undef),
                 ERASECH(37,1),
                 SETPEN(rv=>1),
                 PRINT("-- Start{0/0} items{50} --"),

                 ( map { GOTO($_-1,0),
                         SETPEN,
                         PRINT("Line $_ of content"),
                         SETBG(undef),
                         ERASECH(64-length $_), } 2 .. 25 ) ],
               'Termlog initially' );
}
else {
   is_termlog( [ GOTO(0,0),
                 SETPEN,
                 PRINT("Line 1 of content"),
                 SETBG(undef),
                 ERASECH(37),
                 ( map { GOTO($_-1,0),
                         SETPEN,
                         PRINT("Line $_ of content"),
                         SETBG(undef),
                         ERASECH(64-length $_), } 2 .. 25 ),
                 GOTO(0,54),
                 SETPEN(rv=>1),
                 PRINT("-- Start{0/0} items{50} --") ],
               'Termlog initially' );
}

is_display( [ [TEXT("Line 1 of content" . (" "x37)), TEXT("-- Start{0/0} items{50} --",rv=>1) ],
              map { "Line $_ of content" } 2 .. 25 ],
            'Display initially' );

$scroller->scroll( 2 );
flush_tickit;

if( $Tickit::Window::VERSION >= '0.44' ) {
   is_termlog( [ SETPEN,
                 SCROLLRECT(1,0,24,80,2,0),
                 GOTO(0,0),
                 SETPEN,
                 PRINT("Line 3 of content"),
                 SETBG(undef),
                 ERASECH(37,1),
                 SETPEN(rv=>1),
                 PRINT("-- Start{2/0} items{50} --"),
                 ( map { GOTO($_-3,0),
                         SETPEN,
                         PRINT("Line $_ of content"),
                         SETBG(undef),
                         ERASECH(64-length $_), } 26 .. 27 ) ],
               'Termlog after ->scroll' );
}
else {
   is_termlog( [ SETPEN,
                 SCROLLRECT(1,0,24,80,2,0),
                 GOTO(0,0),
                 SETPEN,
                 PRINT("Line 3 of content"),
                 SETBG(undef),
                 ERASECH(37),
                 GOTO(0,54),
                 SETPEN(rv=>1),
                 PRINT("-- Start{2/0} items{50} --"),
                 ( map { GOTO($_-3,0),
                         SETPEN,
                         PRINT("Line $_ of content"),
                         SETBG(undef),
                         ERASECH(64-length $_), } 26 .. 27 ) ],
               'Termlog after ->scroll' );
}

is_display( [ [TEXT("Line 3 of content" . (" "x37)), TEXT("-- Start{2/0} items{50} --",rv=>1) ],
              map { "Line $_ of content" } 4 .. 27 ],
            'Display after ->scroll' );

$scroller->set_gen_top_indicator( undef );
flush_tickit;

is_termlog( [ GOTO(0,54),
              SETPEN,
              ERASECH(26) ],
            'Termlog after removing top indicator' );

is_display( [ map { "Line $_ of content" } 3 .. 27 ],
            'Display after removing top indicator' );

$scroller->set_gen_bottom_indicator( sub {
   my $self = shift;
   defined $self->item2line( -1, -1 ) ? undef : "-- more --" 
} );

flush_tickit;

is_termlog( [ GOTO(24,70),
              SETPEN(rv=>1),
              PRINT("-- more --") ],
            'Termlog after setting bottom indicator' );

is_display( [ ( map { "Line $_ of content" } 3 .. 26 ),
              [TEXT("Line 27 of content" . (" "x52)), TEXT("-- more --",rv=>1) ] ],
            'Display after setting bottom indicator' );

done_testing;

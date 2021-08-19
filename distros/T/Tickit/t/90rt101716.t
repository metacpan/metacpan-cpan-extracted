use v5.14;
use warnings;

use Test::More;
use Test::Fatal;
use Tickit::Window;
use Tickit::Test;

my ( $term, $win ) = mk_term_and_window;
my $float = $win->make_float( 2, 2, 3, 3 );

$float->bind_event( expose => sub {
   my ( $win, undef, $info ) = @_;
   my $rb = $info->rb;

   $rb->clear;

   my $ch = ord 'x';
   $rb->char_at(0, 0, $ch);

   is( exception {
      $rb->get_cell(300, 300)->char
   }, undef, 'can request position outside renderbuffer');
});

$win->expose;
flush_tickit;

done_testing;

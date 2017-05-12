use warnings;
use strict;

use Test::More tests => 1;

use Text::xSV::Slurp;

my @tests =
   (

   {
   
   id => 'aoa - colon sep_char',

   in => <<EOIN,
a:b:c
1:2:3
4:5:6
EOIN

   exp => 
      [ [4,5,6] ],
      
   opts =>
      {
      shape    => 'aoa',
      row_grep => sub { grep /5/, @{ shift() } },
      text_csv => { sep_char => ':' },
      },

   },

   );

for my $test ( @tests )
   {
   my $got = xsv_slurp( $test->{'in'}, %{ $test->{'opts'} } );
   my $exp = $test->{'exp'};
   my $id  = $test->{'id'};
   is_deeply($got, $exp, $id);
   }

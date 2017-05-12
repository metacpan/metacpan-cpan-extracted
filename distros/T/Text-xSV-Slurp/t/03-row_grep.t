use warnings;
use strict;

use Test::More tests => 4;

use Text::xSV::Slurp;

my @tests =
   (

   {
   
   id => 'aoa',

   in => <<EOIN,
a,b,c
1,2,3
4,5,6
EOIN

   exp => 
      [ [4,5,6] ],
      
   opts =>
      {
      shape    => 'aoa',
      row_grep => sub { grep /5/, @{ shift() } },
      },

   },

   {
   
   id => 'aoh',

   in => <<EOIN,
a,b,c
1,2,3
4,5,6
EOIN

   exp => 
      [
      { a => 4, b => 5, c => 6 },
      ],
      
   opts =>
      {
      shape    => 'aoh',
      row_grep => sub { shift()->{'b'} =~ /5/ },
      },

   },

   {
   
   id => 'hoa',

   in => <<EOIN,
a,b,c
1,2,3
4,5,6
EOIN

   exp => 
      {
      a => [ 4 ],
      b => [ 5 ],
      c => [ 6 ],
      },
      
   opts =>
      {
      shape    => 'hoa',
      row_grep => sub { shift()->{'b'} =~ /5/ },
      },

   },

   {
   
   id => 'hoh',

   in => <<EOIN,
a,b,c,d
1,2,3,7
4,5,6,8
EOIN

   exp => 
      {
      5 => { 6 => { a => 4, d => 8 } },
      },
      
   opts =>
      {
      shape    => 'hoh',
      row_grep => sub { shift()->{'b'} =~ /5/ },
      key      => 'b,c',
      },

   },

   );

for my $test ( @tests )
   {
   my $got = xsv_slurp( string => $test->{'in'}, %{ $test->{'opts'} } );
   my $exp = $test->{'exp'};
   my $id  = $test->{'id'};
   is_deeply($got, $exp, $id);
   }

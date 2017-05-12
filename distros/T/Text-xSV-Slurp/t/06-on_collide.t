use warnings;
use strict;

use Test::More tests => 13;

use Text::xSV::Slurp;

my @tests =
   (

   {
   
   id => 'push collide',

   in => <<EOIN,
a,b,c
1,2,3
1,4,3
1,2,5
EOIN

   exp => 
      {
      1 => { 3 => { b => [2,4] }, 5 => { b => 2 } },
      },
      
   opts =>
      { shape => 'hoh', key => 'a,c', on_collide => 'push' },

   },

   {
   
   id => 'unshift collide',

   in => <<EOIN,
a,b,c
1,2,3
1,4,3
1,2,5
EOIN

   exp => 
      {
      1 => { 3 => { b => [4,2] }, 5 => { b => 2 } },
      },
      
   opts =>
      { shape => 'hoh', key => 'a,c', on_collide => 'unshift' },

   },

   {
   
   id => 'sum collide',

   in => <<EOIN,
a,b,c
1,2,3
1,2,3
1,4,5
EOIN

   exp => 
      {
      1 => { 3 => { b => 4 }, 5 => { b => 4 } },
      },
      
   opts =>
      { shape => 'hoh', key => 'a,c', on_collide => 'sum' },

   },

   {
   
   id => 'average collide',

   in => <<EOIN,
a,b,c
1,2,3
1,2,3
1,2,3
1,2,3
1,7,3
1,8,5
EOIN

   exp => 
      {
      1 => { 3 => { b => 3 }, 5 => { b => 8 } },
      },
      
   opts =>
      { shape => 'hoh', key => 'a,c', on_collide => 'average' },

   },
   
   {
   
   id => 'by key - all',

   in => <<EOIN,
a,b,sum,average,push,unshift
1,2,3,3,2,3
1,4,3,1,2,3
1,2,5,5,3,4
EOIN

   exp => 
      {
      1 => {
         2 => {
            sum     => 8,
            average => 4,
            push    => [ 2, 3 ],
            unshift => [ 4, 3 ],
              },
         4 => {
            sum     => 3,
            average => 1,
            push    => 2,
            unshift => 3,
              },
           },
      },
      
   opts =>
      { shape => 'hoh', key => 'a,b', on_collide => { map { $_ => $_ } qw/ sum average push unshift / } },

   },

   );

for my $test ( @tests )
   {
   my $got = xsv_slurp( string => $test->{'in'}, %{ $test->{'opts'} } );
   my $exp = $test->{'exp'};
   my $id  = $test->{'id'};
   is_deeply($got, $exp, $id);
   }

my $got = eval { xsv_slurp( string => "a,b\n1,1\n1,1\n", shape => 'hoh', key => 'a', on_collide => 'die' ) };

my $err = $@;

like( $err, qr/\AError: key collision in HoH construction \(key-value path was: { 'a' => '1' }\)/, 'die collide' );

ok( ! $got, 'die collide - return' );

$got = eval { xsv_slurp( string => "a,b\n1,1\n", shape => 'hoh', key => 'a', on_collide => 'die' ) };

$err = $@;

ok( ! $err, 'die collide - no collision' );

is_deeply($got, { 1 => { b => 1 } }, 'die collide - no collision return');

{

   my $warning;

   local $SIG{__WARN__} = sub { ($warning) = @_ };
   
   my $got = xsv_slurp( string => "a,b\n1,1\n1,1\n", shape => 'hoh', key => 'a', on_collide => 'warn' );
   
   like( $warning, qr/\AWarning: key collision in HoH construction \(key-value path was: { 'a' => '1' }\)/, 'warn collide' );
   
   is_deeply($got, { 1 => { b => 1 } }, 'warn collide - return');
   
   undef $warning;
   
   $got = xsv_slurp( string => "a,b\n1,1\n", shape => 'hoh', key => 'a', on_collide => 'warn' );

   ok( ! $warning, 'warn collide - no collision' );
   
   is_deeply($got, { 1 => { b => 1 } }, 'warn collide - no collision return');

}


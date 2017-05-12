use warnings;
use strict;

use Test::More tests => 20;

use Text::xSV::Slurp;

my %tests =
   (

   empty        => [ [],
                     q(Error: no source given) ],

   useless      => [ [ potato => "a\n1\n" ],
                     q(Error: no source given) ],

   no_file      => [ [ file => 'does_not_exist.csv' ],
                     q(Error: could not open 'does_not_exist.csv':) ],

   bad_shape    => [ [ string => "a\n1\n", shape => "asdf" ],
                     q(Error: unrecognized shape given (asdf)) ],

   no_hoh_key   => [ [ string => "a\n1\n", shape => "hoh" ],
                     q(Error: no key given for hoh shape) ],

   bad_col_grep => [ [ string => "a\n1\n", shape => "hoh", key => 'a', col_grep => 1 ],
                    q(Error: col_grep must be a CODE ref) ],

   bad_row_grep => [ [ string => "a\n1\n", shape => "hoh", key => 'a', row_grep => 1 ],
                    q(Error: row_grep must be a CODE ref) ],

   bad_store    => [ [ string => "a\n1\n", shape => "hoh", key => 'a', on_store => 1 ],
                    q(Error: invalid 'on_store' handler given (1)) ],

   bad_collide  => [ [ string => "a\n1\n", shape => "hoh", key => 'a', on_collide => 1 ],
                    q(Error: invalid 'on_collide' handler given (1)) ],

   two_handler  => [ [ string => "a\n1\n", shape => "hoh", key => 'a', on_collide => { a => 'sum'}, on_store => { a => 'count' } ],
                    q(Error: cannot set multiple storage handlers for 'a') ],

   );

for my $name ( keys %tests )
   {
   
   my $t = $tests{$name};
   
   eval { xsv_slurp( @{ $t->[0] } ) };
   
   my $error = $@;
   
   ok( $error, "$name - failed" );
   like( $error, qr/\A\Q$t->[1]/, "$name - matched" );
   
   }
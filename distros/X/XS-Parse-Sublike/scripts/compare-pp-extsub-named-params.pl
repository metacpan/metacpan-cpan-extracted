#!/usr/bin/perl

use v5.26;
use warnings;

use experimental 'signatures';
use Sublike::Extended;

use Time::HiRes qw( gettimeofday tv_interval );
sub measure :prototype(&) ( $code )
{
   my $start = [ gettimeofday ];
   $code->();
   return tv_interval $start;
}

my $COUNT = 1_000_000;

my @ARGS = ( x => 10, z => 30 );

sub make_test_subs ( $paramcount )
{
   $paramcount -= 3; # account for $x/$y/$z

   my $named_extras = join ", ", map { ":\$p$_ = undef" } 1 .. $paramcount;
   my $extsub = eval <<"EOF"
extended sub ( :\$x, :\$y = 20, :\$z, $named_extras )
{
   return \$x + \$y + \$z;
}
EOF
      or die $@;

   my $code_extras = join "\n", map { "   my \$p$_ = delete \$params{p$_} // undef;" } 1 .. $paramcount;
   my $ppsub = eval <<"EOF"
sub ( %params )
{
   my \$x = delete \$params{x} or die "Requires 'x'";
   my \$y = delete \$params{y} // 20;
   my \$z = delete \$params{z} or die "Requires 'z'";
$code_extras
   keys %params and die "Unrecognised params";
   return \$x + \$y + \$z;
}
EOF
      or die $@;

   return ( $extsub, $ppsub );
}

for( my $paramcount = 4; $paramcount <= 1024; $paramcount *= 2 ) {
   # Scale this down otherwise it takes foreeeever
   my $count = $COUNT * 4 / $paramcount;

   printf "## Timing with %d params (%d calls)...\n", $paramcount, $count;

   my ( $extsub, $ppsub ) = make_test_subs( $paramcount );
   my $elapsed_extsub = 0;
   my $elapsed_plain = 0;

   # To reduce the influence of bursts of timing noise, interleave many small runs
   # of each type.

   my $return_60 = sub { 60 };

   foreach ( 1 .. 20 ) {
      my $overhead = measure {
         for ( 1 .. $count ) {
            my $total = $return_60->( @ARGS );
            $total == 60 or die "Oops - return_60 gave wrong result";
         }
      };

      $elapsed_extsub += -$overhead + measure {
         for ( 1 .. $count ) {
            my $total = $extsub->( @ARGS );
            $total == 60 or die "Oops - extsub gave wrong result";
         }
      };
      $elapsed_plain += -$overhead + measure {
         for ( 1 .. $count ) {
            my $total = $ppsub->( @ARGS );
            $total == 60 or die "Oops - plain sub gave wrong result";
         }
      };
   }

   if( $elapsed_extsub > $elapsed_plain ) {
      printf "  Plain perl took %.3fsec, ** this was SLOWER at %.3fsec **\n",
         $elapsed_plain, $elapsed_extsub;
   }
   else {
      my $speedup = ( $elapsed_plain - $elapsed_extsub ) / $elapsed_plain;
      printf "  Plain perl took %.3fsec, this was %d%% faster at %.3fsec\n",
         $elapsed_plain, $speedup * 100, $elapsed_extsub;
   }
}

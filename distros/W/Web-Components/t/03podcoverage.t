use strict;
use warnings;
use File::Spec::Functions qw( catdir updir );
use FindBin               qw( $Bin );
use lib               catdir( $Bin, updir, 'lib' );

use Test::More;

BEGIN {
   $ENV{AUTHOR_TESTING}
      or plan skip_all => 'POD coverage test only for developers';
}

use English qw( -no_match_vars );

eval "use Test::Pod::Coverage 1.04";

sub all_my_pod_coverage_ok {
   my $parms = (@_ && (ref $_[0] eq "HASH")) ? shift : {};
   my $msg = shift;
   my $ok = 1;
   my @modules = all_modules();
   if ( @modules ) {
      for my $module ( @modules ) {
         next if $module =~ m{ Forms }mx;
         my $thismsg = defined $msg ? $msg : "Pod coverage on $module";
         my $thisok = pod_coverage_ok( $module, $parms, $thismsg );
         $ok = 0 unless $thisok;
      }
      done_testing;
   }
   else {
      plan( tests => 1 );
      ok( 1, "No modules found." );
   }
   return $ok;
}

all_my_pod_coverage_ok({
   also_private => [
      qr{ \A (BUILD | BUILDARGS | as_string | clone) \z }mx
   ],
});

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:

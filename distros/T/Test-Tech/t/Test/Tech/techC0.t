#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '0.13';
$DATE = '2004/04/13';

BEGIN {
   use FindBin;
   use File::Spec;
   use Cwd;
   use vars qw( $__restore_dir__ );
   $__restore_dir__ = cwd();
   my ($vol, $dirs) = File::Spec->splitpath($FindBin::Bin,'nofile');
   chdir $vol if $vol;
   chdir $dirs if $dirs;
   use lib $FindBin::Bin;

   # Add the directory with "Test.pm" version 1.24 to the front of @INC
   # Thus, load Test::Tech, will find Test.pm 1.24 first
   unshift @INC, File::Spec->catdir ( cwd(), 'V001024'); 

   # Create the test plan by supplying the number of tests
   # and the todo tests
   require Test::Tech;
   Test::Tech->import( qw(plan ok skip skip_tests tech_config finish) );
   plan(tests => 2, todo => [1]);

}

END {
   # Restore working directory and @INC back to when enter script
   @INC = @lib::ORIG_INC;
   chdir $__restore_dir__;
}

# 1.24 error goes to the STDERR
# while 1.15 goes to STDOUT
# redirect STDERR to the STDOUT
tech_config('Test.TESTERR', \*STDOUT);

my $x = 2;
my $y = 3;

#  xy feature Under development, i.e todo
ok( #  ok:  1
    [$x+$y,$y-$x], # actual results
    [5,1], # expected results
    '', 'Todo test that passes');

ok( #  ok:  2
    [$x+$y,$x*$y], # actual results
    [6,5], # expected results
    '', 'Test that fails');

finish() # pick up stats

__END__

=head1 COPYRIGHT

This test script is public domain.

=cut

## end of test script file ##


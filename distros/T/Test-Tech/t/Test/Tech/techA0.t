#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;
use vars qw($VERSION $DATE);
$VERSION = '0.13';
$DATE = '2004/04/15';

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

   # Add the directory with "Test.pm" version 1.15 to the front of @INC
   # Thus, 'use Test;' in  Test::Tech, will find Test.pm 1.15 first
   unshift @INC, File::Spec->catdir ( cwd(), 'V001015'); 

   # Create the test plan by supplying the number of tests
   # and the todo tests
   require Test::Tech;
   Test::Tech->import( qw(plan ok skip skip_tests tech_config finish) );
   plan(tests => 8, todo => [4, 8]);
}


END {
   # Restore working directory and @INC back to when enter script
   @INC = @lib::ORIG_INC;
   chdir $__restore_dir__;
}


my $x = 2;
my $y = 3;

#  ok:  1 - Using Test 1.15
ok( $Test::VERSION, '1.15', '', 'Test version');

skip_tests( 1 ) unless ok( #  ok:  2 - Do not skip rest
    $x + $y, # actual results
    5, # expected results
    '', 'Pass test'); 

#  ok:  3
#
skip( 1, # condition to skip test   
      ($x*$y*2), # actual results
      6, # expected results
      '','Skipped tests');

#  zyw feature Under development, i.e todo
ok( #  ok:  4
    $x*$y*2, # actual results
    6, # expected results
    '','Todo Test that Fails');

skip_tests(1) unless ok( #  ok:  5
    $x + $y, # actual results
    6, # expected results
    '','Failed test that skips the rest'); 

ok( #  ok:  6
    $x + $y + $x, # actual results
    9, # expected results
    '', 'A test to skip');

ok( #  ok:  7
    $x + $y + $x + $y, # actual results
    10, # expected results
    '', 'A not skip to skip');

skip_tests(0);
ok( #  ok:  8
    $x*$y*2, # actual results
         12, # expected results
         '', 'Stop skipping tests. Todo Test that Passes');

ok( #  ok:  9
    $x * $y, # actual results
    6, # expected results
    {name => 'Unplanned pass test'}); 


finish(); # pick up stats

__END__

=head1 COPYRIGHT

This test script is public domain.

=cut

## end of test script file ##


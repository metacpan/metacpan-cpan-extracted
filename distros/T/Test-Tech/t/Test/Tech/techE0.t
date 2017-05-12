#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '0.09';
$DATE = '2004/05/11';

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

   require Test::Tech;
   Test::Tech->import( qw(finish is_skip plan ok skip skip_tests tech_config ) );
   plan(tests => 10, todo => [4, 8]);
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

#  ok:  1 - Using Test 1.24
ok( $Test::VERSION, '1.24', '', 'Test version');

skip_tests( 1 ) unless ok(   #  ok:  2 - Do not skip rest
    $x + $y, # actual results
    5, # expected results
    {name => 'Pass test'} ); 

skip( #  ok:  3
      1, # condition to skip test   
      ($x*$y*2), # actual results
      6, # expected results
      {name => 'Skipped tests'});

#  zyw feature Under development, i.e todo
ok( #  ok:  4
    $x*$y*2, # actual results
    6, # expected results
    [name => 'Todo Test that Fails',
    diagnostic => 'Should Fail']);

skip_tests(1,'Skip test on') unless ok(  #  ok:  5
    $x + $y, # actual results
    6, # expected results
    [diagnostic => 'Should Turn on Skip Test', 
     name => 'Failed test that skips the rest']); 

my ($skip_on, $skip_diag) = is_skip();

ok( #  ok:  6 
    $x + $y + $x, # actual results
    9, # expected results
    '', 'A test to skip');

ok( #  ok:  7 
    skip_tests(0), # actual results
    1, # expected results
    '', 'Turn off skip');

ok( #  ok:  8 
    [$skip_on, $skip_diag], # actual results
    [1,'Skip test on'], # expected results
    '', 'Skip flag');

finish() # pick up stats

__END__

=head1 COPYRIGHT

This test script is public domain.

=cut

## end of test script file ##


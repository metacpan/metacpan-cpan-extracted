#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '0.08';
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
   Test::Tech->import( qw(finish is_skip plan ok ok_sub
                          skip skip_sub skip_tests tech_config) );
   plan(tests => 7);
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
#  ok:  1 - Using Test 1.24
ok( $Test::VERSION, '1.24', '', 'Test version');

ok_sub( #  ok:  2 
    \&tolerance, # critera subroutine
    99, # actual results
    [100,10], # expected results
    'tolerance(x)', 
    'ok tolerance subroutine');

ok_sub( #  ok:  3
    \&tolerance, # critera subroutine
    80, # actual results
    [100,10], # expected results
    'tolerance(x)', 
    'not ok tolerance subroutine');

skip_sub( #  ok:  3 
    \&tolerance, # critera subroutine
    0, # do no skip
    99, # actual results
    [100,10], # expected results
    'tolerance(x)', 
    'no skip - ok tolerance subroutine');

skip_sub( #  ok:  4
    \&tolerance, # critera subroutine
    0,  # do no skip
    80, # actual results
    [100,10], # expected results
    'tolerance(x)', 
    'no skip - not ok tolerance subroutine');

skip_sub( #  ok:  5
    \&tolerance, # critera subroutine
    1,  # skip
    80, # actual results
    [100,10], # expected results
    'tolerance(x)', 
    'skip tolerance subroutine');

finish(); # pick up stats

sub tolerance
{   my ($actual,$expected) = @_;
    my ($average, $tolerance) = @$expected;
    use integer;
    $actual = (($average - $actual) * 100) / $average;
    no integer;
    (-$tolerance < $actual) && ($actual < $tolerance) ? 1 : 0;
}

__END__

=head1 COPYRIGHT

This test script is public domain.

=cut

## end of test script file ##


#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '0.01';   # automatically generated file
$DATE = '2004/05/24';
$FILE = __FILE__;


##### Test Script ####
#
# Name: basic.t
#
# UUT: Test::STDmaker
#
# The module Test::STDmaker generated this test script from the contents of
#
# t::Test::STDmaker::basic;
#
# Don't edit this test script file, edit instead
#
# t::Test::STDmaker::basic;
#
#	ANY CHANGES MADE HERE TO THIS SCRIPT FILE WILL BE LOST
#
#       the next time Test::STDmaker generates this script file.
#
#

######
#
# T:
#
# use a BEGIN block so we print our plan before Module Under Test is loaded
#
BEGIN { 

   use FindBin;
   use File::Spec;
   use Cwd;

   ########
   # The working directory for this script file is the directory where
   # the test script resides. Thus, any relative files written or read
   # by this test script are located relative to this test script.
   #
   use vars qw( $__restore_dir__ );
   $__restore_dir__ = cwd();
   my ($vol, $dirs) = File::Spec->splitpath($FindBin::Bin,'nofile');
   chdir $vol if $vol;
   chdir $dirs if $dirs;

   #######
   # Pick up any testing program modules off this test script.
   #
   # When testing on a target site before installation, place any test
   # program modules that should not be installed in the same directory
   # as this test script. Likewise, when testing on a host with a @INC
   # restricted to just raw Perl distribution, place any test program
   # modules in the same directory as this test script.
   #
   use lib $FindBin::Bin;

   ########
   # Using Test::Tech, a very light layer over the module "Test" to
   # conduct the tests.  The big feature of the "Test::Tech: module
   # is that it takes expected and actual references and stringify
   # them by using "Data::Secs2" before passing them to the "&Test::ok"
   # Thus, almost any time of Perl data structures may be
   # compared by passing a reference to them to Test::Tech::ok
   #
   # Create the test plan by supplying the number of tests
   # and the todo tests
   #
   require Test::Tech;
   Test::Tech->import( qw(finish is_skip ok ok_sub plan skip 
                          skip_sub skip_tests tech_config) );
   plan(tests => 18);

}


END {
 
   #########
   # Restore working directory and @INC back to when enter script
   #
   @INC = @lib::ORIG_INC;
   chdir $__restore_dir__;
}




   # Perl code from C:
    use vars qw($loaded);
    use File::Glob ':glob';
    use File::Copy;
    use File::Package;
    use File::SmartNL;
    use Text::Scrub;
 
    my $fp = 'File::Package';
    my $snl = 'File::SmartNL';
    my $s = 'Text::Scrub';

    my $test_results;
    my $loaded = 0;
    my @outputs;

    my ($success, $diag);



   # Perl code from C:
    @outputs = bsd_glob( 'tg*1.*' );
    unlink @outputs;
    unlink 'tgA1.pm';
    unlink 'tgB1.pm';
    unlink 'tgC1.pm';

    #### 
    #  Use the test software to generate the test of the test software
    #   
    #  tg -o="clean all" TestGen
    # 
    #  0 - series is used to generate an test case test script
    #
    #      generate all output files by 
    #          tg -o=clean TestGen0 TestGen1
    #          tg -o=all TestGen1
    #
    #  1 - this is the actual value test case
    #      thus, TestGen1 is used to produce actual test results
    #
    #  2 - this series is the expected test results
    # 
    #
    # make no residue outputs from last test series
    #
    #  unlink <tg1*.*>;  causes subsequent bsd_blog calls to crash
    #;



ok(  $loaded = $fp->is_package_loaded('Test::STDmaker'), # actual results
      '', # expected results
     "For a valid test, the UUT should not be loaded",
     "UUT not loaded");

#  ok:  1

   # Perl code from C:
my $errors = $fp->load_package( 'Test::STDmaker' );




####
# verifies requirement(s):
# L<Test::STDmaker/load [1]>
# 

#####
skip_tests( 1 ) unless
  skip( $loaded, # condition to skip test   
      $errors, # actual results
      '', # expected results
      "",
      "Load UUT");

#  ok:  2

ok(  $Test::STDmaker::VERSION, # actual results
     $Test::STDmaker::VERSION, # expected results
     "",
     "Test::STDmaker Version $Test::STDmaker::VERSION");

#  ok:  3

   # Perl code from C:
    copy 'tgA0.pm', 'tgA1.pm';
    my $tmaker = new Test::STDmaker(pm =>'t::Test::STDmaker::tgA1', nounlink => 1);
    my $perl_executable = $tmaker->perl_command();
    $success = $tmaker->tmake( 'STD' );
    $diag = "\n~~~~~~~\nFormDB\n\n" . join "\n", @{$tmaker->{FormDB}};
    $diag .= "\n~~~~~~~\nstd_db\n\n" . join "\n", @{$tmaker->{std_db}};
    $diag .= (-e 'temp.pl') ? "\n~~~~~~~\ntemp.pl\n\n" . $snl->fin('temp.pl') : 'No temp.pl';
    $diag .= (-e 'tgA1.pm') ? "\n~~~~~~~\ntgA1.pm\n\n" . $snl->fin('tgA1.pm') : 'No tgA1.pm';



skip_tests( 1 ) unless
  ok(  $success, # actual results
     1, # expected results
     "$diag",
     "tmake('STD', {pm => 't::Test::STDmaker::tgA1'})");

#  ok:  4


####
# verifies requirement(s):
#     L<Test::STDmaker/clean FormDB [1]>
#     L<Test::STDmaker/clean FormDB [2]>
#     L<Test::STDmaker/clean FormDB [3]>
#     L<Test::STDmaker/clean FormDB [4]>
#     L<Test::STDmaker/file_out option [1]>
# 

#####
ok(  $s->scrub_date_version($snl->fin('tgA1.pm')), # actual results
     $s->scrub_date_version($snl->fin('tgA2.pm')), # expected results
     "",
     "Clean STD pm with a todo list");

#  ok:  5

   # Perl code from C:
    skip_tests(0);

    #####
    # Make sure there is no residue outputs hanging
    # around from the last test series.
    #
    @outputs = bsd_glob( 'tg*1.*' );
    unlink @outputs;
    $success = $tmaker->tmake();
    $diag = "\n~~~~~~~\nFormDB\n\n" . join "\n", @{$tmaker->{FormDB}};
    $diag .= "\n~~~~~~~\nstd_db\n\n" . join "\n", @{$tmaker->{std_db}};
    $diag .= (-e 'tgA1.pm') ? "\n~~~~~~~\ntgA1.pm\n\n" . $snl->fin('tgA1.pm') : 'No tgA1.pm';
    $diag .= (-e 'tgA1.t') ? "\n~~~~~~~\ntgA1.t\n\n" . $snl->fin('tgA1.t') : 'No tgA1.t';
    $diag .= (-e 'tgA1.d') ? "\n~~~~~~~\ntgA1.d\n\n" . $snl->fin('tgA1.d') : 'No tgA1.d';



skip_tests( 1 ) unless
  ok(  $success, # actual results
     1, # expected results
     "$diag",
     "tmake( {pm => 't::Test::STDmaker::tgA1'})");

#  ok:  6

   # Perl code from C:
;




####
# verifies requirement(s):
#     L<Test::STDmaker/clean FormDB [1]>
#     L<Test::STDmaker/clean FormDB [2]>
#     L<Test::STDmaker/clean FormDB [3]>
#     L<Test::STDmaker/clean FormDB [4]>
#     L<Test::STDmaker/STD PM POD [1]>
# 

#####
ok(  $s->scrub_date_version($snl->fin('tgA1.pm')), # actual results
     $s->scrub_date_version($snl->fin('tgA2.pm')), # expected results
     "",
     "Cleaned tgA1.pm");

#  ok:  7

   # Perl code from C:
    $test_results = `$perl_executable tgA1.d`;
    $snl->fout('tgA1.txt', $test_results);

    use Data::Dumper;
    my $probe = 3;
    my $actual_results = Dumper([0+$probe]);
    my $internal_storage = 'undetermine';
    if( $actual_results eq Dumper([3]) ) {
        $internal_storage = 'number';
    }
    elsif ( $actual_results eq Dumper(['3']) ) {
        $internal_storage = 'string';
    }

    #######
    # expected results depend upon the internal storage from numbers 
    # Cannot use tga2A1.txt. All the actuals use 1 and the glob
    # that deletes the actuals will delete it.
    #
    my $expected_results;
    if( $internal_storage eq 'string') {
        $expected_results = 'tgA2A3.txt';
    }
    else {
        $expected_results = 'tgA2A2.txt';
    }




####
# verifies requirement(s):
#     L<Test::STDmaker/demo file [1]>
#     L<Test::STDmaker/demo file [2]>
# 

#####
ok(  $test_results, # actual results
     $snl->fin($expected_results), # expected results
     "",
     "Demonstration script");

#  ok:  8

   # Perl code from C:
    $test_results = `$perl_executable tgA1.t`;
    $snl->fout('tgA1.txt', $test_results);




####
# verifies requirement(s):
#     L<Test::STDmaker/verify file [1]>
#     L<Test::STDmaker/verify file [2]>
#     L<Test::STDmaker/verify file [3]>
# 

#####
ok(  $s->scrub_probe($s->scrub_file_line($test_results)), # actual results
     $s->scrub_probe($s->scrub_file_line($snl->fin('tgA2B.txt'))), # expected results
     "",
     "Generated and execute the test script");

#  ok:  9

   # Perl code from C:
    #########
    #
    # Individual generate outputs using options
    #
    ########

    skip_tests(0);

    #####
    # Make sure there is no residue outputs hanging
    # around from the last test series.
    #
    @outputs = bsd_glob( 'tg*1.*' );
    unlink @outputs;
    copy 'tg0.pm', 'tg1.pm';
    copy 'tgA0.pm', 'tgA1.pm';
    my @cwd = File::Spec->splitdir( cwd() );
    pop @cwd;
    pop @cwd;
    unshift @INC, File::Spec->catdir( @cwd );  # put UUT in lib path
    $success = $tmaker->tmake('demo', { pm => 't::Test::STDmaker::tgA1', demo => 1});
    shift @INC;

    #######
    # expected results depend upon the internal storage from numbers 
    #
    if( $internal_storage eq 'string') {
        $expected_results = 'tg2B.pm';
    }
    else {
        $expected_results = 'tg2A.pm';
    }
    $diag = "\n~~~~~~~\nFormDB\n\n" . join "\n", @{$tmaker->{FormDB}};
    $diag .= "\n~~~~~~~\nstd_db\n\n" . join "\n", @{$tmaker->{std_db}};
    $diag .= (-e 'tgA1.pm') ? "\n~~~~~~~\ntgA1.pm\n\n" . $snl->fin('tgA1.pm') : 'No tgA1.pm';
    $diag .= (-e 'tgA1.d') ? "\n~~~~~~~\ntgA1.d\n\n" . $snl->fin('tgA1.d') : 'No tgA1.d';



skip_tests( 1 ) unless
  ok(  $success, # actual results
     1, # expected results
     "$diag",
     "tmake('demo', {pm => 't::Test::STDmaker::tgA1', demo => 1})");

#  ok:  10

ok(  $s->scrub_date_version($snl->fin('tg1.pm')), # actual results
     $s->scrub_date_version($snl->fin($expected_results)), # expected results
     "",
     "Generate and replace a demonstration");

#  ok:  11

   # Perl code from C:
    skip_tests(0);

    no warnings;
    open SAVEOUT, ">&STDOUT";
    use warnings;
    open STDOUT, ">tgA1.txt";
    $success = $tmaker->tmake('verify', { pm => 't::Test::STDmaker::tgA1', run => 1, test_verbose => 1});
    close STDOUT;
    open STDOUT, ">&SAVEOUT";
    
    ######
    # For some reason, test harness puts in a extra line when running u
    # under the Active debugger on Win32. So just take it out.
    # Also the script name is absolute which is site dependent.
    # Take it out of the comparision.
    #
    $test_results = $snl->fin('tgA1.txt');
    $test_results =~ s/.*?1..9/1..9/; 
    $test_results =~ s/------.*?\n(\s*\()/\n $1/s;
    $snl->fout('tgA1.txt',$test_results);




####
# verifies requirement(s):
#     L<Test::STDmaker/verify file [1]>
#     L<Test::STDmaker/verify file [2]>
#     L<Test::STDmaker/verify file [3]>
#     L<Test::STDmaker/verify file [4]>
#     L<Test::STDmaker/execute [3]>
#     L<Test::STDmaker/execute [4]>
# 

#####
skip_tests( 1 ) unless
  ok(  $success, # actual results
     1, # expected results
     "",
     "tmake('verify', {pm => 't::Test::STDmaker::tgA1', run => 1, test_verbose => 1})");

#  ok:  12

ok(  $s->scrub_probe($s->scrub_test_file($s->scrub_file_line($test_results))), # actual results
     $s->scrub_probe($s->scrub_test_file($s->scrub_file_line($snl->fin('tgA2C.txt')))), # expected results
     "",
     "Generate and verbose test harness run test script");

#  ok:  13

   # Perl code from C:
    skip_tests(0);

    no warnings;
    open SAVEOUT, ">&STDOUT";
    use warnings;
    open STDOUT, ">tgA1.txt";
    $main::SIG{__WARN__}=\&__warn__; # kill pesty Format STDOUT and Format STDOUT_TOP redefined
    $success = $tmaker->tmake('verify', { pm => 't::Test::STDmaker::tgA1', run => 1});
    $main::SIG{__WARN__}=\&CORE::warn;
    close STDOUT;
    open STDOUT, ">&SAVEOUT";

    ######
    # For some reason, test harness puts in a extra line when running u
    # under the Active debugger on Win32. So just take it out.
    # Also with absolute file, the file is chopped off, and see
    # stuff that is site dependent. Need to take it out also.
    #
    $test_results = $snl->fin('tgA1.txt');
    $test_results = 'FAILED tests 4, 8' if( $test_results =~ /FAILED tests 4, 8/ );




####
# verifies requirement(s):
#     L<Test::STDmaker/verify file [1]>
#     L<Test::STDmaker/verify file [2]>
#     L<Test::STDmaker/verify file [3]>
#     L<Test::STDmaker/execute [3]>
# 

#####
skip_tests( 1 ) unless
  ok(  $success, # actual results
     1, # expected results
     "",
     "tmake('verify', {pm => 't::Test::STDmaker::tgA1', run => 1})");

#  ok:  14

ok(  $test_results, # actual results
     'FAILED tests 4, 8', # expected results
     "",
     "Generate and test harness run test script");

#  ok:  15

   # Perl code from C:
    skip_tests(0);
    copy 'tgB0.pm', 'tgB1.pm';
    $success = $tmaker->tmake('STD', 'verify', {pm => 't::Test::STDmaker::tgB1', nounlink => 1} );
    $diag = "\n~~~~~~~\nFormDB\n\n" . join "\n", @{$tmaker->{FormDB}};
    $diag .= "\n~~~~~~~\nstd_db\n\n" . join "\n", @{$tmaker->{std_db}};
    $diag .= (-e 'temp.pl') ? "\n~~~~~~~\ntemp.pl\n\n" . $snl->fin('temp.pl') : 'No temp.pl';
    $diag .= (-e 'tgB1.pm') ? "\n~~~~~~~\ntgB1.pm\n\n" . $snl->fin('tgB1.pm') : 'No tgB1.pm';
    $diag .= (-e 'tgB1.t') ? "\n~~~~~~~\ntgB1.t\n\n" . $snl->fin('tgB1.t') : 'No tgB1.t';



skip_tests( 1 ) unless
  ok(  $success, # actual results
     1, # expected results
     "$diag",
     "tmake('STD', 'verify', {pm => 't::Test::STDmaker::tgB1'})");

#  ok:  16


####
# verifies requirement(s):
#     L<Test::STDmaker/clean FormDB [1]>
#     L<Test::STDmaker/clean FormDB [2]>
#     L<Test::STDmaker/clean FormDB [3]>
#     L<Test::STDmaker/clean FormDB [4]>
#     L<Test::STDmaker/file_out option [1]>
# 

#####
ok(  $s->scrub_date_version($snl->fin('tgB1.pm')), # actual results
     $s->scrub_date_version($snl->fin('tgB2.pm')), # expected results
     "",
     "Clean STD pm without a todo list");

#  ok:  17

   # Perl code from C:
    $test_results = `$perl_executable tgB1.t`;
    $snl->fout('tgB1.txt', $test_results);



ok(  $s->scrub_probe($s->scrub_file_line($test_results)), # actual results
     $s->scrub_probe($s->scrub_file_line($snl->fin('tgB2.txt'))), # expected results
     "",
     "Generated and execute the test script");

#  ok:  18

   # Perl code from C:
    #####
    # Make sure there is no residue outputs hanging
    # around from the last test series.
    #
    @outputs = bsd_glob( 'tg*1.*' );
    unlink @outputs;
    unlink 'tgA1.pm';
    unlink 'tgB1.pm';
    unlink 'tgC1.pm';

    #####
    # Suppress some annoying warnings
    #
    sub __warn__ 
    { 
       my ($text) = @_;
       return $text =~ /STDOUT/;
       CORE::warn( $text );
    };




    finish();

__END__

=head1 NAME

basic.t - test script for Test::STDmaker

=head1 SYNOPSIS

 basic.t -log=I<string>

=head1 OPTIONS

All options may be abbreviated with enough leading characters
to distinguish it from the other options.

=over 4

=item C<-log>

basic.t uses this option to redirect the test results 
from the standard output to a log file.

=back

=head1 COPYRIGHT

copyright © 2003 Software Diamonds.

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

\=over 4

\=item 1

Redistributions of source code, modified or unmodified
must retain the above copyright notice, this list of
conditions and the following disclaimer. 

\=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

\=back

SOFTWARE DIAMONDS, http://www.SoftwareDiamonds.com,
PROVIDES THIS SOFTWARE 
'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

## end of test script file ##


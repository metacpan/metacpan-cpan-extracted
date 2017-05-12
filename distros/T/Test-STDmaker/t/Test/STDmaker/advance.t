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
# Name: advance.t
#
# UUT: Test::STDmaker
#
# The module Test::STDmaker generated this test script from the contents of
#
# t::Test::STDmaker::advance;
#
# Don't edit this test script file, edit instead
#
# t::Test::STDmaker::advance;
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
   plan(tests => 6);

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
 
    #########
    # For "TEST" 1.24 or greater that have separate std err output,
    # redirect the TESTERR to STDOUT
    #
    my $restore_testerr = tech_config( 'Test.TESTERR', \*STDOUT );   

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
    copy 'tgC0.pm', 'tgC1.pm';
    my $tmaker = new Test::STDmaker();
    my $perl_executable = $tmaker->perl_command();
    $success = $tmaker->tmake('STD', { pm => 't::Test::STDmaker::tgC1', fspec_out=>'os2'});
    $diag = "\n~~~~~~~\nFormDB\n\n" . join "\n", @{$tmaker->{FormDB}};
    $diag .= "\n~~~~~~~\nstd_db\n\n" . join "\n", @{$tmaker->{std_db}};
    $diag .= (-e 'tgC1.pm') ? "\n~~~~~~~\ntgC1.pm\n\n" . $snl->fin('tgC1.pm') : 'No tgC1.pm';



skip_tests( 1 ) unless
  ok(  $success, # actual results
     1, # expected results
     "$diag",
     "tmake('STD', {pm => 't::Test::STDmaker::tgC1', fspec_out=>'os2'})");

#  ok:  4


####
# verifies requirement(s):
# L<Test::STDmaker/fspec_out option [6]>
# 

#####
ok(  $s->scrub_date_version($snl->fin('tgC1.pm')), # actual results
     $s->scrub_date_version($snl->fin('tgC2.pm')), # expected results
     "",
     "Change File Spec");

#  ok:  5

   # Perl code from C:
   my $OS = $^O;  # Need to escape the form delimiting char ^
   unless ($OS) {   # on some perls $^O is not defined
     require Config;
     $OS = $Config::Config{'osname'};
   } 
   my($vol, $dir) = File::Spec->splitpath(cwd(),'nofile');
   my @dirs = File::Spec->splitdir($dir);
   pop @dirs; # pop STDmaker
   pop @dirs; # pop Test
   pop @dirs; # pop t
   $dir = File::Spec->catdir($vol,@dirs);
   my @t_path = $tmaker->find_t_roots();



ok(  $t_path[0], # actual results
     $dir, # expected results
     "",
     "find_t_roots");

#  ok:  6

   # Perl code from C:
    #####
    # Make sure there is no residue outputs hanging
    # around from the last test series.
    #
    @outputs = bsd_glob( 'tg*1.*' );
    unlink @outputs;
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

advance.t - test script for Test::STDmaker

=head1 SYNOPSIS

 advance.t -log=I<string>

=head1 OPTIONS

All options may be abbreviated with enough leading characters
to distinguish it from the other options.

=over 4

=item C<-log>

advance.t uses this option to redirect the test results 
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


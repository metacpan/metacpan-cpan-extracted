#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  t::Test::STDmaker::advance;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.01';
$DATE = '2004/05/24';
$FILE = __FILE__;

########
# The Test::STDmaker module uses the data after the __DATA__ 
# token to automatically generate the this file.
#
# Do not edit anything before __DATA_. Edit instead
# the data after the __DATA__ token.
#
# ANY CHANGES MADE BEFORE the  __DATA__ token WILL BE LOST
#
# the next time Test::STDmaker generates this file.
#
#


=head1 NAME

t::Test::STDmaker::STDmaker - Software Test Description for Test::STDmaker

=head1 TITLE PAGE

 Detailed Software Test Description (STD)

 for

 Perl Test::STDmaker Program Module

 Revision: -

 Version: 

 Date: 2004/05/24

 Prepared for: General Public 

 Prepared by:  http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com

 Classification: None

#######
#  
#  1. SCOPE
#
#
=head1 SCOPE

This detail STD and the 
L<General Perl Program Module (PM) STD|Test::STD::PerlSTD>
establishes the tests to verify the
requirements of Perl Program Module (PM) L<Test::STDmaker|Test::STDmaker>
The format of this STD is a tailored L<2167A STD DID|Docs::US_DOD::STD>.

#######
#  
#  3. TEST PREPARATIONS
#
#
=head1 TEST PREPARATIONS

Test preparations are establishes by the L<General STD|Test::STD::PerlSTD>.


#######
#  
#  4. TEST DESCRIPTIONS
#
#
=head1 TEST DESCRIPTIONS

The test descriptions uses a legend to
identify different aspects of a test description
in accordance with
L<STD PM Form Database Test Description Fields|Test::STDmaker/STD PM Form Database Test Description Fields>.

=head2 Test Plan

 T: 6^

=head2 ok: 1


  C:
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
 ^
 VO: ^

  C:
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
     #
 ^
  N: UUT not loaded^
 DM: For a valid test, the UUT should not be loaded^
  A: $loaded = $fp->is_package_loaded('Test::STDmaker')^
  E:  ''^
 ok: 1^

=head2 ok: 2

  N: Load UUT^
  R: L<Test::STDmaker/load [1]>^
  S: $loaded^
  C: my $errors = $fp->load_package( 'Test::STDmaker' )^
  A: $errors^
 SE: ''^
 ok: 2^

=head2 ok: 3

  N: Test::STDmaker Version $Test::STDmaker::VERSION^
  A: $Test::STDmaker::VERSION^
  E: $Test::STDmaker::VERSION^
 ok: 3^

=head2 ok: 4

 DO: ^
  N: tmake('STD', {pm => 't::Test::STDmaker::tgC1', fspec_out=>'os2'})^
  A: $snl->fin('tgC0.pm')^

 N: tmake('STD', {pm => 't::Test::STDmaker::tgC1', fspec_out=>'os2'})^

  C:
     copy 'tgC0.pm', 'tgC1.pm';
     my $tmaker = new Test::STDmaker();
     my $perl_executable = $tmaker->perl_command();
     $success = $tmaker->tmake('STD', { pm => 't::Test::STDmaker::tgC1', fspec_out=>'os2'});
     $diag = "\n~~~~~~~\nFormDB\n\n" . join "\n", @{$tmaker->{FormDB}};
     $diag .= "\n~~~~~~~\nstd_db\n\n" . join "\n", @{$tmaker->{std_db}};
     $diag .= (-e 'tgC1.pm') ? "\n~~~~~~~\ntgC1.pm\n\n" . $snl->fin('tgC1.pm') : 'No tgC1.pm';
 ^
  A: $success^
 DM: $diag^
 SE: 1^
 ok: 4^

=head2 ok: 5

  N: Change File Spec^
  R: L<Test::STDmaker/fspec_out option [6]>^
  A: $s->scrub_date_version($snl->fin('tgC1.pm'))^
  E: $s->scrub_date_version($snl->fin('tgC2.pm'))^
 ok: 5^

=head2 ok: 6

  N: find_t_roots^

  C:
    my $OS = $^^O;  # Need to escape the form delimiting char ^^
    unless ($OS) {   # on some perls $^^O is not defined
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
 ^
  A: $t_path[0]^
  E: $dir^
 ok: 6^



#######
#  
#  5. REQUIREMENTS TRACEABILITY
#
#

=head1 REQUIREMENTS TRACEABILITY

  Requirement                                                      Test
 ---------------------------------------------------------------- ----------------------------------------------------------------
 L<Test::STDmaker/fspec_out option [6]>                           L<t::Test::STDmaker::advance/ok: 5>
 L<Test::STDmaker/load [1]>                                       L<t::Test::STDmaker::advance/ok: 2>


  Test                                                             Requirement
 ---------------------------------------------------------------- ----------------------------------------------------------------
 L<t::Test::STDmaker::advance/ok: 2>                              L<Test::STDmaker/load [1]>
 L<t::Test::STDmaker::advance/ok: 5>                              L<Test::STDmaker/fspec_out option [6]>


=cut

#######
#  
#  6. NOTES
#
#

=head1 NOTES

copyright © 2003 Software Diamonds.

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

=over 4

=item 1

Redistributions of source code, modified or unmodified
must retain the above copyright notice, this list of
conditions and the following disclaimer. 

=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

=back

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

#######
#
#  2. REFERENCED DOCUMENTS
#
#
#

=head1 SEE ALSO

=over 4

=item L<File::Package|File::Package>

=item L<File::SmartNL|File::SmartNL>

=item L<File::AnySpec|File::AnySpec>

=item L<File::Data|File::Data>

=item L<File::Where|File::Where>

=item L<Text::Replace|Text::Replace>

=item L<Text::Column|Text::Column>

=item L<Text::Scrub|Text::Scrub>

=item L<Tie::Form|Tie::Form>

=item L<Software Development Standard|Docs::US_DOD::STD2167A>

=item L<Specification Practices|Docs::US_DOD::STD490A>

=item L<STD DID|Docs::US_DOD::STD>

=item L<Test::Harness|Test::Harness>

=item L<Test::Tech|Test::Tech>

=item L<Test|Test>

=back

=back

=for html
<hr>
<p><br>
<!-- BLK ID="NOTICE" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="OPT-IN" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="EMAIL" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="LOG_CGI" -->
<!-- /BLK -->
<p><br>

=cut

__DATA__

Name: t::Test::STDmaker::STDmaker^
File_Spec: Unix^
UUT: Test::STDmaker^
Revision: -^
Version: ^
End_User: General Public^
Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^
STD2167_Template: ^
Detail_Template: ^
Classification: None^
Temp: temp.pl^
Demo: advance.d^
Verify: advance.t^


 T: 6^


 C:
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
^

VO: ^

 C:
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
    #
^

 N: UUT not loaded^
DM: For a valid test, the UUT should not be loaded^
 A: $loaded = $fp->is_package_loaded('Test::STDmaker')^
 E:  ''^
ok: 1^

 N: Load UUT^
 R: L<Test::STDmaker/load [1]>^
 S: $loaded^
 C: my $errors = $fp->load_package( 'Test::STDmaker' )^
 A: $errors^
SE: ''^
ok: 2^

 N: Test::STDmaker Version $Test::STDmaker::VERSION^
 A: $Test::STDmaker::VERSION^
 E: $Test::STDmaker::VERSION^
ok: 3^

DO: ^
 N: tmake('STD', {pm => 't::Test::STDmaker::tgC1', fspec_out=>'os2'})^
 A: $snl->fin('tgC0.pm')^

 N: tmake('STD', {pm => 't::Test::STDmaker::tgC1', fspec_out=>'os2'})^

 C:
    copy 'tgC0.pm', 'tgC1.pm';
    my $tmaker = new Test::STDmaker();
    my $perl_executable = $tmaker->perl_command();
    $success = $tmaker->tmake('STD', { pm => 't::Test::STDmaker::tgC1', fspec_out=>'os2'});
    $diag = "\n~~~~~~~\nFormDB\n\n" . join "\n", @{$tmaker->{FormDB}};
    $diag .= "\n~~~~~~~\nstd_db\n\n" . join "\n", @{$tmaker->{std_db}};
    $diag .= (-e 'tgC1.pm') ? "\n~~~~~~~\ntgC1.pm\n\n" . $snl->fin('tgC1.pm') : 'No tgC1.pm';
^

 A: $success^
DM: $diag^
SE: 1^
ok: 4^

 N: Change File Spec^
 R: L<Test::STDmaker/fspec_out option [6]>^
 A: $s->scrub_date_version($snl->fin('tgC1.pm'))^
 E: $s->scrub_date_version($snl->fin('tgC2.pm'))^
ok: 5^

 N: find_t_roots^

 C:
   my $OS = $^^O;  # Need to escape the form delimiting char ^^
   unless ($OS) {   # on some perls $^^O is not defined
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
^

 A: $t_path[0]^
 E: $dir^
ok: 6^


 C:
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
^



See_Also:
\=over 4

\=item L<File::Package|File::Package>

\=item L<File::SmartNL|File::SmartNL>

\=item L<File::AnySpec|File::AnySpec>

\=item L<File::Data|File::Data>

\=item L<File::Where|File::Where>

\=item L<Text::Replace|Text::Replace>

\=item L<Text::Column|Text::Column>

\=item L<Text::Scrub|Text::Scrub>

\=item L<Tie::Form|Tie::Form>

\=item L<Software Development Standard|Docs::US_DOD::STD2167A>

\=item L<Specification Practices|Docs::US_DOD::STD490A>

\=item L<STD DID|Docs::US_DOD::STD>

\=item L<Test::Harness|Test::Harness>

\=item L<Test::Tech|Test::Tech>

\=item L<Test|Test>

=back
^


Copyright:
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
^


HTML:
<hr>
<p><br>
<!-- BLK ID="NOTICE" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="OPT-IN" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="EMAIL" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="LOG_CGI" -->
<!-- /BLK -->
<p><br>
^



~-~

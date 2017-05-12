#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Docs::Site_SVD::Test_Tech;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.26';
$DATE = '2004/05/20';
$FILE = __FILE__;

use vars qw(%INVENTORY);
%INVENTORY = (
    'lib/Docs/Site_SVD/Test_Tech.pm' => [qw(0.26 2004/05/20), 'revised 0.25'],
    'MANIFEST' => [qw(0.26 2004/05/20), 'generated, replaces 0.25'],
    'Makefile.PL' => [qw(0.26 2004/05/20), 'generated, replaces 0.25'],
    'README' => [qw(0.26 2004/05/20), 'generated, replaces 0.25'],
    'lib/Test/Tech.pm' => [qw(1.26 2004/05/20), 'revised 1.24'],
    't/Test/Tech/Tech.d' => [qw(0.08 2004/05/20), 'revised 0.07'],
    't/Test/Tech/Tech.pm' => [qw(0.07 2004/05/20), 'revised 0.06'],
    't/Test/Tech/Tech.t' => [qw(0.21 2004/05/20), 'revised 0.2'],
    't/Test/Tech/techA0.t' => [qw(0.13 2004/04/15), 'unchanged'],
    't/Test/Tech/techA2.txt' => [qw(0.09 2004/04/15), 'unchanged'],
    't/Test/Tech/techB0.t' => [qw(0.09 2004/04/13), 'unchanged'],
    't/Test/Tech/techC0.t' => [qw(0.13 2004/04/13), 'unchanged'],
    't/Test/Tech/techC2.txt' => [qw(0.12 2004/05/11), 'unchanged'],
    't/Test/Tech/techD0.d' => [qw(0.06 2004/04/13), 'unchanged'],
    't/Test/Tech/techD2.txt' => [qw(0.07 2003/09/15), 'unchanged'],
    't/Test/Tech/techD3.txt' => [qw(0.07 2003/09/15), 'unchanged'],
    't/Test/Tech/techE0.t' => [qw(0.09 2004/05/11), 'unchanged'],
    't/Test/Tech/techE2.txt' => [qw(0.2 2004/05/11), 'unchanged'],
    't/Test/Tech/techF0.t' => [qw(0.08 2004/05/11), 'unchanged'],
    't/Test/Tech/techF2.txt' => [qw(0.23 2004/05/11), 'unchanged'],
    't/Test/Tech/File/Package.pm' => [qw(1.17 2004/05/20), 'unchanged'],
    't/Test/Tech/File/SmartNL.pm' => [qw(1.16 2004/05/20), 'unchanged'],
    't/Test/Tech/Text/Scrub.pm' => [qw(1.14 2004/05/20), 'revised 1.13'],
    't/Test/Tech/Data/Secs2.pm' => [qw(1.26 2004/05/20), 'revised 1.23'],
    't/Test/Tech/Data/Str2Num.pm' => [qw(0.07 2004/05/20), 'new'],
    't/Test/Tech/Data/Startup.pm' => [qw(0.07 2004/05/20), 'revised 0.06'],
    't/Test/Tech/V001024/Test.pm' => [qw(1.25 2003/09/15), 'unchanged'],
    't/Test/Tech/V001015/Test.pm' => [qw(1.16 2003/09/15), 'unchanged'],

);

########
# The ExtUtils::SVDmaker module uses the data after the __DATA__ 
# token to automatically generate this file.
#
# Don't edit anything before __DATA_. Edit instead
# the data after the __DATA__ token.
#
# ANY CHANGES MADE BEFORE the  __DATA__ token WILL BE LOST
#
# the next time ExtUtils::SVDmaker generates this file.
#
#



=head1 NAME

Docs::Site_SVD::Test_Tech - Extends the Test program module

=head1 Title Page

 Software Version Description

 for

 Docs::Site_SVD::Test_Tech - Extends the Test program module

 Revision: AB

 Version: 0.26

 Date: 2004/05/20

 Prepared for: General Public 

 Prepared by:  SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>

 Copyright: copyright © 2003 Software Diamonds

 Classification: NONE

=head1 1.0 SCOPE

This paragraph identifies and provides an overview
of the released files.

=head2 1.1 Identification

This release,
identified in L<3.2|/3.2 Inventory of software contents>,
is a collection of Perl modules that
extend the capabilities of the Perl language.

=head2 1.2 System overview

The system is the Perl programming language software.
As established by the Perl referenced documents,
program modules, such the 
"L<Test::Tech|Test::Tech>" module, extend the Perl language.

The "Test::Tech" module extends the capabilities of the "Test" module.

The design is simple. 
The "Test::Tech" module loads the "Test" module without exporting
any "Test" subroutines into the "Test::Tech" namespace.
There is a "Test::Tech" cover subroutine with the same name
for each "Test" module subroutine.
Each "Test::Tech" cover subroutine will call the &Test::$subroutine
before or after it adds any additional capabilities.
The "Test::Tech" module is a drop-in for the "Test" module.

The "L<Test::Tech|Test::Tech>" module extends the capabilities of
the "L<Test|Test>" module as follows:

=over

=item *

If the compared variables are references, 
stingifies the referenced variable by passing the reference
through I<Data::Dumper> before making the comparison.
Thus, L<Test::Tech|Test::Tech> can test almost any data structure. 
If the compare variables are not refernces, use the &Test::ok
and &Test::skip directly.

=item *

Adds a method to skip the rest of the tests upon a critical failure

=item *

Adds a method to generate demos that appear as an interactive
session using the methods under test

=back

=head2 1.3 Document overview.

This document releases Test::Tech version 0.26
providing description of the inventory, installation
instructions and other information necessary to
utilize and track this release.

=head1 3.0 VERSION DESCRIPTION

All file specifications in this SVD
use the Unix operating
system file specification.

=head2 3.1 Inventory of materials released.

This document releases the file 

 Test-Tech-0.26.tar.gz

found at the following repository(s):

  http://www.softwarediamonds/packages/
  http://www.perl.com/CPAN/authors/id/S/SO/SOFTDIA/

Restrictions regarding duplication and license provisions
are as follows:

=over 4

=item Copyright.

copyright © 2003 Software Diamonds

=item Copyright holder contact.

 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>

=item License.

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

=item 3

Commercial installation of the binary or source
must visually present to the installer 
the above copyright notice,
this list of conditions intact,
that the original source is available
at http://softwarediamonds.com
and provide means
for the installer to actively accept
the list of conditions; 
otherwise, a license fee must be paid to
Softwareware Diamonds.


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

=back

=head2 3.2 Inventory of software contents

The content of the released, compressed, archieve file,
consists of the following files:

 file                                                         version date       comment
 ------------------------------------------------------------ ------- ---------- ------------------------
 lib/Docs/Site_SVD/Test_Tech.pm                               0.26    2004/05/20 revised 0.25
 MANIFEST                                                     0.26    2004/05/20 generated, replaces 0.25
 Makefile.PL                                                  0.26    2004/05/20 generated, replaces 0.25
 README                                                       0.26    2004/05/20 generated, replaces 0.25
 lib/Test/Tech.pm                                             1.26    2004/05/20 revised 1.24
 t/Test/Tech/Tech.d                                           0.08    2004/05/20 revised 0.07
 t/Test/Tech/Tech.pm                                          0.07    2004/05/20 revised 0.06
 t/Test/Tech/Tech.t                                           0.21    2004/05/20 revised 0.2
 t/Test/Tech/techA0.t                                         0.13    2004/04/15 unchanged
 t/Test/Tech/techA2.txt                                       0.09    2004/04/15 unchanged
 t/Test/Tech/techB0.t                                         0.09    2004/04/13 unchanged
 t/Test/Tech/techC0.t                                         0.13    2004/04/13 unchanged
 t/Test/Tech/techC2.txt                                       0.12    2004/05/11 unchanged
 t/Test/Tech/techD0.d                                         0.06    2004/04/13 unchanged
 t/Test/Tech/techD2.txt                                       0.07    2003/09/15 unchanged
 t/Test/Tech/techD3.txt                                       0.07    2003/09/15 unchanged
 t/Test/Tech/techE0.t                                         0.09    2004/05/11 unchanged
 t/Test/Tech/techE2.txt                                       0.2     2004/05/11 unchanged
 t/Test/Tech/techF0.t                                         0.08    2004/05/11 unchanged
 t/Test/Tech/techF2.txt                                       0.23    2004/05/11 unchanged
 t/Test/Tech/File/Package.pm                                  1.17    2004/05/20 unchanged
 t/Test/Tech/File/SmartNL.pm                                  1.16    2004/05/20 unchanged
 t/Test/Tech/Text/Scrub.pm                                    1.14    2004/05/20 revised 1.13
 t/Test/Tech/Data/Secs2.pm                                    1.26    2004/05/20 revised 1.23
 t/Test/Tech/Data/Str2Num.pm                                  0.07    2004/05/20 new
 t/Test/Tech/Data/Startup.pm                                  0.07    2004/05/20 revised 0.06
 t/Test/Tech/V001024/Test.pm                                  1.25    2003/09/15 unchanged
 t/Test/Tech/V001015/Test.pm                                  1.16    2003/09/15 unchanged


=head2 3.3 Changes

Changes  are as follows:

=over 4

=item Test-Tester-0.01

Originated.

=item Test-Tester-0.02

Minor changes to this SVD.

=item Test-Tech-0.01

Due to a non-registered namespace conflict with CPAN,
changed the namespace from Test::Tester to Test::Tech

=item Test-Tech-0.02

Fixed prototype for &Test::Tech::skip_rest Test::Tech line 84

=item Test-Tech-0.03

The &Data::Dumper::Dumper subroutine stringifies the internal Perl
variable. Different Perls keep the have different internal formats
for numbers. Some keep them as binary numbers, while others as
strings. The ones that keep them as strings may be well spec.
In any case they have been let loose in the wild so the test 
scripts that use Data::Dumper must deal with them.

Added a probe to determine how a Perl stores its internal
numbers and added code to the test script to adjust for 
the difference in Perl

~~~~~

 ######
 # This is perl, v5.6.1 built for MSWin32-x86-multi-thread
 # (with 1 registered patch, see perl -V for more detail)
 #
 # Copyright 1987-2001, Larry Wall
 #
 # Binary build 631 provided by ActiveState Tool Corp. http://www.ActiveState.com
 # Built 17:16:22 Jan  2 2002
 #
 #
 # Perl may be copied only under the terms of either the Artistic License or the
 # GNU General Public License, which may be found in the Perl 5 source kit.
 #
 # Complete documentation for Perl, including FAQ lists, should be found on
 # this system using `man perl' or `perldoc perl'.  If you have access to the
 # Internet, point your browser at http://www.perl.com/, the Perl Home Page.
 #
 # ~~~~~~~
 #
 # Wall, Christiansen and Orwant on Perl internal storage
 #
 # Page 351 of Programming Perl, Third Addition, Overloadable Operators
 # quote:
 # 
 # Conversion operators: "", 0+, bool
 #   These three keys let you provide behaviors for Perl's automatic conversions
 #   to strings, numbers, and Boolean values, respectively.
 # 
 # ~~~~~~~
 #
 # Internal Storage of Perls that are in the wild
 #
 #   string - Perl v5.6.1 MSWin32-x86-multi-thread, ActiveState build 631, binary
 #   number - Perl version 5.008 for solaris  
 #
 #   Perls in the wild with internal storage of string may be mutants that need to 
 #   be hunted down killed.
 # 

 ########
 # Probe Perl for internal storage method
 #
 my $probe = 3;
 my $actual = Dumper([0+$probe]);
 my $internal_storage = 'undetermine';
 if( $actual eq Dumper([5]) ) {
     $internal_storage = 'number';
 }
 elsif ( $actual eq Dumper(['3']) ) {
     $internal_storage = 'string';
 }

=item Test::Tech 0.04

=over 4

=item *

Added functions with the same name as the "Test" functions.
This make it easier to upgrade from "Test" to "Test::Tech"

=item * 

Added tests not only for Test 1.15 but also Test 1.24

=item *

Added tests for the new "Test" functions.

=back

=item Test-Tech-0.05

Replaced using Test::Util that has disappeared with its
replacements: File::FileUtil, Test::STD::Scrub, Test::STD::STDutil

=item Test-Tech-0.06

This version changes the previous version but eliminating
all object methods. 
Since this module is built on the L<Test|Test> and the
L<Data::Dumper|Data::Dumper> modules, neither which
are objectified, 
there is little advantage in providing methods
where a large number of data is static for all objects.
In other words, all new objects are mostly same.

=item Test-Tech-0.07

=over 4

=item t/Test/Tech/Tech.t t/Test/Tech/techCO.t

Corrected typos in comments. More info in comments 

=item Tech::Tech

Changed the test for TESTERR and Program_lines for setting
in the tech_p hash from version number to if they are defined. 

=item File::Util

Broke "File::FileUtil" apart into modules with more descriptive names.
Switch to using the new modules "File::Package" and "File::SmartNL"
instead of "file::FileUtil". 

=back

=item Test-Tech-0.09

Left over usage of File::FileUtil in the test script files.
Removed them. Switch from "Test::STD::Scrub" to "Text::Scrub"

=item Test-Tech-0.11

In the test script, switch to using "Data::Hexdumper" module.
Much better hex dumper.

=item Test-Tech-0.12

Removed hex dump in test script.

Change test for begining printout of data, modules used, tec to 1.20 < Test::VERSION

Change the test so that test support program modules resides in distribution
directory tlib directory instead of the lib directory. 
Because they are no longer in the lib directory, 
test support files will not be installed as a pre-condition for the 
test of this module.
The test of this module will precede immediately.
The test support files in the tlib directory will vanish after
the installtion.

=item Test-Tech-0.13

If there is no diagianotic message and there is a test name, 
then use the test name also for the diagnostic message.
Diagnostic message appears in brackets after the expected
value.

=item Test-Tech-0.14

Broke out the 'stringify' subroutine into its own module: 'Data::Strify'

Use Archive::TarGzip 0.02 that uses mode 777 for directories instead of 666. Started to get
emails from Unix about untar not being able to change to
a directory with mod of 666.

=item Test-Tech-0.15

Changed from using 'Data::Strify' to 'Data::Secs2' for the stringify function.
'Data::Secs2' is useful for SEMI clients and also provides sorted hash keys
required for comparing stringifcation of Perl's nested data.
The 'Data::Secs2' obsoletes 'Data::Strify' which is history. 

Double checked that PREREQ_PM is 'Data::Secs2' which
fixes Test-Tech-0.14 error in the PREREQ_PM 
which errorneous used by 'Data/Strify.pm' instead of 'Data::Strify'.
This should clear complain by Mike Castle <dalgoda@ix.netcom.com> that
the MakeFile.PL for Test-Tech-0.14 crashes with a divide by zero.

=item Test-Tech-0.16

Strange failure from cpan-testers

 Cc: SOFTDIA@cpan.org
 Subject: FAIL Test-Tech-0.15 sun4-solaris 2.8
 To: cpan-testers@perl.org 

Additional comments:

Hello, Samson Monaco Tutankhamen! Thanks for uploading your works to CPAN.

I noticed that the test suite seem to fail without these modules:
Data::Secs2

As such, adding the prerequisite module(s) to 'PREREQ_PM' in your
Makefile.PL should solve this problem.  For example:

WriteMakefile(
    AUTHOR      => 'Samson Monaco Tutankhamen (support@SoftwareDiamonds.com)',
    ... # other information
    PREREQ_PM   => {
        'Data::Secs2'   => '0', # or a minimum workable version
    }
);

The PREREQ_PM in the Test-Tech-0.15 MakeFile.PL is as follows:

 PREREQ_PM => {Data::Secs2 => 0.01},

Changed to

 PREREQ_PM => {'Data::Secs2' => '0.01'},

=item Test-Tech-0.17

The POD was citing &Data::Dumper::Dumper which was replaced by Data::Secs2::stringify.
Changed the POD over to &Data::Secs2::stringify

The finish() subroutine was in the POD as a subroutine/method but not part of @EXPORT_OK.
Add it to @EXPORT_OK.

Redirected all output from the 'Test::' module throught a handle Tie. The handle Tie
added the test name on the same line as the 'ok' 'not ok' and collected stats.

Added printout of the stats to the finish() subroutine.

Added optional [@options] or {@options} input to the end of the ok subroutine and
the skip subroutine.

=item Test-Tech-0.18

The test script could not find one of the test library program modules. Revamp
the test script and test library modules and added steps to the ExtUtils::SVDmaker
to have the SVDmaker test target run tests with just bare @INC that references
a vigin Perl installation libraries only.

The lastest build of Test::STDmaker now assumes and expects the test library in the same
directory as the test script.
Coordiated with the lastest Test::STDmaker by moving the
test library from tlib to t/Tie, the same directory as the test script
and deleting the test library File::TestPath program module.

=item Test-Tech-0.19

 Subject: FAIL Test-Tech-0.18 i586-linux 2.4.22-4tr 
 From: cpansmoke@alternation.net 
 Date: Thu,  8 Apr 2004 15:09:35 -0300 (ADT) 

 PERL_DL_NONLAZY=1 /usr/bin/perl5.8.0 "-MExtUtils::Command::MM" "-e" "test_harness(0, 'blib/lib', 'blib/arch')" t/Test/Tech/Tech.t
 t/Test/Tech/Tech....Can't locate FindBIN.pm

 Summary of my perl5 (revision 5.0 version 8 subversion 0) configuration:
   Platform:
     osname=linux, osvers=2.4.22-4tr, archname=i586-linux

This is capitalization problem. The program module name is 'FindBin' not 'FindBIN' which
is part of Perl. Microsoft does not care about capitalization differences while linux
does. This error is in the test script automatically generated by C<Test::STDmaker>
and was just introduced when moved test script libraries from C<tlib> to the directory
of the test script. Repaired C<Test::STDmaker> and regenerated the distribution.

=item Test-Tech-0.20

B<FAILURE REPORT:>

 Subject: FAIL Test-Tech-0.19 i586-linux 2.4.22-4tr 
 To: cpan-testers@perl.org 
 From: cpansmoke@alternation.net 
 Date: Sat, 10 Apr 2004 05:07:51 -0300 (ADT) 

[snip]

Can't locate Data/Secs2.pm in @INC

[snip]

As such, adding the prerequisite module(s) to 'PREREQ_PM' in your
Makefile.PL should solve this problem.  For example:

 WriteMakefile(
     AUTHOR      => 'Samson Monaco Tutankhamen (support@SoftwareDiamonds.com)',
     ... # other information
     PREREQ_PM   => {
        'Data::Secs2'   => '0', # or a minimum workable version
     }
 );

[snip]

B<CORRECTIVE ACTION:>

An exam of MakeFile.PL revealed the following:

 WriteMakefile(
    # [snip]
    PREREQ_PM => {'Data::Secs2' => '0.01'},
    # [snip]
 );

Cannot see anything wrong with the PREREQ_PM statement.
The only possibilities that come to mind are
either CPAN not processing the prereq_pm properly,
same syntax problem with C<PREREQ_PM > 
or because the test script uses C<Test::Tech> 
to test C<Test::Tech>, the prereq is processed too late.

Added C<Data::Secs2> to the test library so the test
will run. 

=item Test-Tech-0.21

For C<Test> module, version 1.20 or greater, changed so it sents failure messages
when skip flag turned on for C<&Test::Tech::ok> and C<&Test::Tech::ok>
out C<$Test::TESTERR> instead of C<$Test::TESTOUT>.

For C<&Test::Tech::finish> automatically generate failure messages
for all missing (not performed) test when the skip rest of tests
flag is on.

The C<FindBIN> that runs fine on Win because Win file spec is case insensitive
and Unix whats case sensitive C<FindBin> was fixed with on test C<Test::Test>.
However, overlooked all the test scripts that the top test script runs,
grabs the output and compares to expected ouput stored in files.
Corrected the C<FindBin> for following test software: 
C<TechA0.t TechB0.t TechC0.t TechD0.d TechE0.t>

=item Test-Tech-0.22

The C<Data::SecsPack> program module is now required to run the C<Test::Tech>
program module. Added a print out of the C<Data::SecsPack> version to the
C<plan> subroutine as follows:

 # Data::Secs2   : $Data::SecsPack::VERSION

=item Test-Tech-0.23

Added C<is_skip> ok_sub and skip_sub subroutines.

Added reporting of C<Data::Secs2::stringify()> errors. Correctly stringify
Perl data structures is not straight forward. Unlike C<Test> and C<Test::Tech>,
C<Data::Secs2> is very large including walks of Perl data structures, processing
of underlying data types such as C<CODE> and many other areas where there may
be unanticipated Perl data structure issues not properly addressed. 
Thus, best to have error detection in place, and stop testing if 
there is a broken C<Data::Secs2::stringify()>.

Changed the look of the C<demo> subroutine output to better resemble Perl code. 
Print the code straight forward without leading '=>'. Put a Perl comment '# ' in front of
each result line instead of printing it straing forward.

Added a print out of the C<Data::Start> version and number of tests to the
C<plan> subroutine.

=item Test-Tech-0.24

None of the test script for 0.23 ran. It appears that the Data::Secs2 does not
load properly and, thus, none of the test scripts execute

 t/Test/Tech/Tech....Data::Secs2 version 1.22 required--this is only version 1.19 

Seen this before were CPAN has troubles with C<WriteMakefile> subroutine in
the C<MakeFile.PL>

    PREREQ_PM => {'Data::Secs2' => '1.22',
                  'Data::SecsPack' => '0.06',
                  'Data::Startup' => '0.03',
                  'Test' => '1.20',},

Put the correct version in the test library, upload and see if this is the
problem. 

=item Test-Tech-0.25

It is unclear whether the failures to Test-Tech-0.24 is because of CPAN setup.

t/Test/Tech/Tech....Perl lib version (v5.8.4) doesn't match executable version (v5.6.1) at /usr/local/perl-5.8.4/lib/5.8.4/sparc-linux/Config.pm line 32.
Compilation failed in require at /usr/local/perl-5.8.4/lib/5.8.4/FindBin.pm line 97.

Since cannot get a response from the tester, bump the version to force a retest.

=item Test-Tech-0.26

Changed C<Data::Secs2> so no longer loads C<Data::SecsPack> unless needed.
C<Test::Tech> no longer loads C<Data::SecsPack> via C<Data::secs2> so 
no longer print out its version. Instead print out the version of C<Data::Str2Num>
which is needed for the C<str2float> and C<str2integer> subroutines that
the C<Data::SecsPack> package supplied.

Test Failure:

Subject: FAIL Test-Tech-0.25 sparc-linux 2.4.21-pre7 
From: alian@cpan.org (alian) 

PERL_DL_NONLAZY=1 /usr/local/perl-5.8.4/bin/perl "-MExtUtils::Command::MM" "-e" "test_harness(0, 'blib/lib', 'blib/arch')" t/Test/Tech/Tech.t
t/Test/Tech/Tech....Perl lib version (v5.8.4) doesn't match executable version (v5.6.1) at /usr/local/perl-5.8.4/lib/5.8.4/sparc-linux/Config.pm line 32.
Compilation failed in require at /usr/local/perl-5.8.4/lib/5.8.4/FindBin.pm line 97.
BEGIN failed--compilation aborted at /usr/local/perl-5.8.4/lib/5.8.4/FindBin.pm line 97.
Compilation failed in require at techA0.t line 13.

Analysis:

Everything  was going well until a C<`perl $command`>. 
From same failure on other test scripts, the test harness perl executable is 
different than the command line perl executable. 

Corrective Action:

Introduced the C<perl_command> subroutine that uses C<$^X> to return the current executable Perl
into the test script.
Use the results of this subroutine instead of 'perl' in backticks.

=back

=head2 3.4 Adaptation data.

This installation requires that the installation site
has the Perl programming language installed.
There are no other additional requirements or tailoring needed of 
configurations files, adaptation data or other software needed for this
installation particular to any installation site.

=head2 3.5 Related documents.

There are no related documents needed for the installation and
test of this release.

=head2 3.6 Installation instructions.

Instructions for installation, installation tests
and installation support are as follows:

=over 4

=item Installation Instructions.

To installed the release file, use the CPAN module
pr PPM module in the Perl release
or the INSTALL.PL script at the following web site:

 http://packages.SoftwareDiamonds.com

Follow the instructions for the the chosen installation software.

If all else fails, the file may be manually installed.
Enter one of the following repositories in a web browser:

  http://www.softwarediamonds/packages/
  http://www.perl.com/CPAN/authors/id/S/SO/SOFTDIA/

Right click on 'Test-Tech-0.26.tar.gz' and download to a temporary
installation directory.
Enter the following where $make is 'nmake' for microsoft
windows; otherwise 'make'.

 gunzip Test-Tech-0.26.tar.gz
 tar -xf Test-Tech-0.26.tar
 perl Makefile.PL
 $make test
 $make install

On Microsoft operating system, nmake, tar, and gunzip 
must be in the exeuction path. If tar and gunzip are
not install, download and install unxutils from

 http://packages.softwarediamonds.com

=item Prerequistes.

 'Data::Secs2' => '1.22',
 'Data::Str2Num' => '0.05',
 'Data::Startup' => '0.03',
 'Test' => '1.20',


=item Security, privacy, or safety precautions.

None.

=item Installation Tests.

Most Perl installation software will run the following test script(s)
as part of the installation:

 t/Test/Tech/Tech.t

=item Installation support.

If there are installation problems or questions with the installation
contact

 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>

=back

=head2 3.7 Possible problems and known errors

Known issues are as follows:

=over 4

=item Merge with the "Test" module

The "Test::Tech" capabilites could be incorporated into the
"Test" program module and "Test::Tech" eliminated.

=item TestLevel and Program_Lines

The "Test" module does not take the I<$TestLevel> value
into account where it chooses the module to load the
I<%Program_Line> hash. 
Since the L<Test::Tech> module adds a module layer in between
the L<Test> module that the test script, the I<$TestLevel>
must be set to 1. 
Thus, the L<Test> module loads the L<Test::Tech> module into
I<%Program_Line> hash instead of the Module Under Test.

=back

=head1 4.0 NOTES

The following are useful acronyms:

=over 4

=item .d

extension for a Perl demo script file

=item .pm

extension for a Perl Library Module

=item .t

extension for a Perl test script file

=back

=head1 2.0 SEE ALSO

=over 4

=item L<Test::Tech|Test::Tech> 

=item L<Docs::US_DOD::SVD|Docs::US_DOD::SVD> 

=back

=for html


=cut

1;

__DATA__

DISTNAME: Test-Tech^
REPOSITORY_DIR: packages^

VERSION : 0.26^
FREEZE: 1^
PREVIOUS_DISTNAME:  ^
PREVIOUS_RELEASE: 0.25^
REVISION: AB^

AUTHOR  : SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>^
ABSTRACT: 
The "Test::Tech" module extends the capabilities of the "Test" module.
It adds the skip_test method to the Test module, and 
adds the ability to compare complex data structures to the Test module.
^

TITLE   : Docs::Site_SVD::Test_Tech - Extends the Test program module^
END_USER: General Public^
COPYRIGHT: copyright © 2003 Software Diamonds^
CLASSIFICATION: NONE^
TEMPLATE:  ^
CSS: help.css^
SVD_FSPEC: Unix^

REPOSITORY: 
  http://www.softwarediamonds/packages/
  http://www.perl.com/CPAN/authors/id/S/SO/SOFTDIA/
^

COMPRESS: gzip^
COMPRESS_SUFFIX: gz^

CHANGE2CURRENT:  ^
RESTRUCTURE: 
^

AUTO_REVISE: 
lib/Test/Tech.pm
t/Test/Tech/*
lib/File/Package.pm => t/Test/Tech/File/Package.pm
lib/File/SmartNL.pm => t/Test/Tech/File/SmartNL.pm
lib/Text/Scrub.pm => t/Test/Tech/Text/Scrub.pm
lib/Data/Secs2.pm => t/Test/Tech/Data/Secs2.pm
lib/Data/Str2Num.pm => t/Test/Tech/Data/Str2Num.pm
lib/Data/Startup.pm => t/Test/Tech/Data/Startup.pm
^

REPLACE:
t/Test/Tech/V001024/*
t/Test/Tech/V001015/*
^

PREREQ_PM: 
'Data::Secs2' => '1.22',
'Data::Str2Num' => '0.05',
'Data::Startup' => '0.03',
'Test' => '1.20',
^
README_PODS: lib/Test/Tech.pm^

TESTS: t/Test/Tech/Tech.t^
EXE_FILES:  ^

CHANGES:

Changes  are as follows:

\=over 4

\=item Test-Tester-0.01

Originated.

\=item Test-Tester-0.02

Minor changes to this SVD.

\=item Test-Tech-0.01

Due to a non-registered namespace conflict with CPAN,
changed the namespace from Test::Tester to Test::Tech

\=item Test-Tech-0.02

Fixed prototype for &Test::Tech::skip_rest Test::Tech line 84

\=item Test-Tech-0.03

The &Data::Dumper::Dumper subroutine stringifies the internal Perl
variable. Different Perls keep the have different internal formats
for numbers. Some keep them as binary numbers, while others as
strings. The ones that keep them as strings may be well spec.
In any case they have been let loose in the wild so the test 
scripts that use Data::Dumper must deal with them.

Added a probe to determine how a Perl stores its internal
numbers and added code to the test script to adjust for 
the difference in Perl

~~~~~

 ######
 # This is perl, v5.6.1 built for MSWin32-x86-multi-thread
 # (with 1 registered patch, see perl -V for more detail)
 #
 # Copyright 1987-2001, Larry Wall
 #
 # Binary build 631 provided by ActiveState Tool Corp. http://www.ActiveState.com
 # Built 17:16:22 Jan  2 2002
 #
 #
 # Perl may be copied only under the terms of either the Artistic License or the
 # GNU General Public License, which may be found in the Perl 5 source kit.
 #
 # Complete documentation for Perl, including FAQ lists, should be found on
 # this system using `man perl' or `perldoc perl'.  If you have access to the
 # Internet, point your browser at http://www.perl.com/, the Perl Home Page.
 #
 # ~~~~~~~
 #
 # Wall, Christiansen and Orwant on Perl internal storage
 #
 # Page 351 of Programming Perl, Third Addition, Overloadable Operators
 # quote:
 # 
 # Conversion operators: "", 0+, bool
 #   These three keys let you provide behaviors for Perl's automatic conversions
 #   to strings, numbers, and Boolean values, respectively.
 # 
 # ~~~~~~~
 #
 # Internal Storage of Perls that are in the wild
 #
 #   string - Perl v5.6.1 MSWin32-x86-multi-thread, ActiveState build 631, binary
 #   number - Perl version 5.008 for solaris  
 #
 #   Perls in the wild with internal storage of string may be mutants that need to 
 #   be hunted down killed.
 # 

 ########
 # Probe Perl for internal storage method
 #
 my $probe = 3;
 my $actual = Dumper([0+$probe]);
 my $internal_storage = 'undetermine';
 if( $actual eq Dumper([5]) ) {
     $internal_storage = 'number';
 }
 elsif ( $actual eq Dumper(['3']) ) {
     $internal_storage = 'string';
 }

\=item Test::Tech 0.04

\=over 4

\=item *

Added functions with the same name as the "Test" functions.
This make it easier to upgrade from "Test" to "Test::Tech"

\=item * 

Added tests not only for Test 1.15 but also Test 1.24

\=item *

Added tests for the new "Test" functions.

\=back

\=item Test-Tech-0.05

Replaced using Test::Util that has disappeared with its
replacements: File::FileUtil, Test::STD::Scrub, Test::STD::STDutil

\=item Test-Tech-0.06

This version changes the previous version but eliminating
all object methods. 
Since this module is built on the L<Test|Test> and the
L<Data::Dumper|Data::Dumper> modules, neither which
are objectified, 
there is little advantage in providing methods
where a large number of data is static for all objects.
In other words, all new objects are mostly same.

\=item Test-Tech-0.07

\=over 4

\=item t/Test/Tech/Tech.t t/Test/Tech/techCO.t

Corrected typos in comments. More info in comments 

\=item Tech::Tech

Changed the test for TESTERR and Program_lines for setting
in the tech_p hash from version number to if they are defined. 

\=item File::Util

Broke "File::FileUtil" apart into modules with more descriptive names.
Switch to using the new modules "File::Package" and "File::SmartNL"
instead of "file::FileUtil". 

\=back

\=item Test-Tech-0.09

Left over usage of File::FileUtil in the test script files.
Removed them. Switch from "Test::STD::Scrub" to "Text::Scrub"

\=item Test-Tech-0.11

In the test script, switch to using "Data::Hexdumper" module.
Much better hex dumper.

\=item Test-Tech-0.12

Removed hex dump in test script.

Change test for begining printout of data, modules used, tec to 1.20 < Test::VERSION

Change the test so that test support program modules resides in distribution
directory tlib directory instead of the lib directory. 
Because they are no longer in the lib directory, 
test support files will not be installed as a pre-condition for the 
test of this module.
The test of this module will precede immediately.
The test support files in the tlib directory will vanish after
the installtion.

\=item Test-Tech-0.13

If there is no diagianotic message and there is a test name, 
then use the test name also for the diagnostic message.
Diagnostic message appears in brackets after the expected
value.

\=item Test-Tech-0.14

Broke out the 'stringify' subroutine into its own module: 'Data::Strify'

Use Archive::TarGzip 0.02 that uses mode 777 for directories instead of 666. Started to get
emails from Unix about untar not being able to change to
a directory with mod of 666.

\=item Test-Tech-0.15

Changed from using 'Data::Strify' to 'Data::Secs2' for the stringify function.
'Data::Secs2' is useful for SEMI clients and also provides sorted hash keys
required for comparing stringifcation of Perl's nested data.
The 'Data::Secs2' obsoletes 'Data::Strify' which is history. 

Double checked that PREREQ_PM is 'Data::Secs2' which
fixes Test-Tech-0.14 error in the PREREQ_PM 
which errorneous used by 'Data/Strify.pm' instead of 'Data::Strify'.
This should clear complain by Mike Castle <dalgoda@ix.netcom.com> that
the MakeFile.PL for Test-Tech-0.14 crashes with a divide by zero.

\=item Test-Tech-0.16

Strange failure from cpan-testers

 Cc: SOFTDIA@cpan.org
 Subject: FAIL Test-Tech-0.15 sun4-solaris 2.8
 To: cpan-testers@perl.org 

Additional comments:

Hello, Samson Monaco Tutankhamen! Thanks for uploading your works to CPAN.

I noticed that the test suite seem to fail without these modules:
Data::Secs2

As such, adding the prerequisite module(s) to 'PREREQ_PM' in your
Makefile.PL should solve this problem.  For example:

WriteMakefile(
    AUTHOR      => 'Samson Monaco Tutankhamen (support@SoftwareDiamonds.com)',
    ... # other information
    PREREQ_PM   => {
        'Data::Secs2'   => '0', # or a minimum workable version
    }
);

The PREREQ_PM in the Test-Tech-0.15 MakeFile.PL is as follows:

 PREREQ_PM => {Data::Secs2 => 0.01},

Changed to

 PREREQ_PM => {'Data::Secs2' => '0.01'},

\=item Test-Tech-0.17

The POD was citing &Data::Dumper::Dumper which was replaced by Data::Secs2::stringify.
Changed the POD over to &Data::Secs2::stringify

The finish() subroutine was in the POD as a subroutine/method but not part of @EXPORT_OK.
Add it to @EXPORT_OK.

Redirected all output from the 'Test::' module throught a handle Tie. The handle Tie
added the test name on the same line as the 'ok' 'not ok' and collected stats.

Added printout of the stats to the finish() subroutine.

Added optional [@options] or {@options} input to the end of the ok subroutine and
the skip subroutine.

\=item Test-Tech-0.18

The test script could not find one of the test library program modules. Revamp
the test script and test library modules and added steps to the ExtUtils::SVDmaker
to have the SVDmaker test target run tests with just bare @INC that references
a vigin Perl installation libraries only.

The lastest build of Test::STDmaker now assumes and expects the test library in the same
directory as the test script.
Coordiated with the lastest Test::STDmaker by moving the
test library from tlib to t/Tie, the same directory as the test script
and deleting the test library File::TestPath program module.

\=item Test-Tech-0.19

 Subject: FAIL Test-Tech-0.18 i586-linux 2.4.22-4tr 
 From: cpansmoke@alternation.net 
 Date: Thu,  8 Apr 2004 15:09:35 -0300 (ADT) 

 PERL_DL_NONLAZY=1 /usr/bin/perl5.8.0 "-MExtUtils::Command::MM" "-e" "test_harness(0, 'blib/lib', 'blib/arch')" t/Test/Tech/Tech.t
 t/Test/Tech/Tech....Can't locate FindBIN.pm

 Summary of my perl5 (revision 5.0 version 8 subversion 0) configuration:
   Platform:
     osname=linux, osvers=2.4.22-4tr, archname=i586-linux

This is capitalization problem. The program module name is 'FindBin' not 'FindBIN' which
is part of Perl. Microsoft does not care about capitalization differences while linux
does. This error is in the test script automatically generated by C<Test::STDmaker>
and was just introduced when moved test script libraries from C<tlib> to the directory
of the test script. Repaired C<Test::STDmaker> and regenerated the distribution.

\=item Test-Tech-0.20

B<FAILURE REPORT:>

 Subject: FAIL Test-Tech-0.19 i586-linux 2.4.22-4tr 
 To: cpan-testers@perl.org 
 From: cpansmoke@alternation.net 
 Date: Sat, 10 Apr 2004 05:07:51 -0300 (ADT) 

[snip]

Can't locate Data/Secs2.pm in @INC

[snip]

As such, adding the prerequisite module(s) to 'PREREQ_PM' in your
Makefile.PL should solve this problem.  For example:

 WriteMakefile(
     AUTHOR      => 'Samson Monaco Tutankhamen (support@SoftwareDiamonds.com)',
     ... # other information
     PREREQ_PM   => {
        'Data::Secs2'   => '0', # or a minimum workable version
     }
 );

[snip]

B<CORRECTIVE ACTION:>

An exam of MakeFile.PL revealed the following:

 WriteMakefile(
    # [snip]
    PREREQ_PM => {'Data::Secs2' => '0.01'},
    # [snip]
 );

Cannot see anything wrong with the PREREQ_PM statement.
The only possibilities that come to mind are
either CPAN not processing the prereq_pm properly,
same syntax problem with C<PREREQ_PM > 
or because the test script uses C<Test::Tech> 
to test C<Test::Tech>, the prereq is processed too late.

Added C<Data::Secs2> to the test library so the test
will run. 

\=item Test-Tech-0.21

For C<Test> module, version 1.20 or greater, changed so it sents failure messages
when skip flag turned on for C<&Test::Tech::ok> and C<&Test::Tech::ok>
out C<$Test::TESTERR> instead of C<$Test::TESTOUT>.

For C<&Test::Tech::finish> automatically generate failure messages
for all missing (not performed) test when the skip rest of tests
flag is on.

The C<FindBIN> that runs fine on Win because Win file spec is case insensitive
and Unix whats case sensitive C<FindBin> was fixed with on test C<Test::Test>.
However, overlooked all the test scripts that the top test script runs,
grabs the output and compares to expected ouput stored in files.
Corrected the C<FindBin> for following test software: 
C<TechA0.t TechB0.t TechC0.t TechD0.d TechE0.t>

\=item Test-Tech-0.22

The C<Data::SecsPack> program module is now required to run the C<Test::Tech>
program module. Added a print out of the C<Data::SecsPack> version to the
C<plan> subroutine as follows:

 # Data::Secs2   : $Data::SecsPack::VERSION

\=item Test-Tech-0.23

Added C<is_skip> ok_sub and skip_sub subroutines.

Added reporting of C<Data::Secs2::stringify()> errors. Correctly stringify
Perl data structures is not straight forward. Unlike C<Test> and C<Test::Tech>,
C<Data::Secs2> is very large including walks of Perl data structures, processing
of underlying data types such as C<CODE> and many other areas where there may
be unanticipated Perl data structure issues not properly addressed. 
Thus, best to have error detection in place, and stop testing if 
there is a broken C<Data::Secs2::stringify()>.

Changed the look of the C<demo> subroutine output to better resemble Perl code. 
Print the code straight forward without leading '=>'. Put a Perl comment '# ' in front of
each result line instead of printing it straing forward.

Added a print out of the C<Data::Start> version and number of tests to the
C<plan> subroutine.

\=item Test-Tech-0.24

None of the test script for 0.23 ran. It appears that the Data::Secs2 does not
load properly and, thus, none of the test scripts execute

 t/Test/Tech/Tech....Data::Secs2 version 1.22 required--this is only version 1.19 

Seen this before were CPAN has troubles with C<WriteMakefile> subroutine in
the C<MakeFile.PL>

    PREREQ_PM => {'Data::Secs2' => '1.22',
                  'Data::SecsPack' => '0.06',
                  'Data::Startup' => '0.03',
                  'Test' => '1.20',},

Put the correct version in the test library, upload and see if this is the
problem. 

\=item Test-Tech-0.25

It is unclear whether the failures to Test-Tech-0.24 is because of CPAN setup.

t/Test/Tech/Tech....Perl lib version (v5.8.4) doesn't match executable version (v5.6.1) at /usr/local/perl-5.8.4/lib/5.8.4/sparc-linux/Config.pm line 32.
Compilation failed in require at /usr/local/perl-5.8.4/lib/5.8.4/FindBin.pm line 97.

Since cannot get a response from the tester, bump the version to force a retest.

\=item Test-Tech-0.26

Changed C<Data::Secs2> so no longer loads C<Data::SecsPack> unless needed.
C<Test::Tech> no longer loads C<Data::SecsPack> via C<Data::secs2> so 
no longer print out its version. Instead print out the version of C<Data::Str2Num>
which is needed for the C<str2float> and C<str2integer> subroutines that
the C<Data::SecsPack> package supplied.

Test Failure:

Subject: FAIL Test-Tech-0.25 sparc-linux 2.4.21-pre7 
From: alian@cpan.org (alian) 

PERL_DL_NONLAZY=1 /usr/local/perl-5.8.4/bin/perl "-MExtUtils::Command::MM" "-e" "test_harness(0, 'blib/lib', 'blib/arch')" t/Test/Tech/Tech.t
t/Test/Tech/Tech....Perl lib version (v5.8.4) doesn't match executable version (v5.6.1) at /usr/local/perl-5.8.4/lib/5.8.4/sparc-linux/Config.pm line 32.
Compilation failed in require at /usr/local/perl-5.8.4/lib/5.8.4/FindBin.pm line 97.
BEGIN failed--compilation aborted at /usr/local/perl-5.8.4/lib/5.8.4/FindBin.pm line 97.
Compilation failed in require at techA0.t line 13.

Analysis:

Everything  was going well until a C<`perl $command`>. 
From same failure on other test scripts, the test harness perl executable is 
different than the command line perl executable. 

Corrective Action:

Introduced the C<perl_command> subroutine that uses C<$^^X> to return the current executable Perl
into the test script.
Use the results of this subroutine instead of 'perl' in backticks.

\=back

^

CAPABILITIES:
The system is the Perl programming language software.
As established by the Perl referenced documents,
program modules, such the 
"L<Test::Tech|Test::Tech>" module, extend the Perl language.

The "Test::Tech" module extends the capabilities of the "Test" module.

The design is simple. 
The "Test::Tech" module loads the "Test" module without exporting
any "Test" subroutines into the "Test::Tech" namespace.
There is a "Test::Tech" cover subroutine with the same name
for each "Test" module subroutine.
Each "Test::Tech" cover subroutine will call the &Test::$subroutine
before or after it adds any additional capabilities.
The "Test::Tech" module is a drop-in for the "Test" module.

The "L<Test::Tech|Test::Tech>" module extends the capabilities of
the "L<Test|Test>" module as follows:

\=over

\=item *

If the compared variables are references, 
stingifies the referenced variable by passing the reference
through I<Data::Dumper> before making the comparison.
Thus, L<Test::Tech|Test::Tech> can test almost any data structure. 
If the compare variables are not refernces, use the &Test::ok
and &Test::skip directly.

\=item *

Adds a method to skip the rest of the tests upon a critical failure

\=item *

Adds a method to generate demos that appear as an interactive
session using the methods under test

\=back

^

PROBLEMS:
Known issues are as follows:

\=over 4

\=item Merge with the "Test" module

The "Test::Tech" capabilites could be incorporated into the
"Test" program module and "Test::Tech" eliminated.

\=item TestLevel and Program_Lines

The "Test" module does not take the I<$TestLevel> value
into account where it chooses the module to load the
I<%Program_Line> hash. 
Since the L<Test::Tech> module adds a module layer in between
the L<Test> module that the test script, the I<$TestLevel>
must be set to 1. 
Thus, the L<Test> module loads the L<Test::Tech> module into
I<%Program_Line> hash instead of the Module Under Test.

\=back
^

DOCUMENT_OVERVIEW:
This document releases ${NAME} version ${VERSION}
providing description of the inventory, installation
instructions and other information necessary to
utilize and track this release.
^

LICENSE:
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

\=item 3

Commercial installation of the binary or source
must visually present to the installer 
the above copyright notice,
this list of conditions intact,
that the original source is available
at http://softwarediamonds.com
and provide means
for the installer to actively accept
the list of conditions; 
otherwise, a license fee must be paid to
Softwareware Diamonds.


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

INSTALLATION:
To installed the release file, use the CPAN module
pr PPM module in the Perl release
or the INSTALL.PL script at the following web site:

 http://packages.SoftwareDiamonds.com

Follow the instructions for the the chosen installation software.

If all else fails, the file may be manually installed.
Enter one of the following repositories in a web browser:

${REPOSITORY}

Right click on '${DIST_FILE}' and download to a temporary
installation directory.
Enter the following where $make is 'nmake' for microsoft
windows; otherwise 'make'.

 gunzip ${BASE_DIST_FILE}.tar.${COMPRESS_SUFFIX}
 tar -xf ${BASE_DIST_FILE}.tar
 perl Makefile.PL
 $make test
 $make install

On Microsoft operating system, nmake, tar, and gunzip 
must be in the exeuction path. If tar and gunzip are
not install, download and install unxutils from

 http://packages.softwarediamonds.com
^

SUPPORT: 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>^

NOTES:
The following are useful acronyms:

\=over 4

\=item .d

extension for a Perl demo script file

\=item .pm

extension for a Perl Library Module

\=item .t

extension for a Perl test script file

\=back
^

SEE_ALSO: 
\=over 4

\=item L<Test::Tech|Test::Tech> 

\=item L<Docs::US_DOD::SVD|Docs::US_DOD::SVD> 

\=back
^


HTML:
^
~-~



























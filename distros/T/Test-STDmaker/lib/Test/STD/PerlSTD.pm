#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Test::STD::PerlSTD;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '1.08';
$DATE = '2004/05/19';

1

__END__

=head1 NAME

Test::STD::PerlSTD - General Perl Software Test Description (STD)

=head1 TITLE PAGE

 Gerneral Software Test Description (STD)

 for

 Perl Program Modules

 Revision: -

 Date: 2004/05/15

 Prepared for: General Public 

 Prepared by:  http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com

 Classification: None

=head1 1. Scope

This general Software Test Decription (STD) for a Perl Program Module (PM).
Together with a detail STD for a Perl Program Module
it establishes the tests to verify the
requirements of specific Perl Program Module (PM).

In order to avoid duplications (i.e boiler plates),
the Perl STD is divided into this general Perl STD
and a detail STD for each program module test.
This is encourage if not in fact required by
L<490A 3.1.2|Docs::US_DOD::490A/3.1.2 Coverage of specifications.>

=head2 1.1 Identification

The package name C<Test::STDmaker::PerSTD> uniquely identfies
this source of this document.
The source is Perl Plain Old Documentation (POD) that may
be rendered into any number of different media and paper formats
by POD translators.

=head2 1.2 System overview

The system is the Perl programming language software.
Perl program modules extend the Perl language.
The focus of this STD is the testing of a particular
Perl program module.

=head2 1.3 Document overview

This general STD establishes the common procedures,
conventions used to prepare and run tests to verify Perl
program modules.
The L<STD DID preprations intructions|Docs::US_DOD::SVD/10. PREPARATION INSTRUCTIONS>
encourages automation, tailoring and allows for different types of media
including data bases and software engineering tools.
This general STD establishes an automation scheme based on the
C<Test::STDmaker|Test::STDmaker> module.
This may or may not be suitable for delivery for a specific end-user.
As per the license agreement herein, Software Diamonds, does not claim and
is not reponsbile for the fitness of this general STD for any specific
use or purpose.

=item 2. REFERENCE DOCUMENTS

Tailoring renames this section to I<SEE ALSO> and
moved it to the end of the document.
This is the customary location for this info
for the Unix community and where the Unix
community expects to find this information.
A special POD translator would move this to
sectin 2 and number it section 2.

=head1 3. TEST PREPARATIONS

=head2 3.x (Project-unique identifier of a test)

A STD test for this general STD and
its associated detail STDs is a Perl test script where the convention
is for test scripts to have an extension of C<.t>.
There must be at least one or more than one test script to verify a
Perl program module.
Each test script is uniquely identified by the
STD program module name used to generate the test script.

=head2 3.x.1 Hardware preparation

Usually there is no hardware preparation to
run a Perl test script.
The detail STD for a program module establishes
any exceptions.

=head2 3.x.2 Software preparation

Usually there is no Software preparation to
run a Perl test script.
The detail STD for a program module establishes
any exceptions.

=head2 3.x.3 Other pre-test preparations

Usually there is no pre-test preparations to
run a Perl test script.
The detail STD for a program module establishes
any exceptions.

=head1 4. TEST DESCRIPTIONS

Each test, corresponding to the 4.x paragraphs of a STD 
Data Item Description (DID),
is covered by its own individual detail STD program 
module.
The C<Test::STDmaker> program module subroutines uses
the data in each detail STD program module to generate
the detail STD POD and a test script.
The Perl convention is a test script prints
a line starting with C<ok> or C<not ok>
at the end of a Perl test (STD test case).
A test case for this general STD and its associated detail STDS is, 
thus, the Perl code 
in a test script starting
from the begining or the just after the
test script printing a line starting with C<ok> or C<not ok>
to and including the next printing of
a line starting with C<ok> or C<not ok> followed by
a number. 
The Perl test C<ok> number is the '.y' number for
a C<STD> test case.

In the tradition of detail sheets, 
the detail STD program module uses
a short hand notation that is used
by the C<Test::STDmaker> module to
automate the generation of test scripts
and other automation as follows:
 
 TEST DESCRIPTIONS

 ok: 1

 N: Test Name
 R: Requirements addressed:
 C: Test - Perl Code
 A: Test - Actual Results
 E: Expected test results


  ..


 ok: x

 N: Test Name
 R: Requirements addressed:
 C: Test - Perl Code
 A: Test - Actual Results
 E: Expected test results

=head2 4.x Project-unique identifier of a test

The project for this general STD is the 
creation of a Perl Program Module(s) (PM) and
a distribution file that contains the 
Perl Program Modules(s) and all the test scripts
necessary to verifiy the Perl Program Modules(s)
meets it requirements.
Each Perl test script is uniquely identified by
the name of the STD program module used to 
generate the test script.

=head2 4.x.y Project-unique identifier of a test case

The unique indentifier of a test case is the
number after C<ok> or C<not ok> that the test script
prints at the end of executing in Perl terminology a test.
The project-unique identifier for a STD test case is the 
name of the STD program module used to generate
the test script and the C<ok> number.
The STD program moudle POD will contain a 
C<=head 2 ok: y> number. 
Thus, where x is the name for the STD program module,
the POD link
C<test case|x/ok: y> 
will not only uniquely identify the STD test case
but also uniquely link to the STD test case (Perl test).

=head2 4.x.y.1 Requirements addressed

The C<R:> field in the detail STD POD program module for each test case, identifies
the requirements addressed.

=head2 4.x.y.2 Prerequisite conditions

The C<C:> and C<QC:> fields in the detail STD POD program module for each test case, identifies
the test inputs.

=head2 4.x.y.3 Test inputs.

The C<A:> field for in the detail STD sheet for each test case, identifies
the test inputs.

=head2 4.x.y.4 Expected test results.

The C<E:> field for in the detail STD sheet for each test case, identifies
the requirements addressed.

=head2 4.x.y.5 Criteria for evaluating results.

The critera for evaluation is normally the C<ok> subroutine of
the C<Test> program module that is has been in the Perl distribution
from the beginning.
THe C<ok> subroutine may be overriden by
the C<TS:> field in the detail STD sheet for each test case.

=head2 4.x.y.6 Test procedure

Following standard Perl conventions, the test scripts, 
detail STD program module, the program module under test,
and other appropriate files are bundled together in
a compressed, archive file. 
Running a test follows normal Perl conventions as follows:

 gunzip ${BASE_DIST_FILE}.tar.gz
 tar -xf ${BASE_DIST_FILE}.tar
 perl Makefile.PL
 $make test
 $make install

Where C<$make> is 'make' for most operating systems
and 'nmake' for Windows operating systems.

=head1 5. REQUIREMENTS TRACEABILITY

The requirements traceability for a program module are
established by the "REQUIREMENTS TRACEABILITY" section
of a detail STD sheet for a program module.
The detail STD "REQUIREMENTS TRACEABILITY" section
contains a requirements to test table and a 
test to requirements table.
The requirements and tests in the tables are
POD links to the appropriate Program Module
header. 

=head1 6. NOTES.

=head2 6.1 Copyright

This Perl Plain Old Documentation (POD) version is
copyright © 2001 2003 Software Diamonds.
This POD version was derived from
the hard copy public domain version freely distributed by
the United States Federal Government.

=head2 License

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

=head2 Copyright Holder Contact

E<lt> support@SoftwareDiamonds.comE <gt>


=head1 2. SEE ALSO (Referenced documents)

=over 4

=item L<Test::Tech|Test::Tech> 

=item L<Test|Test> 

=item L<Test::Harness|Test::Harness> 

=item L<Test::STDmaker::STD|Test::STDmaker::STD>

=item L<Test::STDmaker::Verify|Test::STDmaker::Verify>

=item L<Test::STDmaker::Demo|Test::STDmaker::Demo>

=item L<Test::STDmaker::Check|Test::STDmaker::Check>

=item L<Software Test Description|Docs::US_DOD::STD>

=item L<Specification Practices|Docs::US_DOD::STD490A>

=item L<Software Development|Docs::US_DOD::STD2167A>

=back

=cut

## end of file ##

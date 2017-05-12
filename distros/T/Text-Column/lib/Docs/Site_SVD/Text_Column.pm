#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Docs::Site_SVD::Text_Column;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.05';
$DATE = '2004/04/29';
$FILE = __FILE__;

use vars qw(%INVENTORY);
%INVENTORY = (
    'lib/Docs/Site_SVD/Text_Column.pm' => [qw(0.05 2004/04/29), 'revised 0.04'],
    'MANIFEST' => [qw(0.05 2004/04/29), 'generated, replaces 0.04'],
    'Makefile.PL' => [qw(0.05 2004/04/29), 'generated, replaces 0.04'],
    'README' => [qw(0.05 2004/04/29), 'generated, replaces 0.04'],
    'lib/Text/Column.pm' => [qw(1.11 2004/04/29), 'revised 1.1'],
    't/Text/Column.d' => [qw(0.01 2003/07/27), 'unchanged'],
    't/Text/Column.pm' => [qw(0.04 2004/04/29), 'revised 0.03'],
    't/Text/Column.t' => [qw(0.05 2003/09/15), 'unchanged'],
    't/Text/File/Package.pm' => [qw(1.16 2004/04/29), 'new'],
    't/Text/Test/Tech.pm' => [qw(1.21 2004/04/29), 'new'],
    't/Text/Data/Secs2.pm' => [qw(1.18 2004/04/29), 'new'],
    't/Text/Data/SecsPack.pm' => [qw(0.03 2004/04/29), 'new'],
    't/Text/Data/Startup.pm' => [qw(0.03 2004/04/29), 'new'],

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



=head1 Title Page

 Software Version Description

 for

 Text::Column - Format tables from hashes and arrays suitable for PODs

 Revision: D

 Version: 0.05

 Date: 2004/04/29

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

The "L<Text::Column|Text::Column>" module extends the Perl language (the system).

The US DOD 2167A software development standard creates and cites a
fully decent number of Data Item Descriptions (DID). 
A DID and US DOD 490A, Specification Practices, specify in
great detail the paragraph number, headings and the information
required for each paragraph in the document govern by the DID.

The usually approach is for suppliers of the DIDs to set up templates
and fill in the template with the missing information to complete the
DID document.

Different organizations use different degrees of automation. 
Some will have hard copy templates. Some will use word processor
templates. Others will use Visual Basic to merge database information
into a template. 

The methods in this module support a Perl automation of this processes.
by formatting raw array and hash data into tables for inclusion in PODS

=head2 1.3 Document overview.

This document releases Text::Column version 0.05
providing a description of the inventory, installation
instructions and other information necessary to
utilize and track this release.

=head1 3.0 VERSION DESCRIPTION

All file specifications in this SVD
use the Unix operating
system file specification.

=head2 3.1 Inventory of materials released.

This document releases the file 

 Text-Column-0.05.tar.gz

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
 lib/Docs/Site_SVD/Text_Column.pm                             0.05    2004/04/29 revised 0.04
 MANIFEST                                                     0.05    2004/04/29 generated, replaces 0.04
 Makefile.PL                                                  0.05    2004/04/29 generated, replaces 0.04
 README                                                       0.05    2004/04/29 generated, replaces 0.04
 lib/Text/Column.pm                                           1.11    2004/04/29 revised 1.1
 t/Text/Column.d                                              0.01    2003/07/27 unchanged
 t/Text/Column.pm                                             0.04    2004/04/29 revised 0.03
 t/Text/Column.t                                              0.05    2003/09/15 unchanged
 t/Text/File/Package.pm                                       1.16    2004/04/29 new
 t/Text/Test/Tech.pm                                          1.21    2004/04/29 new
 t/Text/Data/Secs2.pm                                         1.18    2004/04/29 new
 t/Text/Data/SecsPack.pm                                      0.03    2004/04/29 new
 t/Text/Data/Startup.pm                                       0.03    2004/04/29 new


=head2 3.3 Changes

The changes to the previous version are as follows:

=over 4

=item Test-STD-STDutil-0.01

=over 4

=item Rename Module

At 02:44 AM 6/14/2003 +0200, Max Maischein wrote: A second thing
that I would like you to reconsider is the naming of
"Test::TestUtil" respectively "Test::Tech" - neither of those is
descriptive of what the routines actually do or what the module
implements. I would recommend renaming them to something closer to
your other modules, maybe "Test::SVDMaker::Util" and
"Test::SVDMaker::Tech", as some routines do not seem to be specific
to the Test::-suite but rather general (format_array_table). Some
parts (the "scrub" routines) might even better live in another
module namespace, "Test::Util::ScrubData" or something like that.

Broke away the template and table routines from Test::TestUtil
created this module Test::STD::STDutil.

=back

=item Test-STD-STDutil-0.02

Use the new modules from the break-up of the "File::FileUtil" module

=item Text-Text-0.01

Broke up the "Test::STD::STDutil" module and moved it to more
appropriate places in the high level directory tree.

=item Text-Column-0.01

Changed name from Text::Table to Text::Column. Text::Table taken.

=item Text-Column-0.02

Change the test so that test support program modules resides in distribution
directory tlib directory instead of the lib directory. 
Because they are no longer in the lib directory, 
test support files will not be installed as a pre-condition for the 
test of this module.
The test of this module will precede immediately.
The test support files in the tlib directory will vanish after
the installtion.

=item Text-Column-0.03

Recreate distribution file 
with Archive::TarGzip 0.02 that uses mode 777 for directories instead of 666. Started to get
emails from Unix installers about untar not being able to change to
a directory with mode of 666.

=item Text-Column-0.04

Add the module 'Data::Secs2' in the tlib that provides 'stringify' support
for the 'Test::Tech' module.

=item Text-Column-0.05

The lastest build of Test::STDmaker expects the test library in the same
directory as the test script.
Coordiated with the lastest Test::STDmaker by moving the
test library from C<tlib> to C<t/Text>, the same directory as the test script
and deleting the test library File::TestPath program module.
CPAN software does not expect C<tlib> and does not properly process it.

Minor clean-up on the POD.

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

Right click on 'Text-Column-0.05.tar.gz' and download to a temporary
installation directory.
Enter the following where $make is 'nmake' for microsoft
windows; otherwise 'make'.

 gunzip Text-Column-0.05.tar.gz
 tar -xf Text-Column-0.05.tar
 perl Makefile.PL
 $make test
 $make install

On Microsoft operating system, nmake, tar, and gunzip 
must be in the exeuction path. If tar and gunzip are
not install, download and install unxutils from

 http://packages.softwarediamonds.com

=item Prerequistes.

 None.


=item Security, privacy, or safety precautions.

None.

=item Installation Tests.

Most Perl installation software will run the following test script(s)
as part of the installation:

 t/Text/Column.t

=item Installation support.

If there are installation problems or questions with the installation
contact

 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>

=back

=head2 3.7 Possible problems and known errors

There is still much work needed to ensure the quality 
of this module as follows:

=over 4

=item *

State the functional requirements for each method 
including not only the GO paths but also what to
expect for the NOGO paths

=item *

All the tests are GO path tests. Should add
NOGO tests.

=item *

Add the requirements addressed as I<# R: >
comment to the tests

=item *

Write a program to build a matrix to trace
test step to the requirements and vice versa by
parsing the I<# R: > comments.
Automatically insert the matrix in the
Test::TestUtil POD.

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

=item L<Text::Column|Text::Column> 

=item L<Docs::US_DOD::SVD|Docs::US_DOD::SVD> 

=back

=for html


=cut

1;

__DATA__

DISTNAME: Text-Column^
REPOSITORY_DIR: packages^

VERSION : 0.05^
FREEZE: 1^
PREVIOUS_DISTNAME:  ^
PREVIOUS_RELEASE: 0.04^
REVISION: D^

AUTHOR  : SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>^
ABSTRACT: Format tables from hashes and arrays suitable for PODs^
TITLE   : Text::Column - Format tables from hashes and arrays suitable for PODs^
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

RESTRUCTURE:  ^
CHANGE2CURRENT:  ^

AUTO_REVISE: 
lib/Text/Column.pm
t/Text/Column.*
lib/File/Package.pm => t/Text/File/Package.pm
lib/Test/Tech.pm => t/Text/Test/Tech.pm
lib/Data/Secs2.pm => t/Text/Data/Secs2.pm
lib/Data/SecsPack.pm => t/Text/Data/SecsPack.pm
lib/Data/Startup.pm => t/Text/Data/Startup.pm
^

PREREQ_PM:  ^
README_PODS: lib/Text/Column.pm^
TESTS: t/Text/Column.t^
EXE_FILES:  ^

CHANGES:
The changes to the previous version are as follows:

\=over 4

\=item Test-STD-STDutil-0.01

\=over 4

\=item Rename Module

At 02:44 AM 6/14/2003 +0200, Max Maischein wrote: A second thing
that I would like you to reconsider is the naming of
"Test::TestUtil" respectively "Test::Tech" - neither of those is
descriptive of what the routines actually do or what the module
implements. I would recommend renaming them to something closer to
your other modules, maybe "Test::SVDMaker::Util" and
"Test::SVDMaker::Tech", as some routines do not seem to be specific
to the Test::-suite but rather general (format_array_table). Some
parts (the "scrub" routines) might even better live in another
module namespace, "Test::Util::ScrubData" or something like that.

Broke away the template and table routines from Test::TestUtil
created this module Test::STD::STDutil.

\=back

\=item Test-STD-STDutil-0.02

Use the new modules from the break-up of the "File::FileUtil" module

\=item Text-Text-0.01

Broke up the "Test::STD::STDutil" module and moved it to more
appropriate places in the high level directory tree.

\=item Text-Column-0.01

Changed name from Text::Table to Text::Column. Text::Table taken.

\=item Text-Column-0.02

Change the test so that test support program modules resides in distribution
directory tlib directory instead of the lib directory. 
Because they are no longer in the lib directory, 
test support files will not be installed as a pre-condition for the 
test of this module.
The test of this module will precede immediately.
The test support files in the tlib directory will vanish after
the installtion.

\=item Text-Column-0.03

Recreate distribution file 
with Archive::TarGzip 0.02 that uses mode 777 for directories instead of 666. Started to get
emails from Unix installers about untar not being able to change to
a directory with mode of 666.

\=item Text-Column-0.04

Add the module 'Data::Secs2' in the tlib that provides 'stringify' support
for the 'Test::Tech' module.

\=item Text-Column-0.05

The lastest build of Test::STDmaker expects the test library in the same
directory as the test script.
Coordiated with the lastest Test::STDmaker by moving the
test library from C<tlib> to C<t/Text>, the same directory as the test script
and deleting the test library File::TestPath program module.
CPAN software does not expect C<tlib> and does not properly process it.

Minor clean-up on the POD.

\=back

^

DOCUMENT_OVERVIEW:
This document releases ${NAME} version ${VERSION}
providing a description of the inventory, installation
instructions and other information necessary to
utilize and track this release.
^

CAPABILITIES:
The "L<Text::Column|Text::Column>" module extends the Perl language (the system).

The US DOD 2167A software development standard creates and cites a
fully decent number of Data Item Descriptions (DID). 
A DID and US DOD 490A, Specification Practices, specify in
great detail the paragraph number, headings and the information
required for each paragraph in the document govern by the DID.

The usually approach is for suppliers of the DIDs to set up templates
and fill in the template with the missing information to complete the
DID document.

Different organizations use different degrees of automation. 
Some will have hard copy templates. Some will use word processor
templates. Others will use Visual Basic to merge database information
into a template. 

The methods in this module support a Perl automation of this processes.
by formatting raw array and hash data into tables for inclusion in PODS
^

PROBLEMS:
There is still much work needed to ensure the quality 
of this module as follows:

\=over 4

\=item *

State the functional requirements for each method 
including not only the GO paths but also what to
expect for the NOGO paths

\=item *

All the tests are GO path tests. Should add
NOGO tests.

\=item *

Add the requirements addressed as I<# R: >
comment to the tests

\=item *

Write a program to build a matrix to trace
test step to the requirements and vice versa by
parsing the I<# R: > comments.
Automatically insert the matrix in the
Test::TestUtil POD.

\=back

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

\=item L<Text::Column|Text::Column> 

\=item L<Docs::US_DOD::SVD|Docs::US_DOD::SVD> 

\=back
^


HTML:

^
~-~



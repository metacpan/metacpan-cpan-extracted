#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Docs::Site_SVD::Text_Scrub;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.08';
$DATE = '2004/05/25';
$FILE = __FILE__;

use vars qw(%INVENTORY);
%INVENTORY = (
    'lib/Docs/Site_SVD/Text_Scrub.pm' => [qw(0.08 2004/05/25), 'revised 0.07'],
    'MANIFEST' => [qw(0.08 2004/05/25), 'generated, replaces 0.07'],
    'Makefile.PL' => [qw(0.08 2004/05/25), 'generated, replaces 0.07'],
    'README' => [qw(0.08 2004/05/25), 'generated, replaces 0.07'],
    'lib/Text/Scrub.pm' => [qw(1.17 2004/05/25), 'revised 1.16'],
    't/Text/Scrub.d' => [qw(0.03 2004/05/10), 'unchanged'],
    't/Text/Scrub.pm' => [qw(0.03 2004/05/10), 'unchanged'],
    't/Text/Scrub.t' => [qw(0.1 2004/05/10), 'unchanged'],
    't/Text/File/Package.pm' => [qw(1.18 2004/05/25), 'unchanged'],
    't/Text/Test/Tech.pm' => [qw(1.26 2004/05/25), 'unchanged'],
    't/Text/Data/Secs2.pm' => [qw(1.26 2004/05/25), 'unchanged'],
    't/Text/File/SmartNL.pm' => [qw(1.16 2004/05/25), 'unchanged'],
    't/Text/Data/Str2Num.pm' => [qw(0.08 2004/05/25), 'unchanged'],
    't/Text/Data/Startup.pm' => [qw(0.07 2004/05/25), 'unchanged'],

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

Docs::Site_SVD::Text_Scrub - Utilites to wild card parts of a text file for comparisons.

=head1 Title Page

 Software Version Description

 for

 Docs::Site_SVD::Text_Scrub - Utilites to wild card parts of a text file for comparisons.

 Revision: G

 Version: 0.08

 Date: 2004/05/25

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

The "L<Text::Scrub|Text::Scrub>" module extends the Perl language (the system).

When comparing text there are small snippets such as version numbers and dates
that should be wild carded out and not influence the comparisions.
The Test::STD:Scrub module replaces these small snippets with invariant snippet.
By replacing the same part of each file with the same invariant snippet,
those small sections of text are effectively wild carded for the comparisions.

When performing tests, the ability to wild card small snippets of text is
vital in making accurate comparison. 
The same capability is also essential for version control in comparing two
pieces of software to see if there are significant changes.

=head2 1.3 Document overview.

This document releases Text::Scrub version 0.08
providing a description of the inventory, installation
instructions and other information necessary to
utilize and track this release.

=head1 3.0 VERSION DESCRIPTION

All file specifications in this SVD
use the Unix operating
system file specification.

=head2 3.1 Inventory of materials released.

This document releases the file 

 Text-Scrub-0.08.tar.gz

found at the following repository(s):

  http://www.softwarediamonds/packages/
  http://www.perl.com/CPAN/authors/id/S/SO/SOFTDIA/

Restrictions regarding duplication and license provisions
are as follows:

=over 4

=item Copyright.

copyright © 2003 Software Diamonds

=item Copyright holder contact.

 603 882-0846 E<lt> support@SoftwareDiamonds.com E<gt>

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
 lib/Docs/Site_SVD/Text_Scrub.pm                              0.08    2004/05/25 revised 0.07
 MANIFEST                                                     0.08    2004/05/25 generated, replaces 0.07
 Makefile.PL                                                  0.08    2004/05/25 generated, replaces 0.07
 README                                                       0.08    2004/05/25 generated, replaces 0.07
 lib/Text/Scrub.pm                                            1.17    2004/05/25 revised 1.16
 t/Text/Scrub.d                                               0.03    2004/05/10 unchanged
 t/Text/Scrub.pm                                              0.03    2004/05/10 unchanged
 t/Text/Scrub.t                                               0.1     2004/05/10 unchanged
 t/Text/File/Package.pm                                       1.18    2004/05/25 unchanged
 t/Text/Test/Tech.pm                                          1.26    2004/05/25 unchanged
 t/Text/Data/Secs2.pm                                         1.26    2004/05/25 unchanged
 t/Text/File/SmartNL.pm                                       1.16    2004/05/25 unchanged
 t/Text/Data/Str2Num.pm                                       0.08    2004/05/25 unchanged
 t/Text/Data/Startup.pm                                       0.07    2004/05/25 unchanged


=head2 3.3 Changes

The changes are as follows:

=over 4

=item Test-STD-Scrub-0.01

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

Broke away the "scrub" routines from Test::TestUtil
created this module Test::STD::Scrub.

=item new methods

Added the scrub_data and scrub_probe methods

=back

=item Test-STD-Scrub-0.02

Use the new modules from the break-up of the "File::FileUtil" module

=item Text-Scrub-0.01

Moved to a more appropriate library location.

=item Text-Scrub-0.02

Change the test so that test support program modules resides in distribution
directory tlib directory instead of the lib directory. 
Because they are no longer in the lib directory, 
test support files will not be installed as a pre-condition for the 
test of this module.
The test of this module will precede immediately.
The test support files in the tlib directory will vanish after
the installtion.

=item Text-Scrub-0.03

Recreate distribution file 
with Archive::TarGzip 0.02 that uses mode 777 for directories instead of 666. Started to get
emails from Unix installers about untar not being able to change to
a directory with mode of 666.

=item Text-Scrub-0.04

Changes the 'stringify' module for 'Test-Tech' from
'Data::Strify' to 'Data::Secs2'.

=item Text-Scrub-0.05

The lastest build of Test::STDmaker expects the test library in the same
directory as the test script.
Coordiated with the lastest Test::STDmaker by moving the
test library from tlib to t/Text, the same directory as the test script
and deleting the test library File::TestPath program module.

Added "SEE ALSO" section. Reworked QUALITY ASSURANCE and NOTES sections.

=item Text-Scrub-0.06

Cleaned up POD. Add C<scrub_architect> to C<OK_EXPORT>.

=item Text-Scrub-0.07

Added code to the C<scrub_file_line> subroutine to change double quotes
around numbers to single quotes 

=item Text-Scrub-0.08

Added code to the C<scrub_architect> subroutine to C<OS NAME> to
C<Site OS>.

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

Right click on 'Text-Scrub-0.08.tar.gz' and download to a temporary
installation directory.
Enter the following where $make is 'nmake' for microsoft
windows; otherwise 'make'.

 gunzip Text-Scrub-0.08.tar.gz
 tar -xf Text-Scrub-0.08.tar
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

 t/Text/Scrub.t

=item Installation support.

If there are installation problems or questions with the installation
contact

 603 882-0846 E<lt> support@SoftwareDiamonds.com E<gt>

=back

=head2 3.7 Possible problems and known errors

There is still much work needed to ensure the quality 
of this module as follows:

=over 4

=item *

State the functional requirements for each method 
including not only the GO paths but also what to
expect for the NOGO paths

=back

=head1 4.0 NOTES

The following are useful acronyms:

=over 4

=item .pm

extension for a Perl Library Module

=item .t

extension for a Perl test script file

=back

=head1 2.0 SEE ALSO

=over 4

=item L<Text::Scrub|Text::Scrub> 

=item L<Docs::US_DOD::SVD|Docs::US_DOD::SVD> 

=item L<Docs::US_DOD::STD|Docs::US_DOD::STD> 

=back

=for html


=cut

1;

__DATA__

DISTNAME: Text-Scrub^
REPOSITORY_DIR: packages^

VERSION : 0.08^
FREEZE: 1^
PREVIOUS_DISTNAME:  ^
PREVIOUS_RELEASE: 0.07^
REVISION: G^

AUTHOR  : SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>^
ABSTRACT: Utilites to wild card parts of a text file for comparisons.^
TITLE   : Docs::Site_SVD::Text_Scrub - Utilites to wild card parts of a text file for comparisons.^
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
lib/Text/Scrub.pm
t/Text/Scrub.*
lib/File/Package.pm => t/Text/File/Package.pm
lib/Test/Tech.pm => t/Text/Test/Tech.pm
lib/Data/Secs2.pm => t/Text/Data/Secs2.pm
lib/File/SmartNL.pm => t/Text/File/SmartNL.pm
lib/Data/Str2Num.pm => t/Text/Data/Str2Num.pm
lib/Data/Startup.pm => t/Text/Data/Startup.pm
^

PREREQ_PM:  ^
README_PODS: lib/Text/Scrub.pm^
TESTS: t/Text/Scrub.t^

EXE_FILES:  ^
CHANGES:

The changes are as follows:

\=over 4

\=item Test-STD-Scrub-0.01

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

Broke away the "scrub" routines from Test::TestUtil
created this module Test::STD::Scrub.

\=item new methods

Added the scrub_data and scrub_probe methods

\=back

\=item Test-STD-Scrub-0.02

Use the new modules from the break-up of the "File::FileUtil" module

\=item Text-Scrub-0.01

Moved to a more appropriate library location.

\=item Text-Scrub-0.02

Change the test so that test support program modules resides in distribution
directory tlib directory instead of the lib directory. 
Because they are no longer in the lib directory, 
test support files will not be installed as a pre-condition for the 
test of this module.
The test of this module will precede immediately.
The test support files in the tlib directory will vanish after
the installtion.

\=item Text-Scrub-0.03

Recreate distribution file 
with Archive::TarGzip 0.02 that uses mode 777 for directories instead of 666. Started to get
emails from Unix installers about untar not being able to change to
a directory with mode of 666.

\=item Text-Scrub-0.04

Changes the 'stringify' module for 'Test-Tech' from
'Data::Strify' to 'Data::Secs2'.

\=item Text-Scrub-0.05

The lastest build of Test::STDmaker expects the test library in the same
directory as the test script.
Coordiated with the lastest Test::STDmaker by moving the
test library from tlib to t/Text, the same directory as the test script
and deleting the test library File::TestPath program module.

Added "SEE ALSO" section. Reworked QUALITY ASSURANCE and NOTES sections.

\=item Text-Scrub-0.06

Cleaned up POD. Add C<scrub_architect> to C<OK_EXPORT>.

\=item Text-Scrub-0.07

Added code to the C<scrub_file_line> subroutine to change double quotes
around numbers to single quotes 

\=item Text-Scrub-0.08

Added code to the C<scrub_architect> subroutine to C<OS NAME> to
C<Site OS>.

\=back

^

DOCUMENT_OVERVIEW:
This document releases ${NAME} version ${VERSION}
providing a description of the inventory, installation
instructions and other information necessary to
utilize and track this release.
^

CAPABILITIES:
The "L<Text::Scrub|Text::Scrub>" module extends the Perl language (the system).

When comparing text there are small snippets such as version numbers and dates
that should be wild carded out and not influence the comparisions.
The Test::STD:Scrub module replaces these small snippets with invariant snippet.
By replacing the same part of each file with the same invariant snippet,
those small sections of text are effectively wild carded for the comparisions.

When performing tests, the ability to wild card small snippets of text is
vital in making accurate comparison. 
The same capability is also essential for version control in comparing two
pieces of software to see if there are significant changes.

^

PROBLEMS:
There is still much work needed to ensure the quality 
of this module as follows:

\=over 4

\=item *

State the functional requirements for each method 
including not only the GO paths but also what to
expect for the NOGO paths

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

SUPPORT: 603 882-0846 E<lt> support@SoftwareDiamonds.com E<gt>
^

NOTES:
The following are useful acronyms:

\=over 4

\=item .pm

extension for a Perl Library Module

\=item .t

extension for a Perl test script file

\=back
^

SEE_ALSO: 

\=over 4

\=item L<Text::Scrub|Text::Scrub> 

\=item L<Docs::US_DOD::SVD|Docs::US_DOD::SVD> 

\=item L<Docs::US_DOD::STD|Docs::US_DOD::STD> 

\=back
^


HTML:

^
~-~















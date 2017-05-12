#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Docs::Site_SVD::Tie_Eudora;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.01';
$DATE = '2004/05/29';
$FILE = __FILE__;

use vars qw(%INVENTORY);
%INVENTORY = (
    'lib/Docs/Site_SVD/Tie_Eudora.pm' => [qw(0.01 2004/05/29), 'new'],
    'MANIFEST' => [qw(0.01 2004/05/29), 'generated new'],
    'Makefile.PL' => [qw(0.01 2004/05/29), 'generated new'],
    'README' => [qw(0.01 2004/05/29), 'generated new'],
    'lib/Tie/Eudora.pm' => [qw(0.01 2004/05/29), 'new'],
    't/Tie/Eudora.d' => [qw(0.01 2004/05/29), 'new'],
    't/Tie/Eudora.pm' => [qw(0.01 2004/05/29), 'new'],
    't/Tie/Eudora.t' => [qw(0.01 2004/05/29), 'new'],
    't/Tie/Eudora2.mbx' => [qw(0.01 2004/05/29), 'new'],
    't/Tie/File/SmartNL.pm' => [qw(1.16 2004/05/29), 'new'],
    't/Tie/File/Package.pm' => [qw(1.18 2004/05/29), 'new'],
    't/Tie/Test/Tech.pm' => [qw(1.27 2004/05/29), 'new'],
    't/Tie/Data/Secs2.pm' => [qw(1.26 2004/05/29), 'new'],
    't/Tie/Data/Str2Num.pm' => [qw(0.08 2004/05/29), 'new'],

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

Docs::Site_SVD::Tie_Eudora - encode/decode emails, read/write emails in Eudora mailbox files

=head1 Title Page

 Software Version Description

 for

 Docs::Site_SVD::Tie_Eudora - encode/decode emails, read/write emails in Eudora mailbox files

 Revision: -

 Version: 0.01

 Date: 2004/05/29

 Prepared for: General Public 

 Prepared by:  SoftwareDiamonds.com E<lt> support@SoftwareDiamonds.comE <gt>

 Copyright: copyright © 2004 Software Diamonds

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

The C<Tie::Eudora> program module provides a File Handle Tie package
for reading and writing of Eudora mailbox files. 
The C<Tie::Eudora> package handles each email in Eudora
mailbox files as a record.
Each record is read and written not as a scalar text string but
as an array of C<field-name, field-body> pairs corresponding
to the header and body fields in the email.

=head2 1.3 Document overview.

This document releases Tie::Eudora version 0.01
providing description of the inventory, installation
instructions and other information necessary to
utilize and track this release.

=head1 3.0 VERSION DESCRIPTION

All file specifications in this SVD
use the Unix operating
system file specification.

=head2 3.1 Inventory of materials released.

This document releases the file 

 Tie-Eudora-0.01.tar.gz

found at the following repository(s):

  http://www.softwarediamonds/packages/
  http://www.perl.com/CPAN/authors/id/S/SO/SOFTDIA/

Restrictions regarding duplication and license provisions
are as follows:

=over 4

=item Copyright.

copyright © 2004 Software Diamonds

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
 lib/Docs/Site_SVD/Tie_Eudora.pm                              0.01    2004/05/29 new
 MANIFEST                                                     0.01    2004/05/29 generated new
 Makefile.PL                                                  0.01    2004/05/29 generated new
 README                                                       0.01    2004/05/29 generated new
 lib/Tie/Eudora.pm                                            0.01    2004/05/29 new
 t/Tie/Eudora.d                                               0.01    2004/05/29 new
 t/Tie/Eudora.pm                                              0.01    2004/05/29 new
 t/Tie/Eudora.t                                               0.01    2004/05/29 new
 t/Tie/Eudora2.mbx                                            0.01    2004/05/29 new
 t/Tie/File/SmartNL.pm                                        1.16    2004/05/29 new
 t/Tie/File/Package.pm                                        1.18    2004/05/29 new
 t/Tie/Test/Tech.pm                                           1.27    2004/05/29 new
 t/Tie/Data/Secs2.pm                                          1.26    2004/05/29 new
 t/Tie/Data/Str2Num.pm                                        0.08    2004/05/29 new


=head2 3.3 Changes

Changes to previous revisions are as follows:

=over 4

=item Tie::Eudora 0.01

Originated

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

Right click on 'Tie-Eudora-0.01.tar.gz' and download to a temporary
installation directory.
Enter the following where $make is 'nmake' for microsoft
windows; otherwise 'make'.

 gunzip Tie-Eudora-0.01.tar.gz
 tar -xf Tie-Eudora-0.01.tar
 perl Makefile.PL
 $make test
 $make install

On Microsoft operating system, nmake, tar, and gunzip 
must be in the exeuction path. If tar and gunzip are
not install, download and install unxutils from

 http://packages.softwarediamonds.com

=item Prerequistes.

 'Tie::Layers' => '0.06',
 'Data::Startup' => '0.08',


=item Security, privacy, or safety precautions.

None.

=item Installation Tests.

Most Perl installation software will run the following test script(s)
as part of the installation:

 t/Tie/Eudora.t

=item Installation support.

If there are installation problems or questions with the installation
contact

 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>

=back

=head2 3.7 Possible problems and known errors

There are no known open issues.

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

=item L<Tie::Eudora|Tie::Eudora>

=back

=for html


=cut

1;

__DATA__

DISTNAME: Tie-Eudora^
REPOSITORY_DIR: packages^

VERSION : 0.01^
FREEZE: 0^
PREVIOUS_DISTNAME: ^
PREVIOUS_RELEASE: ^
REVISION: - ^

AUTHOR  : SoftwareDiamonds.com E<lt> support@SoftwareDiamonds.comE <gt>^
ABSTRACT: read/write emails in Eudora mailbox files^

TITLE   : Docs::Site_SVD::Tie_Eudora - encode/decode emails, read/write emails in Eudora mailbox files^
END_USER: General Public^
COPYRIGHT: copyright © 2004 Software Diamonds^
CLASSIFICATION: NONE^
TEMPLATE:  ^
CSS: help.css^
SVD_FSPEC: Unix^

COMPRESS: gzip^
COMPRESS_SUFFIX: gz^

REPOSITORY: 
  http://www.softwarediamonds/packages/
  http://www.perl.com/CPAN/authors/id/S/SO/SOFTDIA/
^

RESTRUCTURE:  ^
CHANGE2CURRENT:  ^

AUTO_REVISE:
lib/Tie/Eudora.pm
t/Tie/Eudora*
lib/File/SmartNL.pm => t/Tie/File/SmartNL.pm
lib/File/Package.pm => t/Tie/File/Package.pm
lib/Test/Tech.pm => t/Tie/Test/Tech.pm
lib/Data/Secs2.pm => t/Tie/Data/Secs2.pm
lib/Data/Str2Num.pm => t/Tie/Data/Str2Num.pm
^

PREREQ_PM: 
'Tie::Layers' => '0.06',
'Data::Startup' => '0.08',
^
README_PODS: lib/Tie/Eudora.pm^
TESTS: t/Tie/Eudora.t ^
EXE_FILES:  ^

CHANGES:
Changes to previous revisions are as follows:

\=over 4

\=item Tie::Eudora 0.01

Originated

\=back
^

DOCUMENT_OVERVIEW:
This document releases ${NAME} version ${VERSION}
providing description of the inventory, installation
instructions and other information necessary to
utilize and track this release.
^

CAPABILITIES:
The C<Tie::Eudora> program module provides a File Handle Tie package
for reading and writing of Eudora mailbox files. 
The C<Tie::Eudora> package handles each email in Eudora
mailbox files as a record.
Each record is read and written not as a scalar text string but
as an array of C<field-name, field-body> pairs corresponding
to the header and body fields in the email.
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

SUPPORT: 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>
^


PROBLEMS:
There are no known open issues.
^

SUPPORT:
603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>
^

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

\=item L<Tie::Eudora|Tie::Eudora>

\=back

^

HTML: ^

~-~













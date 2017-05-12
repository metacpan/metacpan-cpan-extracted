#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Docs::Site_SVD::Tie_Layers;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.06';
$DATE = '2004/05/28';
$FILE = __FILE__;

use vars qw(%INVENTORY);
%INVENTORY = (
    'lib/Docs/Site_SVD/Tie_Layers.pm' => [qw(0.06 2004/05/28), 'revised 0.05'],
    'MANIFEST' => [qw(0.06 2004/05/28), 'generated, replaces 0.05'],
    'Makefile.PL' => [qw(0.06 2004/05/28), 'generated, replaces 0.05'],
    'README' => [qw(0.06 2004/05/28), 'generated, replaces 0.05'],
    'lib/Tie/Layers.pm' => [qw(0.06 2004/05/28), 'revised 0.05'],
    't/Tie/Layers.pm' => [qw(0.03 2004/05/28), 'revised 0.02'],
    't/Tie/Layers.t' => [qw(0.03 2004/05/28), 'revised 0.02'],
    't/Tie/Layers.d' => [qw(0.03 2004/05/28), 'revised 0.02'],
    't/Tie/File/Package.pm' => [qw(1.18 2004/05/28), 'unchanged'],
    't/Tie/Test/Tech.pm' => [qw(1.27 2004/05/28), 'revised 1.26'],
    't/Tie/Data/Secs2.pm' => [qw(1.26 2004/05/28), 'unchanged'],
    't/Tie/Data/Str2Num.pm' => [qw(0.08 2004/05/28), 'unchanged'],
    't/Tie/Data/Startup.pm' => [qw(0.08 2004/05/28), 'new'],

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

Docs::Site_SVD::Tie_Layers - read and write files pipelined through a stack of subroutine layers

=head1 Title Page

 Software Version Description

 for

 Docs::Site_SVD::Tie_Layers - read and write files pipelined through a stack of subroutine layers

 Revision: E

 Version: 0.06

 Date: 2004/05/28

 Prepared for: General Public 

 Prepared by:  SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>

 Copyright: copyright 2004 Software Diamonds

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

The C<Tie::Layers> program module contains the tie file handle C<Tie::Layers>
package.
The C<Tie::Layers> package provides the ability to insert a stack of subroutines between
file subroutines C<print> and C<realine> and the underlying C<$file>.
The syntax of the subroutines of each layer of the readline stack and the print
stack must comply to the
the requirements described herein below.
This is necessary so that the C<Tie::Layers> C<READLINE> and C<PRINT> subroutines
know how to transfer the output from one layer to the input of another layer.
The stacks are setup by supplying options with a reference to
the subroutine for each layer in the print stack and the readline stack.
The C<Tie::Layers> are line orientated and do not support any character
file subrouintes. The C<getc>, C<read>, and C<write> file subroutines
are supported by the C<Tie::Layers> package. The seek routines are line
oriented in that the C<seek> and C<tell> subroutine positions are the line
in the underlying file and not the character position in the file.

=head2 1.3 Document overview.

This document releases Tie::Layers version 0.06
providing a description of the inventory, installation
instructions and other information necessary to
utilize and track this release.

=head1 3.0 VERSION DESCRIPTION

All file specifications in this SVD
use the Unix operating
system file specification.

=head2 3.1 Inventory of materials released.

This document releases the file 

 Tie-Layers-0.06.tar.gz

found at the following repository(s):

  http://www.softwarediamonds/packages/
  http://www.perl.com/CPAN/authors/id/S/SO/SOFTDIA/

Restrictions regarding duplication and license provisions
are as follows:

=over 4

=item Copyright.

copyright 2004 Software Diamonds

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
 lib/Docs/Site_SVD/Tie_Layers.pm                              0.06    2004/05/28 revised 0.05
 MANIFEST                                                     0.06    2004/05/28 generated, replaces 0.05
 Makefile.PL                                                  0.06    2004/05/28 generated, replaces 0.05
 README                                                       0.06    2004/05/28 generated, replaces 0.05
 lib/Tie/Layers.pm                                            0.06    2004/05/28 revised 0.05
 t/Tie/Layers.pm                                              0.03    2004/05/28 revised 0.02
 t/Tie/Layers.t                                               0.03    2004/05/28 revised 0.02
 t/Tie/Layers.d                                               0.03    2004/05/28 revised 0.02
 t/Tie/File/Package.pm                                        1.18    2004/05/28 unchanged
 t/Tie/Test/Tech.pm                                           1.27    2004/05/28 revised 1.26
 t/Tie/Data/Secs2.pm                                          1.26    2004/05/28 unchanged
 t/Tie/Data/Str2Num.pm                                        0.08    2004/05/28 unchanged
 t/Tie/Data/Startup.pm                                        0.08    2004/05/28 new


=head2 3.3 Changes

Changes are as follows

=over 4

=item Tie::Layers-0.01

Originated

=item Tie::Layers-0.02

Sometimes get a C<DESTROY> when coming out of C<TIEHANDLE>. Do not
want C<TIEHANDLE> going around closing stuff, especially for an
C<OPEN> with a file handle like C<DATA>. 
If something needs closing, call CLOSE directly.  

=item Tie::Layers-0.03

Added C<Data::Startup> as perquisite.

=item Tie::Layers-0.04

Perquisite did not make it into 0.03. Try again.

=item Tie::Layers-0.05

Test Failure:

 From: mhoyt@houston.rr.com 
 Subject: FAIL Tie-Layers-0.04 darwin-thread-multi-2level 7.0 

 t/Tie/Layers.t
 t/Tie/Layers....Math::BigFloat version 1.4 required--this is only version 1.39 

Annalysis:

This is because using C<Data::Secs2> to stringify test results for comparision.
The C<Data::Secs2> includes C<Data::SecsPack> which includes C<Math::BigFloat>.
There C<Makerfile.PL> prerequisite is only for the Unit Under Test (UUT) software,
not the test software.

Corrective Action:

Since C<Data::SecsPack> is not needed for C<Data::Secs2> stringify, 
rewrote C<Data::Secs2> to include C<Data::SecsPack> only if needed. 
Thus, the test software will not longer be requiring C<Math::BigFloat>.

Also drop the C<Data::SecsPack> version for C<Math::BigFloat> down from
1.40 to 1.39.

=item Tie::Layers 0.06

Add the C<config> subroutine. Redesigned the internal data structures.
Set aside a unique hash member for C<Tie::Layers> class options in
the hash data used by both the C<Tie::Layers> class and any class that
inherits the C<Tie::Layers> class.

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

Right click on 'Tie-Layers-0.06.tar.gz' and download to a temporary
installation directory.
Enter the following where $make is 'nmake' for microsoft
windows; otherwise 'make'.

 gunzip Tie-Layers-0.06.tar.gz
 tar -xf Tie-Layers-0.06.tar
 perl Makefile.PL
 $make test
 $make install

On Microsoft operating system, nmake, tar, and gunzip 
must be in the exeuction path. If tar and gunzip are
not install, download and install unxutils from

 http://packages.softwarediamonds.com

=item Prerequistes.

 'Data::Startup' => '0.08',


=item Security, privacy, or safety precautions.

None.

=item Installation Tests.

Most Perl installation software will run the following test script(s)
as part of the installation:

 t/Tie/Layers.t

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

=item Docs::US_DOD::SVD

=back

=for html


=cut

1;

__DATA__

DISTNAME: Tie-Layers^
VERSION : 0.06^
FREEZE: 1^
PREVIOUS_DISTNAME: ^
PREVIOUS_RELEASE: 0.05^
REVISION: E ^

AUTHOR  : SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>^
ABSTRACT: read and write files pipelined through a stack of subroutine layers^
TITLE   : Docs::Site_SVD::Tie_Layers - read and write files pipelined through a stack of subroutine layers^
END_USER: General Public^
COPYRIGHT: copyright 2004 Software Diamonds^
CLASSIFICATION: NONE^
TEMPLATE:  ^
CSS: help.css^
SVD_FSPEC: Unix^

REPOSITORY_DIR: packages^
REPOSITORY: 
  http://www.softwarediamonds/packages/
  http://www.perl.com/CPAN/authors/id/S/SO/SOFTDIA/
^

COMPRESS: gzip^
COMPRESS_SUFFIX: gz^

RESTRUCTURE:  ^
CHANGE2CURRENT:  ^

AUTO_REVISE: 
lib/Tie/Layers.pm
t/Tie/Layers.pm
t/Tie/Layers.t
t/Tie/Layers.d
lib/File/Package.pm => t/Tie/File/Package.pm
lib/Test/Tech.pm => t/Tie/Test/Tech.pm
lib/Data/Secs2.pm => t/Tie/Data/Secs2.pm
lib/Data/Str2Num.pm => t/Tie/Data/Str2Num.pm
lib/Data/Startup.pm => t/Tie/Data/Startup.pm
^

REPLACE:  ^

PREREQ_PM: 
'Data::Startup' => '0.08',
^
README_PODS: lib/Tie/Layers.pm^

TESTS: t/Tie/Layers.t^
EXE_FILES:  ^

CHANGES: 
Changes are as follows

\=over 4

\=item Tie::Layers-0.01

Originated

\=item Tie::Layers-0.02

Sometimes get a C<DESTROY> when coming out of C<TIEHANDLE>. Do not
want C<TIEHANDLE> going around closing stuff, especially for an
C<OPEN> with a file handle like C<DATA>. 
If something needs closing, call CLOSE directly.  

\=item Tie::Layers-0.03

Added C<Data::Startup> as perquisite.

\=item Tie::Layers-0.04

Perquisite did not make it into 0.03. Try again.

\=item Tie::Layers-0.05

Test Failure:

 From: mhoyt@houston.rr.com 
 Subject: FAIL Tie-Layers-0.04 darwin-thread-multi-2level 7.0 

 t/Tie/Layers.t
 t/Tie/Layers....Math::BigFloat version 1.4 required--this is only version 1.39 

Annalysis:

This is because using C<Data::Secs2> to stringify test results for comparision.
The C<Data::Secs2> includes C<Data::SecsPack> which includes C<Math::BigFloat>.
There C<Makerfile.PL> prerequisite is only for the Unit Under Test (UUT) software,
not the test software.

Corrective Action:

Since C<Data::SecsPack> is not needed for C<Data::Secs2> stringify, 
rewrote C<Data::Secs2> to include C<Data::SecsPack> only if needed. 
Thus, the test software will not longer be requiring C<Math::BigFloat>.

Also drop the C<Data::SecsPack> version for C<Math::BigFloat> down from
1.40 to 1.39.

\=item Tie::Layers 0.06

Add the C<config> subroutine. Redesigned the internal data structures.
Set aside a unique hash member for C<Tie::Layers> class options in
the hash data used by both the C<Tie::Layers> class and any class that
inherits the C<Tie::Layers> class.

\=back

^

DOCUMENT_OVERVIEW:
This document releases ${NAME} version ${VERSION}
providing a description of the inventory, installation
instructions and other information necessary to
utilize and track this release.
^

CAPABILITIES: 
The C<Tie::Layers> program module contains the tie file handle C<Tie::Layers>
package.
The C<Tie::Layers> package provides the ability to insert a stack of subroutines between
file subroutines C<print> and C<realine> and the underlying C<$file>.
The syntax of the subroutines of each layer of the readline stack and the print
stack must comply to the
the requirements described herein below.
This is necessary so that the C<Tie::Layers> C<READLINE> and C<PRINT> subroutines
know how to transfer the output from one layer to the input of another layer.
The stacks are setup by supplying options with a reference to
the subroutine for each layer in the print stack and the readline stack.
The C<Tie::Layers> are line orientated and do not support any character
file subrouintes. The C<getc>, C<read>, and C<write> file subroutines
are supported by the C<Tie::Layers> package. The seek routines are line
oriented in that the C<seek> and C<tell> subroutine positions are the line
in the underlying file and not the character position in the file.
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

\=item Docs::US_DOD::SVD

\=back
^

HTML:
^
~-~





















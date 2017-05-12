#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Docs::Site_SVD::Tie_Form;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.02';
$DATE = '2004/05/13';
$FILE = __FILE__;

use vars qw(%INVENTORY);
%INVENTORY = (
    'lib/Docs/Site_SVD/Tie_Form.pm' => [qw(0.02 2004/05/13), 'revised 0.01'],
    'MANIFEST' => [qw(0.02 2004/05/13), 'generated, replaces 0.01'],
    'Makefile.PL' => [qw(0.02 2004/05/13), 'generated, replaces 0.01'],
    'README' => [qw(0.02 2004/05/13), 'generated, replaces 0.01'],
    'lib/Tie/Form.pm' => [qw(0.02 2004/05/13), 'revised 0.01'],
    't/Tie/Form.d' => [qw(0.01 2004/05/09), 'unchanged'],
    't/Tie/Form.pm' => [qw(0.01 2004/05/09), 'unchanged'],
    't/Tie/Form.t' => [qw(0.02 2004/05/13), 'revised 0.01'],
    't/Tie/_Form_/lenient0.txt' => [qw(0.01 2004/05/09), 'unchanged'],
    't/Tie/_Form_/lenient2.txt' => [qw(0.01 2004/05/09), 'unchanged'],
    't/Tie/_Form_/strict0.txt' => [qw(0.01 2004/05/09), 'unchanged'],
    't/Tie/File/SmartNL.pm' => [qw(1.16 2004/05/13), 'revised 1.14'],
    't/Tie/File/Package.pm' => [qw(1.17 2004/05/13), 'revised 1.16'],
    't/Tie/Test/Tech.pm' => [qw(1.25 2004/05/13), 'revised 1.22'],
    't/Tie/Data/Secs2.pm' => [qw(1.23 2004/05/13), 'revised 1.19'],
    't/Tie/Data/SecsPack.pm' => [qw(0.08 2004/05/13), 'revised 0.04'],

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

Docs::Site_SVD::Tie_Form - Text Database that mimics a Form

=head1 Title Page

 Software Version Description

 for

 Docs::Site_SVD::Tie_Form - Text Database that mimics a Form

 Revision: -

 Version: 0.02

 Date: 2004/05/13

 Prepared for: General Public 

 Prepared by:  SoftwareDiamonds.com E<lt> support@SoftwareDiamonds.comE <gt>

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
program modules, such the "Tie::Form" module, extends the Perl language.

The "Tie::Form" program module accesses a text database file
in the very specific Form format
and inherits generic database methods from the "DataPort::DataFile" module.
The "Tie::Form" program module is a data source for
the "DataPort::DataFile" module.

The Form format has improve flexability and
performance over other text base formats such as the Comma Separated
Variable (CSV) format.

The text format resembles as much as possible the standard hard copy forms.
An example of a "L<DatatPort::FIleType::Form|DatatPort::FIleType::Form>
record follows:

 manhood length: ________ ^
 time spent in big house: _________ ^

 what drugs do you use:
 _________ 
 _________ 

 ^

 ~-~

The ':' separates field names and field content.
The '^' tags the end of a field and the '~-~' tags the
end of the record.
The separation sequences are escaped within the form
by adding an extra character as follows:

  sequence  escaped
  --------  --------
  ~-~       ~--~
  ~--~      ~---~
  ^         ^^
  ^^        ^^^
  :         :
  ::        :::

Since ~-~ never appears inside a record, Perl or
any other Programming Language can very
easily find the record separators just by ... well ...
searching for it. The search for the end of field
and end of field name are just a little bit more 
complicated. Search for a  ':' or '^' all by itself.
Escaping and unescaping is just adding one more
':', '^', '-' or removing one of these characters.

The Form record looks very much like a hard copy 
form yet is very simple and straight forward for
Perl or any other programming language to process.

=head2 1.3 Document overview.

This document releases Tie::Form version 0.02
providing description of the inventory, installation
instructions and other information necessary to
utilize and track this release.

=head1 3.0 VERSION DESCRIPTION

All file specifications in this SVD
use the Unix operating
system file specification.

=head2 3.1 Inventory of materials released.

This document releases the file 

 Tie-Form-0.02.tar.gz

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
 lib/Docs/Site_SVD/Tie_Form.pm                                0.02    2004/05/13 revised 0.01
 MANIFEST                                                     0.02    2004/05/13 generated, replaces 0.01
 Makefile.PL                                                  0.02    2004/05/13 generated, replaces 0.01
 README                                                       0.02    2004/05/13 generated, replaces 0.01
 lib/Tie/Form.pm                                              0.02    2004/05/13 revised 0.01
 t/Tie/Form.d                                                 0.01    2004/05/09 unchanged
 t/Tie/Form.pm                                                0.01    2004/05/09 unchanged
 t/Tie/Form.t                                                 0.02    2004/05/13 revised 0.01
 t/Tie/_Form_/lenient0.txt                                    0.01    2004/05/09 unchanged
 t/Tie/_Form_/lenient2.txt                                    0.01    2004/05/09 unchanged
 t/Tie/_Form_/strict0.txt                                     0.01    2004/05/09 unchanged
 t/Tie/File/SmartNL.pm                                        1.16    2004/05/13 revised 1.14
 t/Tie/File/Package.pm                                        1.17    2004/05/13 revised 1.16
 t/Tie/Test/Tech.pm                                           1.25    2004/05/13 revised 1.22
 t/Tie/Data/Secs2.pm                                          1.23    2004/05/13 revised 1.19
 t/Tie/Data/SecsPack.pm                                       0.08    2004/05/13 revised 0.04


=head2 3.3 Changes

Changes to previous revisions are as follows:

=over 4

=item Tie::Form 0.01

Originated

=item Tie::Form 0.02

The C<new> subroutine did not C<bless> with the
input C<$class>. Fixed.

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

Right click on 'Tie-Form-0.02.tar.gz' and download to a temporary
installation directory.
Enter the following where $make is 'nmake' for microsoft
windows; otherwise 'make'.

 gunzip Tie-Form-0.02.tar.gz
 tar -xf Tie-Form-0.02.tar
 perl Makefile.PL
 $make test
 $make install

On Microsoft operating system, nmake, tar, and gunzip 
must be in the exeuction path. If tar and gunzip are
not install, download and install unxutils from

 http://packages.softwarediamonds.com

=item Prerequistes.

 'Tie::Layers' => '0.01',
 'Data::Startup' => '0.02',


=item Security, privacy, or safety precautions.

None.

=item Installation Tests.

Most Perl installation software will run the following test script(s)
as part of the installation:

 t/Tie/Form.t

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

L<Tie::Form|Tie::Form>

=for html


=cut

1;

__DATA__

DISTNAME: Tie-Form^
REPOSITORY_DIR: packages^

VERSION : 0.02^
FREEZE: 1^
PREVIOUS_DISTNAME:  ^
PREVIOUS_RELEASE: 0.01^
REVISION: - ^

AUTHOR  : SoftwareDiamonds.com E<lt> support@SoftwareDiamonds.comE <gt>^
ABSTRACT: 
Text database with simple escapes so separation characters never
appear in the data. The text file resembles mimics hard copy
forms. There is a very liberal acceptance of separation sequences.
^

TITLE   : Docs::Site_SVD::Tie_Form - Text Database that mimics a Form^
END_USER: General Public^
COPYRIGHT: copyright © 2003 Software Diamonds^
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
lib/Tie/Form.pm
t/Tie/Form*
t/Tie/_Form_/*
lib/File/SmartNL.pm => t/Tie/File/SmartNL.pm
lib/File/Package.pm => t/Tie/File/Package.pm
lib/Test/Tech.pm => t/Tie/Test/Tech.pm
lib/Data/Secs2.pm => t/Tie/Data/Secs2.pm
lib/Data/SecsPack.pm => t/Tie/Data/SecsPack.pm
^

PREREQ_PM: 
'Tie::Layers' => '0.01',
'Data::Startup' => '0.02',
^
README_PODS: lib/Tie/Form.pm^
TESTS: t/Tie/Form.t ^
EXE_FILES:  ^

CHANGES:
Changes to previous revisions are as follows:

\=over 4

\=item Tie::Form 0.01

Originated

\=item Tie::Form 0.02

The C<new> subroutine did not C<bless> with the
input C<$class>. Fixed.

\=back
^

DOCUMENT_OVERVIEW:
This document releases ${NAME} version ${VERSION}
providing description of the inventory, installation
instructions and other information necessary to
utilize and track this release.
^

CAPABILITIES:
The system is the Perl programming language software.
As established by the Perl referenced documents,
program modules, such the "Tie::Form" module, extends the Perl language.

The "Tie::Form" program module accesses a text database file
in the very specific Form format
and inherits generic database methods from the "DataPort::DataFile" module.
The "Tie::Form" program module is a data source for
the "DataPort::DataFile" module.

The Form format has improve flexability and
performance over other text base formats such as the Comma Separated
Variable (CSV) format.

The text format resembles as much as possible the standard hard copy forms.
An example of a "L<DatatPort::FIleType::Form|DatatPort::FIleType::Form>
record follows:

 manhood length: ________ ^^
 time spent in big house: _________ ^^

 what drugs do you use:
 _________ 
 _________ 

 ^^

 ~--~

The ':' separates field names and field content.
The '^^' tags the end of a field and the '~--~' tags the
end of the record.
The separation sequences are escaped within the form
by adding an extra character as follows:

  sequence  escaped
  --------  --------
  ~--~       ~---~
  ~---~      ~----~
  ^^         ^^^
  ^^^        ^^^^
  :         :
  ::        :::

Since ~--~ never appears inside a record, Perl or
any other Programming Language can very
easily find the record separators just by ... well ...
searching for it. The search for the end of field
and end of field name are just a little bit more 
complicated. Search for a  ':' or '^^' all by itself.
Escaping and unescaping is just adding one more
':', '^^', '-' or removing one of these characters.

The Form record looks very much like a hard copy 
form yet is very simple and straight forward for
Perl or any other programming language to process.
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

L<Tie::Form|Tie::Form>


^

HTML: 
^
~-~







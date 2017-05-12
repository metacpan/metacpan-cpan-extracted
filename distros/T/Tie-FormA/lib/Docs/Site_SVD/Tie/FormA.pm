#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Docs::Site_SVD::Tie::FormA;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.02';
$DATE = '2004/06/03';
$FILE = __FILE__;

use vars qw(%INVENTORY);
%INVENTORY = (
    'lib/Docs/Site_SVD/Tie/FormA.pm' => [qw(0.02 2004/06/03), 'revised 0.01'],
    'MANIFEST' => [qw(0.02 2004/06/03), 'generated, replaces 0.01'],
    'Makefile.PL' => [qw(0.02 2004/06/03), 'generated, replaces 0.01'],
    'README' => [qw(0.02 2004/06/03), 'generated, replaces 0.01'],
    'lib/Tie/FormA.pm' => [qw(0.02 2004/06/03), 'revised 0.01'],
    'lib/Bundle/Tie/FormA.pm' => [qw(0.02 2004/06/03), 'revised 0.01'],
    't/Tie/FormA.d' => [qw(0.02 2004/06/03), 'revised 0.01'],
    't/Tie/FormA.pm' => [qw(0.02 2004/06/03), 'revised 0.01'],
    't/Tie/FormA.t' => [qw(0.02 2004/06/03), 'revised 0.01'],
    't/Tie/FormA/lenient0.txt' => [qw(0.01 2004/06/01), 'unchanged'],
    't/Tie/FormA/lenient2.txt' => [qw(0.01 2004/06/01), 'unchanged'],
    't/Tie/FormA/strict0.txt' => [qw(0.01 2004/06/01), 'unchanged'],
    't/digest.t' => [qw(0.01 2004/06/03), 'new'],
    't/File/Digest.pm' => [qw(1.14 2004/05/03), 'new'],
    't/Tie/Test.pm' => [qw(1.25 2004/04/28), 'unchanged'],
    't/Tie/Algorithm/Diff.pm' => [qw(1.15 ), 'unchanged'],
    't/Tie/File/SmartNL.pm' => [qw(1.16 2004/05/24), 'unchanged'],
    't/Tie/File/Package.pm' => [qw(1.18 2004/05/24), 'unchanged'],
    't/Tie/Test/Tech.pm' => [qw(1.27 2004/05/28), 'unchanged'],
    't/Tie/Data/Secs2.pm' => [qw(1.26 2004/05/24), 'unchanged'],
    't/Tie/Data/Str2Num.pm' => [qw(0.08 2004/05/24), 'unchanged'],

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

Docs::Site_SVD::Tie::FormA - Software Version Description (SVD) for the Tie::FormA program module.

=head1 Title Page

Software Version Description

for

Tie::FormA - Text Database that mimics a Form

Revision: A

Version: 0.02

Date: 2004/06/03

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

This document releases Tie::FormA version 0.02
providing description of the inventory, installation
instructions and other information necessary to
utilize and track this release.

=head1 3.0 VERSION DESCRIPTION

All file specifications in this SVD
use the Unix operating
system file specification.

=head2 3.1 Inventory of materials released.

This document releases the file 

 Tie-FormA-0.02.tar.gz

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
shall[1] retain the above copyright notice, this list of
conditions and the following disclaimer. 

=item 2

Redistributions in binary form shall[2]
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

=item 3

In addition to condition (1) and (2),
commercial installation of a software product
with the binary or source code embedded in the
software product or a software product of
binary or source code, with or without modifications,
shall[3] visually present to the installer 
the above copyright notice,
this list of conditions intact,
that the original source is available
at http://packages.softwarediamonds.com
and provide means for the installer to actively accept
the list of conditions; 
otherwise, the commercial activity,
as determined by Software Diamonds and
published at http://packages.softwarediamonds.com, 
shall[4] pay a license fee to
Software Diamonds and shall[5] make donations,
to open source repositories carrying
the source code.

=back

The construction of the word "shall[x]" is always mandatory 
and not merely directory and identifies each binding
requirement of this License. 
It is the responsibility of the licensee to
conform to all requirements.

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
 lib/Docs/Site_SVD/Tie/FormA.pm                               0.02    2004/06/03 revised 0.01
 MANIFEST                                                     0.02    2004/06/03 generated, replaces 0.01
 Makefile.PL                                                  0.02    2004/06/03 generated, replaces 0.01
 README                                                       0.02    2004/06/03 generated, replaces 0.01
 lib/Tie/FormA.pm                                             0.02    2004/06/03 revised 0.01
 lib/Bundle/Tie/FormA.pm                                      0.02    2004/06/03 revised 0.01
 t/Tie/FormA.d                                                0.02    2004/06/03 revised 0.01
 t/Tie/FormA.pm                                               0.02    2004/06/03 revised 0.01
 t/Tie/FormA.t                                                0.02    2004/06/03 revised 0.01
 t/Tie/FormA/lenient0.txt                                     0.01    2004/06/01 unchanged
 t/Tie/FormA/lenient2.txt                                     0.01    2004/06/01 unchanged
 t/Tie/FormA/strict0.txt                                      0.01    2004/06/01 unchanged
 t/digest.t                                                   0.01    2004/06/03 new
 t/File/Digest.pm                                             1.14    2004/05/03 new
 t/Tie/Test.pm                                                1.25    2004/04/28 unchanged
 t/Tie/Algorithm/Diff.pm                                      1.15               unchanged
 t/Tie/File/SmartNL.pm                                        1.16    2004/05/24 unchanged
 t/Tie/File/Package.pm                                        1.18    2004/05/24 unchanged
 t/Tie/Test/Tech.pm                                           1.27    2004/05/28 unchanged
 t/Tie/Data/Secs2.pm                                          1.26    2004/05/24 unchanged
 t/Tie/Data/Str2Num.pm                                        0.08    2004/05/24 unchanged


=head2 3.3 Changes

Changes to previous revisions are as follows:

=over 4

=item Tie::Form 0.01

Originated

=item Tie::Form 0.02

The C<new> subroutine did not C<bless> with the
input C<$class>. Fixed.

=item Tie::FormA 0.01

Add the C<config> subroutine.

Recoded the C<new> subroutine changing the functional (user) interface.
The different user interface destories backward compatiblitiy with
the version. Adding a revision letter A to the program module name
starts a new development thread that superceds and obsoletes
the C<Tie::Form> module.

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

Right click on 'Tie-FormA-0.02.tar.gz' and download to a temporary
installation directory.
Enter the following where $make is 'nmake' for microsoft
windows; otherwise 'make'.

 gunzip Tie-FormA-0.02.tar.gz
 tar -xf Tie-FormA-0.02.tar
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

 t/digest.t
 t/Tie/FormA.t

=item Installation support.

If there are installation problems or questions with the installation
contact

 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>

=back

=head2 3.7 Possible problems and known errors

There are no known open issues.

=head1 4.0 NOTES

=head2 Acronyms

The following are useful acronyms:

=over 4

=item .d

extension for a Perl demo script file

=item .pm

extension for a Perl Library Module

=item .t

extension for a Perl test script file

=back

=head2 Construction of Words

The construction of the words "shall", "may" and "should"
shall[1] conform to United States (US) Departmart of Defense (DoD)
L<STD490A 3.2.3.6|Docs::US_DOD::STD490A/3.2.3.6>
which is more precise and even consistent, at times, with
RFC 2119, http://www.ietf.org/rfc/rfc2119.txt
Binding requirements shall[2] be uniquely identified by
the construction "shall[\d+]" , where "\d+" is an unique number
for each paragraph(s) uniquely identified by a header.
The construction of commonly used words and phrasing
shall[3] conform to US DoD 
L<STD490A 3.2.3.5|Docs::US_DOD::STD490A/3.2.3.5 Commonly used words and phrasing.>
In accordance with US Dod L<STD490A 3.2.6|Docs::US_DOD::STD490A/3.2.6 Underlining.>,
requirments shall[4] not be emphazied by underlining and capitalization.
All of the requirements are important in obtaining
the desired performance.

Unless otherwise specified, in accordance with Software Diamonds' License, 
Software Diamonds shall[5] not be responsible for this program module conforming to all the
specified requirements, binding or otherwise.

=head1 2.0 SEE ALSO

=over 4

=item L<Tie::FormA|Tie::FormA>

=back

=for html


=cut

1;

__DATA__

USE: ExtUtils::SVDmaker^
UUT: Tie::FormA^
DISTNAME: Tie-FormA^
REPOSITORY_DIR: packages^

VERSION : 0.02^
FREEZE: 1^
PREVIOUS_DISTNAME: ^
PREVIOUS_RELEASE: 0.01^

AUTHOR  : SoftwareDiamonds.com E<lt> support@SoftwareDiamonds.comE <gt>^
ABSTRACT: 
Text database with simple escapes so separation characters never
appear in the data. The text file resembles mimics hard copy
forms. There is a very liberal acceptance of separation sequences.
^

TITLE   : ${UUT} - Text Database that mimics a Form^
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
lib/Tie/FormA.pm
lib/Bundle/Tie/FormA.pm
t/Tie/FormA*
t/Tie/FormA/*
bin/digest.t => t/digest.t
^

REPLACE: 
lib/File/Digest.pm => t/File/Digest.pm
libperl/Test.pm => t/Tie/Test.pm
libperl/Algorithm/Diff.pm  => t/Tie/Algorithm/Diff.pm
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

TESTS:
t/digest.t
t/Tie/FormA.t
^

README_PODS: lib/Tie/FormA.pm ^
STDS: t::Tie::FormA ^
BUNDLE: Tie::FormA ^
EXE_FILES:  ^

CHANGES:
Changes to previous revisions are as follows:

\=over 4

\=item Tie::Form 0.01

Originated

\=item Tie::Form 0.02

The C<new> subroutine did not C<bless> with the
input C<$class>. Fixed.

\=item Tie::FormA 0.01

Add the C<config> subroutine.

Recoded the C<new> subroutine changing the functional (user) interface.
The different user interface destories backward compatiblitiy with
the version. Adding a revision letter A to the program module name
starts a new development thread that superceds and obsoletes
the C<Tie::Form> module.

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
shall[1] retain the above copyright notice, this list of
conditions and the following disclaimer. 

\=item 2

Redistributions in binary form shall[2]
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

\=item 3

In addition to condition (1) and (2),
commercial installation of a software product
with the binary or source code embedded in the
software product or a software product of
binary or source code, with or without modifications,
shall[3] visually present to the installer 
the above copyright notice,
this list of conditions intact,
that the original source is available
at http://packages.softwarediamonds.com
and provide means for the installer to actively accept
the list of conditions; 
otherwise, the commercial activity,
as determined by Software Diamonds and
published at http://packages.softwarediamonds.com, 
shall[4] pay a license fee to
Software Diamonds and shall[5] make donations,
to open source repositories carrying
the source code.

\=back

The construction of the word "shall[x]" is always mandatory 
and not merely directory and identifies each binding
requirement of this License. 
It is the responsibility of the licensee to
conform to all requirements.

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

PROBLEMS: There are no known open issues.^

SUPPORT:
603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>
^

NOTES:

\=head2 Acronyms

The following are useful acronyms:

\=over 4

\=item .d

extension for a Perl demo script file

\=item .pm

extension for a Perl Library Module

\=item .t

extension for a Perl test script file

\=back

\=head2 Construction of Words

The construction of the words "shall", "may" and "should"
shall[1] conform to United States (US) Departmart of Defense (DoD)
L<STD490A 3.2.3.6|Docs::US_DOD::STD490A/3.2.3.6>
which is more precise and even consistent, at times, with
RFC 2119, http://www.ietf.org/rfc/rfc2119.txt
Binding requirements shall[2] be uniquely identified by
the construction "shall[\d+]" , where "\d+" is an unique number
for each paragraph(s) uniquely identified by a header.
The construction of commonly used words and phrasing
shall[3] conform to US DoD 
L<STD490A 3.2.3.5|Docs::US_DOD::STD490A/3.2.3.5 Commonly used words and phrasing.>
In accordance with US Dod L<STD490A 3.2.6|Docs::US_DOD::STD490A/3.2.6 Underlining.>,
requirments shall[4] not be emphazied by underlining and capitalization.
All of the requirements are important in obtaining
the desired performance.

Unless otherwise specified, in accordance with Software Diamonds' License, 
Software Diamonds shall[5] not be responsible for this program module conforming to all the
specified requirements, binding or otherwise.
^

SEE_ALSO:

\=over 4

\=item L<Tie::FormA|Tie::FormA>

\=back

^

HTML: ^
~-~



































































































































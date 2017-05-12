#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '0.01';   # automatically generated file
$DATE = '2004/06/03';
$FILE = __FILE__;

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
   use Test;

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

   plan(tests => 1);

}


END {
 
   #########
   # Restore working directory and @INC back to when enter script
   #
   @INC = @lib::ORIG_INC;
   chdir $__restore_dir__;
}

use File::Digest;
my $result = File::Digest->check(File::Spec->updir(), 'digest.txt');
ok($result?0:1,1,$result);

__END__

=head1 NAME

digest.t - test script to validate the digest for files in the distribution

=head1 SYNOPSIS

 digest.t digest_file

=head1 DESCRIPTION

The C<digest_file> is a file generated with the C<File::Digest->generate> method.
This script uses the  C<File::Digest->check> to regenerate the digests of
the files listed C<digest_file> and compare them with the digest in C<digest_file>.

=back

=head1 Notes

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

\=head2 Author

The author, holder of the copyright and maintainer is

E<lt>support@SoftwareDiamonds.comE<gt>

\=head2 Copyright

copyright © 2004 SoftwareDiamonds.com

\=head2 License

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
otherwise, the commerical activity,
as determined by Software Diamonds and
published at http://packages.softwarediamonds.com, 
shall[4] pay a license fee to
Software Diamonds and shall[5] make donations,
to open source repositories carrying
the source code.

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


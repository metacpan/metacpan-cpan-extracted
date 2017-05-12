#!perl
#
# Documentation, copyright and license is at the end of this file.
#

package  File::Digest;

use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '1.14';
$DATE = '2004/05/03';

use vars qw(@ISA @EXPORT_OK);
require Exporter;
@ISA= qw(Exporter);
@EXPORT_OK = qw();

use File::Spec;
use File::Spec::Unix;
use Cwd;

# use SelfLoader;
# 1
# __DATA__

####
# digest of distribution files
#
sub generate
{
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);;
 
     my $event;
     my $cipher = shift;
     return 1 unless $cipher;
     my $digest = eval {
         require "Digest/$cipher.pm"; 
         "Digest::$cipher"->new();
     };
     unless($digest) {
         warn( "Unknown digest cipher $cipher\n");
         return \$event; 
     }

     ########
     # Find the plain text digest of each file in the manifest
     #
     my $digest_text = '';
     local *CONTENTS;
     my ($file, $hexdigest,$vol,$dirs,@dirs);
     foreach  (@_) {
	unless (open CONTENTS, "<$_") {
            $event = "Cannot open <$_\n\t$!\n";
            return \$event;
        }
	binmode(CONTENTS) if -B $_;
	$digest->addfile(*CONTENTS);
        $hexdigest = $digest->hexdigest();
        $digest->reset();
        unless(close CONTENTS) {
            $event =  "Cannot close <$file\n\t$!\n";
            return \$event;
        }

	$digest_text .= $cipher . ' ' . $hexdigest . ' ';
        ($vol,$dirs,$file) = File::Spec->splitpath($_);
        @dirs = File::Spec->splitdir($dirs); 
        $dirs = File::Spec::Unix->catdir(@dirs);
        $digest_text .= File::Spec::Unix->catpath($vol,$dirs,$file) . "\n";
     }
     $digest_text;
}


sub check
{
     my $event = '';
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     my $digest_file_home = shift;
     my $digest_file = shift;
     my $restore_dir = cwd();     
     chdir $digest_file_home;

     local *CONTENTS;
     local *DIGEST;
     unless (open DIGEST, "< $digest_file") {
         $event = "Cannot open < $digest_file\n\t$!\n";
         goto EVENT;
     }
     my ($cipher,$expected_digest,$actual_digest,$digest);
     my ($vol,$dirs,$file,@dirs);
     while( <DIGEST> ) {
         ($cipher,$expected_digest,$file) = $_ =~ /(\S+)\s*([0-9A-Fa-f]+)\s*(.*)\s*\n/;
         next unless $cipher && $expected_digest && $file;
         while(chomp($file)) { };
         $digest = eval {
             require "Digest/$cipher.pm"; 
             "Digest::$cipher"->new();
         };
         unless($digest) {
             $event .= "Unknown digest cipher $cipher\n\t$file";
             next; 
         }
         ($vol,$dirs,$file) = File::Spec::Unix->splitpath($file);
         @dirs = File::Spec::Unix->splitdir($dirs); 
         $dirs = File::Spec->catdir(@dirs);
         $file = File::Spec->catpath($vol,$dirs,$file);
	 unless (open CONTENTS, "<$file") {
             $event .= "Cannot open <$file\n\t$!\n";
             next;
         }
	 binmode(CONTENTS) if -B $file;
	 $digest->addfile(*CONTENTS);
         $actual_digest = $digest->hexdigest();
         unless(close CONTENTS) {
             $event .=  "Cannot close <$file\n\t$!\n";
             next;
         }
         next if $expected_digest eq $actual_digest;
         $event .= "file $file may be corrupted\n";      
     }
     unless(close DIGEST) {
         $event .= "Cannot close > $digest_file\n\t$!\n";
     }
     return '' unless $event;

EVENT:
     chdir $restore_dir;
     $event;
}

1;

__END__

=head1 NAME


=head1 SYNOPSIS



=head1 DESCRIPTION


=head1 SUBROUTINES

=head2 fspec_glob

 
=head2 fspec2pm


=head1 REQUIREMENTS


=head1 DEMONSTRATION

 
=head1 NOTES

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

Unless otherwise specified, in accordance with the Software Diamonds' License, 
Software Diamonds shall[5] not be responsible for this program module conforming to all the
specified requirements, binding or otherwise.

=head2 Author

The author, holder of the copyright and maintainer is

E<lt>support@SoftwareDiamonds.comE<gt>

=head2 Copyright

copyright © 2003 SoftwareDiamonds.com

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

=item 3

In addition to condition (1) and (2),
commercial installation of a software product
with the binary or source code embedded in the
software product or a software product of
binary or source code, with or without modifications,
must visually present to the installer 
the above copyright notice,
this list of conditions intact,
that the original source is available
at http://packages.softwarediamonds.com
and provide means for the installer to actively accept
the list of conditions; 
otherwise, the commercial activity,
as determined by Software Diamonds and
published at http://packages.softwarediamonds.com, 
shall[1] pay a license fee to
Software Diamonds and shall[2] make donations,
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

=head1 SEE_ALSO:

=over 4

=back

=cut

### end of file ###
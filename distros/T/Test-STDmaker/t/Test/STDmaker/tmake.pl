#!perl
#
#

use strict;
use warnings;
use warnings::register;
use 5.001;

use Getopt::Long;
use Test::STDmaker;
use Pod::Usage;

use vars qw($VERSION $DATE);
$VERSION = '1.06';
$DATE = '2004/05/14';

my $output = 'all';
my $man = '0';
my $help = '0';
my %options;

unless ( GetOptions( 
            'output=s' => \$output,
            'help|?!' => \$help,
            'man!' => \$man,
            'pm=s' => \$options{pm},
            'options_pm=s' => \$options{options_pm}, 
            'targets=s' => \$options{targets}, 
            'test_scripts=s' => \$options{test_scripts},
            'test_fspec=s' => \$options{test_fspec},
            'replace!' => \$options{demo},
            'demo!' => \$options{demo},
            'report!' => \$options{report},
            'nounlink!' => \$options{nounlink},
            'STD2167!' => \$options{STD2167},
            'verbose!' => \$options{verbose},
            'test_verbose!' => \$options{test_verbose},
            'fspec_out=s' => \$options{fspec_out},
            'perform|execute|run!' => \$options{run},
           ) ) {
   pod2usage(1);
}

#####
# Help section. Note the pod2usage(2) has big problems
# with the spaces in WIN32 file names. Thus, simply
# supply the perdoc system command directly that
# pod2usage supplies. Actually faster and cleaner.
#
pod2usage(1) if ( $help );
if($man) {
   system "perldoc \"$0\"";
   exit 1;
}

#####
# General test documents and test scripts in accordance with the
# Software Test Description files.
#
my $std = new Test::STDmaker(\%options);
$std->tmake(@ARGV);

__END__


=head1 SYNOPSIS
 
 tmake [-help|?] [-man] [-options] target ... target 

=head1 DESCRIPTION

The tg command is a cover command for the following function:

    STD::TestGen->fgenerate(@files, \%options);

See L<STD::TestGen|STD::TestGen>

=OPTIONS

For all options not listed, see L<Test::STDmaker|Test::STDmaker/Options>

=over 4

=item C<-help|?>  

This option tells C<sdbuild> to output this 
Plain Old Documentation (POD) SYNOPSIS and OPTIONS 
instead of its normal processing.

=item C<-man>

This option tells C<sdbuild> to output all of this 
Plain Old Documentation (POD) 
instead of its normal processing.


=back

=head1 NOTES

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

=head1 SEE ALSO

L<Test|Test> 
L<Test::Harness|Test::Harness> 
L<tg|STD::t::tg>
L<STDtailor|STD::STDtailor>
L<STD|US_DOD::STD>
L<SVD|US_DOD::SVD>
L<DOD STD 490A|US_DOD::STD490A>
L<DOD STD 2167A|US_DOD::STD2167A>

=for html
<hr>
<p><br>
<!-- BLK ID="NOTICE" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="OPT-IN" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="EMAIL" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="LOG_CGI" -->
<!-- /BLK -->
<p><br>

=cut

### end of file ###



















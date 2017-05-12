#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '0.1';   # automatically generated file
$DATE = '2004/05/10';
$FILE = __FILE__;


##### Test Script ####
#
# Name: Scrub.t
#
# UUT: Text::Scrub
#
# The module Test::STDmaker generated this test script from the contents of
#
# t::Text::Scrub;
#
# Don't edit this test script file, edit instead
#
# t::Text::Scrub;
#
#	ANY CHANGES MADE HERE TO THIS SCRIPT FILE WILL BE LOST
#
#       the next time Test::STDmaker generates this script file.
#
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

   ########
   # Using Test::Tech, a very light layer over the module "Test" to
   # conduct the tests.  The big feature of the "Test::Tech: module
   # is that it takes expected and actual references and stringify
   # them by using "Data::Secs2" before passing them to the "&Test::ok"
   # Thus, almost any time of Perl data structures may be
   # compared by passing a reference to them to Test::Tech::ok
   #
   # Create the test plan by supplying the number of tests
   # and the todo tests
   #
   require Test::Tech;
   Test::Tech->import( qw(finish is_skip ok plan skip skip_tests tech_config) );
   plan(tests => 9);

}


END {
 
   #########
   # Restore working directory and @INC back to when enter script
   #
   @INC = @lib::ORIG_INC;
   chdir $__restore_dir__;
}


=head1 comment_out

###
# Have been problems with debugger with trapping CARP
#

####
# Poor man's eval where the test script traps off the Carp::croak 
# Carp::confess functions.
#
# The Perl authorities have Core::die locked down tight so
# it is next to impossible to trap off of Core::die. Lucky 
# must everyone uses Carp to die instead of just dieing.
#
use Carp;
use vars qw($restore_croak $croak_die_error $restore_confess $confess_die_error);
$restore_croak = \&Carp::croak;
$croak_die_error = '';
$restore_confess = \&Carp::confess;
$confess_die_error = '';
no warnings;
*Carp::croak = sub {
   $croak_die_error = '# Test Script Croak. ' . (join '', @_);
   $croak_die_error .= Carp::longmess (join '', @_);
   $croak_die_error =~ s/\n/\n#/g;
       goto CARP_DIE; # once croak can not continue
};
*Carp::confess = sub {
   $confess_die_error = '# Test Script Confess. ' . (join '', @_);
   $confess_die_error .= Carp::longmess (join '', @_);
   $confess_die_error =~ s/\n/\n#/g;
       goto CARP_DIE; # once confess can not continue

};
use warnings;
=cut


   # Perl code from C:
    use File::Spec;

    use File::Package;
    my $fp = 'File::Package';

    my $uut = 'Text::Scrub';

    my $loaded = '';
    my $template = '';
    my %variables = ();
    my $expected = '';

ok(  $loaded = $fp->is_package_loaded($uut), # actual results
      '', # expected results
     "",
     "UUT not loaded");

#  ok:  1

   # Perl code from C:
my $errors = $fp->load_package($uut);

skip_tests( 1 ) unless skip(
      $loaded, # condition to skip test   
      $errors, # actual results
      '',  # expected results
      "",
      "Load UUT");
 
#  ok:  2

   # Perl code from C:
my $text = 'ok 2 # (E:/User/SoftwareDiamonds/installation/t/Test/STDmaker/tgA1.t at line 123 TODO?!)';

ok(  $uut->scrub_file_line($text), # actual results
     'ok 2 # (xxxx.t at line 000 TODO?!)', # expected results
     "",
     " scrub_file_line");

#  ok:  3

   # Perl code from C:
$text = 'Running Tests\n\nE:/User/SoftwareDiamonds/installation/t/Test/STDmaker/tgA1.1..16 todo 2 5;';

ok(  $uut->scrub_test_file($text), # actual results
     'Running Tests xxx.t 1..16 todo 2 5;', # expected results
     "",
     " scrub_test_file");

#  ok:  4

   # Perl code from C:
$text = '$VERSION = \'0.01\';\n$DATE = \'2003/06/07\';';

ok(  $uut->scrub_date_version($text), # actual results
     '$VERSION = \'0.00\';\n$DATE = \'Feb 6, 1969\';', # expected results
     "",
     " scrub_date_version");

#  ok:  5

   # Perl code from C:
$text = <<'EOF';
Date: Apr 12 00 00 00 2003 +0000
Subject: 20030506, This Week in Health'
X-SDticket: 20030205
X-eudora-date: Feb 6 2000 00 00 2003 +0000
X-SDmailit: dead Feb 5 2000 00 00 2003
Sent email 20030205-20030506 to support.softwarediamonds.com
EOF

my $expected_text = <<'EOF';
Date: Feb 6 00 00 00 1969 +0000
Subject: XXXXXXXXX-X,  This Week in Health'
X-SDticket: XXXXXXXXX-X
X-eudora-date: Feb 6 00 00 00 1969 +0000
X-SDmailit: dead Sat Feb 6 00 00 00 1969 +0000
Sent email XXXXXXXXX-X to support.softwarediamonds.com
EOF

# end of EOF;

ok(  $uut->scrub_date_ticket($text), # actual results
     $expected_text, # expected results
     "",
     " scrub_date_ticket");

#  ok:  6

   # Perl code from C:
$text = 'Going to happy valley 2003/06/07';

ok(  $uut->scrub_date($text), # actual results
     'Going to happy valley 1969/02/06', # expected results
     "",
     " scrub_date");

#  ok:  7

   # Perl code from C:
$text = <<'EOF';
1..8 todo 2 5;
# OS            : MSWin32
# Perl          : 5.6.1
# Local Time    : Thu Jun 19 23:49:54 2003
# GMT Time      : Fri Jun 20 03:49:54 2003 GMT
# Number Storage: string
# Test::Tech    : 1.06
# Test          : 1.15
# Data::Dumper  : 2.102
# =cut 
# Pass test
ok 1
EOF

$expected_text = <<'EOF';
1..8 todo 2 5;
# Pass test
ok 1
EOF

# end of EOF;

ok(  $uut->scrub_probe($text), # actual results
     $expected_text, # expected results
     "",
     " scrub_probe");

#  ok:  8

   # Perl code from C:
$text = 'ARCHITECTURE NAME="MSWin32-x86-multi-thread-5.5"';

ok(  $uut->scrub_architect($text), # actual results
     'ARCHITECTURE NAME="Perl"', # expected results
     "",
     " scrub_architect");

#  ok:  9

   # Perl code from C:
unlink 'actual.txt';


=head1 comment out

# does not work with debugger
CARP_DIE:
    if ($croak_die_error || $confess_die_error) {
        print $Test::TESTOUT = "not ok $Test::ntest\n";
        $Test::ntest++;
        print $Test::TESTERR $croak_die_error . $confess_die_error;
        $croak_die_error = '';
        $confess_die_error = '';
        skip_tests(1, 'Test invalid because of Carp die.');
    }
    no warnings;
    *Carp::croak = $restore_croak;    
    *Carp::confess = $restore_confess;
    use warnings;
=cut

    finish();

__END__

=head1 NAME

Scrub.t - test script for Text::Scrub

=head1 SYNOPSIS

 Scrub.t -log=I<string>

=head1 OPTIONS

All options may be abbreviated with enough leading characters
to distinguish it from the other options.

=over 4

=item C<-log>

Scrub.t uses this option to redirect the test results 
from the standard output to a log file.

=back

=head1 COPYRIGHT

copyright © 2003 Software Diamonds.

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

/=over 4

/=item 1

Redistributions of source code, modified or unmodified
must retain the above copyright notice, this list of
conditions and the following disclaimer. 

/=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

/=back

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


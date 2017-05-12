#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '0.04';   # automatically generated file
$DATE = '2004/04/16';
$FILE = __FILE__;


##### Test Script ####
#
# Name: Gzip.t
#
# UUT: Tie::Gzip
#
# The module Test::STDmaker generated this test script from the contents of
#
# t::Tie::Gzip;
#
# Don't edit this test script file, edit instead
#
# t::Tie::Gzip;
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
   plan(tests => 13);

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
    use File::Package;
    use File::Copy;
    use File::SmartNL;

    my $uut = 'Tie::Gzip'; # Unit Under Test
    my $fp = 'File::Package';
    my $snl = 'File::SmartNL';
    my $loaded;

skip_tests( 1 ) unless ok(
      $loaded = $fp->is_package_loaded($uut), # actual results
       '', # expected results
      "",
      "UUT not loaded"); 

#  ok:  1

   # Perl code from C:
my $errors = $fp->load_package($uut);

skip_tests( 1 ) unless ok(
      $errors, # actual results
      '', # expected results
      "",
      "Load UUT"); 

#  ok:  2

ok(  $loaded = $fp->is_package_loaded($uut), # actual results
     1, # expected results
     "",
     "Tie::Gzip Version $Tie::Gzip::VERSION loaded");

#  ok:  3

   # Perl code from C:
my $dm = 
'cwd: ' . cwd() . "\n" .
'FindBin: ' . $FindBin::Bin . "\n" .
'$0: ' . $0 . "\n" .
'abs $0: ' . File::Spec->rel2abs($0) . "\n";

skip_tests( 1 ) unless ok(
      -f 'gzip0.htm', # actual results
      1, # expected results
      "$dm",
      "Ensure gzip.t can access gzip0.htm"); 

#  ok:  4

   # Perl code from C:
unlink 'gzip1.htm';

skip_tests( 1 ) unless ok(
      copy('gzip0.htm', 'gzip1.htm'), # actual results
      1, # expected results
      "$!",
      "Copy gzip0.htm to gzip1.htm."); 

#  ok:  5

   # Perl code from C:
      sub gz_decompress
     {
         my ($gzip) = shift @_;
         my $file = 'gzip1.htm';
 
         return undef unless open($gzip, "< $file.gz");

         if( open (FILE, "> $file" ) ) {
             while( my $line = <$gzip> ) {
                  print FILE $line;
             }
             close FILE;
             close $gzip;
             unlink 'gzip1.htm.gz';
             return 1;
         }

         1 

     }

     sub gz_compress
     {
         my ($gzip) = shift @_;
         my $file = 'gzip1.htm';
         return undef unless open($gzip, "> $file.gz");
        
         if( open(FILE, "< $file") ) {
             while( my $line = <FILE> ) {
                    print $gzip $line;
             }
             close FILE;
             unlink $file;
         }
         close $gzip;
    }

    #####
    # Compress gzip1.htm with gzip software unit of opportunity
    # Decompress gzip1.htm,gz with gzip software unit of opportunity
    #
    tie *GZIP, 'Tie::Gzip';
    my $tie_obj = tied *GZIP;
    my $gz_package = $tie_obj->{gz_package};
    my $gzip = \*GZIP;
    
    #####
    # Do not skip tests next compress and decompress tests if this expression fails.
    # Passing the next compress and decompress tests is mandatory to ensure at 
    # least one gzip is available and works
    # 
    my $gzip_opportunity= gz_compress( $gzip );

ok(  -f 'gzip1.htm.gz', # actual results
     1, # expected results
     "",
     "Compress gzip1.htm with gzip of opportunity. Validate gzip1.htm.gz exists");

#  ok:  6

   # Perl code from C:
gz_decompress( $gzip );


####
# verifies requirement(s):
# L<Tie::Gzip/data integrity [1]>
# 

#####
skip_tests( 1 ) unless ok(
      $snl->fin( 'gzip1.htm'), # actual results
      $snl->fin( 'gzip0.htm'), # expected results
      "",
      "Decompress gzip1.htm.gz with gzip of opportunity. Validate gzip1.htm same as gzip0.htm"); 

#  ok:  7

   # Perl code from C:
    ##### 
    # Compress gzip1.htm with site operating system GNU gzip
    # Decompress gzip1.htm,gz with site GNU gzip
    #
    tie *GZIP, 'Tie::Gzip', {
        read_pipe => 'gzip --decompress --stdout {}',
        write_pipe => 'gzip --stdout > {}',
    };
    $gzip = \*GZIP;
  
    my $skip_flag = is_skip();
    unless($skip_flag) {
        unless( gz_compress($gzip) ) {
            $skip_flag = 1;
            skip_tests( );
        }
    };

ok(  -f 'gzip1.htm.gz', # actual results
     1, # expected results
     "",
     "Compress gzip1.htm with site os GNU gzip. Validate gzip1.htm.gz exists");

#  ok:  8

   # Perl code from C:
gz_decompress( $gzip ) unless $skip_flag;


####
# verifies requirement(s):
# L<Tie::Gzip/data integrity [1]>
# 

#####
skip_tests( 1 ) unless ok(
      $skip_flag ? '' : $snl->fin( 'gzip1.htm'), # actual results
      $skip_flag ? '' : $snl->fin( 'gzip0.htm'), # expected results
      "",
      "Decompress with site os GNU gzip. Validate gzip1.htm same as gzip0.htm"); 

#  ok:  9

   # Perl code from C:
    ######
    # Compress gzip1.htm with Compress::Zlib
    # Decompress gzip1.htm,gz with site GNU gzip
    #
    $skip_flag = $gz_package ? 0 : 1;
    skip_tests( ) if $skip_flag;
    unless($skip_flag) {
        tie *GZIP, 'Tie::Gzip', {
            read_pipe => 'gzip --decompress --stdout {}',
        };
        $gzip = \*GZIP;
        gz_compress( $gzip );
    };

ok(  -f 'gzip1.htm.gz', # actual results
     1, # expected results
     "",
     "Compress gzip1.htm with Compress::Zlib. Validate gzip1.htm.gz exists.");

#  ok:  10

   # Perl code from C:
gz_decompress( $gzip ) unless $skip_flag;


####
# verifies requirement(s):
# L<Tie::Gzip/interoperability [1]>
# 

#####
ok(  $skip_flag ? '' : $snl->fin( 'gzip1.htm'), # actual results
     $skip_flag ? '' : $snl->fin( 'gzip0.htm'), # expected results
     "",
     "Decompress gzip1.htm.gz with site OS GNU gzip. Validate gzip1.htm same as gzip0.htm");

#  ok:  11

   # Perl code from C:
    ######
    # Compress gzip1.htm with site GNU gzipC
    # Decompress gzip1.htm,gz with Compress::Zlib
    #
    unless($skip_flag) {
        tie *GZIP, 'Tie::Gzip', {
            write_pipe => 'gzip --stdout > {}',
        };
        $gzip = \*GZIP;
        skip_tests( ) unless gz_compress( $gzip );
    };

ok(  -f 'gzip1.htm.gz', # actual results
     1, # expected results
     "",
     "Compress gzip1.htm with site os GNU gzip. Validate gzip1.htm.gz exists.");

#  ok:  12

   # Perl code from C:
gz_decompress( $gzip ) unless $skip_flag;


####
# verifies requirement(s):
# L<Tie::Gzip/interoperability [1]>
# 

#####
ok(  $skip_flag ? '' : $snl->fin( 'gzip1.htm'), # actual results
     $skip_flag ? '' : $snl->fin( 'gzip0.htm'), # expected results
     "",
     "Decompress gzip1.htm.gz with Compress::Zlib. Validate gzip1.htm same as gzip0.htm.");

#  ok:  13

   # Perl code from C:
unlink 'gzip1.htm';


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

Gzip.t - test script for Tie::Gzip

=head1 SYNOPSIS

 Gzip.t -log=I<string>

=head1 OPTIONS

All options may be abbreviated with enough leading characters
to distinguish it from the other options.

=over 4

=item C<-log>

Gzip.t uses this option to redirect the test results 
from the standard output to a log file.

=back

=head1 COPYRIGHT

copyright © 2003 Software Diamonds.

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

=cut

## end of test script file ##


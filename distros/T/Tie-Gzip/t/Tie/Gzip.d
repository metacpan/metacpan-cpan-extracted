#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '0.04';   # automatically generated file
$DATE = '2004/04/16';


##### Demonstration Script ####
#
# Name: Gzip.d
#
# UUT: Tie::Gzip
#
# The module Test::STDmaker generated this demo script from the contents of
#
# t::Tie::Gzip 
#
# Don't edit this test script file, edit instead
#
# t::Tie::Gzip
#
#	ANY CHANGES MADE HERE TO THIS SCRIPT FILE WILL BE LOST
#
#       the next time Test::STDmaker generates this script file.
#
#

######
#
# The working directory is the directory of the generated file
#
use vars qw($__restore_dir__ @__restore_inc__ );

BEGIN {
    use Cwd;
    use File::Spec;
    use FindBin;
    use Test::Tech qw(demo is_skip plan skip_tests tech_config );

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

    unshift @INC, File::Spec->catdir( cwd(), 'lib' ); 

}

END {

    #########
    # Restore working directory and @INC back to when enter script
    #
    @INC = @lib::ORIG_INC;
    chdir $__restore_dir__;

}

print << 'MSG';

 ~~~~~~ Demonstration overview ~~~~~
 
Perl code begins with the prompt

 =>

The selected results from executing the Perl Code 
follow on the next lines. For example,

 => 2 + 2
 4

 ~~~~~~ The demonstration follows ~~~~~

MSG

demo( "\ \ \ \ use\ File\:\:Package\;\
\ \ \ \ use\ File\:\:Copy\;\
\ \ \ \ use\ File\:\:SmartNL\;\
\
\ \ \ \ my\ \$uut\ \=\ \'Tie\:\:Gzip\'\;\ \#\ Unit\ Under\ Test\
\ \ \ \ my\ \$fp\ \=\ \'File\:\:Package\'\;\
\ \ \ \ my\ \$snl\ \=\ \'File\:\:SmartNL\'\;\
\ \ \ \ my\ \$loaded\;"); # typed in command           
          use File::Package;
    use File::Copy;
    use File::SmartNL;

    my $uut = 'Tie::Gzip'; # Unit Under Test
    my $fp = 'File::Package';
    my $snl = 'File::SmartNL';
    my $loaded;; # execution

print << 'EOF';

 => ##################
 => # Load UUT
 => # 
 => ###

EOF

demo( "my\ \$errors\ \=\ \$fp\-\>load_package\(\$uut\)"); # typed in command           
      my $errors = $fp->load_package($uut); # execution

demo( "\$errors", # typed in command           
      $errors); # execution


print << 'EOF';

 => ##################
 => # Tie::Gzip Version $Tie::Gzip::VERSION loaded
 => # 
 => ###

EOF

demo( "\$loaded\ \=\ \$fp\-\>is_package_loaded\(\$uut\)", # typed in command           
      $loaded = $fp->is_package_loaded($uut)); # execution


print << 'EOF';

 => ##################
 => # Copy gzip0.htm to gzip1.htm.
 => # 
 => ###

EOF

demo( "unlink\ \'gzip1\.htm\'"); # typed in command           
      unlink 'gzip1.htm'; # execution

demo( "copy\(\'gzip0\.htm\'\,\ \'gzip1\.htm\'\)", # typed in command           
      copy('gzip0.htm', 'gzip1.htm')); # execution


demo( "\ \ \ \ \ \ sub\ gz_decompress\
\ \ \ \ \ \{\
\ \ \ \ \ \ \ \ \ my\ \(\$gzip\)\ \=\ shift\ \@_\;\
\ \ \ \ \ \ \ \ \ my\ \$file\ \=\ \'gzip1\.htm\'\;\
\ \
\ \ \ \ \ \ \ \ \ return\ undef\ unless\ open\(\$gzip\,\ \"\<\ \$file\.gz\"\)\;\
\
\ \ \ \ \ \ \ \ \ if\(\ open\ \(FILE\,\ \"\>\ \$file\"\ \)\ \)\ \{\
\ \ \ \ \ \ \ \ \ \ \ \ \ while\(\ my\ \$line\ \=\ \<\$gzip\>\ \)\ \{\
\ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ print\ FILE\ \$line\;\
\ \ \ \ \ \ \ \ \ \ \ \ \ \}\
\ \ \ \ \ \ \ \ \ \ \ \ \ close\ FILE\;\
\ \ \ \ \ \ \ \ \ \ \ \ \ close\ \$gzip\;\
\ \ \ \ \ \ \ \ \ \ \ \ \ unlink\ \'gzip1\.htm\.gz\'\;\
\ \ \ \ \ \ \ \ \ \ \ \ \ return\ 1\;\
\ \ \ \ \ \ \ \ \ \}\
\
\ \ \ \ \ \ \ \ \ 1\ \
\
\ \ \ \ \ \}\
\
\ \ \ \ \ sub\ gz_compress\
\ \ \ \ \ \{\
\ \ \ \ \ \ \ \ \ my\ \(\$gzip\)\ \=\ shift\ \@_\;\
\ \ \ \ \ \ \ \ \ my\ \$file\ \=\ \'gzip1\.htm\'\;\
\ \ \ \ \ \ \ \ \ return\ undef\ unless\ open\(\$gzip\,\ \"\>\ \$file\.gz\"\)\;\
\ \ \ \ \ \ \ \ \
\ \ \ \ \ \ \ \ \ if\(\ open\(FILE\,\ \"\<\ \$file\"\)\ \)\ \{\
\ \ \ \ \ \ \ \ \ \ \ \ \ while\(\ my\ \$line\ \=\ \<FILE\>\ \)\ \{\
\ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ \ print\ \$gzip\ \$line\;\
\ \ \ \ \ \ \ \ \ \ \ \ \ \}\
\ \ \ \ \ \ \ \ \ \ \ \ \ close\ FILE\;\
\ \ \ \ \ \ \ \ \ \ \ \ \ unlink\ \$file\;\
\ \ \ \ \ \ \ \ \ \}\
\ \ \ \ \ \ \ \ \ close\ \$gzip\;\
\ \ \ \ \}\
\
\ \ \ \ \#\#\#\#\#\
\ \ \ \ \#\ Compress\ gzip1\.htm\ with\ gzip\ software\ unit\ of\ opportunity\
\ \ \ \ \#\ Decompress\ gzip1\.htm\,gz\ with\ gzip\ software\ unit\ of\ opportunity\
\ \ \ \ \#\
\ \ \ \ tie\ \*GZIP\,\ \'Tie\:\:Gzip\'\;\
\ \ \ \ my\ \$tie_obj\ \=\ tied\ \*GZIP\;\
\ \ \ \ my\ \$gz_package\ \=\ \$tie_obj\-\>\{gz_package\}\;\
\ \ \ \ my\ \$gzip\ \=\ \\\*GZIP\;\
\ \ \ \ \
\ \ \ \ \#\#\#\#\#\
\ \ \ \ \#\ Do\ not\ skip\ tests\ next\ compress\ and\ decompress\ tests\ if\ this\ expression\ fails\.\
\ \ \ \ \#\ Passing\ the\ next\ compress\ and\ decompress\ tests\ is\ mandatory\ to\ ensure\ at\ \
\ \ \ \ \#\ least\ one\ gzip\ is\ available\ and\ works\
\ \ \ \ \#\ \
\ \ \ \ my\ \$gzip_opportunity\=\ gz_compress\(\ \$gzip\ \)\;"); # typed in command           
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
    my $gzip_opportunity= gz_compress( $gzip );; # execution

print << 'EOF';

 => ##################
 => # Compress gzip1.htm with gzip of opportunity. Validate gzip1.htm.gz exists
 => # 
 => ###

EOF

demo( "\-f\ \'gzip1\.htm\.gz\'", # typed in command           
      -f 'gzip1.htm.gz'); # execution


print << 'EOF';

 => ##################
 => # Decompress gzip1.htm.gz with gzip of opportunity. Validate gzip1.htm same as gzip0.htm
 => # 
 => ###

EOF

demo( "gz_decompress\(\ \$gzip\ \)"); # typed in command           
      gz_decompress( $gzip ); # execution

demo( "\$snl\-\>fin\(\'gzip1\.htm\'\)\ eq\ \$snl\-\>fin\(\'gzip0\.htm\'\)", # typed in command           
      $snl->fin('gzip1.htm') eq $snl->fin('gzip0.htm')); # execution


demo( "unlink\ \'gzip1\.htm\'"); # typed in command           
      unlink 'gzip1.htm'; # execution


=head1 NAME

Gzip.d - demostration script for Tie::Gzip

=head1 SYNOPSIS

 Gzip.d

=head1 OPTIONS

None.

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

## end of test script file ##

=cut


#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '0.01';   # automatically generated file
$DATE = '2004/05/09';


##### Demonstration Script ####
#
# Name: Form.d
#
# UUT: Tie::Form
#
# The module Test::STDmaker generated this demo script from the contents of
#
# t::Tie::Form 
#
# Don't edit this test script file, edit instead
#
# t::Tie::Form
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
 
The results from executing the Perl Code 
follow on the next lines as comments. For example,

 2 + 2
 # 4

~~~~~~ The demonstration follows ~~~~~

MSG

demo( "\ \ \ \ use\ File\:\:Package\;\
\ \ \ \ use\ File\:\:SmartNL\;\
\ \ \ \ use\ File\:\:Spec\;\
\
\ \ \ \ my\ \$uut\ \=\ \'Tie\:\:Form\'\;\ \#\ Unit\ Under\ Test\
\ \ \ \ my\ \$fp\ \=\ \'File\:\:Package\'\;\
\ \ \ \ my\ \$loaded\;\
\
\ \ \ \ my\ \(\@fields\)\;\ \ \#\ force\ context\
\ \ \ \ my\ \$out_file\ \=\ File\:\:Spec\-\>catfile\(\'_Form_\'\,\'form1\.txt\'\)\;\;\
\ \ \ \ unlink\ \$out_file\;\
\
\ \ \ \ my\ \$lenient_in_file\ \=\ File\:\:Spec\-\>catfile\(\'_Form_\'\,\'lenient0\.txt\'\)\;\
\ \ \ \ my\ \$strict_in_file\ \=\ File\:\:Spec\-\>catfile\(\'_Form_\'\,\'strict0\.txt\'\)\;\
\
\ \ \ \ my\ \$version\ \=\ \$Tie\:\:Form\:\:VERSION\;\
\ \ \ \ \$version\ \=\ \'\'\ unless\ \$version\;"); # typed in command           
          use File::Package;
    use File::SmartNL;
    use File::Spec;

    my $uut = 'Tie::Form'; # Unit Under Test
    my $fp = 'File::Package';
    my $loaded;

    my (@fields);  # force context
    my $out_file = File::Spec->catfile('_Form_','form1.txt');;
    unlink $out_file;

    my $lenient_in_file = File::Spec->catfile('_Form_','lenient0.txt');
    my $strict_in_file = File::Spec->catfile('_Form_','strict0.txt');

    my $version = $Tie::Form::VERSION;
    $version = '' unless $version;; # execution

      ######
# Not needed for demo, so use the Quiet Code (QC) 
# 
my $lenient_expected_file = File::Spec->catfile('_Form_','lenient2.txt');
my $strict_expected_file = File::Spec->catfile('_Form_','lenient2.txt');

my @test_data1 = (
[
  'UUT',
  'File/Version.pm',
  'File_Spec',
  '',
  'Revision',
  '',
  'End_User',
  '',
  'Author',
  'http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com',
  'SVD',
  'SVD::DataCop-DataFile',
  'Template',
  'STD/STD001.frm',
],

[
   'Email',
   'nobody@hotmail.com',
   'Form',
   'Udo-fully processed oils',
   'Tutorial',
   '*~~* Better Health thru Biochemistry *~~*',
   'REMOTE_ADDR',
   '213.158.186.150',
   'HTTP_USER_AGENT',
   'Mozilla/4.0 (compatible; MSIE 5.0; Windows 98; DigExt)',
   'HTTP_REFERER',
   'http://computerdiamonds.com/',
],
  
[   'EOF',
     '\n',
    'EOL',
    '\n^\n',
    'EOV',
    '}',
    'SOV',
    '${'
],

[  'EOF', 
    '^',
   'EOL',
    '~-~',
    'SOV',
    '${',
    'EOV',
    '}'
],

[   'EOF', 
    '^^',
    'EOL',
     '~---~',   
     'SOV',
     '${',
     'EOV',
     '}',
]

);; # execution

print << "EOF";

 ##################
 # Load UUT
 # 
 
EOF

demo( "my\ \$errors\ \=\ \$fp\-\>load_package\(\$uut\)"); # typed in command           
      my $errors = $fp->load_package($uut); # execution

demo( "\$errors", # typed in command           
      $errors); # execution


print << "EOF";

 ##################
 # Tie::Form Version $version loaded
 # 
 
EOF

demo( "\$fp\-\>is_package_loaded\(\$uut\)", # typed in command           
      $fp->is_package_loaded($uut)); # execution


print << "EOF";

 ##################
 # Read lenient Form
 # 
 
EOF

demo( "\ \ \ \ tie\ \*FORM\,\ \'Tie\:\:Form\'\;\
\ \ \ \ open\ FORM\,\'\<\'\,File\:\:Spec\-\>catfile\(\$lenient_in_file\)\;\
\ \ \ \ \@fields\ \=\ \<FORM\>\;\
\ \ \ \ close\ FORM\;"); # typed in command           
          tie *FORM, 'Tie::Form';
    open FORM,'<',File::Spec->catfile($lenient_in_file);
    @fields = <FORM>;
    close FORM;; # execution

demo( "\[\@fields\]", # typed in command           
      [@fields]); # execution


print << "EOF";

 ##################
 # Write lenient Form
 # 
 
EOF

demo( "\ \ \ \ open\ FORM\,\ \'\>\'\,\ \$out_file\;\
\ \ \ \ print\ FORM\ \@fields\;\
\ \ \ \ close\ FORM\;"); # typed in command           
          open FORM, '>', $out_file;
    print FORM @fields;
    close FORM;; # execution

demo( "File\:\:SmartNL\-\>fin\(\$out_file\)", # typed in command           
      File::SmartNL->fin($out_file)); # execution


print << "EOF";

 ##################
 # Read strict Form
 # 
 
EOF

demo( "\ \ \ \ tie\ \*FORM\,\ \'Tie\:\:Form\'\;\
\ \ \ \ open\ FORM\,\'\<\'\,File\:\:Spec\-\>catfile\(\$strict_in_file\)\;\
\ \ \ \ \@fields\ \=\ \<FORM\>\;\
\ \ \ \ close\ FORM\;"); # typed in command           
          tie *FORM, 'Tie::Form';
    open FORM,'<',File::Spec->catfile($strict_in_file);
    @fields = <FORM>;
    close FORM;; # execution

demo( "\[\@fields\]", # typed in command           
      [@fields]); # execution


print << "EOF";

 ##################
 # Write strict Form
 # 
 
EOF

demo( "\ \ \ \ open\ FORM\,\ \'\>\'\,\ \$out_file\;\
\ \ \ \ print\ FORM\ \@fields\;\
\ \ \ \ close\ FORM\;"); # typed in command           
          open FORM, '>', $out_file;
    print FORM @fields;
    close FORM;; # execution

demo( "File\:\:SmartNL\-\>fin\(\$out_file\)", # typed in command           
      File::SmartNL->fin($out_file)); # execution


demo( "unlink\ \$out_file\;"); # typed in command           
      unlink $out_file;; # execution


=head1 NAME

Form.d - demostration script for Tie::Form

=head1 SYNOPSIS

 Form.d

=head1 OPTIONS

None.

=head1 COPYRIGHT

copyright © 2004 Software Diamonds.

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


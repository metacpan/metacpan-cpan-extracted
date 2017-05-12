#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '0.01';   # automatically generated file
$DATE = '2004/05/24';


##### Demonstration Script ####
#
# Name: advance.d
#
# UUT: Test::STDmaker
#
# The module Test::STDmaker generated this demo script from the contents of
#
# t::Test::STDmaker::advance 
#
# Don't edit this test script file, edit instead
#
# t::Test::STDmaker::advance
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
    Test::Tech->import( qw(demo finish is_skip ok ok_sub plan skip 
                          skip_sub skip_tests tech_config) );

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

demo( "\ \ \ \ use\ vars\ qw\(\$loaded\)\;\
\ \ \ \ use\ File\:\:Glob\ \'\:glob\'\;\
\ \ \ \ use\ File\:\:Copy\;\
\ \ \ \ use\ File\:\:Package\;\
\ \ \ \ use\ File\:\:SmartNL\;\
\ \ \ \ use\ Text\:\:Scrub\;\
\ \
\ \ \ \ \#\#\#\#\#\#\#\#\#\
\ \ \ \ \#\ For\ \"TEST\"\ 1\.24\ or\ greater\ that\ have\ separate\ std\ err\ output\,\
\ \ \ \ \#\ redirect\ the\ TESTERR\ to\ STDOUT\
\ \ \ \ \#\
\ \ \ \ my\ \$restore_testerr\ \=\ tech_config\(\ \'Test\.TESTERR\'\,\ \\\*STDOUT\ \)\;\ \ \ \
\
\ \ \ \ my\ \$fp\ \=\ \'File\:\:Package\'\;\
\ \ \ \ my\ \$snl\ \=\ \'File\:\:SmartNL\'\;\
\ \ \ \ my\ \$s\ \=\ \'Text\:\:Scrub\'\;\
\
\ \ \ \ my\ \$test_results\;\
\ \ \ \ my\ \$loaded\ \=\ 0\;\
\ \ \ \ my\ \@outputs\;\
\
\ \ \ \ my\ \(\$success\,\ \$diag\)\;"); # typed in command           
          use vars qw($loaded);
    use File::Glob ':glob';
    use File::Copy;
    use File::Package;
    use File::SmartNL;
    use Text::Scrub;
 
    #########
    # For "TEST" 1.24 or greater that have separate std err output,
    # redirect the TESTERR to STDOUT
    #
    my $restore_testerr = tech_config( 'Test.TESTERR', \*STDOUT );   

    my $fp = 'File::Package';
    my $snl = 'File::SmartNL';
    my $s = 'Text::Scrub';

    my $test_results;
    my $loaded = 0;
    my @outputs;

    my ($success, $diag); # execution



print << "EOF";

 ##################
 # Load UUT
 # 
 
EOF

demo( "my\ \$errors\ \=\ \$fp\-\>load_package\(\ \'Test\:\:STDmaker\'\ \)"); # typed in command           
      my $errors = $fp->load_package( 'Test::STDmaker' ); # execution



demo( "\$errors", # typed in command           
      $errors # execution
) unless     $loaded; # condition for execution                            

print << "EOF";

 ##################
 # Test::STDmaker Version $Test::STDmaker::VERSION
 # 
 
EOF

demo( "\$Test\:\:STDmaker\:\:VERSION", # typed in command           
      $Test::STDmaker::VERSION); # execution


print << "EOF";

 ##################
 # tmake('STD', {pm => 't::Test::STDmaker::tgC1', fspec_out=>'os2'})
 # 
 
EOF

demo( "\$snl\-\>fin\(\'tgC0\.pm\'\)", # typed in command           
      $snl->fin('tgC0.pm')); # execution


print << "EOF";

 ##################
 # tmake('STD', {pm => 't::Test::STDmaker::tgC1', fspec_out=>'os2'})
 # 
 
EOF

demo( "\ \ \ \ copy\ \'tgC0\.pm\'\,\ \'tgC1\.pm\'\;\
\ \ \ \ my\ \$tmaker\ \=\ new\ Test\:\:STDmaker\(\)\;\
\ \ \ \ my\ \$perl_executable\ \=\ \$tmaker\-\>perl_command\(\)\;\
\ \ \ \ \$success\ \=\ \$tmaker\-\>tmake\(\'STD\'\,\ \{\ pm\ \=\>\ \'t\:\:Test\:\:STDmaker\:\:tgC1\'\,\ fspec_out\=\>\'os2\'\}\)\;\
\ \ \ \ \$diag\ \=\ \"\\n\~\~\~\~\~\~\~\\nFormDB\\n\\n\"\ \.\ join\ \"\\n\"\,\ \@\{\$tmaker\-\>\{FormDB\}\}\;\
\ \ \ \ \$diag\ \.\=\ \"\\n\~\~\~\~\~\~\~\\nstd_db\\n\\n\"\ \.\ join\ \"\\n\"\,\ \@\{\$tmaker\-\>\{std_db\}\}\;\
\ \ \ \ \$diag\ \.\=\ \(\-e\ \'tgC1\.pm\'\)\ \?\ \"\\n\~\~\~\~\~\~\~\\ntgC1\.pm\\n\\n\"\ \.\ \$snl\-\>fin\(\'tgC1\.pm\'\)\ \:\ \'No\ tgC1\.pm\'\;"); # typed in command           
          copy 'tgC0.pm', 'tgC1.pm';
    my $tmaker = new Test::STDmaker();
    my $perl_executable = $tmaker->perl_command();
    $success = $tmaker->tmake('STD', { pm => 't::Test::STDmaker::tgC1', fspec_out=>'os2'});
    $diag = "\n~~~~~~~\nFormDB\n\n" . join "\n", @{$tmaker->{FormDB}};
    $diag .= "\n~~~~~~~\nstd_db\n\n" . join "\n", @{$tmaker->{std_db}};
    $diag .= (-e 'tgC1.pm') ? "\n~~~~~~~\ntgC1.pm\n\n" . $snl->fin('tgC1.pm') : 'No tgC1.pm'; # execution



demo( "\$success", # typed in command           
      $success); # execution


print << "EOF";

 ##################
 # Change File Spec
 # 
 
EOF

demo( "\$s\-\>scrub_date_version\(\$snl\-\>fin\(\'tgC1\.pm\'\)\)", # typed in command           
      $s->scrub_date_version($snl->fin('tgC1.pm'))); # execution


print << "EOF";

 ##################
 # find_t_roots
 # 
 
EOF

demo( "\ \ \ my\ \$OS\ \=\ \$\^O\;\ \ \#\ Need\ to\ escape\ the\ form\ delimiting\ char\ \^\
\ \ \ unless\ \(\$OS\)\ \{\ \ \ \#\ on\ some\ perls\ \$\^O\ is\ not\ defined\
\ \ \ \ \ require\ Config\;\
\ \ \ \ \ \$OS\ \=\ \$Config\:\:Config\{\'osname\'\}\;\
\ \ \ \}\ \
\ \ \ my\(\$vol\,\ \$dir\)\ \=\ File\:\:Spec\-\>splitpath\(cwd\(\)\,\'nofile\'\)\;\
\ \ \ my\ \@dirs\ \=\ File\:\:Spec\-\>splitdir\(\$dir\)\;\
\ \ \ pop\ \@dirs\;\ \#\ pop\ STDmaker\
\ \ \ pop\ \@dirs\;\ \#\ pop\ Test\
\ \ \ pop\ \@dirs\;\ \#\ pop\ t\
\ \ \ \$dir\ \=\ File\:\:Spec\-\>catdir\(\$vol\,\@dirs\)\;\
\ \ \ my\ \@t_path\ \=\ \$tmaker\-\>find_t_roots\(\)\;"); # typed in command           
         my $OS = $^O;  # Need to escape the form delimiting char ^
   unless ($OS) {   # on some perls $^O is not defined
     require Config;
     $OS = $Config::Config{'osname'};
   } 
   my($vol, $dir) = File::Spec->splitpath(cwd(),'nofile');
   my @dirs = File::Spec->splitdir($dir);
   pop @dirs; # pop STDmaker
   pop @dirs; # pop Test
   pop @dirs; # pop t
   $dir = File::Spec->catdir($vol,@dirs);
   my @t_path = $tmaker->find_t_roots(); # execution



demo( "\$t_path\[0\]", # typed in command           
      $t_path[0]); # execution


demo( "\ \ \ \ \#\#\#\#\#\
\ \ \ \ \#\ Make\ sure\ there\ is\ no\ residue\ outputs\ hanging\
\ \ \ \ \#\ around\ from\ the\ last\ test\ series\.\
\ \ \ \ \#\
\ \ \ \ \@outputs\ \=\ bsd_glob\(\ \'tg\*1\.\*\'\ \)\;\
\ \ \ \ unlink\ \@outputs\;\
\ \ \ \ unlink\ \'tgC1\.pm\'\;\
\
\ \ \ \ \#\#\#\#\#\
\ \ \ \ \#\ Suppress\ some\ annoying\ warnings\
\ \ \ \ \#\
\ \ \ \ sub\ __warn__\ \
\ \ \ \ \{\ \
\ \ \ \ \ \ \ my\ \(\$text\)\ \=\ \@_\;\
\ \ \ \ \ \ \ return\ \$text\ \=\~\ \/STDOUT\/\;\
\ \ \ \ \ \ \ CORE\:\:warn\(\ \$text\ \)\;\
\ \ \ \ \}\;"); # typed in command           
          #####
    # Make sure there is no residue outputs hanging
    # around from the last test series.
    #
    @outputs = bsd_glob( 'tg*1.*' );
    unlink @outputs;
    unlink 'tgC1.pm';

    #####
    # Suppress some annoying warnings
    #
    sub __warn__ 
    { 
       my ($text) = @_;
       return $text =~ /STDOUT/;
       CORE::warn( $text );
    }; # execution




=head1 NAME

advance.d - demostration script for Test::STDmaker

=head1 SYNOPSIS

 advance.d

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


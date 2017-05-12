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
# Name: basic.d
#
# UUT: Test::STDmaker
#
# The module Test::STDmaker generated this demo script from the contents of
#
# t::Test::STDmaker::basic 
#
# Don't edit this test script file, edit instead
#
# t::Test::STDmaker::basic
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


demo( "\$snl\-\>fin\(\'tgA0\.pm\'\)", # typed in command           
      $snl->fin('tgA0.pm')); # execution


print << "EOF";

 ##################
 # tmake('STD', {pm => 't::Test::STDmaker::tgA1'})
 # 
 
EOF

demo( "\ \ \ \ copy\ \'tgA0\.pm\'\,\ \'tgA1\.pm\'\;\
\ \ \ \ my\ \$tmaker\ \=\ new\ Test\:\:STDmaker\(pm\ \=\>\'t\:\:Test\:\:STDmaker\:\:tgA1\'\,\ nounlink\ \=\>\ 1\)\;\
\ \ \ \ my\ \$perl_executable\ \=\ \$tmaker\-\>perl_command\(\)\;\
\ \ \ \ \$success\ \=\ \$tmaker\-\>tmake\(\ \'STD\'\ \)\;\
\ \ \ \ \$diag\ \=\ \"\\n\~\~\~\~\~\~\~\\nFormDB\\n\\n\"\ \.\ join\ \"\\n\"\,\ \@\{\$tmaker\-\>\{FormDB\}\}\;\
\ \ \ \ \$diag\ \.\=\ \"\\n\~\~\~\~\~\~\~\\nstd_db\\n\\n\"\ \.\ join\ \"\\n\"\,\ \@\{\$tmaker\-\>\{std_db\}\}\;\
\ \ \ \ \$diag\ \.\=\ \(\-e\ \'temp\.pl\'\)\ \?\ \"\\n\~\~\~\~\~\~\~\\ntemp\.pl\\n\\n\"\ \.\ \$snl\-\>fin\(\'temp\.pl\'\)\ \:\ \'No\ temp\.pl\'\;\
\ \ \ \ \$diag\ \.\=\ \(\-e\ \'tgA1\.pm\'\)\ \?\ \"\\n\~\~\~\~\~\~\~\\ntgA1\.pm\\n\\n\"\ \.\ \$snl\-\>fin\(\'tgA1\.pm\'\)\ \:\ \'No\ tgA1\.pm\'\;"); # typed in command           
          copy 'tgA0.pm', 'tgA1.pm';
    my $tmaker = new Test::STDmaker(pm =>'t::Test::STDmaker::tgA1', nounlink => 1);
    my $perl_executable = $tmaker->perl_command();
    $success = $tmaker->tmake( 'STD' );
    $diag = "\n~~~~~~~\nFormDB\n\n" . join "\n", @{$tmaker->{FormDB}};
    $diag .= "\n~~~~~~~\nstd_db\n\n" . join "\n", @{$tmaker->{std_db}};
    $diag .= (-e 'temp.pl') ? "\n~~~~~~~\ntemp.pl\n\n" . $snl->fin('temp.pl') : 'No temp.pl';
    $diag .= (-e 'tgA1.pm') ? "\n~~~~~~~\ntgA1.pm\n\n" . $snl->fin('tgA1.pm') : 'No tgA1.pm'; # execution



demo( "\$success", # typed in command           
      $success); # execution


print << "EOF";

 ##################
 # Clean STD pm with a todo list
 # 
 
EOF

demo( "\$s\-\>scrub_date_version\(\$snl\-\>fin\(\'tgA1\.pm\'\)\)", # typed in command           
      $s->scrub_date_version($snl->fin('tgA1.pm'))); # execution


print << "EOF";

 ##################
 # Cleaned tgA1.pm
 # 
 
EOF

demo( ""); # typed in command           
      ; # execution



demo( "\$s\-\>scrub_date_version\(\$snl\-\>fin\(\'tgA1\.pm\'\)\)", # typed in command           
      $s->scrub_date_version($snl->fin('tgA1.pm'))); # execution


print << "EOF";

 ##################
 # Internal Storage
 # 
 
EOF

demo( "\ \ \ \ use\ Data\:\:Dumper\;\
\ \ \ \ my\ \$probe\ \=\ 3\;\
\ \ \ \ my\ \$actual_results\ \=\ Dumper\(\[0\+\$probe\]\)\;\
\ \ \ \ my\ \$internal_storage\ \=\ \'undetermine\'\;\
\ \ \ \ if\(\ \$actual_results\ eq\ Dumper\(\[3\]\)\ \)\ \{\
\ \ \ \ \ \ \ \ \$internal_storage\ \=\ \'number\'\;\
\ \ \ \ \}\
\ \ \ \ elsif\ \(\ \$actual_results\ eq\ Dumper\(\[\'3\'\]\)\ \)\ \{\
\ \ \ \ \ \ \ \ \$internal_storage\ \=\ \'string\'\;\
\ \ \ \ \}\
\
\ \ \ \ my\ \$expected_results\;"); # typed in command           
          use Data::Dumper;
    my $probe = 3;
    my $actual_results = Dumper([0+$probe]);
    my $internal_storage = 'undetermine';
    if( $actual_results eq Dumper([3]) ) {
        $internal_storage = 'number';
    }
    elsif ( $actual_results eq Dumper(['3']) ) {
        $internal_storage = 'string';
    }

    my $expected_results; # execution



demo( "\$internal_storage", # typed in command           
      $internal_storage); # execution


print << "EOF";

 ##################
 # tmake('demo', {pm => 't::Test::STDmaker::tgA1', demo => 1})
 # 
 
EOF

demo( "\$snl\-\>fin\(\ \'tg0\.pm\'\ \ \)", # typed in command           
      $snl->fin( 'tg0.pm'  )); # execution


print << "EOF";

 ##################
 # tmake('demo', {pm => 't::Test::STDmaker::tgA1', demo => 1})
 # 
 
EOF

demo( "\ \ \ \ \#\#\#\#\#\#\#\#\#\
\ \ \ \ \#\
\ \ \ \ \#\ Individual\ generate\ outputs\ using\ options\
\ \ \ \ \#\
\ \ \ \ \#\#\#\#\#\#\#\#\
\
\ \ \ \ skip_tests\(0\)\;\
\
\ \ \ \ \#\#\#\#\#\
\ \ \ \ \#\ Make\ sure\ there\ is\ no\ residue\ outputs\ hanging\
\ \ \ \ \#\ around\ from\ the\ last\ test\ series\.\
\ \ \ \ \#\
\ \ \ \ \@outputs\ \=\ bsd_glob\(\ \'tg\*1\.\*\'\ \)\;\
\ \ \ \ unlink\ \@outputs\;\
\ \ \ \ copy\ \'tg0\.pm\'\,\ \'tg1\.pm\'\;\
\ \ \ \ copy\ \'tgA0\.pm\'\,\ \'tgA1\.pm\'\;\
\ \ \ \ my\ \@cwd\ \=\ File\:\:Spec\-\>splitdir\(\ cwd\(\)\ \)\;\
\ \ \ \ pop\ \@cwd\;\
\ \ \ \ pop\ \@cwd\;\
\ \ \ \ unshift\ \@INC\,\ File\:\:Spec\-\>catdir\(\ \@cwd\ \)\;\ \ \#\ put\ UUT\ in\ lib\ path\
\ \ \ \ \$success\ \=\ \$tmaker\-\>tmake\(\'demo\'\,\ \{\ pm\ \=\>\ \'t\:\:Test\:\:STDmaker\:\:tgA1\'\,\ demo\ \=\>\ 1\}\)\;\
\ \ \ \ shift\ \@INC\;\
\
\ \ \ \ \#\#\#\#\#\#\#\
\ \ \ \ \#\ expected\ results\ depend\ upon\ the\ internal\ storage\ from\ numbers\ \
\ \ \ \ \#\
\ \ \ \ if\(\ \$internal_storage\ eq\ \'string\'\)\ \{\
\ \ \ \ \ \ \ \ \$expected_results\ \=\ \'tg2B\.pm\'\;\
\ \ \ \ \}\
\ \ \ \ else\ \{\
\ \ \ \ \ \ \ \ \$expected_results\ \=\ \'tg2A\.pm\'\;\
\ \ \ \ \}\
\ \ \ \ \$diag\ \=\ \"\\n\~\~\~\~\~\~\~\\nFormDB\\n\\n\"\ \.\ join\ \"\\n\"\,\ \@\{\$tmaker\-\>\{FormDB\}\}\;\
\ \ \ \ \$diag\ \.\=\ \"\\n\~\~\~\~\~\~\~\\nstd_db\\n\\n\"\ \.\ join\ \"\\n\"\,\ \@\{\$tmaker\-\>\{std_db\}\}\;\
\ \ \ \ \$diag\ \.\=\ \(\-e\ \'tgA1\.pm\'\)\ \?\ \"\\n\~\~\~\~\~\~\~\\ntgA1\.pm\\n\\n\"\ \.\ \$snl\-\>fin\(\'tgA1\.pm\'\)\ \:\ \'No\ tgA1\.pm\'\;\
\ \ \ \ \$diag\ \.\=\ \(\-e\ \'tgA1\.d\'\)\ \?\ \"\\n\~\~\~\~\~\~\~\\ntgA1\.d\\n\\n\"\ \.\ \$snl\-\>fin\(\'tgA1\.d\'\)\ \:\ \'No\ tgA1\.d\'\;"); # typed in command           
          #########
    #
    # Individual generate outputs using options
    #
    ########

    skip_tests(0);

    #####
    # Make sure there is no residue outputs hanging
    # around from the last test series.
    #
    @outputs = bsd_glob( 'tg*1.*' );
    unlink @outputs;
    copy 'tg0.pm', 'tg1.pm';
    copy 'tgA0.pm', 'tgA1.pm';
    my @cwd = File::Spec->splitdir( cwd() );
    pop @cwd;
    pop @cwd;
    unshift @INC, File::Spec->catdir( @cwd );  # put UUT in lib path
    $success = $tmaker->tmake('demo', { pm => 't::Test::STDmaker::tgA1', demo => 1});
    shift @INC;

    #######
    # expected results depend upon the internal storage from numbers 
    #
    if( $internal_storage eq 'string') {
        $expected_results = 'tg2B.pm';
    }
    else {
        $expected_results = 'tg2A.pm';
    }
    $diag = "\n~~~~~~~\nFormDB\n\n" . join "\n", @{$tmaker->{FormDB}};
    $diag .= "\n~~~~~~~\nstd_db\n\n" . join "\n", @{$tmaker->{std_db}};
    $diag .= (-e 'tgA1.pm') ? "\n~~~~~~~\ntgA1.pm\n\n" . $snl->fin('tgA1.pm') : 'No tgA1.pm';
    $diag .= (-e 'tgA1.d') ? "\n~~~~~~~\ntgA1.d\n\n" . $snl->fin('tgA1.d') : 'No tgA1.d'; # execution



demo( "\$success", # typed in command           
      $success); # execution


print << "EOF";

 ##################
 # Generate and replace a demonstration
 # 
 
EOF

demo( "\$s\-\>scrub_date_version\(\$snl\-\>fin\(\'tg1\.pm\'\)\)", # typed in command           
      $s->scrub_date_version($snl->fin('tg1.pm'))); # execution


print << "EOF";

 ##################
 # tmake('verify', {pm => 't::Test::STDmaker::tgA1', run => 1, test_verbose => 1})
 # 
 
EOF

demo( "\ \ \ \ skip_tests\(0\)\;\
\
\ \ \ \ no\ warnings\;\
\ \ \ \ open\ SAVEOUT\,\ \"\>\&STDOUT\"\;\
\ \ \ \ use\ warnings\;\
\ \ \ \ open\ STDOUT\,\ \"\>tgA1\.txt\"\;\
\ \ \ \ \$success\ \=\ \$tmaker\-\>tmake\(\'verify\'\,\ \{\ pm\ \=\>\ \'t\:\:Test\:\:STDmaker\:\:tgA1\'\,\ run\ \=\>\ 1\,\ test_verbose\ \=\>\ 1\}\)\;\
\ \ \ \ close\ STDOUT\;\
\ \ \ \ open\ STDOUT\,\ \"\>\&SAVEOUT\"\;\
\ \ \ \ \
\ \ \ \ \#\#\#\#\#\#\
\ \ \ \ \#\ For\ some\ reason\,\ test\ harness\ puts\ in\ a\ extra\ line\ when\ running\ u\
\ \ \ \ \#\ under\ the\ Active\ debugger\ on\ Win32\.\ So\ just\ take\ it\ out\.\
\ \ \ \ \#\ Also\ the\ script\ name\ is\ absolute\ which\ is\ site\ dependent\.\
\ \ \ \ \#\ Take\ it\ out\ of\ the\ comparision\.\
\ \ \ \ \#\
\ \ \ \ \$test_results\ \=\ \$snl\-\>fin\(\'tgA1\.txt\'\)\;\
\ \ \ \ \$test_results\ \=\~\ s\/\.\*\?1\.\.9\/1\.\.9\/\;\ \
\ \ \ \ \$test_results\ \=\~\ s\/\-\-\-\-\-\-\.\*\?\\n\(\\s\*\\\(\)\/\\n\ \$1\/s\;\
\ \ \ \ \$snl\-\>fout\(\'tgA1\.txt\'\,\$test_results\)\;"); # typed in command           
          skip_tests(0);

    no warnings;
    open SAVEOUT, ">&STDOUT";
    use warnings;
    open STDOUT, ">tgA1.txt";
    $success = $tmaker->tmake('verify', { pm => 't::Test::STDmaker::tgA1', run => 1, test_verbose => 1});
    close STDOUT;
    open STDOUT, ">&SAVEOUT";
    
    ######
    # For some reason, test harness puts in a extra line when running u
    # under the Active debugger on Win32. So just take it out.
    # Also the script name is absolute which is site dependent.
    # Take it out of the comparision.
    #
    $test_results = $snl->fin('tgA1.txt');
    $test_results =~ s/.*?1..9/1..9/; 
    $test_results =~ s/------.*?\n(\s*\()/\n $1/s;
    $snl->fout('tgA1.txt',$test_results); # execution



demo( "\$success", # typed in command           
      $success); # execution


print << "EOF";

 ##################
 # Generate and verbose test harness run test script
 # 
 
EOF

demo( "\$s\-\>scrub_probe\(\$s\-\>scrub_test_file\(\$s\-\>scrub_file_line\(\$test_results\)\)\)", # typed in command           
      $s->scrub_probe($s->scrub_test_file($s->scrub_file_line($test_results)))); # execution


print << "EOF";

 ##################
 # Generate and test harness run test script
 # 
 
EOF

demo( "\$test_results", # typed in command           
      $test_results); # execution


demo( "\$snl\-\>fin\(\'tgB0\.pm\'\)", # typed in command           
      $snl->fin('tgB0.pm')); # execution


demo( "\ \ \ \ skip_tests\(0\)\;\
\ \ \ \ copy\ \'tgB0\.pm\'\,\ \'tgB1\.pm\'\;\
\ \ \ \ \$success\ \=\ \$tmaker\-\>tmake\(\'STD\'\,\ \'verify\'\,\ \{pm\ \=\>\ \'t\:\:Test\:\:STDmaker\:\:tgB1\'\,\ nounlink\ \=\>\ 1\}\ \)\;\
\ \ \ \ \$diag\ \=\ \"\\n\~\~\~\~\~\~\~\\nFormDB\\n\\n\"\ \.\ join\ \"\\n\"\,\ \@\{\$tmaker\-\>\{FormDB\}\}\;\
\ \ \ \ \$diag\ \.\=\ \"\\n\~\~\~\~\~\~\~\\nstd_db\\n\\n\"\ \.\ join\ \"\\n\"\,\ \@\{\$tmaker\-\>\{std_db\}\}\;\
\ \ \ \ \$diag\ \.\=\ \(\-e\ \'temp\.pl\'\)\ \?\ \"\\n\~\~\~\~\~\~\~\\ntemp\.pl\\n\\n\"\ \.\ \$snl\-\>fin\(\'temp\.pl\'\)\ \:\ \'No\ temp\.pl\'\;\
\ \ \ \ \$diag\ \.\=\ \(\-e\ \'tgB1\.pm\'\)\ \?\ \"\\n\~\~\~\~\~\~\~\\ntgB1\.pm\\n\\n\"\ \.\ \$snl\-\>fin\(\'tgB1\.pm\'\)\ \:\ \'No\ tgB1\.pm\'\;\
\ \ \ \ \$diag\ \.\=\ \(\-e\ \'tgB1\.t\'\)\ \?\ \"\\n\~\~\~\~\~\~\~\\ntgB1\.t\\n\\n\"\ \.\ \$snl\-\>fin\(\'tgB1\.t\'\)\ \:\ \'No\ tgB1\.t\'\;"); # typed in command           
          skip_tests(0);
    copy 'tgB0.pm', 'tgB1.pm';
    $success = $tmaker->tmake('STD', 'verify', {pm => 't::Test::STDmaker::tgB1', nounlink => 1} );
    $diag = "\n~~~~~~~\nFormDB\n\n" . join "\n", @{$tmaker->{FormDB}};
    $diag .= "\n~~~~~~~\nstd_db\n\n" . join "\n", @{$tmaker->{std_db}};
    $diag .= (-e 'temp.pl') ? "\n~~~~~~~\ntemp.pl\n\n" . $snl->fin('temp.pl') : 'No temp.pl';
    $diag .= (-e 'tgB1.pm') ? "\n~~~~~~~\ntgB1.pm\n\n" . $snl->fin('tgB1.pm') : 'No tgB1.pm';
    $diag .= (-e 'tgB1.t') ? "\n~~~~~~~\ntgB1.t\n\n" . $snl->fin('tgB1.t') : 'No tgB1.t'; # execution



print << "EOF";

 ##################
 # tmake('STD', 'verify', {pm => 't::Test::STDmaker::tgB1'})
 # 
 
EOF

demo( "\$success", # typed in command           
      $success); # execution


print << "EOF";

 ##################
 # Clean STD pm without a todo list
 # 
 
EOF

demo( "\$s\-\>scrub_date_version\(\$snl\-\>fin\(\'tgB1\.pm\'\)\)", # typed in command           
      $s->scrub_date_version($snl->fin('tgB1.pm'))); # execution


print << "EOF";

 ##################
 # Generated and execute the test script
 # 
 
EOF

demo( "\ \ \ \ \$test_results\ \=\ \`\$perl_executable\ tgB1\.t\`\;\
\ \ \ \ \$snl\-\>fout\(\'tgB1\.txt\'\,\ \$test_results\)\;"); # typed in command           
          $test_results = `$perl_executable tgB1.t`;
    $snl->fout('tgB1.txt', $test_results); # execution



demo( "\$s\-\>scrub_probe\(\$s\-\>scrub_file_line\(\$test_results\)\)", # typed in command           
      $s->scrub_probe($s->scrub_file_line($test_results))); # execution


demo( "\ \ \ \ \#\#\#\#\#\
\ \ \ \ \#\ Make\ sure\ there\ is\ no\ residue\ outputs\ hanging\
\ \ \ \ \#\ around\ from\ the\ last\ test\ series\.\
\ \ \ \ \#\
\ \ \ \ \@outputs\ \=\ bsd_glob\(\ \'tg\*1\.\*\'\ \)\;\
\ \ \ \ unlink\ \@outputs\;\
\ \ \ \ unlink\ \'tgA1\.pm\'\;\
\ \ \ \ unlink\ \'tgB1\.pm\'\;\
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
    unlink 'tgA1.pm';
    unlink 'tgB1.pm';
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

basic.d - demostration script for Test::STDmaker

=head1 SYNOPSIS

 basic.d

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


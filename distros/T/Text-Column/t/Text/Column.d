#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '0.04';   # automatically generated file
$DATE = '2003/07/27';


##### Demonstration Script ####
#
# Name: Column.d
#
# UUT: Text::Column
#
# The module Test::STDmaker generated this demo script from the contents of
#
# t::Text::Column 
#
# Don't edit this test script file, edit instead
#
# t::Text::Column
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
    use File::TestPath;
    use Test::Tech qw(tech_config plan demo skip_tests);

    ########
    # Working directory is that of the script file
    #
    $__restore_dir__ = cwd();
    my ($vol, $dirs, undef) = File::Spec->splitpath(__FILE__);
    chdir $vol if $vol;
    chdir $dirs if $dirs;

    #######
    # Add the library of the unit under test (UUT) to @INC
    #
    @__restore_inc__ = File::TestPath->test_lib2inc();

    unshift @INC, File::Spec->catdir( cwd(), 'lib' ); 

}

END {

   #########
   # Restore working directory and @INC back to when enter script
   #
   @INC = @__restore_inc__;
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

demo( "\ \ \ \ use\ File\:\:Spec\;\
\
\ \ \ \ use\ File\:\:Package\;\
\ \ \ \ my\ \$fp\ \=\ \'File\:\:Package\'\;\
\
\ \ \ \ my\ \$tt\ \=\ \'Text\:\:Column\'\;\
\
\ \ \ \ my\ \$loaded\ \=\ \'\'\;\
\ \ \ \ my\ \$template\ \=\ \'\'\;\
\ \ \ \ my\ \%variables\ \=\ \(\)\;\
\ \ \ \ my\ \$expected\ \=\ \'\'\;"); # typed in command           
          use File::Spec;

    use File::Package;
    my $fp = 'File::Package';

    my $tt = 'Text::Column';

    my $loaded = '';
    my $template = '';
    my %variables = ();
    my $expected = '';; # execution

demo( "my\ \$errors\ \=\ \$fp\-\>load_package\(\$tt\)"); # typed in command           
      my $errors = $fp->load_package($tt); # execution

demo( "\$errors", # typed in command           
      $errors # execution
) unless     $loaded; # condition for execution                            

demo( "my\ \@array_table\ \=\ \ \(\
\ \ \ \[qw\(module\.pm\ 0\.01\ 2003\/5\/6\ new\)\]\,\
\ \ \ \[qw\(bin\/script\.pl\ 1\.04\ 2003\/5\/5\ generated\)\]\,\
\ \ \ \[qw\(bin\/script\.pod\ 3\.01\ 2003\/6\/8\)\,\ \'revised\ 2\.03\'\]\
\)\;"); # typed in command           
      my @array_table =  (
   [qw(module.pm 0.01 2003/5/6 new)],
   [qw(bin/script.pl 1.04 2003/5/5 generated)],
   [qw(bin/script.pod 3.01 2003/6/8), 'revised 2.03']
);; # execution

demo( "\$tt\-\>format_array_table\(\\\@array_table\,\ \[15\,7\,10\,15\]\,\[qw\(file\ version\ date\ comment\)\]\)", # typed in command           
      $tt->format_array_table(\@array_table, [15,7,10,15],[qw(file version date comment)])); # execution


demo( "my\ \%hash_table\ \=\ \ \(\
\ \ \ \'module\.pm\'\ \=\>\ \[qw\(0\.01\ 2003\/5\/6\ new\)\]\,\
\ \ \ \'bin\/script\.pl\'\ \=\>\ \[qw\(1\.04\ 2003\/5\/5\ generated\)\]\,\
\ \ \ \'bin\/script\.pod\'\ \=\>\ \[qw\(3\.01\ 2003\/6\/8\)\,\ \'revised\ 2\.03\'\]\
\)\;"); # typed in command           
      my %hash_table =  (
   'module.pm' => [qw(0.01 2003/5/6 new)],
   'bin/script.pl' => [qw(1.04 2003/5/5 generated)],
   'bin/script.pod' => [qw(3.01 2003/6/8), 'revised 2.03']
);; # execution

demo( "\$tt\-\>format_hash_table\(\\\%hash_table\,\ \[15\,7\,10\,15\]\,\[qw\(file\ version\ date\ comment\)\]\)", # typed in command           
      $tt->format_hash_table(\%hash_table, [15,7,10,15],[qw(file version date comment)])); # execution


demo( "\%hash_table\ \=\ \ \(\
\ \ \ \'L\<test1\>\'\ \=\>\ \{\'L\<requirement4\>\'\ \=\>\ undef\,\ \'L\<requirement1\>\'\ \=\>\ undef\ \}\,\
\ \ \ \'L\<test2\>\'\ \=\>\ \{\'L\<requirement3\>\'\ \=\>\ undef\ \}\,\
\ \ \ \'L\<test3\>\'\ \=\>\ \{\'L\<requirement2\>\'\ \=\>\ undef\,\ \'L\<requirement1\>\'\ \=\>\ undef\ \}\,\
\)\;"); # typed in command           
      %hash_table =  (
   'L<test1>' => {'L<requirement4>' => undef, 'L<requirement1>' => undef },
   'L<test2>' => {'L<requirement3>' => undef },
   'L<test3>' => {'L<requirement2>' => undef, 'L<requirement1>' => undef },
);; # execution

demo( "\$tt\-\>format_hash_table\(\\\%hash_table\,\ \[20\,20\]\,\[qw\(test\ requirement\)\]\)", # typed in command           
      $tt->format_hash_table(\%hash_table, [20,20],[qw(test requirement)])); # execution



=head1 NAME

Column.d - demostration script for Text::Column

=head1 SYNOPSIS

 Column.d

=head1 OPTIONS

None.

=head1 COPYRIGHT

copyright © 2003 Software Diamonds.

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

## end of test script file ##

=cut


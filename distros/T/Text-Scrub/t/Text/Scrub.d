#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '0.03';   # automatically generated file
$DATE = '2004/05/10';


##### Demonstration Script ####
#
# Name: Scrub.d
#
# UUT: Text::Scrub
#
# The module Test::STDmaker generated this demo script from the contents of
#
# t::Text::Scrub 
#
# Don't edit this test script file, edit instead
#
# t::Text::Scrub
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

demo( "\ \ \ \ use\ File\:\:Spec\;\
\
\ \ \ \ use\ File\:\:Package\;\
\ \ \ \ my\ \$fp\ \=\ \'File\:\:Package\'\;\
\
\ \ \ \ my\ \$uut\ \=\ \'Text\:\:Scrub\'\;\
\
\ \ \ \ my\ \$loaded\ \=\ \'\'\;\
\ \ \ \ my\ \$template\ \=\ \'\'\;\
\ \ \ \ my\ \%variables\ \=\ \(\)\;\
\ \ \ \ my\ \$expected\ \=\ \'\'\;"); # typed in command           
          use File::Spec;

    use File::Package;
    my $fp = 'File::Package';

    my $uut = 'Text::Scrub';

    my $loaded = '';
    my $template = '';
    my %variables = ();
    my $expected = '';; # execution

print << "EOF";

 ##################
 # Load UUT
 # 
 
EOF

demo( "my\ \$errors\ \=\ \$fp\-\>load_package\(\$uut\)"); # typed in command           
      my $errors = $fp->load_package($uut); # execution

demo( "\$errors", # typed in command           
      $errors # execution
) unless     $loaded; # condition for execution                            

print << "EOF";

 ##################
 #  scrub_file_line
 # 
 
EOF

demo( "my\ \$text\ \=\ \'ok\ 2\ \#\ \(E\:\/User\/SoftwareDiamonds\/installation\/t\/Test\/STDmaker\/tgA1\.t\ at\ line\ 123\ TODO\?\!\)\'"); # typed in command           
      my $text = 'ok 2 # (E:/User/SoftwareDiamonds/installation/t/Test/STDmaker/tgA1.t at line 123 TODO?!)'; # execution

demo( "\$uut\-\>scrub_file_line\(\$text\)", # typed in command           
      $uut->scrub_file_line($text)); # execution


print << "EOF";

 ##################
 #  scrub_test_file
 # 
 
EOF

demo( "\$text\ \=\ \'Running\ Tests\\n\\nE\:\/User\/SoftwareDiamonds\/installation\/t\/Test\/STDmaker\/tgA1\.1\.\.16\ todo\ 2\ 5\;\'"); # typed in command           
      $text = 'Running Tests\n\nE:/User/SoftwareDiamonds/installation/t/Test/STDmaker/tgA1.1..16 todo 2 5;'; # execution

demo( "\$uut\-\>scrub_test_file\(\$text\)", # typed in command           
      $uut->scrub_test_file($text)); # execution


print << "EOF";

 ##################
 #  scrub_date_version
 # 
 
EOF

demo( "\$text\ \=\ \'\$VERSION\ \=\ \\\'0\.01\\\'\;\\n\$DATE\ \=\ \\\'2003\/06\/07\\\'\;\'"); # typed in command           
      $text = '$VERSION = \'0.01\';\n$DATE = \'2003/06/07\';'; # execution

demo( "\$uut\-\>scrub_date_version\(\$text\)", # typed in command           
      $uut->scrub_date_version($text)); # execution


print << "EOF";

 ##################
 #  scrub_date_ticket
 # 
 
EOF

demo( "\$text\ \=\ \<\<\'EOF\'\;\
Date\:\ Apr\ 12\ 00\ 00\ 00\ 2003\ \+0000\
Subject\:\ 20030506\,\ This\ Week\ in\ Health\'\
X\-SDticket\:\ 20030205\
X\-eudora\-date\:\ Feb\ 6\ 2000\ 00\ 00\ 2003\ \+0000\
X\-SDmailit\:\ dead\ Feb\ 5\ 2000\ 00\ 00\ 2003\
Sent\ email\ 20030205\-20030506\ to\ support\.softwarediamonds\.com\
EOF\
\
my\ \$expected_text\ \=\ \<\<\'EOF\'\;\
Date\:\ Feb\ 6\ 00\ 00\ 00\ 1969\ \+0000\
Subject\:\ XXXXXXXXX\-X\,\ \ This\ Week\ in\ Health\'\
X\-SDticket\:\ XXXXXXXXX\-X\
X\-eudora\-date\:\ Feb\ 6\ 00\ 00\ 00\ 1969\ \+0000\
X\-SDmailit\:\ dead\ Sat\ Feb\ 6\ 00\ 00\ 00\ 1969\ \+0000\
Sent\ email\ XXXXXXXXX\-X\ to\ support\.softwarediamonds\.com\
EOF\
\
\#\ end\ of\ EOF"); # typed in command           
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

# end of EOF; # execution

demo( "\$uut\-\>scrub_date_ticket\(\$text\)", # typed in command           
      $uut->scrub_date_ticket($text)); # execution


print << "EOF";

 ##################
 #  scrub_date
 # 
 
EOF

demo( "\$text\ \=\ \'Going\ to\ happy\ valley\ 2003\/06\/07\'"); # typed in command           
      $text = 'Going to happy valley 2003/06/07'; # execution

demo( "\$uut\-\>scrub_date\(\$text\)", # typed in command           
      $uut->scrub_date($text)); # execution


print << "EOF";

 ##################
 #  scrub_probe
 # 
 
EOF

demo( "\$text\ \=\ \<\<\'EOF\'\;\
1\.\.8\ todo\ 2\ 5\;\
\#\ OS\ \ \ \ \ \ \ \ \ \ \ \ \:\ MSWin32\
\#\ Perl\ \ \ \ \ \ \ \ \ \ \:\ 5\.6\.1\
\#\ Local\ Time\ \ \ \ \:\ Thu\ Jun\ 19\ 23\:49\:54\ 2003\
\#\ GMT\ Time\ \ \ \ \ \ \:\ Fri\ Jun\ 20\ 03\:49\:54\ 2003\ GMT\
\#\ Number\ Storage\:\ string\
\#\ Test\:\:Tech\ \ \ \ \:\ 1\.06\
\#\ Test\ \ \ \ \ \ \ \ \ \ \:\ 1\.15\
\#\ Data\:\:Dumper\ \ \:\ 2\.102\
\#\ \=cut\ \
\#\ Pass\ test\
ok\ 1\
EOF\
\
\$expected_text\ \=\ \<\<\'EOF\'\;\
1\.\.8\ todo\ 2\ 5\;\
\#\ Pass\ test\
ok\ 1\
EOF\
\
\#\ end\ of\ EOF"); # typed in command           
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

# end of EOF; # execution

demo( "\$uut\-\>scrub_probe\(\$text\)", # typed in command           
      $uut->scrub_probe($text)); # execution


print << "EOF";

 ##################
 #  scrub_architect
 # 
 
EOF

demo( "\$text\ \=\ \'ARCHITECTURE\ NAME\=\"MSWin32\-x86\-multi\-thread\-5\.5\"\'"); # typed in command           
      $text = 'ARCHITECTURE NAME="MSWin32-x86-multi-thread-5.5"'; # execution

demo( "\$uut\-\>scrub_architect\(\$text\)", # typed in command           
      $uut->scrub_architect($text)); # execution


demo( "unlink\ \'actual\.txt\'"); # typed in command           
      unlink 'actual.txt'; # execution


=head1 NAME

Scrub.d - demostration script for Text::Scrub

=head1 SYNOPSIS

 Scrub.d

=head1 OPTIONS

None.

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

## end of test script file ##

=cut


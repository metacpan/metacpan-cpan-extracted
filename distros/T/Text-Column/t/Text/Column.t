#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '0.05';   # automatically generated file
$DATE = '2003/09/15';
$FILE = __FILE__;

use Getopt::Long;
use Cwd;
use File::Spec;

##### Test Script ####
#
# Name: Column.t
#
# UUT: Text::Column
#
# The module Test::STDmaker generated this test script from the contents of
#
# t::Text::Column;
#
# Don't edit this test script file, edit instead
#
# t::Text::Column;
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
   use vars qw( $__restore_dir__ @__restore_inc__);

   ########
   # Working directory is that of the script file
   #
   $__restore_dir__ = cwd();
   my ($vol, $dirs) = File::Spec->splitpath(__FILE__);
   chdir $vol if $vol;
   chdir $dirs if $dirs;
   ($vol, $dirs) = File::Spec->splitpath(cwd(), 'nofile'); # absolutify

   #######
   # Add the library of the unit under test (UUT) to @INC
   # It will be found first because it is first in the include path
   #
   use Cwd;
   @__restore_inc__ = @INC;

   ######
   # Find root path of the t directory
   #
   my @updirs = File::Spec->splitdir( $dirs );
   while(@updirs && $updirs[-1] ne 't' ) { 
       chdir File::Spec->updir();
       pop @updirs;
   };
   chdir File::Spec->updir();
   my $lib_dir = cwd();

   #####
   # Add this to the include path. Thus modules that start with t::
   # will be found.
   # 
   $lib_dir =~ s|/|\\|g if $^O eq 'MSWin32';  # microsoft abberation
   unshift @INC, $lib_dir;  # include the current test directory

   #####
   # Add lib to the include path so that modules under lib at the
   # same level as t, will be found
   #
   $lib_dir = File::Spec->catdir( cwd(), 'lib' );
   $lib_dir =~ s|/|\\|g if $^O eq 'MSWin32';  # microsoft abberation
   unshift @INC, $lib_dir;

   #####
   # Add tlib to the include path so that modules under tlib at the
   # same level as t, will be found
   #
   $lib_dir = File::Spec->catdir( cwd(), 'tlib' );
   $lib_dir =~ s|/|\\|g if $^O eq 'MSWin32';  # microsoft abberation
   unshift @INC, $lib_dir;
   chdir $dirs if $dirs;
 
   #####
   # Add lib under the directory where the test script resides.
   # This may be used to place version sensitive modules.
   #
   $lib_dir = File::Spec->catdir( cwd(), 'lib' );
   $lib_dir =~ s|/|\\|g if $^O eq 'MSWin32';  # microsoft abberation
   unshift @INC, $lib_dir;

   ##########
   # Pick up a output redirection file and tests to skip
   # from the command line.
   #
   my $test_log = '';
   GetOptions('log=s' => \$test_log);

   ########
   # Using Test::Tech, a very light layer over the module "Test" to
   # conduct the tests.  The big feature of the "Test::Tech: module
   # is that it takes a expected and actual reference and stringify
   # them by using "Data::Dumper" before passing them to the "ok"
   # in test.
   #
   # Create the test plan by supplying the number of tests
   # and the todo tests
   #
   require Test::Tech;
   Test::Tech->import( qw(plan ok skip skip_tests tech_config) );
   plan(tests => 5);

}



END {

   #########
   # Restore working directory and @INC back to when enter script
   #
   @INC = @__restore_inc__;
   chdir $__restore_dir__;
}

   # Perl code from C:
    use File::Spec;

    use File::Package;
    my $fp = 'File::Package';

    my $tt = 'Text::Column';

    my $loaded = '';
    my $template = '';
    my %variables = ();
    my $expected = '';

ok(  $loaded = $fp->is_package_loaded($tt), # actual results
      '', # expected results
     '',
     'UUT not loaded');

#  ok:  1

   # Perl code from C:
my $errors = $fp->load_package($tt);

skip_tests( 1 ) unless skip(
      $loaded, # condition to skip test   
      $errors, # actual results
      '',  # expected results
      '',
      'Load UUT');
 
#  ok:  2

   # Perl code from C:
my @array_table =  (
   [qw(module.pm 0.01 2003/5/6 new)],
   [qw(bin/script.pl 1.04 2003/5/5 generated)],
   [qw(bin/script.pod 3.01 2003/6/8), 'revised 2.03']
);

   # Perl code from C:
$expected = << 'EOF';
 file            version date       comment
 --------------- ------- ---------- ---------------
 module.pm       0.01    2003/5/6   new
 bin/script.pl   1.04    2003/5/5   generated
 bin/script.pod  3.01    2003/6/8   revised 2.03
EOF

1;

ok(  $tt->format_array_table(\@array_table, [15,7,10,15],[qw(file version date comment)]), # actual results
     $expected, # expected results
     '',
     'format_array_table');

#  ok:  3

   # Perl code from C:
my %hash_table =  (
   'module.pm' => [qw(0.01 2003/5/6 new)],
   'bin/script.pl' => [qw(1.04 2003/5/5 generated)],
   'bin/script.pod' => [qw(3.01 2003/6/8), 'revised 2.03']
);

   # Perl code from C:
$expected = << 'EOF';
 file            version date       comment
 --------------- ------- ---------- ---------------
 bin/script.pl   1.04    2003/5/5   generated
 bin/script.pod  3.01    2003/6/8   revised 2.03
 module.pm       0.01    2003/5/6   new
EOF
1;

ok(  $tt->format_hash_table(\%hash_table, [15,7,10,15],[qw(file version date comment)]), # actual results
     $expected, # expected results
     '',
     'format_hash_table - hash of array');

#  ok:  4

   # Perl code from C:
%hash_table =  (
   'L<test1>' => {'L<requirement4>' => undef, 'L<requirement1>' => undef },
   'L<test2>' => {'L<requirement3>' => undef },
   'L<test3>' => {'L<requirement2>' => undef, 'L<requirement1>' => undef },
);

   # Perl code from C:
$expected = << 'EOF';
 test                 requirement
 -------------------- --------------------
 L<test1>             L<requirement1>
 L<test1>             L<requirement4>
 L<test2>             L<requirement3>
 L<test3>             L<requirement1>
 L<test3>             L<requirement2>
EOF
1;

ok(  $tt->format_hash_table(\%hash_table, [20,20],[qw(test requirement)]), # actual results
     $expected, # expected results
     '',
     'format_hash_table - hash of hash');

#  ok:  5


=head1 NAME

Column.t - test script for Text::Column

=head1 SYNOPSIS

 Column.t -log=I<string>

=head1 OPTIONS

All options may be abbreviated with enough leading characters
to distinguish it from the other options.

=over 4

=item C<-log>

Column.t uses this option to redirect the test results 
from the standard output to a log file.

=back

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

=cut

## end of test script file ##


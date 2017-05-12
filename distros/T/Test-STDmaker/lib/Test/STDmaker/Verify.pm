#!perl
#
# Documentation, copyright and license is at the end of this file.
#

package  Test::STDmaker::Verify;

use 5.001;
use strict;
use warnings;
use warnings::register;

use File::Spec;
use File::AnySpec;
use File::Where;
use Test::Harness 2.42;

use vars qw($VERSION $DATE);
$VERSION = '1.15';
$DATE = '2004/05/22';

########
# Inherit classes
#
use Test::STDmaker;
use vars qw(@ISA);
@ISA = qw(Test::STDmaker);


#############################################################################
#  
#                           TEST DESCRIPTION METHODS
#
#

sub A
{
   my ($self, $command,$data) = @_;
   my $module = ref($self);
   my $module_db = $self->{$module};
   if ( $module_db->{demo_only} ) {
       $module_db->{requirement} = '';
       $module_db->{demo_only} = '';
       $module_db->{demo_only_expected} = 1;
       $module_db->{skip} = '';
       $module_db->{test_name} = '';
       $module_db->{diag_msg} = '';
       $module_db->{test_subroutine} = '',
       return '';
   }

   $self->{$module}->{actual} = $data;
   $module_db->{demo_only_expected} = '';
   ''  # writing actual out in the expected statement
}

sub C
{
   my ($self, $command, $data) = @_;
   my $module = ref($self);
   return '' if  $self->{$module}->{'demo_only'};

   while (chomp $data) { };
   my $end_char = substr( $data,-1,1);
   unless( $self->{options}->{nosemi} ) {
       if ($end_char ne ';' &&  $end_char ne '{' &&   $end_char ne '}' ) {
           $data .= ';'
       }
   }
   $data .= "\n\n";

   << "EOF";
   # Perl code from ${command}:
$data

EOF
 
}

sub DM 
{ 
   my ($self, $command, $data) = @_;
   my $module = ref($self);
   return '' if  $self->{$module}->{demo_only};
   $self->{$module}->{diag_msg} = $data;
   '' 
};



#######
# Condition to skip a test
#
sub DO
{
    my ($self, $command,$data) = @_;
    my $module = ref($self);
    $self->{$module}->{demo_only} = "    $data";
    ''
}





sub E
{
   my ($self, $command, $data) = @_;
   my $module = ref($self);
   my $module_db = $self->{$module};

   if ( $module_db->{demo_only_expected} ) {
       $module_db->{requirement} = '';
       $module_db->{demo_only_expected} = '';
       $module_db->{skip} = '';
       $module_db->{test_name} = '';
       $module_db->{diag_msg} = '';
       $module_db->{test_subroutine} = '',
       return '';
   }

   my $skip = $module_db->{skip};
   my $subroutine = $module_db->{test_subroutine};
   my $requirement = $module_db->{requirement};
   $module_db->{skip} = '';
   $module_db->{requirement} = '';
   $module_db->{test_subroutine} = '';

   my $msg = '';
   if($requirement) {
       $requirement =~ s/\n/\n# /g;
       $msg = "\n####\n# verifies requirement(s):\n# $requirement\n\n#####\n";
   }

   $msg .=  'skip_tests( 1 ) unless' . "\n  " if(  $command eq 'SE' );

   if( $subroutine ) {        

       #######
       # Skip stop statement
       #
       if( $skip ) {
           $msg .=  << "EOF";
skip_sub( $subroutine, # test subroutine
          $skip, # condition to skip test   
          $module_db->{actual}, # actual results
          $data,  # expected results
          \"$module_db->{diag_msg}\",
          \"$module_db->{test_name}\");
 
EOF
       }
       
       #######
       # ok stop statement
       #
       else {

           $msg .=  << "EOF";
ok_sub( $subroutine, # test subroutine
        $module_db->{actual}, # actual results
        $data, # expected results
        \"$module_db->{diag_msg}\",
        \"$module_db->{test_name}\"); 

EOF

       }
  

   }
   else {

       #######
       # Skip ok statement
       #
       if( $skip ) {
           $msg .=  << "EOF";
skip( $skip, # condition to skip test   
      $module_db->{actual}, # actual results
      $data, # expected results
      \"$module_db->{diag_msg}\",
      \"$module_db->{test_name}\");

EOF
       }
       
       #######
       # ok statement
       #
       else {

           $msg .=  << "EOF";
ok(  $module_db->{actual}, # actual results
     $data, # expected results
     \"$module_db->{diag_msg}\",
     \"$module_db->{test_name}\");

EOF
       }
   }

   $module_db->{test_name} = '';
   $module_db->{diag_msg} = '',
   $msg;

}


sub N 
{ 
   my ($self, $command, $data) = @_;
   my $module = ref($self);
   return '' if  $self->{$module}->{demo_only};
   $self->{$module}->{test_name} = $data;
   '' 
};




sub ok
{
   my ($self, $command,$data) = @_;

   << "EOF";
#  ${command}:  $data

EOF

}





sub QC { C(@_) };

sub R
{
   my ($self, $command,$data) = @_;
   my $module = ref($self);
   return '' if  $self->{$module}->{demo_only};

   ######
   # Accumulate for the next expected statement
   #
   $data .= "\n" if substr( $data, length($data)-1,1) ne "\n";
   $self->{$module}->{'requirement'} .= "$data";
   '';
}


sub S
{
   my ($self, $command,$data) = @_;
   my $module = ref($self);
   $self->{$module}->{skip} = $data;
   '';
}


sub SE { E(@_) };


sub SF
{
   my ($self, $command,$data) = @_;
   
   my @data;
   if ($data ) {
       @data = split /\s*,\s*/;
   }
   unless($data[0]) {
       $data[0] = 1;
   }
  
   if($data[1]) {

   << "EOF";
skip_tests( $data[0],$data[1] );

EOF

   }
   else { 

   << "EOF";
skip_tests( $data[0] );

EOF

   }
}




sub T
{
    my ($self, $command, $data) = @_;

    my ($tests, $todo) = split ' - ', $data;

    my $plan = "tests => $tests";
    $plan .= ", todo => [$todo]" if $todo;

    ######
    # Build reference files
    #
    my (undef,undef,$test_script) = File::Spec->splitpath( $self->{Verify} );
    my $uut = File::AnySpec->fspec2pm($self->{File_Spec},  $self->{UUT}  );

    ###########
    # use in variables without have to backslash escape the dollar sign
    # every which way in the below << here statement
    #   
    my ($vol, $dirs, $__restore_dir__) = ('$vol', '$dirs', '$__restore_dir__');
    my ($VERSION, $DATE, $FILE) = ('$VERSION', '$DATE', '$FILE');

    my ($restore_croak, $croak_die_error, $restore_confess, $confess_die_error) =
           ('$restore_croak', '$croak_die_error', '$restore_confess', '$confess_die_error');

    << "EOF";
#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '0.01';   # automatically generated file
$DATE = '$self->{'Date'}';
$FILE = __FILE__;


##### Test Script ####
#
# Name: $test_script
#
# UUT: $uut
#
# The module Test::STDmaker generated this test script from the contents of
#
# $self->{std_pm};
#
# Don't edit this test script file, edit instead
#
# $self->{std_pm};
#
#	ANY CHANGES MADE HERE TO THIS SCRIPT FILE WILL BE LOST
#
#       the next time Test::STDmaker generates this script file.
#
#

######
#
# ${command}:
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
   my ($vol, $dirs) = File::Spec->splitpath(\$FindBin::Bin,'nofile');
   chdir $vol if $vol;
   chdir $dirs if $dirs;

   #######
   # Pick up any testing program modules off this test script.
   #
   # When testing on a target site before installation, place any test
   # program modules that should not be installed in the same directory
   # as this test script. Likewise, when testing on a host with a \@INC
   # restricted to just raw Perl distribution, place any test program
   # modules in the same directory as this test script.
   #
   use lib \$FindBin::Bin;

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
   Test::Tech->import( qw(finish is_skip ok ok_sub plan skip 
                          skip_sub skip_tests tech_config) );
   plan($plan);

}


END {
 
   #########
   # Restore working directory and \@INC back to when enter script
   #
   \@INC = \@lib::ORIG_INC;
   chdir $__restore_dir__;
}




EOF

}

sub TS 
{ 
   my ($self, $command, $data) = @_;
   my $module = ref($self);
   return '' if  $self->{$module}->{demo_only};
   $self->{$module}->{test_subroutine} = $data;
   '' 
};


sub U
{
   my ($self, $command,$data) = @_;
   my $module = ref($self);
   return '' if  $self->{$module}->{demo_only};

   << "EOF";
###
#  $data
#  Under development, i.e todo
EOF

}


sub VO { '' }

##################################################################################
#
#                            ADMINSTRATIVE METHODS
#
#
sub AUTOLOAD
{
    our $AUTOLOAD;
    return undef if $AUTOLOAD =~ /DESTROY/;
    warn "Method $AUTOLOAD not supported by STD::Gen::Verify";
    undef;
}

sub extension { '.t' };

sub finish
{
    my ($self) = @_;

    my (undef,undef,$test_script) = File::Spec->splitpath( $self->{'Verify'} );

    my ($restore_croak, $croak_die_error, $restore_confess, $confess_die_error) =
           ('$restore_croak', '$croak_die_error', '$restore_confess', '$confess_die_error');

    my $msg = << "EOF";

    finish();

__END__

\=head1 NAME

$test_script - test script for $self->{UUT}

\=head1 SYNOPSIS

 $test_script -log=I<string>

\=head1 OPTIONS

All options may be abbreviated with enough leading characters
to distinguish it from the other options.

\=over 4

\=item C<-log>

$test_script uses this option to redirect the test results 
from the standard output to a log file.

\=back

\=head1 COPYRIGHT

$self->{Copyright}

\=cut

## end of test script file ##

EOF

}





#####
#
# Start generating the file 
#
sub post_generate
{
     my ($self) = @_;

     my $module = ref($self);

     #####
     # Run the tests and use the output to
     # replace the =head2 Test Report header in the UUT
     # program module 
     #
     if ($self->{options}->{report}) {
         my $test_report = ();
         my $test_script = '';
         my @test_report;
         my $base_test_script;
         my $perl = $self->perl_command();
         foreach $test_script (@{$self->{$module}->{generated_files}}) {
            (undef,undef,$base_test_script) = File::Spec->splitpath($test_script);
            @test_report = `$perl $test_script`;
            $test_report .= "\n => perl $base_test_script\n\n";
            $test_report .= join '',@test_report;
         };
         $test_report =~ s/\n/\n /g;         

         ######
         # Find uut file
         #
         my $uut = $self->{'UUT'};
         if( $uut ) {
            my ($uut_file) = File::Where->where_pm($uut);
            if( $uut_file && -e $uut_file ) {
                my $uut_contents = File::SmartNL->fin( $uut_file );
                $uut_contents =~ s/(\n=head\d\s+Test Report).*?\n=/$1\n$test_report\n=/si;
                File::SmartNL->fout( $uut_file, $uut_contents);
             }
            else {
                warn("No UUT specified.\n");
            }
         }
     }

     #####
     # Run tests under test harness
     #
     unless ($self->{options}->{run}) {
         @{$self->{$module}->{generated_files}} = ();
         return 1 
     }

     if( $self->{options}->{test_verbose} ) {
         print( "~~~~\nRunning Tests\n\n" );
         $Test::Harness::verbose = 1;
     }
     else {
         $Test::Harness::verbose = 0;
     } 

     ########
     # Run under eval because runtests is loaded with dies
     #
     eval 'runtests( @{$self->{$module}->{generated_files}} )';
     print $@ if $@; # send any die messages to standard out

     @{$self->{$module}->{generated_files}} = ();

     print( "~~~~\nFinished running Tests\n\n" ) if $self->{options}->{test_verbose};

     return 1;

}



sub start
{
     my ($self) = @_;
     my $module = ref($self);
     my $module_db = $self->{$module};

     $module_db->{requirement} = '';
     $module_db->{demo_only} = '';
     $module_db->{demo_only_expected} = 1;
     $module_db->{skip} = '';
     $module_db->{test_name} = '';
     $module_db->{diag_msg} = '';
     $module_db->{test_subroutine} = '',
}

1

__END__

=head1 NAME

Test::STDmaker::Verify - generate test scripts from a test description short hand

=head1 DESCRIPTION

The C<Test::STDmaker::Verify> package is an internal driver package to
the L<Test::STDmaker|Test::STDmaker> package that supports the 
L<Test::STDmaker::tmake()|Test::STDmaker/tmake> method.
Any changes to the internal drive interface and this package will not
even consider backward compatibility.
Thus, this POD serves as a Software Design Folder 
documentation the current internal design of the
C<Test::STDmaker> and its driver packages.

The C<Test::STDmaker::Verify> package inherits the methods of the
C<Test::STDmaker> package.
The C<Test::STDmaker> C<build> C<generate> and <print>
methods directs the C<Test::STDmaker::Verify> package to perform
its work by calling its methods.

The C<Test::STDmaker::Verify> methods builds a test script whereby
the test script loads the L<Test::Tech|Test::Tech> package and
uses the methods from the C<Test::Tech> package.

During the course of the processing the C<Test::STDmaker::Verify>
package maintains the following in the C<$self> object
data hash:

=over 4

=item $actual

the actual results

=item $diag_msg

a diagnostic message

=item $demo_only

Flags if the test is demo only and 
will be ignore as far as the generating
the check test script

=item $demo_only_expected

Once only flag set by the C<A> subroutine
and reset by the next C<E> subroutine.
There should be no C<E> subroutine after
a C<A> demo only subroutine.

=item $requirement

requirements addressed by test

=item $skip

skip condition

=item $name

the name of the test

=item $subroutine

a reference to a test subroutine

}

=back

The C<Test::STDmaker::Verify> package processes the following
options that are passed as part of the C<$self> hash
from C<Test::STDmaker> methods:

=over 4

=item report

Replace the UUT POD 'Test Report' section with the
results from the test script

=item run

Run the test script under the L<Test::Harness|Test::Harness>

=item test_verbose

Set any L<Test::Harness|Test::Harness> run to verbose

=item nosemi

The C<C> subroutine will not automatically add a ';' at
the end of the code field.

=back

=head1 TEST DESCRIPTION METHODS

=head2 A

 $file_data = A($command, $actual-expression );

If the C<demo_only> object data is set, the
C<A> subroutine 
resets the object data and
returns empty for C<$file_data>;
otherwise, the subroutine saves
the C<$actual-expression> in the
C<$actual> object data and returns
empty for C<$file_data>.

=head2 C

 $file_data = C($command, $code);

If the C<demo_only> object data is set, the
C<C> subroutine returns empty for C<$file_data>;
otherwise, the subroutine 
returns C<$file_data> with C<$code> and a comment.

=head2 DM

 $file_data = DM($command, $msg);

If the C<demo_only> object data is set, the
C<DM> subroutine returns empty for C<$file_data>;
otherwise, the subroutine 
sets C<$diag_msg> object data to C<$msg> and
returns an empty for C<$file_data>

=head2 DO

 $file_data = DO($command, $comment);

The C<DO> subroutine 
sets C<$demo_only> object data to C<$comment> and
returns an empty for C<$file_data>

=head2 E
 
 $file_data = E($command, $expected-expression)

If the C<demo_only> object data is set, the
C<E> subroutine 
resets the object data and
returns empty for C<$file_data>;
otherwise, the subroutine builds
and returns C<$file_data> as follows:

=over 4

=item  requirements

adds the C<$requirement> object data as a comment of the
requirementd addressed

=item skip with subroutine

if there is C<$skip> and C<$subroutine> data,
adds the below (all arguments except $expected-expression
are object data):

  skip_sub( $subroutine,
          $skip,    
          $actual,
          $expected-expression,
          $diag_msg,
          $name);

=item skip without subroutine

if there is C<$skip> and no C<$subroutine> data,
adds the below (all arguments except $expected-expression
are object data):

  skip( $subroutine,
          $skip,    
          $actual,
          $expected-expression,
          $diag_msg,
          $name);

=item no skip and subroutine

if there is no C<$skip> and C<$subroutine> data,
adds the below (all arguments except $expected-expression
are object data):

  ok_sub( $subroutine,
          $actual,
          $expected-expression,
          $diag_msg,
          $name);

=item no skip and no subroutine

if there is no C<$skip> and no C<$subroutine> data,
adds the below (all arguments except $expected-expression
are object data):

  ok( $actual,
      $expected-expression,
      $diag_msg,
      $name);

=back

=item reset object data

reset the appropriate object data before return
the above describe construction as C<$file_data>.

=head2 N

 $file_data = N($command, $name_data);

If the C<demo_only> object data is set, the
C<N> subroutine returns empty for C<$file_data>;
otherwise, the subroutine 
sets C<$name> object data to C<$name_data> and
returns an empty for C<$file_data>

=head2 ok

 $file_data = ok($command, $test_number);

The
C<ok> subroutine 
returns the following for C<$file_data>

 # ok: $test_number

=head2 QC

 $file_data = QC($command, $code);

If the C<demo_only> object data is set, the
C<QC> subroutine returns empty for C<$file_data>;
otherwise, the subroutine 
returns C<$file_data> with C<$code> and a comment.

=head2 R

 $file_data = R($command, $requirement_data);

If the C<demo_only> object data is set, the
C<R> subroutine returns empty for C<$file_data>;
otherwise, the subroutine 
sets C<$requirement> object data to C<$requirement_data> and
returns an empty for C<$file_data>

=head2 S

 $file_data = S($command, $expression);

If the C<demo_only> object data is set, the
C<S> subroutine returns empty for C<$file_data>;
otherwise, the subroutine 
sets C<$skip> object data to C<$expression> and
returns an empty for C<$file_data>

=head2 SE

 $file_data = SE($command, $expected-expression);

The C<SE> subroutine performs the same processing
as the C<S> subroutine expect that the subroutine 
also adds the following to the beginning of
C<$file_data>:

 skip_tests( 1 ) unless

Thus, if the test fails the rest of the tests
are skipped effectively stopping the testing.

=head2 SF

 $file_data = SF($command, "$value,$msg");

The C<SF> command splits C<"$value,$msg">
and returns the following as C<$file_data>

 skip_tests($value,$msg)

=head2 T

 $file_data = T($command,  $tests );

The C<T> routine returns in C<$file_data> the
C<BEGIN> and <END> block for the demo script.
The C<BEGIN> block loads the L<Test::Tech|Test::Tech> 
program module, 
executes a C<plan($tests)>,
changes the working directory
to the directory of the demo script, and
adds some extra directories to the front of
C<@INC>.
The <END> block restores everything to
the state before the execution of the
C<BEGIN> block.

=head2 TS

 $file_data = TS(command, \&subroutine);

If the C<demo_only> object data is set, the
C<TS> subroutine returns empty for C<$file_data>;
otherwise, the subroutine 
sets C<$subroutine> object data to C<\&subroutine> and
returns an empty for C<$file_data>

=head2 U

 $file_data = U($command, $comment);

=head2 VO

 $file_data = VO($command, $comment);

The C<VO> subroutine returns a empty
for C<$file_data>.

=head1 ADMINSTRATIVE METHODS

=head2 finish

 $file_data = finish();

The C<finish> subroutine returns adds a short POD
to the test script by returning it in C<$file_data>.

=head2 post_print

 $success = post_print();

If the C<report> option is set,
the C<post_print> subroutine will run the test script
and replace the 'Test Report' section of the UUT POD
with the results. 

If the C<run> option is set,
the C<post_print> subroutine will run the test script
under the L<Test::Harness|Test::Harness>. If the
C<test_verbose> option is set, the subroutine runs
the test harness in verbose.

=head2 start

 $file_data = start();

The C<start> routine initializes the
object data.

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

=item 3

Commercial installation of the binary or source
must visually present to the installer 
the above copyright notice,
this list of conditions intact,
that the original source is available
at http://softwarediamonds.com
and provide means
for the installer to actively accept
the list of conditions; 
otherwise, a license fee must be paid to
Softwareware Diamonds.

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

=over 4

=item L<Test::Tech|Test::Tech> 

=item L<Test|Test> 

=item L<Test::Harness|Test::Harness> 

=item L<Test::STDmaker|Test::STDmaker>

=item L<Test::STDmaker::Demo|Test::STDmaker::Demo>

=item L<Test::STDmaker::STD|Test::STDmaker::STD>

=item L<Test::STDmaker::Check|Test::STDmaker::Check>

=item L<STD - Software Test Description|Docs::US_DOD::STD>

=item L<Specification Practices|Docs::US_DOD::STD490A>

=item L<Software Development|Docs::US_DOD::STD2167A>

=back


=cut

### end of file ###


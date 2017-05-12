 #!perl
#
# Documentation, copyright and license is at the end of this file.
#
###########################

package  Test::STDmaker::Check;

use 5.001;
use strict;
use warnings;
use warnings::register;

use File::Spec;
use vars qw($VERSION $DATE);
use Cwd;
use File::AnySpec;

$VERSION = '1.15';
$DATE = '2004/05/23';

########
# Inherit classes
#
use Test::STDmaker;
use vars qw(@ISA);
@ISA = qw(Test::STDmaker);

use vars qw(@required_data_base);

#######
# The order of the required fields is the order printed out in the STD.
# Do not change them.
#
@required_data_base = qw(
   Name File_Spec UUT Revision Version End_User Author 
   STD2167_Template Detail_Template Classification Temp  
   Copyright HTML See_Also );

#############################################################################
#  
#                           TEST DESCRIPTION METHODS
#
#

sub  A 
{ 
    my ($self, $command, $data) = @_;
    my $module = ref($self);
    push @{$self->{$module}->{test_db}}, ($command, $data);
    if($self->{$module}->{demo_only}) {
        $self->{$module}->{demo_only} = '';
        $self->{$module}->{demo_only_expected} = 1;
        return '';
    }
    if($self->{$module}->{demo_only_expected}) {
        $self->{$module}->{demo_only_expected} = '';
        return "\n";
    }
    '' 
}


sub C
{ 
    my ($self, $command, $data) = @_;
    my $module = ref($self);
    push @{$self->{$module}->{test_db}}, ($command, $data);

    ($data) = $data =~ /^\s*(.*)\s*$/s; # drop leading trailing white space

    while (chomp $data) { };
    my $end_char = substr( $data,-1,1);
    unless( $self->{options}->{nosemi} ) {
        my $last_char = substr( $data, length($data)-1,1);
        $data .= ';' if $last_char ne ';' && $last_char ne '{'  && $last_char ne '}';
    }

    << "EOF";
   # Perl code from ${command}:
$data

EOF
 
}



sub DM { R(@_) }

#######
# These are test sections. Add to the test array,
#
sub DO
{ 
    my ($self, $command,$data) = @_;
    my $module = ref($self);
    push @{$self->{$module}->{test_db}}, ($command, $data);
    $self->{$module}->{demo_only} = "    $data";
    ''
}



sub E
{
    my ($self, $command, $data) = @_;
    my $module = ref($self);
    push @{$self->{$module}->{test_db}}, ($command, $data);

    if($self->{$module}->{demo_only_expected}) {
        $self->{$module}->{demo_only_expected} = '';
        return '';
    }

    push @{$self->{$module}->{test_db}}, ('ok', $self->{$module}->{ok});
    
    $data = << "EOF";

    ######
    # ok $self->{$module}->{ok}
    #
    \$__test__++; 
    \$__tests__{ $self->{$module}->{ok} } .= "\$__test__,";    

EOF

    $self->{$module}->{ok}++;

    $data
}

sub  N { R(@_) }

sub ok { T(@_) }

sub QC { C(@_) }


sub  R
{ 
    my ($self, $command, $data) = @_;
    my $module = ref($self);
    push @{$self->{$module}->{test_db}}, ($command, $data);
    '' 
};



sub  S { R(@_) }

########
# Count the tests and provide results as a ok command, data pair
#
sub SE { E(@_) }

sub SF { R(@_) }
sub T { '' }
sub TS { R(@_) }


sub U 
{ 
    my ($self, $command, $data) = @_;
    my $module = ref($self);
    push @{$self->{$module}->{test_db}}, ($command, $data);
    push @{$self->{$module}->{todo}},$self->{$module}->{ok};
    ''
}


sub VO { R(@_) }


##################################################################################
#
#                            ADMINSTRATIVE METHODS
#
#

sub AUTOLOAD
{
    our $AUTOLOAD;
    return '' if $AUTOLOAD =~ /DESTROY/;
    my ($self, $command, $data) = @_;
    return '' unless $command && $data;
    $self->{$command} = $data;
    '';
}

sub file_out { 'temp.pl' }

sub finish
{

   my ($self) = @_;

   my $module = ref($self);

   ########
   #  Fill in the number of test at the first instruction
   #
   $self->{$module}->{test_db}->[1] = $self->{$module}->{ok} - 1;
   if (@{$self->{$module}->{todo}}) {
       my $todo = join ',', @{$self->{$module}->{todo}};
       $self->{$module}->{test_db}->[1] .= " - $todo" ;
   }

   ######
   # Replace the std_db with the checked and cleaned test_db
   #
   $self->{std_db} = $self->{$module}->{test_db};
   $self->{$module}->{test_db} = undef;


   #######
   # Change the UUT and Temp file specs with so
   # directed by the fspec_out option and define
   # all required fields
   #
   $self->{File_Spec} = 'Unix' unless $self->{File_Spec};

   my @required_data = @required_data_base;
   $self->{required_data} = \@required_data;
   foreach my $required (@required_data) {
       $self->{$required} = '' unless defined $self->{$required};
   }


   ######
   # Provide an default output file for all output generators
   #
   my ($package,$method,$error);
   foreach my $generator (@{$self->{generators}}) {
       $package = "Test::STDmaker::" . $generator;
       if ($package->can( 'file_out' )) {
           $method = "${package}::file_out";
           $self->{$package}->{file_out} = $self->$method();
           next;
       }

       if( !$self->{$generator} ) {
           $self->{$generator} = $self->{file};
           $self->{$generator} =~ s/\..*?$//; # drop extension
           $self->{$generator} .= $package->extension( );
       }

       #######
       # Change generator spec to current operating system spec
       #
       else {
           $self->{$generator} = File::AnySpec->fspec2os( 
                   $self->{File_Spec}, $self->{$generator} );
       }
       $self->{$package}->{file_out} = $self->{$generator};
   }


   #####
   # If not successful in the check, provide a diagnostic dump
   #
   unless( $self->{$module}->{success} ) {

       #######
       # Diagnostic dump
       #
       my $data_out;
       my $clean = new STD::GenType::Clean( $self );
       $clean->generate( );
       $clean->print( );

   }


   ######
   # Update the file specification
   #
   $self->{File_Spec} = $self->{options}->{fspec_out} if $self->{options}->{fspec_out};
   $self->{File_Spec} = 'Unix' unless $self->{File_Spec};
   
   << 'EOF';

   print "tests\n$__test__\n";

   foreach $__test__ (keys %__tests__) {
      print "$__test__\n$__tests__{$__test__}\n";
   }


EOF
}   



#####
#
# post print processing
#
sub post_print
{

    my ($self) = @_;
    my $module = ref($self);

    my $cwd = cwd();

    my $command = $self->perl_command() . ' ' . $self->{$module}->{file_out};
    my @tests = `$command`;
    return undef unless @tests;
    unlink $self->{$module}->{file_out} unless $self->{options}->{nounlink};
    pop @tests if @tests % 2; # try best if code messes up
    foreach my $test (@tests) {
         chomp $test;
    }
    my %tests = @tests;

    #######
    # Now that have the test number(s) according to the
    # execution of the code, replace the original ok
    # ident with the one obtained from the code.
    #
    my $db_p = $self->{std_db};
    for( my $i=0; $i < @$db_p; $i += 2) {
        if( $db_p->[$i] eq 'ok' ) {
            $db_p->[$i+1] = $tests{$db_p->[$i+1]};  # test according to code
            if( $db_p->[$i+1] ) {
               $db_p->[$i+1] = substr($db_p->[$i+1],0,length($db_p->[$i+1])-1); # drop last ', '
            }

            #######
            # ok never executed
            # 
            else {
               $db_p->[$i+1] = '';
            }
        }
        elsif( $db_p->[$i] eq 'T' ) {
            my $todo = '';
            foreach my $t (  @{$self->{$module}->{todo}}  ) {
                $todo .= "$tests{$t}";
            }
            $db_p->[$i+1] = "$tests{tests}";
            if ($todo) {
                $todo = substr($todo,0,length($todo)-1); # drop last ', '
                $db_p->[$i+1] .= " - $todo" ;
            }
        }
    }

    1

}

sub start
{

    my ($self) = @_;

    #########
    # Always lead off with a N and a T
    #
    my @test_db = ('T', '');
    my $module = ref($self);
    $self->{$module}->{test_db} =  \@test_db;
    $self->{$module}->{ok} = 1;
    $self->{$module}->{success} = 1;
    $self->{$module}->{todo} = [];
    $self->{$module}->{name} = '';

    ###########
    # use in variables without have to backslash escape the dollar sign
    # every which way in the below << here statement
    #   
    my ($__test__, $__restore_dir__) = ('$__test__', '$__restore_dir__');
    my ($vol, $dirs, $T) = ('$vol', '$dirs', '$T');

    << "EOF";
#!perl
#
#

BEGIN { 

    use Cwd;
    use FindBin;
    use File::Spec;
    use vars qw(%__tests__ $__test__ $__restore_dir__);
    
    $__test__ = 0;
    %__tests__ = ();

    ########
    # The working directory for this script file is the directory where
    # the test script resides. Thus, any relative files written or read
    # by this test script are located relative to this test script.
    #
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

}

END {

   finish( );

   #########
   # Restore working directory and \@INC back to when enter script
   #
   \@INC = \@lib::ORIG_INC;
   chdir $__restore_dir__;

}

EOF


}


1

__END__

=head1 NAME

Test::STDmaker::Check - checks a software test description short hand

=head1 DESCRIPTION

The C<Test::STDmaker::Check> package is an internal driver package to
the L<Test::STDmaker|Test::STDmaker> package that supports the 
L<Test::STDmaker::tmake()|Test::STDmaker/tmake> method.
Any changes to the internal drive interface and this package will not
even consider backward compatibility.
Thus, this POD serves as a Software Design Folder 
documentation the current internal design of the
C<Test::STDmaker> and its driver packages.

The C<Test::STDmaker::Check> package performs the following:

=over 4

=item 1

checks the STD database

=item 2

creates a test description of ordered name,value pairs
database array @{$self->{$module}->{test_db}}

=item 3

generates a check script 
that numbers the  C<ok> the same
as if generated by a test script
The name for the check script is
the STD database C<Temp> field and usually is
C<temp.pl>.

=item 4

Runs the check script to obtan a C<ok> translation table.

=item 5

Change the C<ok> fields in the
STD database according to the C<ok> tranlation
table from the check script.

=back

The C<Test::STDmaker::Check> package inherits the methods of the
C<Test::STDmaker> package.
The C<Test::STDmaker> C<build> C<generate> and <print>
methods directs the C<Test::STDmaker::Check> package to perform
its work by calling its methods.

During the course of the processing the C<Test::STDmaker::Check>
package maintains the following in the C<$self> object
data hash:

=over 4

=item $demo_only

Flags if the test is demo only and 
will be ignore as far as the generating
the check test script

=item $demo_only_expected

Once only flag set by the C<A> subroutine
and reset by the next C<E> subroutine.
There should be no C<E> subroutine after
a C<A> demo only subroutine.

=item $ok

Sequential count of the C<ok> fields.
This is the initial count enter in the
test description data base and used
by the clean script to record the
true ok count from running the clean script.

=item $success

Use by the C<finish> subroutine for a diagnostic
dump if the process does not go right.

=item @todo

A list of todo tests.

=back

The C<Test::STDmaker::Check> package has the following
options that are passed as part of the C<$self> hash
from C<Test::STDmaker> methods:

=over 4

=item fspec_out

The C<File_Spec> field determines he file specification for the STD database.
The C<finish> routine will set the C<File_Spec> to the
C<fspec_out> optin if it is present.

=item nounlink

The C<post_generate> subroutine will not unlink the
check script (usually temp.pl) if there is a nounlink
option.

=back

=head1 TEST DESCRIPTION METHODS

The test description methods clean up the
STD database and contribute to the check
script. 
Data from processing fields that are test descriptions
are added to the @{$self->{std_db}}
array in the same order as the test description fields.
The C<$file_data> return from the test description
methods are appended to the check test script.

The test description methods are 
as follows. 

=head2 A

 $file_data = A($command, $actual-expression );

The C<A> subroutine appends C<$command, $actual-expression>
to @{$self->{std_db}} unchanged and returns '' for 
C<$file_data>.

If C<demo_only> exists,
the C<A> subroutine resets the C<demo_only> flag
and sets the C<demo_only_expected> flag; otherwise
it resets the C<demo_only_expected> flag.

=head2 C

 $file_data = C($command, $code);

The C<C> subroutine appends C<$command, $code>
to @{$self->{std_db}} unchanged and returns C<$code> for 
C<$file_data>.
 
=head2 DO

 $file_data = DO($command, $comment);

The C<DO> subroutine appends C<$command, $comment>
to @{$self->{std_db}} unchanged and returns '' for 
C<$file_data>.

The subroutine sets the C<$demo_only> flag.

=head2 DM

 $file_data = DM($command, $msg);

The C<DM> subroutine appends C<$command, $msg>
to @{$self->{std_db}} unchanged returns '' for 
C<$file_data>.

=head2 E
 
 $file_data = E($command, $expected-expression);

The C<E> subroutine appends 
C<$command, $expected-expression, 'ok', $ok++>
to @{$self->{std_db}} and returns
code for incrementing the test count and adding
the test count to the C<ok> database in
C<$file_data>.

=head2 N

 $file_data = N($command, $name_data);

The C<N> subroutine appends C<$command, $name_data>
to @{$self->{std_db}} unchanged and returns '' for 
C<$file_data>.

=head2 ok

 $file_data = ok($command, $test_number);

The C<ok> subroutine does nothing.

=head2 QC

 $file_data = QC($command, $code);

The C<QC> subroutine appends C<$command, $code>
to @{$self->{std_db}} unchanged and returns C<$code> for 
C<$file_data>.

=head2 R

 $file_data = R($command, $requirement_data);

The C<R> subroutine appends C<$command, $requrement_data>
to @{$self->{std_db}} unchanged and returns '' for 
C<$file_data>.

=head2 S

 $file_data = S($command, $expression);

The C<S> subroutine appends C<$command, $expression>
to @{$self->{std_db}} unchanged and returns '' for 
C<$file_data>.

=head2 SE

 $file_data = SE($command, $expected-expression);

The C<SE> subroutine appends 
C<$command, $expected-expression, 'ok', $ok++>
to @{$self->{std_db}} and returns
code for incrementing the test count and adding
the test count to the C<ok> database in
C<$file_data>.

=head2 SF

 $file_data = SF($command, "$value,$msg");

The C<SF> subroutine appends C<$command, "$value,$msg"
to @{$self->{std_db}} unchanged and returns '' for 
C<$file_data>.

=head2 T

 $file_data = T($command,  $tests );

The C<start> subroutine initilizes @{$self->{std_db}} 
to C<(T,'')> as the first name,value pair.
There is only one C<T> field per test description
database.
Thus, the C<T> subroutine does nothing.

=head2 TS

 $file_data = TS(command, \&subroutine);

The C<TS> subroutine appends C<$command, \&subroutine
to @{$self->{std_db}} unchanged and returns '' for 
C<$file_data>.

=head2 U

 $file_data = U($command, $comment);

The C<U> subroutine appends C<$command, $comment
to @{$self->{std_db}} unchanged and returns '' for 
C<$file_data>.

=head2 VO

 $file_data = VO($command, $comment);

The C<VO> subroutine appends C<$command, \&subroutine
to @{$self->{std_db}} unchanged and returns '' for 
C<$file_data>.

=head1 ADMINSTRATIVE METHODS

=head2 AUTOLOAD

The C<AUTOLOAD> subroutine is a catch for
any STD database field that is not a
test description fields.
Without this catch, C<Test::STDmaker>
methods calls with these field names
causes a false error.

=head2 start

 $file_data = start();

The C<start> subroutine initilizes the object
data.
The C<start> routine returns in C<$file_data> the
C<BEGIN> and <END> block for the demo script.
The C<BEGIN> block loads the L<Test::Tech|Test::Tech> 
program module, changes the working directory
to the directory of the demo script, and
adds some extra directories to the front of
C<@INC>.
The <END> block restores everything to
the state before the execution of the
C<BEGIN> block.

=head2 finish

 $file_data = $success = finish();

The C<finish> subroutine performs numerous checks
and updates on the C<$self> STD database fields.
Some of the checks and updates are as follows:

=over 4

=item *

Provides default file output for output targets
if one is not specified

=item *

Ensures all required fields to create
a STD are present

=back

The C<start> subroutine returns in C<$file_data> the
code to dump the C<ok> translation table.

=head2 post_print

 post_print()

The C<post_print> subroutine picks up the
C<ok> translation table by running the
check test script.
The C<post_print> subroutine runs through
all the C<@{self->{std_db}}> database fields, replacing all
C<ok> fields with the value
from the C<ok> translation table.
The C<post_print> method updates the
C<@{self->{std_db}}> database C<T> field with the
number of tests.

=head1 NOTES

=head2 Author

The holder of the copyright and maintainer is

 E<lt>support@SoftwareDiamonds.comE<gt>

=head2 Copyright

Copyrighted (c) 2002 Software Diamonds

All Rights Reserved

=head2 Binding Requirements

Binding requirements are indexed with the
pharse 'shall[dd]' where dd is an unique number
for each header section.
This conforms to standard federal
government practices, L<STD490A 3.2.3.6|Docs::US_DOD::STD490A/3.2.3.6>.
In accordance with the License, Software Diamonds
is not liable for any requirement, binding or otherwise.

=head2 License

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

=over 4

=item 1

Redistributions of source code must retain
the above copyright notice, this list of
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

SOFTWARE DIAMONDS PROVIDES THIS SOFTWARE 
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

=item L<Test::STDmaker::STD|Test::STDmaker::STD>

=item L<Test::STDmaker::Verify|Test::STDmaker::Verify>

=item L<Test::STDmaker::Demo|Test::STDmaker::Demo>

=item L<Software Test Description|Docs::US_DOD::STD>

=item L<Specification Practices|Docs::US_DOD::STD490A>

=item L<Software Development|Docs::US_DOD::STD2167A>

=back

=cut


### end of file ###


#!perl
#
# Documentation, copyright and license is at the end of this file.
#
package  Test::STDmaker::Demo;

use 5.001;
use strict;
use warnings;
use warnings::register;

use File::Spec;
use File::Glob ':glob';
use File::Spec;
use File::AnySpec;
use File::SmartNL;

use vars qw($VERSION $DATE);
$VERSION = '1.14';
$DATE = '2004/05/21';


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

#######
# Simulate typing in commands at the terminal
#
sub A
{
    my ($self, $command, $data) = @_;
    my $module = ref($self);

    if ( $self->{$module}->{'verify_only'} ) {
        $self->{$module}->{'verify_only'} = '';
        $self->{$module}->{'skip'} = '';
        return '';
    }

    my $datameta = quotemeta($data);
#    my $datameta = $data;
    $datameta =~ s/\"/\\\"/g;

    my $msg;
    if( $self->{$module}->{'skip'} ) {

       $msg = << "EOF";
demo( \"$datameta\", # typed in command           
      $data # execution
) unless $self->{$module}->{'skip'}; # condition for execution                            

EOF

       $self->{$module}->{'skip'} = '';
   }
   else {

       $msg = << "EOF";
demo( \"$datameta\", # typed in command           
      $data); # execution


EOF
   
  }

  $msg;

}


#########
# Print text string of the Perl expression
# and then execute the expression 
#
sub C
{
    my ($self, $command, $data) = @_;
    my $module = ref($self);
    return '' if  $self->{$module}->{'verify_only'};
    my $datameta = quotemeta($data);

    while (chomp $data) { };
    unless( $self->{options}->{nosemi} ) {
        my $end_char = substr($data,-1,1);
        if ($end_char ne ';' &&  $end_char ne '{' &&   $end_char ne '}' ) {
           $data .= ';'
        }
    }
    $data .= " # execution\n\n";

    my $msg = << "EOF";
demo( \"$datameta\"); # typed in command           
      $data

EOF

}

#####
# Reset verify only
#
sub  E 
{ 
    my ($self) = @_;
    my $module = ref($self);
    $self->{$module}->{'verify_only'} = '';
    ''
}

sub DM { '' }


#####
#
sub DO { 
    my ($self, $command,$data) = @_;
    my $module = ref($self);
    $self->{$module}->{'verify_only'} = '';
    ''
}


#######
# Condition to skip a test
#
sub N
{
    my ($self, $command,$data) = @_;
    my $module = ref($self);

    return '' if ( $self->{$module}->{'verify_only'} );
    << "EOF1";
print << \"EOF\";

 ##################
 # $data
 # 
 
EOF

EOF1

}


sub ok { '' }

#########
# Print text string of the Perl expression
# and then execute the expression 
#
sub QC
{
    my ($self, $command, $data) = @_;
    my $module = ref($self);
    return '' if  $self->{$module}->{'verify_only'};
 
    while (chomp $data) { };
 
    unless( $self->{options}->{nosemi} ) {
        my $end_char = substr($data,-1,1);
        if ($end_char ne ';' &&  $end_char ne '{' &&   $end_char ne '}' ) {
           $data .= ';'
        }
    }

    $data .= " # execution\n\n"; 
 
my $msg = << "EOF";
      $data 

EOF

}


#######
# No processing
#
sub  R { '' }
sub SE { '' }
sub  T { '' }


#######
# Condition to skip a test
#
sub TS
{
    my ($self, $command,$data) = @_;
    my $module = ref($self);
    ''
}


#######
# Condition to skip a test
#
sub S
{
    my ($self, $command,$data) = @_;
    my $module = ref($self);
    return '' if  $self->{$module}->{'verify_only'};
    $self->{$module}->{'skip'} = "    $data";
    ''
}



sub  U { '' }



#######
# Condition to skip a test
#
sub VO
{
    my ($self, $command,$data) = @_;
    my $module = ref($self);
    $self->{$module}->{'verify_only'} = "    $data";
    ''
}

##################################################################################
#
#                            ADMINSTRATIVE METHODS
#
#

sub AUTOLOAD
{
    our $AUTOLOAD;
    return undef if $AUTOLOAD =~ /DESTROY/;
    warn "Method $AUTOLOAD not supported by Test::STDmaker::Demo";
    undef;
}

sub extension { '.d' }

sub finish
{
    my ($self) = @_;
    my $module = ref($self);

    my (undef,undef,$demo_script) = File::Spec->splitpath( $self->{'Demo'} );
    my $pm = File::AnySpec->fspec2pm($self->{File_Spec}, $self->{UUT});

    << "EOF";

\=head1 NAME

$demo_script - demostration script for $pm

\=head1 SYNOPSIS

 $demo_script

\=head1 OPTIONS

None.

\=head1 COPYRIGHT

$self->{Copyright}

## end of test script file ##

\=cut

EOF
}



#####
#
# post print processing
#
sub post_generate
{
     my ($self) = @_;

     my $module = ref($self);

     # replace option for backward compatibility
     unless ($self->{options}->{demo} || $self->{options}->{replace}) {
         @{$self->{$module}->{generated_files}} = ();
         return 1;
     }
 
     ######
     # Generate demo
     #
     my @demo;
     my $demo = '';
     my $base_demo_script;
     my $demo_script;
     my $perl = $self->perl_command();
     foreach $demo_script (@{$self->{$module}->{generated_files}}) {
         (undef,undef,$base_demo_script) = File::Spec->splitpath($demo_script);
         @demo = `$perl $demo_script`;
         $demo .= "\n #########\n" .
                 " # perl $base_demo_script\n" .
                 " ###\n\n";

         $demo .= join '',@demo;
     }
     return undef unless $demo;

     $demo =~ s/\n\s+\n/\n\n/g;

     ######
     # Find uut file
     #
     my $uut = $self->{'UUT'};
     unless( $uut ) {
         warn("No UUT specified.\n");
         return undef;
     }
     
     my ($uut_file) = File::Where->where_pm($uut);
     return undef unless $uut_file && -e $uut_file;
     my $uut_contents = File::SmartNL->fin( $uut_file );
     $uut_contents =~ s/(\n=head\d\s+Demonstration).*?\n=/$1\n$demo\n=/si;
     File::SmartNL->fout( $uut_file, $uut_contents);
 
     1   

}


#####
#
# Start generating the file 
#
sub start
{
    my ($self) = @_;

    ###########
    # use in variables without have to backslash escape the dollar sign
    # every which way in the below << here statement
    #   
    my ($test_log,$T) = ('$test_log','$T');
    my ($vol, $dirs, $__restore_dir__, $VERSION, $DATE) = 
      ('$vol', '$dirs', '$__restore_dir__','$VERSION', '$DATE');


    my (undef,undef,$demo_script) = File::Spec->splitpath( $self->{Demo} );
    my $uut = File::AnySpec->fspec2pm($self->{File_Spec}, $self->{UUT}  );

    << "EOF";
#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE);
$VERSION = '0.01';   # automatically generated file
$DATE = '$self->{Date}';


##### Demonstration Script ####
#
# Name: $demo_script
#
# UUT: $uut
#
# The module Test::STDmaker generated this demo script from the contents of
#
# $self->{std_pm} 
#
# Don't edit this test script file, edit instead
#
# $self->{std_pm}
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
use vars qw($__restore_dir__ \@__restore_inc__ );

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
    Test::Tech->import( qw(demo finish is_skip ok ok_sub plan skip 
                          skip_sub skip_tests tech_config) );

}

END {

    #########
    # Restore working directory and \@INC back to when enter script
    #
    \@INC = \@lib::ORIG_INC;
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

EOF

}

1

__END__

=head1 NAME

Test::STDmaker::Demo - generates demo scripts from a test description short hand

=head1 DESCRIPTION

The C<Test::STDmaker::Demo> package is an internal driver package to
the L<Test::STDmaker|Test::STDmaker> package that supports the 
L<Test::STDmaker::tmake()|Test::STDmaker/tmake> method.
Any changes to the internal drive interface and this package will not
even consider backward compatibility.
Thus, this POD serves as a Software Design Folder 
documentation the current internal design of the
C<Test::STDmaker> and its driver packages.

The C<Test::STDmaker::Check> package inherits the methods of the
C<Test::STDmaker> package.
The C<Test::STDmaker> C<build> C<generate> and <print>
methods directs the C<Test::STDmaker::Demo> package to perform
its work by calling its methods.

The C<Test::STDmaker::Demo> methods builds a demo script whereby
the demo script loads the L<Test::Tech|Test::Tech> package and
uses the methods from the C<Test::Tech> package.

During the course of the processing the C<Test::STDmaker::Demo>
package maintains the following in the C<$self> object
data hash:

=over 4

=item $skip

condition that a test should be skipped

=item $verify_only

flag that a test is for the verify (test script) output only

=back

The C<Test::STDmaker::Demo> package has the following
options that are passed as part of the C<$self> hash
from C<Test::STDmaker> methods:

=over 4

=item demo

Replaces the C<UUT> DEMONSTRATION POD section with
the results from the demo script.

=item replace 

same as the C<demo> option

=item nosemi

The C<C> subroutine will not automatically add a ';' at
the end of the code field.

=back

=head1 TEST DESCRIPTION METHODS

=head2 A

 $file_data = A($command, $actual-expression )

If the C<$verify_only> object data is set, the
C<A> subroutine 
resets the C<$verify_only> and C<$skip> object data and
returns empty for C<file_data>;
otherwise, performs the following.

If the C<skip> flag is set, the C<A> subroutine
adds the following to the demo script
by returning it in C<$file_data>

 demo( text_of($actual_expression), $actual-expression) )
   unless C<$skip>;

and resets the C<$skip> condition; otherwise

 demo( text_of($actual_expression), $actual-expression) );

=head2 E
 
 $file_data = E($command, $expected-expression)

The C<E> subroutine resets the C<verify_only> object
data and returns empty for C<$file_data>. 

=head2 C

 $file_data = C($command, $code)

If the C<$verify_only> object data is set, the
C<C> subroutine returns empty for C<file_data>;
otherwise, adds the following to the demo script
by returning it in C<$file_data>

  demo( text_of($actual_expression)) )
  $actual-expression

=head2 DM

 $file_data = DM($command, $msg)

The C<DM> subroutine returns empty for C<$file_data>.

=head2 DO

 $file_data = DO($command, $comment)

The C<DO> subroutine resets the C<verify_only> object
data and returns empty for C<$file_data>. 

=head2 N

 $file_data = N($command, $name_data)

If the C<$verify_only> object data is set, the
C<C> subroutine returns empty for C<file_data>;
otherwise, adds the C<$name_data> as a comment
to the demo script
by returning it in C<$file_data>

=head2 ok

 $file_data = ok($command, $test_number)

The C<ok> subroutine returns empty for C<$file_data>.

=head2 QC

 $file_data = QC($command, $code)

If the C<verify_only> object data is set, the
C<QC> subroutine returns empty for C<file_data>;
otherwise, adds the following to the demo script
by returning it in C<$file_data>

  $actual-expression

=head2 R

 $file_data = R($command, $requirement_data)

The C<R> subroutine returns empty for C<$file_data>.

=head2 S

 $file_data = S($command, $expression)


=head2 SE

 $file_data = SE($command, $expected-expression)

The C<SE> subroutine returns empty for C<$file_data>.

=head2 SF

 $file_data = SF($command, "$value,$msg")

The C<SF> subroutine returns empty for C<$file_data>.

=head2 T

 $file_data = T($command,  $tests )

The C<T> subroutine returns empty for C<$file_data>.

=head2 TS

 $file_data = TS(command, \&subroutine)

The C<TS> subroutine returns empty for C<$file_data>.

=head2 U

 $file_data = U($command, $comment)

The C<U> subroutine returns empty for  C<$file_data>.

=head2 VO

 $file_data = VO($command, $comment)

The C{VO} subroutine sets the C<$verify_only> flag
and returns empty for  C<$file_data>.


=head1 ADMINSTRATIVE METHODS

=head2 AUTOLOAD

The C<AUTOLOAD> subroutine issues a warning
whether called by the orphan method C<$AUTOLOAD>

=head2 finish

 $file_data = finish()

The C<finish> subroutine returns adds a short POD
to the demo script by returning it in C<$file_data>.

=head2 post_print

 $success = post_print()

If either the C<demo> or C<replace> option is set,
the C<post_print> subroutine will run the demo script
and replace the DEMONSTRATION section of the UUT POD
with the results. 

=head2 start

 $file_data = start()

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

=head1 NOTES

=head2 Author

The holder of the copyright and maintainer is

E<lt>support@SoftwareDiamonds.comE<gt>

=head2 Copyright Notice 

Copyrighted (c) 2002 Software Diamonds

All Rights Reserved

=head2 Binding Requirement Notice

Binding requirements are indexed with the
pharse 'shall[dd]' where dd is an unique number
for each header section.
This conforms to standard federal
government practices, L<US DOD 490A 3.2.3.6|Docs::US_DOD::STD490A/3.2.3.6>.
In accordance with the License, Software Diamonds
is not liable for any requirement, binding or otherwise.

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

=item L<Test::STDmaker::STD|Test::STDmaker::STD>

=item L<Test::STDmaker::Verify|Test::STDmaker::Verify>

=item L<Test::STDmaker::Check|Test::STDmaker::Check>

=item L<Software Test Description|Docs::US_DOD::STD>

=item L<DSpecification Practices|Docs::US_DOD::STD490A>

=item L<Software Development|Docs::US_DOD::STD2167A>

=back

=cut


### end of file ###


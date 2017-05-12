#!perl
#
# Documentation, copyright and license is at the end of this file.
#
###########################

package  Test::STDmaker::STD;

use 5.001;
use strict;
use warnings;
use warnings::register;

use File::AnySpec;
use Text::Replace;
use Text::Column;
use File::Package;
use Tie::Form;

use vars qw($VERSION $DATE);
$VERSION = '1.12';
$DATE = '2004/05/23';

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
sub  A 
{ 
    my ($self, $command, $data) = @_;
    $self->format( $command, $data );
    my $module = ref($self);
    if($self->{$module}->{demo_only}) {
        $self->{$module}->{demo_only} = '';
        $self->{$module}->{fields} .= "\n";
        $self->{$module}->{test} .= "\n";
    }
    ''
}


#######
# These are test sections. Add to the test array,
#
sub DO
{ 
    my ($self, $command,$data) = @_;
    my $module = ref($self);
    $self->{$module}->{demo_only} = "    $data";
    $self->format( $command, $data );
    ''
}


sub N
{
    my ($self, $command, $data) = @_;
    my $module = ref($self);
    $self->{$module}->{name} = $data;
    $self->format( $command, $data );
    ''
}




sub ok 
{
    my ($self, $command, $test_nums) = @_;
    my $module = ref($self);
    my $module_db = $self->{$module};

    my $trace_req_p = $module_db->{trace_req};
    my $trace_test_p = $module_db->{trace_test};

    my @test_num = split /[ ;,]/, $test_nums;
    my $std_pm = $self->{std_pm};

    my $test_num;
    for $test_num (@test_num) {

        ######
        # Provide a link to this test for each data requirement
        # for later output of tracebility matrices. 
        #
        # Tracebility matrices are very important for bean counters
        # who do not understand the code.
        # 
        # 
        my $requirement;
        foreach $requirement (@{$module_db->{requirements}}) {
            ($requirement) = $requirement =~ /^\s*(.*)\s*$/; # remove leading and tailing white space
            next unless $requirement;

            #####
            # Enter test into trace requirement matrix hash
            #
            $trace_req_p->{$requirement}->{"L<$std_pm/ok: $test_nums>"} = undef;

            ######
            # Enter requirement into trace test matrix hash
            #  
            $trace_test_p->{"L<$std_pm/ok: $test_nums>"}->{$requirement} = undef;
        }  

    }
    $module_db->{name} = '';
    $module_db->{requirements} = [];

    $self->format( $command, $test_nums );

    $self->{Test_Descriptions} .= "=head2 ok: $test_nums\n\n";
    $self->{Test_Descriptions} .= ' ' . $module_db->{test} . "\n";
    $module_db->{test} = '';

    ''
}

sub R
{

    my ($self, $command, $data) = @_;
    my $module = ref($self);
    while( chomp $data ) {};
    my @data = split /(?:,|;|\n)+/, $data;
    push @{$self->{$module}->{requirements}}, @data;
    $self->format( $command, $data );
    ''
}




sub T
{
    my ($self, $command, $data) = @_;
    my $module = ref($self);
    my $module_db = $self->{$module};
    $self->format( $command, $data );
    $self->{Test_Descriptions} .= "=head2 Test Plan\n\n" . $module_db->{test} . "\n";
    $module_db->{test} = '';
    ''
}


##################################################################################
#
#                            ADMINSTRATIVE METHODS
#
#
AUTOLOAD
{
    our $AUTOLOAD;
    return '' if $AUTOLOAD =~ /DESTROY/;
    my $self = shift @_;
    $self->format( @_ );

}




#####
#
# Default SVD template
# 
#
sub default_template
{
    <<'EOF';

\=head1 NAME

${Name} - Software Test Description for ${UUT}

\=head1 TITLE PAGE

 Detailed Software Test Description (STD)

 for

 Perl ${UUT} Program Module

 Revision: ${Revision}

 Version: ${Version}

 Date: ${Date}

 Prepared for: ${End_User} 

 Prepared by:  ${Author}

 Classification: ${Classification}

#######
#  
#  1. SCOPE
#
#
\=head1 SCOPE

This detail STD and the 
L<General Perl Program Module (PM) STD|Test::STD::PerlSTD>
establishes the tests to verify the
requirements of Perl Program Module (PM) L<${UUT}|${UUT}>
The format of this STD is a tailored L<2167A STD DID|Docs::US_DOD::STD>.

#######
#  
#  3. TEST PREPARATIONS
#
#
\=head1 TEST PREPARATIONS

Test preparations are establishes by the L<General STD|Test::STD::PerlSTD>.


#######
#  
#  4. TEST DESCRIPTIONS
#
#
\=head1 TEST DESCRIPTIONS

The test descriptions uses a legend to
identify different aspects of a test description
in accordance with
L<STD PM Form Database Test Description Fields|Test::STDmaker/STD PM Form Database Test Description Fields>.

${Test_Descriptions}

#######
#  
#  5. REQUIREMENTS TRACEABILITY
#
#

\=head1 REQUIREMENTS TRACEABILITY

 ${Trace_Requirement_Table}

 ${Trace_Test_Table}

\=cut

#######
#  
#  6. NOTES
#
#

\=head1 NOTES

${Copyright}

#######
#
#  2. REFERENCED DOCUMENTS
#
#
#

\=head1 SEE ALSO

${See_Also}

\=back

\=for html
${HTML}

\=cut

EOF

}


sub extension { '.pm' }
sub file_out { $_[0]->{std_file} }


sub finish
{
    my ($self) = @_;
    my $module = ref($self);
    my $module_db = $self->{$module};
    my $std_db = $self->{std_db};

    my $dbh = $module_db->{dbh};
       
    my $fields = "\n";
    my @fields = (
        'See_Also', $self->{'See_Also'},
        'Copyright', $self->{'Copyright'},
        'HTML', $self->{'HTML'}
    );
    $fields .= ${$dbh->encode_field(\@fields)};
    $fields .= "\n\n";
    $fields  = $module_db->{fields} . $fields;
    $module_db->{fields} = '';

    my $record = '';
    $record .= ${$dbh->encode_record(\$fields)};
    $record = "__DATA__\n" . $record;

    my $header = <<"EOF";      
#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  $self->{std_pm};

EOF

    $header .= <<'EOF';      
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.01';
$DATE = '2003/06/07';
$FILE = __FILE__;

########
# The Test::STDmaker module uses the data after the __DATA__ 
# token to automatically generate the this file.
#
# Do not edit anything before __DATA_. Edit instead
# the data after the __DATA__ token.
#
# ANY CHANGES MADE BEFORE the  __DATA__ token WILL BE LOST
#
# the next time Test::STDmaker generates this file.
#
#

EOF

    ######
    # Build macro substitutes
    #
    $self->{Trace_Requirement_Table} = "No requirements specified.\n";
    if( $module_db->{trace_req} ) {
       $self->{Trace_Requirement_Table} = Text::Column->format_hash_table( $module_db->{trace_req}, [64,64], ["Requirement", "Test"] );
       $module_db->{trace_req} = {};
    }

    $self->{Trace_Test_Table} = '';
    if( $module_db->{trace_test} ) {
       $self->{Trace_Test_Table} = Text::Column->format_hash_table( $module_db->{trace_test}, [64,64], ["Test", "Requirement"] );
       $module_db->{trace_test} = {};
    }

    $self->{Test_Descriptions} =~ s/\n \n/\n\n/g; # no white space lines
 
    #########
    # Get the STD detail template
    #  
    my ($error, $template_contents);
    if( $self->{Detail_Template} ) {
        $error = File::Package->load_package( $self->{Detail_Template} );
        no strict;
        my $data_handle = \*{$self->{Detail_Template} . '::DATA'};
        use strict;
        my $position = tell($data_handle);
        $template_contents = join '',<$data_handle>;
        seek($data_handle,0,0);
    }
    $template_contents = default_template() unless $template_contents;

    my @vars = qw(Name UUT Revision Date End_User Author Classification
      Copyright See_Also Test_Descriptions Version
      Trace_Requirement_Table Trace_Test_Table HTML);

    Text::Replace->replace_variables(\$template_contents, $self, \@vars);

    $template_contents =~ s/\n\\=/\n=/g; # unescape POD directives
    $template_contents =~ s/\n \n/\n\n/g; # no white space lines

    $header . $template_contents . $record;

}


sub format
{

    my ($self, $command, $data) = @_;
    my $module = ref($self);
    my $module_db = $self->{$module};

    my $precision   = $self->{precision};
    $precision = 2 unless $precision;
    $command = sprintf("%${precision}s", $command);
    my $field = '';
    $field .= ${$self->{$module}->{dbh}->encode_field( [$command, $data])};            
    $field .= "\n" if ($command =~ /\s*ok\s*/ | $command =~ /\s*T\s*/);
    $self->{$module}->{fields} .= $field;
    $field =~ s/\n/\n /g;   # tell Perl POD it is code
    $field =~ s/\n \n/\n/g; # no white space blank lines
    $module_db->{test} .= $field;
    ''
}

sub start
{
    my ($self) = @_;
    my $module = ref($self);
    my $module_db = $self->{$module};

    $module_db->{trace_req} = {};
    $module_db->{trace_test} = {};
    $module_db->{requirements} = [];
    $self->{Test_Descriptions} = '';
    $module_db->{test} = '';

    my $dbh = bless {},'Tie::Form';
    $dbh->{options}->{'Tie::Form'} = new Tie::Form;

    my $fields = "\n";
    my $fspec_out = $self->{options}->{fspec_out};
    $fspec_out = 'Unix' unless $fspec_out;
    my $file_out;
    foreach my $item (@{$self->{required_data}}) {
        next if $item eq 'Copyright' || $item eq 'See_Also' || $item eq 'HTML';
        if( $item eq 'File_Spec') {
             $fields .= ${$dbh->encode_field( ['File_Spec', $fspec_out])};
             next;
        }
        elsif( $item eq 'Temp') {
            $file_out = File::AnySpec->fspec2os($fspec_out, $self->{Temp});
            $fields .= ${$dbh->encode_field( ['Temp', $file_out])};
            next;
        }
        $fields .= ${$dbh->encode_field( [$item, $self->{$item}] )} ;
    }

    #########
    # 
    #
    my ($package);
    foreach my $generator (@{$self->{generators}}) {
        $package = "Test::STDmaker::" . $generator;        
        next if $package->can( 'file_out' );
        $file_out = File::AnySpec->fspec2os($fspec_out, $self->{$generator});
        $fields .= ${$dbh->encode_field( [$generator, $file_out] )};
    }

    $fields .= "\n\n";
    $module_db->{fields} = $fields;
    $module_db->{dbh} = $dbh;
    ''

} 

1

__END__

=head1 NAME

Test::STDmaker::STD - generates a STD POD from a test description short hand

=head1 DESCRIPTION

The C<Test::STDmaker::STD> package is an internal driver package to
the L<Test::STDmaker|Test::STDmaker> package that supports the 
L<Test::STDmaker::tmake()|Test::STDmaker/tmake> method.
Any changes to the internal drive interface and this package will not
even consider backward compatibility.
Thus, this POD serves as a Software Design Folder 
documentation the current internal design of the
C<Test::STDmaker> and its driver packages.

The C<Test::STDmaker::STD> package inherits the methods of the
C<Test::STDmaker> package.
The C<Test::STDmaker> C<build> C<generate> and <print>
methods directs the C<Test::STDmaker::STD> to perform
its work by calling its methods.

The C<Test::STDmaker::STD> package methods use the L<Tie::Form|Tie::Form>
methods to encode a STD POD and STD form database from the internal
database checked by the C<Test::STDmaker::STD> package methods.
The C<Test::STDmaker> package takes this data from the 
C<Test::STDmaker::STD> package methods and generates a STD program
module with a fresh POD and a checked C<__DATA__> form database
with correctly counted C<ok> fields.
The C<Test::STDmaker::STD> package useful product is tables
that trace requirements to tests and test headers that may
be used to link (cite) tests in the tracebility matrices and
other PODs.

During the course of the processing the C<Test::STDmaker::STD>
package maintains the following in the C<$self> object
data hash:

=over 4

=item $demo_only

flags that the test description is for demo only

=item $fields

cumulative fields for the C<__DATA__> form section

=item @requirements

list of requirements for a test

=item $test

short hand test descriptions for a test

=item $Test_Descriptions

cumulative test descriptions POD

=item %trace_req

cumulative requirements to test hash

=item %trace_test

cumulative test to requirements hash

=back

The C<Test::STDmaker::STD> package processes following
options that are passed as part of the C<$self> hash
from C<Test::STDmaker> methods:

=over 4

=item fspec_out

The file specification for the files in the
C<__DATA__> form database.

=back

=head1 TEST DESCRIPTION METHODS

=head2 A

 $file_data = A($command, $actual-expression );

The C<A> subroutine formats C<$command,$actual-expression> in
the L<Tie::Form> format and adds it to both the
C<$test> and C<$fields> object data.

If C<demo_only> exists,
the C<A> subroutine resets the C<demo_only> flag
and adds a new line to both the C<$test> and C<$fields> object data.

=head2 DO

 $file_data = DO($command, $comment);

The C<DO> subroutine formats C<$command,$actual-expression> in
the L<Tie::Form> format and adds it to both the
C<$test> and C<$fields> object data.

The subroutine sets the C<$demo_only> flag.

=head2 ok

 $file_data = ok($command, $test_number)

If a C<ok> test description short hand is in a loop, 
C<test_number> will contain
multiple numbers. 
The C<ok> splits C<$test_number> into separate tests and
enters all combinations of the tests and the C<@requirements>
object data into the C<%test_req> and C<%req_test> object data;
after which, the subroutine resets C<@requements> to an empty list.
The C<ok> subroutine formats C<$command, $test_number> in
the L<Tie::Form> format and adds it to both the
C<$test> and C<$fields> object data.
The C<T> subroutine adds a ok header followed
by the C<$test> formated short hand test descriptions
to the C<$Test_Description> object data and resets
the C<$test> object data to a empty string.
The subroutine returns an empty string for C<$file_data>.

=head2 R

 $file_data = R($command, $requirement_data)

The C<R> subroutine formats C<$command, $requirement_data> in
the L<Tie::Form> format and adds it to both the
C<$test> and C<$fields> object data.
The C<R> subroutine splits the C<$requirement_data> into
individual requirements and adds them to C<@requirments>.
The subroutine returns an empty string for C<$file_data>.

=head2 T

 $file_data = T($command,  $tests )

The C<T> subroutine formats C<$command, $data> in
the L<Tie::Form> format and adds it to both the
C<$test> and C<$fields> object data.
The C<T> subroutine adds a test plan header followed
by the C<$test> formated short hand test descriptions
to the C<$Test_Description> object data and resets
the C<$test> object data to a empty string.
The subroutine returns an empty string for C<$file_data>.

=head1 ADMINSTRATIVE METHODS

=head2 AUTOLOAD

The C<AUTOLOAD> routine formats C<$command, $data> in
the L<Tie::Form> format and adds it to both the
C<$test> and C<$fields> object data.

=head2 finish

 $file_data = finish()

The C<finish> subroutine encodes and adds the
last adminstrative fields to the C<fields> object
data, builds the C<__DATA_> form database record,
builds and adds the tracebility tables from the
C<%test_req> and C<%req_test> hash to the
C<Test_Description> object data, uses a build-in
template and C<Test_Description> to build the
STD POD, puts it all together and returns
it in C<$file_data> to the C<Test::STDmaker>
package methods.

=head2 start

 $file_data = start()

The <start> subroutine initializes the object data,
and starts the C<fields> object data by adding
encoded adminstrative fields.
The subroutine returns an empty string for C<$file_data>.

=head1 NOTES

=head2 Author

The holder of the copyright and maintainer is

 E<lt>support@SoftwareDiamonds.comE<gt>

=head2 COPYRIGHT NOTICE

Copyrighted (c) 2002 Software Diamonds

All Rights Reserved

=head2 BINDING REQUIREMENTS NOTICE

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
at http://www.softwarediamonds.com
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

=item L<Test::STDmaker::Demo|Test::STDmaker::Demo>

=item L<Test::STDmaker::Verify|Test::STDmaker::Verify>

=item L<Test::STDmaker::Check|Test::STDmaker::Check>

=item L<Software Test Description|Docs::US_DOD::STD>

=item L<Specification Practices|Docs::US_DOD::STD490A>

=item L<Software Development|Docs::US_DOD::STD2167A>

=back

=cut


### end of file ###


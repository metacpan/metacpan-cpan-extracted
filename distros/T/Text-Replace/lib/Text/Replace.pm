#!perl
#
# Documentation, copyright and license is at the end of this file.
#
package  Text::Replace;

use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '1.13';
$DATE = '2004/05/11';
$FILE = __FILE__;

use vars qw(@ISA @EXPORT_OK);
require Exporter;
@ISA=('Exporter');
@EXPORT_OK = qw(&replace_variables);

#######
# Replace variables in template
#
sub replace_variables
{
    
    ######
    # This subroutine uses no object data; therefore,
    # drop any class or object.
    #
    shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);

    my ($template_p, $hash_p, $variables_p) = @_;

    unless( $variables_p ) {
        my @keys = sort keys %$hash_p;
        $variables_p = \@keys;
    }

    #########
    # Substitute selected content macros
    # 
    my $count = 1;
    while( $count ) {
        $count = 0;
        foreach my $variable (@$variables_p) {
            $count += $$template_p =~ s/([^\\])\$\{$variable\}/${1}$hash_p->{$variable}/g;
        }
    }
    $$template_p =~ s/\\\$/\$/g;  # unescape macro dollar

    1;
}


1


__END__

=head1 NAME
  
Text::Replace - replace variables from a hash

=head1 SYNOPSIS

 #######
 # Subroutine Interface
 #
 use Text::Replace qw(&replace_variables);
 $success = replace_variables(\$template, \%variable_hash, \@variable);

 ########
 # Class Interface
 #
 use Text::Replace;
 $success = Text::Replace->replace_variables(\$template, \%variable_hash, \@variable);

=head1 DESCRIPTION

The C<Text::Replace> program module is simple and plain by design.
The C<Text::Replace> program module mimics the
built-in Perl double quote, '"', literal scalar that
replaces Perl scalar variables named with a leading '$'.
The C<Text::Replace> program module stays in the background,
just like John William's movie scores.
There is no large manual thicker than the Bible 
with tricks and tips and gyrations to learn and 
to distract. The module is plain, simple with
no expressiveness.
The C<Text::Replace> program module does only one
thing: substitute a value for a variable.
It is amazing how many times, just a simple double quote
literal replacement in a small string or even
a large text string gets the job done.

Does C<Text::Replace> solve all variable replacement, template
problems? Definitely not.
There is no capabilities for inserting graphs, text wrap plug-ins,
GD interface.
If an application needs something this sophisticated,
there are many fine template program modules in CPAN
such as the highly rated C<Template> program module.

=head1 SUBROUTINES

=head2 replace_variables

The C<replace_variables> subroutine, takes a C<\$template> reference containing
Perl scalar variables, always named the leading I<funny character> '$', 
and recursively looks up the value for the scalar variables in the 
C<\%variable_hash> and replaces the value in the C<\$template>.
The C<replace_variables> subroutine only replaces those variables
in the C<\@variable> list.

=head1 REQUIREMENTS

Some day.

=head1 DEMONSTRATION

 #########
 # perl Replace.d
 ###

~~~~~~ Demonstration overview ~~~~~

The results from executing the Perl Code 
follow on the next lines as comments. For example,

 2 + 2
 # 4

~~~~~~ The demonstration follows ~~~~~

     use File::Spec;

     use File::Package;
     my $fp = 'File::Package';

     my $tr = 'Text::Replace';

     my $loaded = '';
     my $template = '';
     my %variables = ();
     my $expected = '';

 ##################
 # Load UUT
 # 

 my $errors = $fp->load_package($tr)
 $errors

 # ''
 #

 ##################
 # replace variables
 # 

 $template = << 'EOF';
 =head1 Title Page

  Software Version Description

  for

  ${TITLE}

  Revision: ${REVISION}

  Version: ${VERSION}

  Date: ${DATE}

  Prepared for: ${END_USER} 

  Prepared by:  ${AUTHOR}

  Copyright: ${COPYRIGHT}

  Classification: ${CLASSIFICATION}

 =cut

 EOF

 %variables = (
    TITLE => 'SVDmaker',
    REVISION => '-',
    VERSION => '0.01',
    DATE => '1969/5/6',
    END_USER => 'General Public',
    AUTHOR => 'Software Diamonds',
    COPYRIGHT => 'none',
    CLASSIFICATION => 'none');

 $tr->replace_variables( \$template, \%variables );
 $template

 # '=head1 Title Page

 # Software Version Description

 # for

 # SVDmaker

 # Revision: -

 # Version: 0.01

 # Date: 1969/5/6

 # Prepared for: General Public 

 # Prepared by:  Software Diamonds

 # Copyright: none

 # Classification: none

 #=cut

 #'
 #

=head1 QUALITY ASSURANCE

Running the test script C<Replace.t> verifies
the requirements for this module.
The C<tmake.pl> cover script for L<Test::STDmaker|Test::STDmaker>
automatically generated the
C<Replace.t> test script, C<Replace.d> demo script,
and C<t::Text::Replace> program module POD,
from the C<t::Text::Replace> program module contents.
The C<tmake.pl> cover script automatically ran the
C<Replace.d> demo script and inserted the results
into the 'DEMONSTRATION' section above.
The  C<t::Text::Replace> program module
is in the distribution file
F<Text-Replace-$VERSION.tar.gz>.

=head1 NOTES

=head2 Author 

The holder of the copyright and maintainer is

E<lt>support@SoftwareDiamonds.comE<gt>

=head2 Copyright Notice

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

SOFTWARE DIAMONDS, http://www.softwarediamonds.com,
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

=item L<Template|Template>

=item L<Docs::Site_SVD::Text_Replace|Docs::Site_SVD::Text_Replace>

=item L<Test::STDmaker|Test::STDmaker>

=item L<ExtUtils::SVDmaker|ExtUtils::SVDmaker> 

=back

=cut

### end of file ###
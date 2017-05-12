#!perl
#
# Documentation, copyright and license is at the end of this file.
#

package  File::Package;

use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '1.16';
$DATE = '2004/04/15';
$FILE = __FILE__;

use File::Spec;
use SelfLoader;

use vars qw(@ISA @EXPORT_OK);
require Exporter;
@ISA= qw(Exporter);
@EXPORT_OK = qw(load_package is_package_loaded eval_str);
use vars qw(@import);

1;

__DATA__


######
#
#
sub load_package
{

     ######
     # This subroutine uses no object data; therefore,
     # drop any class or object.
     #
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     local @import;

     (my $program_module, @import) = @_;
     return  "# The package name is empty. There is no package to load.\n"
         unless ($program_module); 

     my $packages = $import[-1] && ref($import[-1]) eq 'ARRAY' ? pop @import : [$program_module];
        
     my $error = '';
     my $restore_warn = $SIG{__WARN__};
     my $restore_croak = \&Carp::croak;
     unless (File::Package->is_package_loaded( $program_module )) {

         #####
         # Load the module
         #
         # On error when evaluating "require $program_module" only the last
         # line of STDERR, at least on one Perl, is return in $@.
         # Save the entire STDERR to a memory variable by using eval_str
         #
         $error = eval_str ("require $program_module;");
         return "Cannot load $program_module\n\t" . $error if $error;

         #####
         # Verify the package vocabulary is present
         #
         my @package_names = ();
         foreach (@$packages) { 
             push @package_names, $_ unless File::Package->is_package_loaded($_, $program_module );
         }
         return "# $program_module file but package(s) " . (join ',',@package_names) . " absent.\n"
              if @package_names;
     }

     ####
     # Import flagged symbols from load package into current package vocabulary.
     #
     if( @import ) {

         ####
         # Import does not work correctly when running under eval. Import
         # uses the caller stack to determine way to stuff the symbols.
         # The eval messes with the stack. Since not using an eval, need
         # to double check to make sure import does not die.
         
         ####
         # Poor man's eval where trap off the Carp::croak function.
         # The Perl authorities have Core::die locked down tight so
         # it is next to impossible to trap off of Core::die. Lucky 
         # must everyone uses Carp::croak instead of just dieing.
         #
         # Anyway, get the benefit of a lot of stack gyrations to
         # formulate the correct error msg by Exporter::import.
         # 
         no warnings;
         $SIG{__WARN__} = sub { $error .= join '', @_; };
         *Carp::croak = sub {
             $error = 'import die. ' . (join '', @_);
             $error .= Carp::longmess (join '', @_);
             goto IMPORT; # once croak can not continue
         };
         use warnings;
         local $Exporter::ExportLevel = 1;
         if(@import == 1 && defined $import[0] && $import[0] eq '') {
             $program_module->import( );
         }
         else {
             $program_module->import( @import );
         }
         no warnings;
         IMPORT: *Carp::croak = $restore_croak;
         $SIG{__WARN__} = ref( $restore_warn ) ? $restore_warn : '';
         use warnings;
     }
     $SIG{__WARN__} = ref( $restore_warn ) ? $restore_warn : '';
     return $error;
}




#####
# Many times, all the warnings do not get into the $@ string
#
sub eval_str
{
     shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);
     my ($str) = @_;

     my $restore_warn = $SIG{__WARN__};
     my $error_msg = '';
     $SIG{__WARN__} = sub { $error_msg .= join '', @_; };
     eval $str;
     $SIG{__WARN__} = ref( $restore_warn ) ? $restore_warn : '';

     $error_msg = $@ . $error_msg if $@;
     $error_msg =~ s/\n/\n\t/g if $error_msg;
     $error_msg;
}


######
#
#
sub is_package_loaded
{
     ######
     # This subroutine uses no object data; therefore,
     # drop any class or object.
     #
     shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);

     my ($package, $program_module) = @_;
   
     my $package_hash = $package . "::";
     my $vocabulary = defined %$package_hash;


     $program_module = $package unless $program_module;
     my $require = File::Spec->catfile( split /::/, $program_module . '.pm');
     my $inc = $INC{$require};

     ####
     # Microsoft cannot make up its mind to use
     # Microsoft \ or Unix / for path separator.
     # 
     # Just in case, running Microsoft, delete
     # Unix mirror name for the file
     #
     my $OS = $^O; 
     unless ($OS) {   # on some perls $^O is not defined
         require Config;
	 $OS = $Config::Config{'osname'};
     } 
     $require =~ s|\\|/|g if $OS eq 'MSWin32';; 
     $inc = $inc || $INC{$require};
     ($vocabulary && $inc) ? 1 : '';
}

1


__END__


=head1 NAME

File::Package - test load a program module with a package of the same name

=head1 SYNOPSIS

 ##########
 # Subroutine interface
 #
 use File::Package qw(is_package_loaded load_package);

 $yes = is_package_loaded($package, $program_module);

 $error   = load_package($program_module);
 $error   = load_package($program_module, @import);
 $error   = load_package($program_module, [@package_list]);
 $error   = load_package($program_module, @import, [@package_list]);

 ##########
 # Class Interface
 # 
 use File::Package;

 $yes = is_package_loaded($package, $program_module);

 $error   = File::Package->load_package($program_module);
 $error   = File::Package->load_package($program_module, @import);
 $error   = File::Package->load_package($program_module, [@package_list]);
 $error   = File::Package->load_package($program_module, @import, [@package_list]);

=head1 DESCRIPTION

Although a program module and package have the same name
syntax, they are entirely different.
A program module is a file. 
A package is a hash of symbols, a symbol table.
The Perl convention is that the names for each are the same
which enhances the appearance that they are the same
when in fact they are different.

=head2 is_package_loaded subroutine

 $package = is_package_loaded($program_module, $package)

The C<is_package_loaded> subroutine determines if the C<$package>
is present and the C<$progarm_module> loaded. 
If C<$package> is absent, 0 or '', C<$package> is set to the 
C<program_module>.

=head2 load_package subroutine

  $error = load_package($program_module, @import, [@package_list]);

The C<load_package> subroutine attempts to capture any load problems by
loading the package with a "require " under an eval and capturing
all the "warn" and $@ messages. 

If the C<$program_module> load is successful, 
the checks that the packages in the @package list are present.
If @package list is absent, the C<$program_module> uses
the C<program_module> name as a list of one package.

Finanly the C<$program_module> subroutine will import the symbols
in the C<@import> list.
If C<@import> is absent C<$program_module> subroutine does not
import any symbols; if C<@import> is '', all symbols are imported.
A C<@import> of 0 usually results in an C<$error>.

The C<$program_module> traps all load errors and all import
C<Carp::Crock> errors and returns them in the C<$error> string.

One very useful application of the C<load_package> subroutine is in test scripts. 
If a package does load, it is very helpful that the program does
not die and reports the reason the package did not load. 
This information is readily available when loaded at a local site.
However, it the load occurs at a remote site and the load crashes
Perl, the remote tester usually will not have this information
readily available. 

Other applications include using backup alternative software
if a package does not load. For example if the package
'Compress::Zlib' did not load, an attempt may be made
to use the gzip system command. 

=head1 BUGS

The C<load_package> cannot load program modules whose
name contain the '-' characters. 
The 'eval' function used to trap the die errors
believes it means subtraction.

=head1 REQUIREMENTS

Coming soon.

=head1 DEMONSTRATION

 ~~~~~~ Demonstration overview ~~~~~

Perl code begins with the prompt

 =>

The selected results from executing the Perl Code 
follow on the next lines. For example,

 => 2 + 2
 4

 ~~~~~~ The demonstration follows ~~~~~

 =>     use File::Package;
 =>     my $uut = 'File::Package';
 => my $error = $uut->load_package( 'File::Basename' )
 ''

 => $error = $uut->load_package( '_File_::BadLoad' )
 'Cannot load _File_::BadLoad
 	syntax error at E:/User/SoftwareDiamonds/installation/t/File/_File_/BadLoad.pm line 13, near "$FILE "
 	Global symbol "$FILE" requires explicit package name at E:/User/SoftwareDiamonds/installation/t/File/_File_/BadLoad.pm line 13.
 	Compilation failed in require at (eval 4) line 1.
 	Scalar found where operator expected at E:/User/SoftwareDiamonds/installation/t/File/_File_/BadLoad.pm line 13, near "$FILE"
 		(Missing semicolon on previous line?)
 	'

 => $uut->load_package( '_File_::BadPackage' )
 '# _File_::BadPackage file but package(s) _File_::BadPackage absent.
 '

 => $uut->load_package( '_File_::Multi' )
 '# _File_::Multi file but package(s) _File_::Multi absent.
 '

 => $error = $uut->load_package( '_File_::Hyphen-Test' )
 'Cannot load _File_::Hyphen-Test
 	syntax error at (eval 7) line 1, near "require _File_::Hyphen-"
 	Warning: Use of "require" without parens is ambiguous at (eval 7) line 1.
 	'

 => !defined($main::{'find'})
 '1'

 => $error = $uut->load_package( 'File::Find', 'find', ['File::Find'] )
 ''

 => defined($main::{'find'})
 '1'

 => !defined($main::{'finddepth'})
 '1'

 => $uut->load_package( 'File::Find', 'Jolly_Green_Giant')
 '"Jolly_Green_Giant" is not exported by the File::Find module
 Can't continue after import errors'

 => !defined($main::{'finddepth'})
 '1'

 => $error = $uut->load_package( 'File::Find', '')
 ''

 => defined($main::{'finddepth'})
 '1'


=head1 QUALITY ASSURANCE

Running the test script 'Package.t' found in
the "File-Package-$VERSION.tar.gz" distribution file verifies
the requirements for this module.

All testing software and documentation
stems from the 
Software Test Description (L<STD|Docs::US_DOD::STD>)
program module 't::File::Package',
found in the distribution file 
"File-Package-$VERSION.tar.gz". 

The 't::File::Package' L<STD|Docs::US_DOD::STD> POD contains
a tracebility matix between the
requirements established above for this module, and
the test steps identified by a
'ok' number from running the 'Package.t'
test script.

The t::File::Package' L<STD|Docs::US_DOD::STD>
program module '__DATA__' section contains the data 
to perform the following:

=over 4

=item *

to generate the test script 'Package.t'

=item *

generate the tailored 
L<STD|Docs::US_DOD::STD> POD in
the 't::File::Package' module, 

=item *

generate the 'Package.d' demo script, 

=item *

replace the POD demonstration section
herein with the demo script
'Package.d' output, and

=item *

run the test script using Test::Harness
with or without the verbose option,

=back

To perform all the above, prepare
and run the automation software as 
follows:

=over 4

=item *

Install "Test_STDmaker-$VERSION.tar.gz"
from one of the respositories only
if it has not been installed:

=over 4

=item *

http://www.softwarediamonds/packages/

=item *

http://www.perl.com/CPAN-local/authors/id/S/SO/SOFTDIA/

=back
  
=item *

manually place the script tmake.pl
in "Test_STDmaker-$VERSION.tar.gz' in
the site operating system executable 
path only if it is not in the 
executable path

=item *

place the 't::File::Package' at the same
level in the directory struture as the
directory holding the 'File::Package'
module

=item *

execute the following in any directory:

 tmake -test_verbose -replace -run -pm=t::File::Package

=back

=head1 NOTES

=head2 FILES

The installation of the
"File-Package-$VERSION.tar.gz" distribution file
installs the 'Docs::Site_SVD::File_Package'
L<SVD|Docs::US_DOD::SVD> program module.

The __DATA__ data section of the 
'Docs::Site_SVD::File_Package' contains all
the necessary data to generate the POD
section of 'Docs::Site_SVD::File_Package' and
the "File-Package-$VERSION.tar.gz" distribution file.

To make use of the 
'Docs::Site_SVD::File_Package'
L<SVD|Docs::US_DOD::SVD> program module,
perform the following:

=over 4

=item *

install "ExtUtils-SVDmaker-$VERSION.tar.gz"
from one of the respositories only
if it has not been installed:

=over 4

=item *

http://www.softwarediamonds/packages/

=item *

http://www.perl.com/CPAN-local/authors/id/S/SO/SOFTDIA/

=back

=item *

manually place the script vmake.pl
in "ExtUtils-SVDmaker-$VERSION.tar.gz' in
the site operating system executable 
path only if it is not in the 
executable path

=item *

Make any appropriate changes to the
__DATA__ section of the 'Docs::Site_SVD::File_Package'
module.
For example, any changes to
'File::Package' will impact the
at least 'Changes' field.

=item *

Execute the following:

 vmake readme_html all -pm=Docs::Site_SVD::File_Package

=back

=head2 AUTHOR

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
government practices, 490A (L<STD490A/3.2.3.6>).
In accordance with the License, Software Diamonds
is not liable for any requirement, binding or otherwise.

=head2 LICENSE

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

=back

SOFTWARE DIAMONDS, http::www.softwarediamonds.com,
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

=for html
<p><br>
<!-- BLK ID="NOTICE" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="OPT-IN" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="EMAIL" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="COPYRIGHT" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="LOG_CGI" -->
<!-- /BLK -->
<p><br>

=cut

### end of file ###
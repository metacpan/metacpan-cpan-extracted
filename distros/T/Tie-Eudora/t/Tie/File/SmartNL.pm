#!perl
#
# Documentation, copyright and license is at the end of this file.
#

#####
#
# File::SmartNL package
#
package  File::SmartNL;

use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '1.16';
$DATE = '2004/05/29';
$FILE = __FILE__;

use File::Spec; # Added mkpath option, 2003/11/10
use File::Path; # Added mkpath option, 2003/11/10
use Data::Startup;

use vars qw(@ISA @EXPORT_OK);
require Exporter;
@ISA= qw(Exporter);
@EXPORT_OK = qw(config fin fout smartnl);

use vars qw($default_options);
$default_options =  File::SmartNL->defaults();

# use SelfLoader;
# 1
# __DATA__


#######
# Object used to set default, startup, options values.
#
sub defaults
{
   my $class = shift;
   $class = ref($class) if ref($class);
   my $self = $class->Data::Startup::new(   
      warn => 1,
      binary => 0,
   );
   $self->Data::Startup::override(@_);

}

######
# Perl 5.6 introduced a built-in smart nl functionality as an IO discipline :crlf.
# See I<Programming Perl> by Larry Wall, Tom Christiansen and Jon Orwant,
# page 754, Chapter 29: Functions, open function.
# For Perl 5.6 or above, the :crlf IO discipline may be preferable over the
# smart_nl method of this package.
#
sub smart_nl
{
   shift if UNIVERSAL::isa($_[0],__PACKAGE__);
   my ($data) = @_;
   $data =~ s/\015\012|\012\015/\012/g;  # replace LFCR or CRLF with a LF
   $data =~ s/\012|\015/\n/g;   # replace CR or LF with logical \n 
   $data;
}

######
# Program module wide configuration
#
sub config
{
     $default_options = File::SmartNL->defaults() unless $default_options;
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     $default_options->Data::Startup::config(@_);
}


####
# slurp in a text file in a platform independent manner
#
sub fin
{

   my $event;
   shift if UNIVERSAL::isa($_[0],__PACKAGE__);
   my ($file, @options) = @_;
   $default_options = File::SmartNL->default() unless $default_options;
   my $options = $default_options->Data::Startup::override(@options);

   ######
   # If have a file name, open the file, otherwise
   # the file is opened and the file name is a 
   # file handle.
   #
   my ($fh,$is_handle);
   if( (UNIVERSAL::isa($file,'GLOB') or UNIVERSAL::isa(\$file,'GLOB')) 
		and defined fileno($file) ) {
       $fh = $file;
       $is_handle = 1;
   }
   else {
       unless(open $fh, "<$file") {
           $event = "# Cannot open <$file\n#\t$!";
           goto EVENT;
       }
       $is_handle = 0;
   } 

   #####
   # slurp in the file contents with no operating system
   # translations
   #
   binmode $fh; # make the test friendly for more platforms
   my $data = join '', <$fh>;

   #####
   # Close the file
   #
   unless($is_handle) {
       unless(close($fh)) {
           $event = "# Cannot close $file\n#\t$!";
           goto EVENT;
       }
   }
   return $data unless( $data );

   #########
   # No matter what platform generated the data, convert
   # all platform dependent new lines to the new line for
   # the current platform.
   #
   $data = smart_nl($data) unless $options->{binary};
   return $data; 

EVENT:
   $event .= "\tFile::SmartNL::fin $VERSION\n";  
   if($options->{warn}) {
       warn( $event );
       return undef;
   }         
   return \$event;
}



###
# slurp a file out, current platform text format
#
sub fout
{
   my $event;
   shift if UNIVERSAL::isa($_[0],__PACKAGE__);
   my ($file, $data, @options) = @_;
   $default_options = File::SmartNL->default() unless $default_options;
   my $options = $default_options->Data::Startup::override(@options);

   ######
   # Added mkdir option, 2003/11/10
   # 
   unless( $options->{no_mkpath} ) {
       my ($vol, $dirs) = File::Spec->splitpath($file);
       $dirs = File::Spec->catdir($vol,$dirs) if $vol && $dirs;
       mkpath $dirs if $dirs;
   }

   if($options->{append}) {
       unless(open OUT, ">>$file") {
           $event = "# Cannot open >$file\n\t$!";
           goto EVENT;
       }
   }
   else {

       unless(open OUT, ">$file") {
           $event = "# Cannot open >$file\n\t$!";
           goto EVENT;
       }

   }

   binmode OUT if $options->{binary};
   my $char_out = print OUT $data;
   unless(close(OUT)) {
       $event = "# Cannot close $file\n\t$!";
       goto EVENT;
   }

   return $char_out; 

EVENT:
   $event .= "\n#\tFile::SmartNL::fout $VERSION\n";  
   if($options->{warn}) {
       warn( "# Cannot close $file\n");
       return undef;
   }         
   return \$event;
}

1


__END__


=head1 NAME

File::SmartNL - slurp text files no matter the New Line (NL) sequence

=head1 SYNOPSIS

 #####
 # Subroutine Interface
 #
 use File::SmartNL qw(config fin fout smartnl);

 $old_value = config( $option );
 $old_value = config( $option => $new_value);
 (@all_options) = config( );

 $data          = smart_nl($data);
 $data          = fin( $file_name, @options );
 $char_count    = fout($file_name, $data, @options);

 ######
 # Object Interface
 # 
 use File::SmartNL;

 $default_options = File::SmartNL->default(@options);

 $old_value = $default_options->config( $option );
 $old_value = $default_options->config( $option => $new_value);
 (@all_options) = $default_options->config( );

 $data          = File::SmartNL->smart_nl($data);
 $data          = File::SmartNL->fin( $file_name, @options );
 $char_count    = File::SmartNL->fout($file_name, $data, @options);

Generally, if a subroutine will process a list of options, C<@options>,
that subroutine will also process an array reference, C<\@options>, C<[@options]>,
or hash reference, C<\%options>, C<{@options}>.
If a subroutine will process an array reference, C<\@options>, C<[@options]>,
that subroutine will also process a hash reference, C<\%options>, C<{@options}>.
See the description for a subroutine for details and exceptions.

=head1 DESCRIPTION

Different operating systems have different sequences for new-lines.
Historically when computers where first being born, 
one of the mainstays was the teletype. 
The teletype understood L<ASCII|http:E<sol>E<sol>ascii.computerdiamonds.com>.
The teletype was an automated typewriter that would perform a 
carriage return when it received an ASCII Carriage Return (CR), \015,  character
and a new line when it received a Line Feed (LF), \012 character.

After some time came Unix. Unix had a tty driver that had a raw mode that
sent data unprocessed to a teletype and a cooked mode that performed all
kinds of translations and manipulations. Unix stored data internally using
a single NL character at the ends of lines. The tty driver in the cooked
mode would translate the New Line (NL) character to a CR,LF sequence. 
When driving a teletype, the physicall action of performing a carriage
return took some time. By always putting the CR before the LF, the
teletype would actually still be performing a carriage return when it
received the LF and started a line feed.

After some time came DOS. Since the tty driver is actually one of the largest
peices of code for UNIX and DOS needed to run in very cramp space,
the DOS designers decided, that instead of writing a tailored down tty driver,
they would stored a CR,LF in the internal memory. Data internally would be
either 'text' data or 'binary' data.

Needless to say, after many years and many operating systems about every
conceivable method of storing new lines may be found amoung the various
operating systems.
This greatly complicates moving files from one operating system to
another operating system.

The smart NL methods in this package are designed to take any combination
of CR and NL and translate it into the special NL seqeunce used on the
site operating system. Thus, by using these methods, the messy problem of 
moving files between operating systems is mostly hidden in these methods.
By using the C<fin> and C<fout> methods, text files may be freely exchanged between
operating systems without any other processing. 

The one thing not hidden is that the methods need to know if the data is
'text' data or 'binary' data. Normally, the assume the data is 'text' and
are overriden by setting the 'binary' option.

Perl 5.6 introduced a built-in smart nl functionality as an IO discipline :crlf.
See I<Programming Perl> by Larry Wall, Tom Christiansen and Jon Orwant,
page 754, Chapter 29: Functions, open function.
For Perl 5.6 or above, the :crlf IO discipline my be preferable over the
smart_nl method of this program module.

=head1 SUBROUTINES

=head2 config

 $old_value = config( $option );
 $old_value = config( $option => $new_value);
 (@all_options) = config( );

When Perl loads 
the C<File::SmartNL> program module,
Perl creates a
C<$File::Drawing::default_options> object
using the C<default> method.

Using the C<config> as a subroutine 

 config(@_) 

writes and reads
the C<$File::Drawing::default_options> object
directly using the L<Data::Startup::config|Data::Startup/config>
method.
Avoided the C<config> and in multi-threaded environments
where separate threads are using C<File::Drawing>.
All other subroutines are multi-thread safe.
They use C<override> to obtain a copy of the 
C<$File::Drawing::default_options> and apply any option
changes to the copy keeping the original intact.

Using the C<config> as a method,

 $options->config(@_)

writes and reads the C<$options> object
using the L<Data::Startup::config|Data::Startup/config>
method.
It goes without saying that that object
should have been created using one of
the following or equivalent:

 $default_options = $class->File::Drawing::defaults(@_);

The underlying object data for the C<File::SmartNL>
class of objects is a hash. For object oriented
conservative purist, the C<config> subroutine is
the accessor function for the underlying object
hash.

Since the data are all options whose names and
usage is frozen as part of the C<File::Drawing>
interface, the more liberal minded, may avoid the
C<config> accessor function layer, and access the
object data directly.

=head2 defaults

The C<defaults> subroutine establish C<File::Drawing> class wide options
options as follows:

 option                  initial value
 --------------------------------------------
 warn                      1
 binary                    0

=head2 fin

 $data = fin( $file_name )
 $data = fin( $file_name, @options )
 $data = fin( $file_name, [@options] )
 $data = fin( $file_name, {@options} )

For the C<binary> option, the C<fin> subroutine reads
C<$data> from the C<$file_name> as it; otherwise, it converts
any CR LF sequence to the
the logical Perl C<\n> character for site.

=head2 fout

 $success = fout($file_name, $data)
 $success = fout($file_name, $data, @options)
 $success = fout($file_name, $data, [@options])
 $success = fout($file_name, $data, {@options})

For the C<binary> option, the C<fout> subroutine writes out the
C<$data> to the C<$file_name> as it; otherwise, it converts
the logical Perl C<\n> character to th site CR LF sequence for a NL.

=head2 smart_nl 

  $data = smart_nl( $data  )

The C<smart_nl> subroutine converts any combination of
CR and LF to the NL of the site operationg system.

=head1 REQUIREMENTS

Someday.

=head1 DEMONSTRATION

 #########
 # perl SmartNL.d
 ###

~~~~~~ Demonstration overview ~~~~~

The results from executing the Perl Code 
follow on the next lines as comments. For example,

 2 + 2
 # 4

~~~~~~ The demonstration follows ~~~~~

     use File::Package;
     my $fp = 'File::Package';

     my $uut = 'File::SmartNL';
     my $loaded = '';
     my $expected = '';
     my $data = '';

 VO:

 ##################
 # UUT not loaded
 # 

 $loaded = $fp->is_package_loaded('File::Where')

 # ''
 #

 ##################
 # Load UUT
 # 

 my $errors = $fp->load_package($uut, 'config')
 $errors

 # ''
 #
    unlink 'test.pm';
    $expected = "=head1 Title Page\n\nSoftware Version Description\n\nfor\n\n";
    $uut->fout( 'test.pm', $expected, {binary => 1} );

 ##################
 # fout Unix fin
 # 

 $uut->fin( 'test.pm' )

 # '=head1 Title Page

 #Software Version Description

 #for

 #'
 #
    unlink 'test.pm';
    $data = "=head1 Title Page\r\n\r\nSoftware Version Description\r\n\r\nfor\r\n\r\n";
    $uut->fout( 'test.pm', $data, {binary => 1} );

 ##################
 # fout Dos Fin
 # 

 $uut->fin('test.pm')

 # '=head1 Title Page

 #Software Version Description

 #for

 #'
 #
   unlink 'test.pm';
   $data =   "line1\015\012line2\012\015line3\012line4\015";
   $expected = "line1\nline2\nline3\nline4\n";

 ##################
 # smart_nl
 # 

 $uut->smart_nl($data)

 # 'line1
 #line2
 #line3
 #line4
 #'
 #

 ##################
 # read configuration
 # 

 [config('binary')]

 # [
 #          'binary',
 #          0
 #        ]
 #

 ##################
 # write configuration
 # 

 [config('binary',1)]

 # [
 #          'binary',
 #          0
 #        ]
 #

 ##################
 # verify write configuration
 # 

 [config('binary')]

 # [
 #          'binary',
 #          1
 #        ]
 #

=head1 QUALITY ASSURANCE

Running the test script C<SmartNL.t> verifies
the requirements for this module.
The C<tmake.pl> cover script for L<Test::STDmaker|Test::STDmaker>
automatically generated the
C<SmartNL.t> test script, C<SmartNL.d> demo script,
and C<t::File::SmartNL> STD program module POD,
from the C<t::File::SmartNL> program module contents.
The C<tmake.pl> cover script automatically ran the
C<SmartNL.d> demo script and inserted the results
into the 'DEMONSTRATION' section above.
The  C<t::File::SmartNL> program module
is in the distribution file
F<File-SmartNL-$VERSION.tar.gz>.

=head1 NOTES

=head2 Author

The holder of the copyright and maintainer is

E<lt>support@SoftwareDiamonds.comE<gt>

=head2 Copyright

Copyrighted (c) 2002 Software Diamonds

All Rights Reserved

=head2 Binding Requirements Notice

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

=item L<Docs::Site_SVD::File_SmartNL|Docs::Site_SVD::File_SmartNL>

=item L<Test::STDmaker|Test::STDmaker>

=item L<ExtUtils::SVDmaker|ExtUtils::SVDmaker> 

=back

=cut

### end of file ###
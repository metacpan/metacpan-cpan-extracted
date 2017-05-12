#!perl
#
# Documentation, copyright and license is at the end of this file.
#
package Tie::Gzip;

use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '1.15';
$DATE = '2004/04/16';
$FILE = __FILE__;

use File::Spec;

######
#  Started with CPAN::Tarzip::TIEHANDLE which
#  still retains a faint resemblence.
#
sub TIEHANDLE
{

     my($class, @args) = @_;

     #########
     # create new object of $class
     # 
     # If there is ref($class) than $class
     # is an object whose class is ref($class).
     # 
     $class = ref($class) if ref($class); 
     my $self = bless {}, $class;

     ######
     # Parse the last argument as options if it is a reference.
     #
     my $options = {};
     if( ref($args[-1]) ) {
          $options = pop @args;
          if(ref($options) eq 'ARRAY') {
              my %options = @{$options};
              $options = \%options;
          }          
     }
     $self->{options} = $options;


     #####################
     # If the Compress::Zlib package is not defined,
     # load it.
     #
     my $package = 'Compress::Zlib::';
     File::Package->load_package('Compress::Zlib') unless(defined %$package);
     $self->{gz_package} = defined %$package;

     if( $self->{gz_package} ) {
         Compress::Zlib->import( qw(&gzopen $gzerrno Z_STREAM_END) );       
     }

     else {

         $options->{read_pipe} = 'gzip --decompress --stdout {}' unless $options->{read_pipe};
         $options->{write_pipe} = 'gzip --stdout > {}' unless $options->{write_pipe};
     } 

     $options->{read_pipe} .= ' |' if $options->{read_pipe} && $options->{read_pipe} !~ /\|/;
     $options->{write_pipe} = '| ' . $options->{write_pipe} if $options->{write_pipe} && $options->{write_pipe} !~ /\|/;

     ######
     # Open the gzip file
     #
     return $self->OPEN( @args ) if( @args );

     $self;

}


######
#  Lifted from CPAN::Tarzip::TIEHANDLE in the
#  CPAN.pm module
#
#  A tied object can be used to close current file
#  and open another file.
#
sub OPEN
{

     ######
     # Make a copy so change without impacting
     # the using variables.
     #
     my ($self, $mode, $file) = @_;
 
     $self->CLOSE;

     unless (defined $file) {
         $file = $mode;
         $file =~ s/^\s*([<>+|]+)\s*//;
         $mode = $1;
     }
     my $options = $self->{options};

     if( $mode eq '<' ) {

         if ($self->{gz_package} && !$options->{read_pipe}) {
             my $gz = gzopen($file,'rb');
             unless($gz) {
                 warn( "gzopen($file,'rb') failed\n") ;
                 $self->CLOSE;
                 return undef;
             }
             $self -> {GZ} = $gz;
         } 

         else {

             my $pipe = $options->{read_pipe};
             $pipe =~ s/{}/$file/g;

             ###############
             # Some perls will return a glob and a warning
             # for certain pipe errors such as the command
             # not a recognized command
             #
             my $success = open PIPE, $pipe;
             $! = 0;    ### MAS ###
             if($! || !$success) {
                 warn "Could not pipe $pipe: $!\n";
                 $self->CLOSE;
                 return undef;
             } 
             binmode PIPE;
             $self-> {FH} = \*PIPE;

         }

         ######
         # The existance of $self->{file} means the file is open
         # for business.
         #
         $self->{eof} = 0;
         $self->{file} = $file; 
         $self->{mode} = $mode; 

     }

     elsif ($mode eq '>' ) {

         if ($self->{gz_package} && !$options->{write_pipe}) {
             my $gz = gzopen($file,'wb');
             unless($gz) {
                 warn( "gzopen($file,'rb') failed\n") ;
                 $self->CLOSE;
                 return undef;
             }
             $self -> {GZ} = $gz;
         } 

         else {
             my $pipe = $options->{write_pipe};
             $pipe =~ s/{}/$file/g;

             ###############
             # Some perls will return a glob and a warning
             # for certain pipe errors such as the command
             # not a recognized command
             #
             my $success = open PIPE, $pipe;
             $! = 0;    ### MAS ###
             if($! || !$success) {
                 warn "Could not pipe $pipe: $!\n";
                 $self->CLOSE;
                 return undef;
             } 
             binmode PIPE;
             $self-> {FH} = \*PIPE;
         }
         $self->{tell} = 0;
         $self->{eof} = 0;
         $self->{file} = $file; 
         $self->{mode} = $mode; 
 
     }
 
     else {
         warn( "Opening file $file with $mode not allowed\n");
         return undef;
     }
     $self->{file_abs} = File::Spec->rel2abs( $self->{file} ) if $self->{file};

     $self;

}



#####
# Started with the CPAN::Tarzip::READLINE in the
# CPAN.pm module
#
sub READLINE
{
    my($self) = @_;

    my $line = undef;
    my $bytesread = -1;
    if (defined $self->{GZ}) {
        $bytesread = $self->{GZ}->gzreadline($line);
    } 

    elsif (defined $self->{FH}) {
        my $fh = $self->{FH};
        $line = <$fh>;
        $bytesread = $line ? length($line) : 0;
    }

    if ($bytesread <= 0) {
        $self->{eof} = 1;
        return undef;
    }
    $self->{tell} += $bytesread;

    $line;

}


#####
# Started with the CPAN::Tarzip::READ in the
# CPAN.pm module
#
sub READ
{

    my($self, undef, $length, $offset) = @_;
 
    if(defined $offset) {
        warn "read with offset not implemented\n";
        return undef;
    }

    my $bytes_read = 0;
    my $bufref = \$_[1];
    if (defined $self->{GZ}) {
        $bytes_read =  $self->{GZ}->gzread($$bufref,$length);
    } 

    elsif(defined $self->{FH}) {
        my $fh = $self->{FH};
        $bytes_read = read($fh,$$bufref,$length);
    }

    $self->{tell} += $bytes_read;
    $bytes_read;

}



#####
# 
#
sub GETC
{

    my($self) = @_;
 
    my $c;

    my $bytes_read = 0;
    if (defined $self->{GZ}) {
        $bytes_read =  $self->{GZ}->gzread($c, 1);
    } 

    elsif(defined $self->{FH}) {
        my $fh = $self->{FH};
        $c = getc($fh);
        $bytes_read = length($c);
    }

    $self->{tell} += $bytes_read;
    $c;

}




#####
# 
#
sub PRINT
{
    my $self = shift;   

    my $buf = join(defined $, ? $, : '',@_);
    $buf .= $\ if defined $\;

    my $bytes_written = 0;
    if (defined $self->{GZ}) {
        $bytes_written =  $self->{GZ}->gzwrite($buf);
    } 

    elsif(defined $self->{FH}) {
        my $fh = $self->{FH};
        return undef unless $bytes_written = print $fh $buf;
        
    }

    $self->{tell} += $bytes_written;
    $bytes_written;

}



#####
# 
#
sub PRINTF
{
    my $self = shift;   
    $self->PRINT (sprintf(shift,@_));
}



#####
# 
#
sub WRITE
{
    my($self, $buf, $length, $offset) = @_;

    if(defined $offset) {
        warn "read with offset not implemented\n";
        return undef;
    }

    my $bytes_written = 0;
    $buf = substr($buf,0,$length);
    if (defined $self->{GZ}) {
        $bytes_written =  $self->{GZ}->gzwrite($buf);
    } 

    elsif(defined $self->{FH}) {
        my $fh = $self->{FH};
        $bytes_written = print $fh $buf;
    }

    $self->{tell} += $bytes_written;
    $bytes_written;

}





#####
# Started with CPAN::Tarzip::DESTROY, CPAN::Tarzip::gtest 
#
sub CLOSE
{

    my($self) = @_;

    return 1 unless $self->{file};

    my $success = 1;
    if ($self->{GZ}) {
        my $gz = $self->{GZ};
        my $err = $gz->gzerror();
        $gz->gzclose();
        if ($self->{mode} eq '<' ) {
            $success = !$err || $err == Z_STREAM_END();
            if($success && $self->{tell} == -s $self->{file_abs}) {
                 $success = 0;
                $err =  "Uncompressed file\n";
            }
        }
        warn("success: $success\n\terr: $err") unless $success;
    } 

    else {
        my $fh = $self->{FH};
        $success = close $fh if defined $fh;
        warn("success: 0\n\terr: $!") unless $success;
    }

    $self->{file} = '';
    $self->{mode} = '';
    $self->{FH} = undef;
    $self->{GZ} = undef;
    $self->{tell} = 0;
    $self->{eof} = 0;

    $success;
}


#####
#
#
sub DESTROY
{
    CLOSE( @_ );
 
}


#####
#
#
sub SEEK
{
    my ($self, $offset, $whence) = @_;

    if($whence ne 1) {
        warn "Whence of $whence not allowed.\n";
        return undef;
    }
    if($offset < 0) {
        warn "Negative offset of $offset not allowed.\n";
        return undef;
    }

    my $buffer;
    $self->READ( $buffer, $offset);

}



#####
#
#
sub TELL
{
    my $self = shift;
    $self->{tell};
}


#####
#
#
sub EOF
{
    my $self = shift;
    $self->{eof};
}


######
#
#
sub BINMODE
{

    my ($self, $disc) = @_;

    my $binmode =  ':raw';
    if (exists $self->{FH}) {
        my $fh = $self->{FH};
        $binmode =  binmode $fh;
    }
    $binmode;

}


######
#
#
sub FILENO
{
    my $self = shift;

    my $fileno =  undef;
    if (exists $self->{FH}) {
        my $fh = $self->{FH};
        $fileno =  fileno $fh;
    }

    $fileno;
}


1


__END__

=head1 NAME

Tie::Gzip - read and write gzip compressed files

=head1 SYNOPSIS

 require Tie::Gzip;

 tie filehandle, 'Tie::Gzip'
 tie filehandle, 'Tie::Gzip', mode, filename
 tie filehandle, 'Tie::Gzip', filename

 tie filehandle, 'Tie::Gzip', \%options
 tie filehandle, 'Tie::Gzip', mode, filename, \%options 
 tie filehandle, 'Tie::Gzip', filename, \%options

 tie filehandle, 'Tie::Gzip', \@options
 tie filehandle, 'Tie::Gzip', mode, filename, \@options 
 tie filehandle, 'Tie::Gzip', filename, \@options

=head1 DESCRIPTION

The 'Tie::Gzip' module provides a file handle Tie 
for compressing and uncompressing files using
the gzip compression format.

By tieing a filehandle to 'Tie::Gzip' subsequent uses
of the file subroutines with the tied filehandle will
compress data written to an opened file using gzip compression
and decompress data read from an opened file using gzip
compression.

If the 'Tie::Gzip' tie receives a I<filename> or I<mode filename>
after completing the tie, 'Tie::Gzip' will open I<filename>.

During the tie, Tie::Gzip will first try to load the
'Compress::Zlib' module and package. 
If successful, 'Tie::Gzip' uses the 'Compress::Zlib' for
compressing and decompressing the file data.

If unsuccessful, 'Tie::Gzip' setups up the following pipes
to an anticipated GNU 'gzip' site command for compressing and
decompressing the file data:

 gzip --decompress --stdout {} | # read file data
 | gzip --stdout > {} # write file data

where the string '{}' is a placeholder for the I<filename>.

Many sites, especially UNIX Internet Service Providers, 
will not provide the 'Compress::Zlib' module.
Instead they expect the users to make use of a site
Unix gzip command.

If neither of these gzip resources are available for a site,
'Tie::Gzip' provides the 'read_pipe' and 'write_pipe'
options, to tie to a suitable local site gzip 
command.

For example, to specify the GNU gzip, provide the
following options as either a hash or array reference:

 [ read_pipe => 'gzip --decompress --stdout {}',
   write_pipe => ' gzip --stdout > {}' ]

The pipe symbol '|' is optional.
The 'Tie::Gzip' uses the 'binmode' for all data
to and from the read and write pipes.
This is equivalent to 'raw' (as oppose to 'cooked') for Unix file drivers
and the binary (as oppose to 'text') for Windows file drivers.

The hash reference to the 'Tie::Gzip' data 
may be obtained as follows:

  my $self = tied filehandle;
  
The 'Tie::Gzip' data hash keys and contents 
are subject to change without
notice expect for 

  $self->{options}->{read_pipe}
  $self->{options}->{write_pipe}

as described above.

Because of the nature of the gzip compression software,
the file subroutines have at least the following
restrictions:

=over 4

=item open

The open command will accept only the '>' and the '<' modes.
All other modes are invalid. 
The 'Tie::Gzip' tie does provide greatly limited piping
capabilities with the 'read_pipe' and 'write_pipe' options.
Feature creep of reading and writing a compress file is
coming.

=item seek

The seek is only valid for mode 1, positive seeks when
reading a compress files.
Feature creep of seek is comming.

=item fileno

The file no when using "Compress::Zlib" is undefined.

=item binmode

This subroutine does nothing since the tied 'Tie::Gzip'
file handle is always in the binmode.

=back

=head1 REQUIREMENTS

For these requirements the pharse 'Tie Gzip file handle'
will mean a file handle successfully tied to 'Tie::Gzip'
that uses either the 'Compress::Zlib' module or the
a site system GNU gzip executable to compress and decompress
the file data.
Thus, the data written to a file using a 'Tie::Gzip file handle'
should be in accordance with RFC 1951 and RFC 1952.

The 'Tie::Gzip' requirements are as follows:

=over 4

=item data integrity [1]

The data read back from a file using a 'Tie::Gzip file handle' 
shall[1] be the same as the data written
to the file using a 'Tie::Gzip file handle'.

=item interoperability [1]

The data read back from a file using a software unit or executable 
program in accordance with RFC 1951
and RFC 1952 shall[1] be the same as the data written
to the same file using a 'Tie::Gzip file handle'.

=item interoperability [2]

The data read back from a file using 'Tie::Gzip file handle
shall[2] be the same as the data written
to the same file using a software unit or executable program
in accordance with RFC 1951 and RFC 1952.

=back

=head1 DEMONSTRATION

 #########
 # perl Gzip.d
 ###

 ~~~~~~ Demonstration overview ~~~~~

Perl code begins with the prompt

 =>

The selected results from executing the Perl Code 
follow on the next lines. For example,

 => 2 + 2
 4

 ~~~~~~ The demonstration follows ~~~~~

 =>     use File::Package;
 =>     use File::Copy;
 =>     use File::SmartNL;

 =>     my $uut = 'Tie::Gzip'; # Unit Under Test
 =>     my $fp = 'File::Package';
 =>     my $snl = 'File::SmartNL';
 =>     my $loaded;

 => ##################
 => # Load UUT
 => # 
 => ###

 => my $errors = $fp->load_package($uut)
 => $errors
 ''

 => ##################
 => # Tie::Gzip Version $Tie::Gzip::VERSION loaded
 => # 
 => ###

 => $loaded = $fp->is_package_loaded($uut)
 1

 => ##################
 => # Copy gzip0.htm to gzip1.htm.
 => # 
 => ###

 => unlink 'gzip1.htm'
 => copy('gzip0.htm', 'gzip1.htm')
 '1'

 =>       sub gz_decompress
 =>      {
 =>          my ($gzip) = shift @_;
 =>          my $file = 'gzip1.htm';
 =>  
 =>          return undef unless open($gzip, "< $file.gz");

 =>          if( open (FILE, "> $file" ) ) {
 =>              while( my $line = <$gzip> ) {
 =>                   print FILE $line;
 =>              }
 =>              close FILE;
 =>              close $gzip;
 =>              unlink 'gzip1.htm.gz';
 =>              return 1;
 =>          }

 =>          1 

 =>      }

 =>      sub gz_compress
 =>      {
 =>          my ($gzip) = shift @_;
 =>          my $file = 'gzip1.htm';
 =>          return undef unless open($gzip, "> $file.gz");
 =>         
 =>          if( open(FILE, "< $file") ) {
 =>              while( my $line = <FILE> ) {
 =>                     print $gzip $line;
 =>              }
 =>              close FILE;
 =>              unlink $file;
 =>          }
 =>          close $gzip;
 =>     }

 =>     #####
 =>     # Compress gzip1.htm with gzip software unit of opportunity
 =>     # Decompress gzip1.htm,gz with gzip software unit of opportunity
 =>     #
 =>     tie *GZIP, 'Tie::Gzip';
 =>     my $tie_obj = tied *GZIP;
 =>     my $gz_package = $tie_obj->{gz_package};
 =>     my $gzip = \*GZIP;
 =>     
 =>     #####
 =>     # Do not skip tests next compress and decompress tests if this expression fails.
 =>     # Passing the next compress and decompress tests is mandatory to ensure at 
 =>     # least one gzip is available and works
 =>     # 
 =>     my $gzip_opportunity= gz_compress( $gzip );

 => ##################
 => # Compress gzip1.htm with gzip of opportunity. Validate gzip1.htm.gz exists
 => # 
 => ###

 => -f 'gzip1.htm.gz'
 '1'

 => ##################
 => # Decompress gzip1.htm.gz with gzip of opportunity. Validate gzip1.htm same as gzip0.htm
 => # 
 => ###

 => gz_decompress( $gzip )
 => $snl->fin('gzip1.htm') eq $snl->fin('gzip0.htm')
 '1'

 => unlink 'gzip1.htm'

=head1 QUALITY ASSURANCE

=head2 Test Script Design

The C<Tie:Gzip> test script performs multiple duties. 
The C<Tie::Gzip> program module finds a gzip software unit
of opportunity looking for both Perl C<Compress::Zlib> program module
and a site operating system gzip with the following GNU syntax:

 read_pipe => 'gzip --decompress --stdout {}',
 write_pipe => 'gzip --stdout > {}',

If a particular site does not support both gzips, 
those tests, such as the interoperatability between
different gzip software units, are skipped.

For quality assurance, the C<Tie::Gzip> test is performed on a site that
supports both. For installation test, only one is needed for a pass.
However if an installation supports both, both should pass in order
to meet the interoperatability requirement for the C<Tie::Gzip> module.
This of course does not test that files produced from gzip software
units outside the site are interoperatable.
However, since the site gzip used for the quality assurance test meets
the RFC 1951 and RFC 1952, the chances are that the gzip outside
the site is broken if C<Tie::Gzip> cannot decompress it.

=head2 Test Report

 => perl Gzip.t

1..13
# Running under perl version 5.006001 for MSWin32
# Win32::BuildNumber 635
# Current time local: Fri Apr 16 15:59:27 2004
# Current time GMT:   Fri Apr 16 19:59:27 2004
# Using Test.pm version 1.24
# Test::Tech    : 1.19
# Data::Secs2   : 1.17
# Data::SecsPack: 0.02
# =cut 
ok 1 - UUT not loaded 
ok 2 - Load UUT 
ok 3 - Tie::Gzip Version 1.14 loaded 
ok 4 - Ensure gzip.t can access gzip0.htm 
ok 5 - Copy gzip0.htm to gzip1.htm. 
ok 6 - Compress gzip1.htm with gzip of opportunity. Validate gzip1.htm.gz exists 
ok 7 - Decompress gzip1.htm.gz with gzip of opportunity. Validate gzip1.htm same as gzip0.htm 
ok 8 - Compress gzip1.htm with site os GNU gzip. Validate gzip1.htm.gz exists 
ok 9 - Decompress with site os GNU gzip. Validate gzip1.htm same as gzip0.htm 
ok 10 - Compress gzip1.htm with Compress::Zlib. Validate gzip1.htm.gz exists. 
ok 11 - Decompress gzip1.htm.gz with site OS GNU gzip. Validate gzip1.htm same as gzip0.htm 
ok 12 - Compress gzip1.htm with site os GNU gzip. Validate gzip1.htm.gz exists. 
ok 13 - Decompress gzip1.htm.gz with Compress::Zlib. Validate gzip1.htm same as gzip0.htm. 
# Passed : 13/13 100%

=head2 Test Script Software and Operation

Running the test script 'Gzip.t' found in
the "Tie-Gzip-$VERSION.tar.gz" distribution file verifies
the requirements for this module.

All testing software and documentation
stems from the 
Software Test Description (L<STD|Docs::US_DOD::STD>)
program module 't::Tie::Gzip',
found in the distribution file 
"Tie-Gzip-$VERSION.tar.gz". 

The 't::Tie::Gzip' L<STD|Docs::US_DOD::STD> POD contains
a tracebility matix between the
requirements established above for this module, and
the test steps identified by a
'ok' number from running the 'Gzip.t'
test script.

The t::Tie::Gzip' L<STD|Docs::US_DOD::STD>
program module '__DATA__' section contains the data 
to perform the following:

=over 4

=item *

to generate the test script 'Gzip.t'

=item *

generate the tailored 
L<STD|Docs::US_DOD::STD> POD in
the 't::Tie::Gzip' module, 

=item *

generate the 'Gzip.d' demo script, 

=item *

replace the POD demonstration section
herein with the demo script
'Gzip.d' output, and

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

place the 't::Tie::Gzip' at the same
level in the directory struture as the
directory holding the 'Tie::Gzip'
module

=item *

execute the following in any directory:

 tmake -test_verbose -replace -run -pm=t::Tie::Gzip

=back

=head1 NOTES

=head2 RELATED MODULES

The package 'CPAN::Tarzip::TIEHANDLE' 
buried deep in the 'CPAN' module has
a bare bones tie to decompress gzip files.
A study of this package proved valuable in
identifying some of the pitfalls that
the author of this package encountered
in his similar endeavor. 
One issue was that 'Compress::Zlib' gzip
subroutines/methods will return 
data entact from a file that is not compress
as well as compress gzip file contents
without any signaling of the differences
in the raw file contents.

This 'Compress::Gzip' module follows the 
overall direction of 'CPAN::Tarzip::TIEHANDLE' 
in handling this issue with
a different code implementation.

Another related module is the 'PerlIO::gzip'
module that implements the gzip file disciplines.
Gzip file disciplines are available in the newer
version of Perls.
Altough the C code was not examined for this module,
there appears in the POD a somewhat different approach
to processing the file content that
is not gzip compressed. 
There is a lot of gzip header checking and whatever.

Many of the older Perls in wide spread use do
not support file disciplines.

head2 FEEDBACK

From: Mark.Scarton@FranklinCovey.com 
Date: Thu, 19 Feb 2004 17:23:37 -0700 

In the 'lib/Tie/Gzip.pm' module of the Tie-Gzip-0.01 package,
the open of the pipe ("gzip --decompress --stdout |") is
failing due to the reference to $! in the conditional.
As a test, I cleared $! before issuing the open call as follows:

Line 124:

             ###############
             # Some perls will return a glob and a warning
             # for certain pipe errors such as the command
             # not a recognized command
             #
             $! = 0;    ### MAS ###
             my $success = open PIPE, $pipe;
             if($! || !$success) {
                 warn "Could not pipe $pipe: $!\n";
                 $self->CLOSE;
                 return undef;
             }

Line 167:

             ###############
             # Some perls will return a glob and a warning
             # for certain pipe errors such as the command
             # not a recognized command
             #
             $! = 0;    ### MAS ###
             my $success = open PIPE, $pipe;
             if($! || !$success) {
                 warn "Could not pipe $pipe: $!\n";
                 $self->CLOSE;
                 return undef;
             }

This works. Prior to making this change, test 6 of Gzip.t would fail.

According to the Learning Perl O'Reilly book, 

"But if you use die to indicate an error that is not the failure of a
system request, don't include $!, since it will generally hold
an unrelated message left over from something Perl did internally.
It will hold a useful value only immediately after a failed system request.
A successful request won't leave anything useful there."

So $! is only sourced when a system error occurs and it is not cleared prior
to the call. If no error occurs, the value is indeterminate.


head2 FILES

The installation of the
"Tie-Gzip-$VERSION.tar.gz" distribution file
installs the 'Docs::Site_SVD::Tie_Gzip'
L<SVD|Docs::US_DOD::SVD> program module.

The __DATA__ data section of the 
'Docs::Site_SVD::Tie_Gzip' contains all
the necessary data to generate the POD
section of 'Docs::Site_SVD::Tie_Gzip' and
the "Tie-Gzip-$VERSION.tar.gz" distribution file.

To make use of the 
'Docs::Site_SVD::Tie_Gzip'
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
__DATA__ section of the 'Docs::Site_SVD::Tie_Gzip'
module.
For example, any changes to
'Tie::Gzip' will impact the
at least 'Changes' field.

=item *

Execute the following:

 vmake readme_html all -pm=Docs::Site_SVD::Tie_Gzip -verbose

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
In accordance with the License for 'Tie::Gzip', 
Software Diamonds
is not liable for meeting any requirement, 
binding or otherwise.

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

=head1 SEE ALSO

L<CSPAN>, L<PerlIO::gzip>, L<Test::STDmaker>, L<Docs::US_DOD::STD>,
L<ExtUtils::SVDmaker>, L<Docs::US_DOD::SVD>,
L<gzip>, L<rfc 1952|http://www.ietf.org/rfc/rfc1952.txt> (the gzip
file format specification), L<rfc 1951|http://www.ietf.org/rfc/rfc1951.txt>
(DEFLATE compressed data format specification)

=cut

### end of file ###


package Win32::Scanner::EZTWAIN;

use warnings;
use strict;
use Carp;

require 5;

require Exporter;

use vars qw( @ISA $VERSION );

our @ISA = qw(Exporter);
our @EXPORT = qw(TWAIN_BW TWAIN_GRAY TWAIN_RGB TWAIN_PALETTE TWAIN_ANYTYPE TWAIN_ACQUIRE_SUCCESS TWAIN_ACQUIRE_FAILED TWAIN_ACQUIRE_ERROPENFILE TWAIN_ACQUIRE_WEIRD TWAIN_ACQUIRE_ERRWRITEFILE);
our $VERSION = "0.01";

use Win32::API;

###########################################################################
###
### Define variables for this module
###
###########################################################################

my $twain_select_image_source;
my $twain_acquire_to_file;
my $twain_acquire_to_clipboard;
my $twain_is_available;
my $twain_easy_version;


###########################################################################
###
### Define constants for this module, functions are exported.
###
###########################################################################

sub TWAIN_BW { 1; }
sub TWAIN_GRAY { 2; }
sub TWAIN_RGB { 4; }
sub TWAIN_PALETTE { 8; }
sub TWAIN_ANYTYPE { 0; }

# Pixel types, from the well documented C header file eztwain.h
#
# 1  1-bit per pixel, B&W.
# 2  1,4, or 8-bit grayscale.
# 4  24-bit RGB color.
# 8  1,4, or 8-bit palette.
# 0  Any of the above (recommend).

sub TWAIN_ACQUIRE_SUCCESS { 0; }
sub TWAIN_ACQUIRE_FAILED { -1; }
sub TWAIN_ACQUIRE_ERROPENFILE { -2; }
sub TWAIN_ACQUIRE_WEIRD { -3; }
sub TWAIN_ACQUIRE_ERRWRITEFILE { -4; }

#  Return values, from the well documented C header file eztwain.h
#
#  0 Success.
# -1 Acquire failed OR user cancelled File Save dialog.
# -2 File open error (invalid path or name, or access denied).
# -3 (weird) Unable to lock DIB - probably an invalid handle.
# -4 Writing BMP data failed, possibly output device is full.


###########################################################################
###
### Construct our object, and import API calls.
###
###########################################################################

sub new {
 my $class = shift;
 my %parms = @_;
 my $self;
 my $path_to_dll = "";

 if(defined $parms{-dll}) { $path_to_dll = $parms{-dll}; }

 $twain_select_image_source = new Win32::API("${path_to_dll}eztw32.dll", "TWAIN_SelectImageSource", ['N'], 'N') || croak "Importing API call TWAIN_SelectImageSource failed";
 $twain_acquire_to_file = new Win32::API("${path_to_dll}eztw32.dll", "TWAIN_AcquireToFilename", ['N', 'P'], 'N') || croak "Importing API call TWAIN_AcquireToFilename failed";
 $twain_acquire_to_clipboard = new Win32::API("${path_to_dll}eztw32.dll", "TWAIN_AcquireToClipboard", ['N', 'I'], 'N') || croak "Importing API call TWAIN_AcquireToClipboard failed";
 $twain_is_available = new Win32::API("${path_to_dll}eztw32.dll", "TWAIN_IsAvailable", undef, 'N') || croak "Importing API call TWAIN_IsAvailable failed";
 $twain_easy_version = new Win32::API("${path_to_dll}eztw32.dll", "TWAIN_EasyVersion", undef, 'N') || croak "Importing API call TWAIN_EasyVersion failed";

 %{$self} = %parms;
 bless $self, $class;
 return $self;
}


###########################################################################
###
### Methods.
###
###########################################################################

# select_image_source, acquire_to_file and acquire_to_clipboard don't need
# a windows handle. TWAIN wants to defocus and disable the application
# window that called him. According to the documented source file of
# eztw32.dll you may omit the handle. If you omit the handle, eztw32.dll 
# will create an invisible proxy window. But what ever you do, don't pass 
# the handle of your console window, if you do this anyway, it can really
# screw things up.

sub select_image_source 
{ 
 my $self = shift; my $hwnd = 0;
 if(defined $self->{-hwnd}) { $hwnd = $self->{-hwnd}; }
 return $twain_select_image_source->Call($hwnd);
}

sub acquire_to_file 
{ 
 my ($self, $file) = @_; my $hwnd = 0;
 if(defined $self->{-hwnd}) { $hwnd = $self->{-hwnd}; }
 if(!defined $file) { $file = ""; }
 return $twain_acquire_to_file->Call($hwnd, $file); 
}

sub acquire_to_clipboard 
{ 
 my($self, $pixtype)  = @_; my $hwnd = 0;
 if(defined $self->{-hwnd}) { $hwnd = $self->{-hwnd}; }
 if(!defined $pixtype) { $pixtype = TWAIN_ANYTYPE; }
 return $twain_acquire_to_clipboard->Call($hwnd, $pixtype);
}

sub is_available { return $twain_is_available->Call(); }
sub easy_version { return sprintf("%.2f", ($twain_easy_version->Call() / 100)); }

1;

__END__

###########################################################################
###
### Documentation
### 
###########################################################################


=head1 NAME

Win32::Scanner::EZTWAIN - An interface to the classic EZTWAIN library

=head1 SYNOPSIS

    use Win32::Scanner::EZTWAIN;

    my $scanner = new Win32::Scanner::EZTWAIN();
    $scanner->select_image_source();
    $scanner->acquire_to_file("D:\\windows\\desktop\\test.bmp");


=head1 ABSTRACT

The EZTWAIN library has been around for a long time. With Visual C and
Visual Basic it is pretty easy to import the API calls from eztw32.dll,
and fire up the scanner user interface from your application. With this
module you can do this from a perl application.

EZTWAIN comes in two flavours: classic EZTWAIN and EZTWAIN pro. This
module was written for the first flavour, but it also seems to run fine 
with the latter. You can download classic EZTWAIN (freeware) from the 
site http://www.dosadi.com/. Place eztw32.dll in your windows system 
directory or just place it in the directory where your perl application 
is located.

=head1 DESCRIPTION

=head2 Constructor

=over 4

=item new Win32::Scanner::EZTWAIN(-dll => $path_to_dll, -hwnd => $window_handle)

Constructor for a new object. The options -dll and -hwnd are optional.
If your dll is not in a standard place you can use this option to tell 
where eztw32.dll is located, use a trailing slash.

The second option, -hwnd, is used to pass your window handle of your
application. TWAIN seems to want to disable the window that called him.
If you don't build windows gui applications, and your application is a
plain console application, don't pass anything. When nothing is passed
eztw32.dll will create a dummy window, and will pass that handle to
TWAIN.

=back

=head2 Methods

=over 4

=item select_image_source()

This method allows the user to select the appropriate device. Returns 1
if a device was selected. Returns 0 if no device was selected, i.e. the
operation was cancelled by the user.

=item acquire_to_file($file)

This method starts the scanner user interface and stores the scanned image 
in the given filename. Classic EZTWAIN only support windows bitmaps, so 
make sure the given filename has a .bmp extension. If you omit a filename 
the standard windows file save dialog pops up, which allows the user to 
save the image manually.

Return values:

=over 4

=item TWAIN_ACQUIRE_SUCCESS

If the operation was a success.

=item TWAIN_ACQUIRE_FAILED

Acquire failed or the user cancelled the file save dialog box.

=item TWAIN_ACQUIRE_ERROPENFILE

There was an error opening the specified file.

=item TWAIN_ACQUIRE_WEIRD

Unable to lock DIB, probably an invalid handle (weird).

=item TWAIN_ACQUIRE_ERRWRITEFILE

Writing bitmap to file failed, device full?

=back

=item acquire_to_clipboard($pix_type)

This method starts the scanner user interface and pastes the scanned image
as a bitmap to the windows clipboard. You can force the user interface to
scan the image in a specified pixel type.

Possible pixel types:

=over 4

=item TWAIN_BW

Black and white bitmap, 1-bit per pixel.

=item TWAIN_GRAY

Grayscale bitmap, 1, 4, or 8-bit.

=item TWAIN_RGB

True color bitmap - 24-bit RGB color.

=item TWAIN_PALETTE

Color bitmap, 1, 4, or 8-bit palette.

=item TWAIN_ANYTYPE

Any of the above, whatever pixel type is available for the specific device.

=back

Only use pixel types that are supported by your scanner device, this implies 
that you know what your scanner is capable of. Use TWAIN_ANYTYPE if you 
are not sure. If you omit the pixel type argument, TWAIN_ANYTYPE is passed.
You can combine different pixel types with OR, like this C<&TWAIN_BG | &TWAIN_GRAY>.

=item is_available()

This method returns 1 if TWAIN services are available, 0 if no TWAIN 
services are available.

=item easy_version()

This method returns the version of the used EZTWAIN library.

=back

=head1 EXPORT

This module exports the following constants:

=over 4

=item TWAIN_BW

=item TWAIN_GRAY

=item TWAIN_RGB

=item TWAIN_PALETTE

=item TWAIN_ANYTYPE

=item TWAIN_ACQUIRE_SUCCESS

=item TWAIN_ACQUIRE_FAILED

=item TWAIN_ACQUIRE_ERROPENFILE

=item TWAIN_ACQUIRE_WEIRD

=item TWAIN_ACQUIRE_ERRWRITEFILE

=back

=head1 INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

=head1 REQUIRED MODULES

C<Win32::API>

=head1 BUGS AND QUIRKS

I noticed that this module doesn't work flawlessly with all scanners, I had
no problems, with my AGFA StudioStar SCSII scanner. On the other hand, the
TWAIN service of my Pinnacle Sys TV card caused some problems. Don't say
I didn't warn you.

=head1 SEE ALSO

C<Win32::Clipboard>, get the scanned image from the clipboard.

=head1 AUTHOR

Lennert Ouwerkerk <lennert@kabelfoon.nl>

=head1 COPYRIGHT

Copyright (C) 2002 Lennert Ouwerkerk. All rights reserved.

=head1 LICENSE

This package is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

=cut
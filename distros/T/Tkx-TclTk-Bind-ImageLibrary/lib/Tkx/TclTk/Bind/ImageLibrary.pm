# ##############################################################################
# # Script     : Tkx::TclTk::Bind::ImageLibrary.pm                             #
# # -------------------------------------------------------------------------- #
# # Copyright  : Frei unter GNU General Public License  bzw.  Artistic License #
# # Authors    : JVBSOFT - Jürgen von Brietzke                   0.001 - 1.400 #
# # Version    : 1.400                                             14.Feb.2016 #
# # -------------------------------------------------------------------------- #
# # Function   : Bindet die TclTk 'Img1.4.0.4' Bibliothek an Perl::Tkx         #
# # -------------------------------------------------------------------------- #
# # Language   : PERL 5                                (V) 5.12.xx  -  5.22.xx #
# # Coding     : ISO 8859-15 / Latin-9                         UNIX-Zeilenende #
# # Standards  : Perl-Best-Practices                       severity 1 (brutal) #
# # -------------------------------------------------------------------------- #
# # Module     : Enc::C                                 ActivePerl-REPO-Module #
# #              Modern::PBP::Perl                                             #
# #              Tkx::TclTk::Bind                                              #
# ##############################################################################

package Tkx::TclTk::Bind::ImageLibrary 1.400;

# ##############################################################################

use Modern::PBP::Perl qw{5.12};
use Tkx::TclTk::Bind qw{ &load_library };

# ##############################################################################

sub BEGIN {

   my $path_to_image_library;

   my $temp_dir = load_library( 'image', 'Img1.4.0.4' );

   # --- Steuervariablen belegen -----------------------------------------------
   $path_to_image_library = File::Spec->catfile( $temp_dir, 'Img1.4.0.4' );

   # --- Image-Library in Tkx binden -------------------------------------------
   Tkx::lappend( '::auto_path', $path_to_image_library );
   Tkx::package_require('img::bmp');
   Tkx::package_require('img::gif');
   Tkx::package_require('img::ico');
   Tkx::package_require('img::jpeg');
   Tkx::package_require('img::pcx');
   Tkx::package_require('img::pixmap');
   Tkx::package_require('img::png');
   Tkx::package_require('img::ppm');
   Tkx::package_require('img::tiff');
   Tkx::package_require('img::window');
   Tkx::package_require('img::xbm');
   Tkx::package_require('img::xpm');

} # end of sub BEGIN

# ##############################################################################
# #                                   E N D                                    #
# ##############################################################################
1;
__END__

=pod

=head1 NAME

Tkx::TclTk::Bind::ImageLibrary - Adds additional graphic formats to Tkx.


=head1 VERSION

This document describes Perl::Modern::Perl version 1.400.


=head1 SYNOPSIS

   use Tkx::TclTk::Bind::ImageLibrary;
   ...
   $mw = Tkx::widget->new(q{.});
   $mw->Tkx::wm_title('Test');
   ...
   Tkx::image_create_photo( 'image', -file => $file_path_name );
   my $label = $mw->new_label( -compound => "left",
      -image => 'image_gif',
      -text => "Label",
   );
   ...
   Tkx::grid( $label, -column => 0, -row => 0 );
   ...
   Tkx::MainLoop();


=head1 DESCRIPTION

This modul load the Img4.0.4-library in the 'User-TEMP-Directory' and
binding the library on Tkx. The modul ship the iwidget library as TAR-Ball
for the OS-System MSWin32, Linux (32 and 64-bit) and Mac OS X.

The following libraries are provided:

   - bmp    : Windows bitmap format
   - gif    : The venerable graphics interchange format
   - ico    : Windows icon files
   - jpeg   : Joint Picture Experts Group
   - pcx    : Paintbrush image format
   - pixmap : While the other formats are handlers for the Tk photo image type
   - png    : Portable Network Graphics
   - ppm    : Portable Pixmaps
   - tiff   : Tagged Interchange File Format
   - xbm    : X Bitmaps
   - xpm    : X Pixmaps

This modul provide support for 'ActiveState PerlApp'. You can import library as
TAR-Ball from directory '.../lib/Tkx/TclTk/Bind/TAR/...' over 'Bound files' in
PerlApp.

When program will ending, the modul delete all files from 'User-TEMP'-Directory.


=head1 DIAGNOSTICS

none


=head1 INTERFACE

none


=head1 CONFIGURATION AND ENVIRONMENT

none


=head1 DEPENDENCIES

The following pragmas and modules are required:

=head2  CPAN or ActiveState Repository

   - Modern::PBP::Perl
   - Tkx::TclTk::Bind


=head1 INCOMPATIBILITIES

The module works with PERL 5:12 or higher under MS Win, Linux and Max OS.


=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-perl-modern-moose@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Juergen von Brietzke  C<< <juergen.von.brietzke@t-online.de> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015,
Juergen von Brietzke C<< <juergen.von.brietzke@t-online.de> >>.
All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

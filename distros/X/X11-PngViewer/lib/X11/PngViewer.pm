package X11::PngViewer;

use strict;
use warnings;

use base qw(DynaLoader);

our $VERSION = '0.09';

bootstrap X11::PngViewer $VERSION;

1;

__END__

=head1 NAME

X11::PngViewer - Png Viewer in X11

=head1 VERSION
 
Version 0.09
 
=head1 SYNOPSIS
 
    use X11::PngViewer();
 
    my $viewer = X11::PngViewer->new();
    my $directory = File::HomeDir->my_pictures();
    my $handle = DirHandle->new($directory) or die "No slideshow from $directory:$!";
    while(my $entry = $handle->read()) {
	if ($entry =~ /[.]png/smx) {
	    $viewer->show(File::Slurper::read_binary(File::Spec->catfile($directory, $entry)));
	    sleep 1;
	}
    }
    
=head1 DESCRIPTION
 
This is a simple PNG image viewer for X11, intended for slideshows, etc.
 
=head1 SUBROUTINES/METHODS
 
=head2 new
  
This method creates a new X11 window at the maximum possible size, and if possible, full screens the new X11 window as well
 
=head2 show
  
This method accepts the contents of a PNG file, clears the X11 window and displays the image in the center of the X11 window
 
=head1 DIAGNOSTICS
 
=over
  
=item C<< Cannot connect to X server >>
 
The module was unable to connect to a X11 server.  Check the contents of the DISPLAY environment variable. 
 
=back
 
=head1 CONFIGURATION AND ENVIRONMENT
 
X11::PngViewer will use the DISPLAY variable to try to connect to an X Server.
 
=head1 DEPENDENCIES
 
X11::PngViewer requires no non-core Perl modules
  
=head1 INCOMPATIBILITIES
 
None reported.
 
=head1 BUGS AND LIMITATIONS
 
No bugs have been reported.
 
Please report any bugs or feature requests to
C<bug-x11-pngviewer@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.
 
=head1 SEE ALSO
 
=over
  
=item * X11::Xlib
 
=item * Image::PNG::Libpng
 
=item * Time::Slideshow
 
=back
 
=head1 AUTHOR
 
David Dick  C<< <ddick@cpan.org> >>
 
=head1 ACKNOWLEDGEMENTS
  
Thanks to the authors of the documentation in the following sources;
 
=over 4
 
=item * L<Perl and XS|https://www.lemoda.net/xs/xs-intro/set-bit.html>
 
=item * L<Xlib Manual|https://tronche.com/gui/x/xlib/>
 
=item * L<PNG - The Definite Guide|http://www.libpng.org/pub/png/book/toc.html>
 
=back
 
=head1 LICENSE AND COPYRIGHT
 
Copyright (c) 2018, David Dick C<< <ddick@cpan.org> >>. All rights reserved.
 
This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic/perlartistic>.
 
 
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

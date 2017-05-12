package Win32::Screenshot;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = (

'api' => [ qw(
  WindowFromPoint
  GetForegroundWindow
  GetDesktopWindow
  GetActiveWindow
  GetWindow
  FindWindow
  ShowWindow
  GetCursorPos
  SetCursorPos
  GetClientRect
  GetWindowRect
  BringWindowToTop
  GetWindowText
  IsVisible
  GetTopWindow
  Minimize
  Restore
  ScrollWindow
) ],

'gw_const' => [ qw (
  GW_CHILD
  GW_HWNDFIRST
  GW_HWNDLAST
  GW_HWNDNEXT
  GW_HWNDPREV
  GW_OWNER
) ],

'sw_const' => [ qw (
  SW_HIDE
  SW_MAXIMIZE
  SW_MINIMIZE
  SW_RESTORE
  SW_SHOW
  SW_SHOWDEFAULT
  SW_SHOWMAXIMIZED
  SW_SHOWMINIMIZED
  SW_SHOWMINNOACTIVE
  SW_SHOWNA
  SW_SHOWNOACTIVATE
  SW_SHOWNORMAL
) ],

'raw' => [ qw (
  JoinRawData
  CaptureHwndRect
  CreateImage
  PostProcessImage
  @POST_PROCESS
) ],

'default' => [ qw (
  CaptureWindowRect
  CaptureWindow
  CaptureRect
  CaptureScreen
  ListChilds
  ListWindows
) ],

'pp' => [ qw (
  ppResize
  ppOuterGlow
) ],

);

$EXPORT_TAGS{all} = [ map {@$_} values %EXPORT_TAGS ];

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = @{ $EXPORT_TAGS{'default'} };

our $VERSION = '1.20';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Win32::Screenshot::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	*$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Win32::Screenshot', $VERSION);

use Image::Magick;

our @POST_PROCESS;

sub ppResize {
  my $ratio = shift || 0.74;
  my ($w, $h) = $_->Get('width', 'height');
  $w = sprintf "%.0f", $w*$ratio;
  $h = sprintf "%.0f", $h*$ratio;
  $_->Resize(width=>$w,height=>$h,blur=>0.9,filter=>'Sinc');
}

sub ppOuterGlow {
  my ($outer, $inner, $width) = @_;

  $inner ||= sprintf('#%02x%02x%02x', map {$_>>8} split (/,/, $_->Get('pixel[0,0]')));
  $outer ||= 'white';
  $width ||= 17;
  my $top = sprintf "%.0f", $width/3.4;

  # prepare background
  my ($w, $h) = $_->Get('width', 'height');
  my $g = Image::Magick->new;
  $g->Set(size=>($w+$width).'x'.($h+$width));
  $g->ReadImage('xc:'.$outer);
  $g->Draw(
    stroke=>$inner,
    fill=>$inner,
    primitive=>'rectangle',
    points=> join(',',$top, $top, $w+$width-$top, $h+$width-$top),
  );
  $g->Blur(radius=>sprintf("%.0f", $width/2.8333), sigma=>3);

  # compose
  $g->Composite( image=>$_, 'x'=>sprintf("%.0f", $width/1.8888), 'y'=>sprintf("%.0f", $width/1.8888) );

  return $g;
}


sub ListWindows () {
  ListChilds(GetDesktopWindow());
}

sub ListChilds ($) {
  my $parent = shift;
  my $hwnd = GetWindow($parent, GW_CHILD());
  my @list;

  while($hwnd) {
    my %win = (
      hwnd => $hwnd,
      title => GetWindowText($hwnd),
      rect  => [ GetWindowRect($hwnd) ],
      visible => IsVisible($hwnd),
    );
    push @list, \%win;
    $hwnd = GetWindow($hwnd, GW_HWNDNEXT());
  }

  return @list;
}

sub _getHwnd ($) {
  my $id = shift;
  if ( $id !~ /^\d+$/ ) {
    $id = FindWindow(undef, $id);
  }
  return $id;
}

sub _capture {
  CreateImage( CaptureHwndRect(@_) );
}

sub CreateImage {
  my $image=Image::Magick->new();
  $image->Set(magick=>'rgba');
  $image->Set(size=>"$_[0]x$_[1]");
  $image->Set(depth=>8);
  $image->BlobToImage($_[2]);

  return PostProcessImage($image);
}

sub PostProcessImage {
  my $image = shift;
  my $out;
  for my $hnd ( @POST_PROCESS ) {
    $_ = $image;
    if ( ref $hnd eq 'CODE' ) {
      $out = &$hnd( $image );
    } else {
      $out = eval $hnd;
    }
    if ( ref $out eq ref $image && $out != $image ) {
      $image = $out;
    }
  }
  return $image;
}

sub CaptureWindowRect ($$$$$) {
  _capture(_getHwnd(shift), @_);
}

sub CaptureWindow ($) {
  my $id = _getHwnd(shift);
  my @rect = GetWindowRect($id);
  _capture(GetDesktopWindow(), $rect[0], $rect[1], $rect[2]-$rect[0], $rect[3]-$rect[1] );
}

sub CaptureScreen () {
  my $id = GetDesktopWindow();
  _capture($id, GetWindowRect($id));
}

sub CaptureRect ($$$$) {
  my $id = GetDesktopWindow();
  _capture($id, @_);
}

1;

__END__

=head1 NAME

Win32::Screenshot - Capture and process the screen, window or rectangle

=head1 SYNOPSIS

  use Win32::Screenshot;

  $image = CaptureRect( $x, $y, $width, $height );
  $image->Write('screenshot.png');

=head1 DESCRIPTION

The package utilizes some Win32 API function and L<Image::Magick|Image::Magick>
to let you capture the screen, a window or a part of it. The
C<Capture*(...)> functions returns a new L<Image::Magick|Image::Magick> object which
you can easily use to modify the screenshot or to store it in the
file. You can define your own post processing handlers and chain them in
the list.

There are Perl equivalents of Win32 API functions for working with
windows implemented in the package. These functions will allow easy
identification of windows on the screen.

=head2 Image post-processing

The handler receives a reference to an Image::Magick object. If the
handler returns such reference it will be used instead of the input
one for further processing. It means that the handler can return
completely different image.

The handlers are organized in a list @POST_PROCESS. The item of the
list can be a string passed to C<eval> or a code reference. The image
will be passed to the handler as C<$_> for evals or C<$_[0]> for subs.

If you want to modify the list just use push or direct access.

  @POST_PROCESS = (
    'ppResize(0.5)',
    sub { $_[0]->Blur(); }
  );

Handlers are executed starting with $POST_PROCESS[0]. The
function C<CreateImage> calls C<PostProcessImage> function
which manages the post-processing list. This function
is called from all C<Capture*(...)> functions, you don't
have to call it explicitly.

See chapter L<Post-processing handlers> for details on build-in handlers.

=head1 EXPORT

=over 8

=item :default

C<CaptureRect>
C<CaptureScreen>
C<CaptureWindow>
C<CaptureWindowRect>
C<ListChilds>
C<ListWindows>
C<@POST_PROCESS>

=item :raw

C<CaptureHwndRect>
C<CreateImage>
C<JoinRawData>
C<PostProcessImage>

=item :pp

C<ppResize>
C<ppOuterGlow>

=item :api

C<BringWindowToTop>
C<FindWindow>
C<GetActiveWindow>
C<GetClientRect>
C<GetCursorPos>
C<GetDesktopWindow>
C<GetForegroundWindow>
C<GetTopWindow>
C<GetWindow>
C<GetWindowRect>
C<GetWindowText>
C<IsVisible>
C<Minimize>
C<Restore>
C<ScrollWindow>
C<ShowWindow>
C<WindowFromPoint>

=item :gw_const

GW_CHILD
GW_HWNDFIRST
GW_HWNDLAST
GW_HWNDNEXT
GW_HWNDPREV
GW_OWNER

=item :sw_const

SW_HIDE
SW_MAXIMIZE
SW_MINIMIZE
SW_RESTORE
SW_SHOW
SW_SHOWDEFAULT
SW_SHOWMAXIMIZED
SW_SHOWMINIMIZED
SW_SHOWMINNOACTIVE
SW_SHOWNA
SW_SHOWNOACTIVATE
SW_SHOWNORMAL

=back

=head2 Screen capture functions

All these functions return a new L<Image::Magick|Image::Magick> object
on success or undef on failure. These function are exported by default.

=over 8

=item CaptureRect( $x, $y, $width, $height )

Captures part of the screen. The [0, 0] coordinate is the upper-left
corner of the screen. The [$x, $y] defines the the upper-left corner
of the rectangle to be captured.

=item CaptureScreen( )

Captures whole screen including the taskbar.

=item CaptureWindow( $hwnd | $title )

Captures whole window including title and border. Pass the window
handle or the window title as the function parameter. If the parameter
is a number it will be used directly as a handle to identify the
window, if it's something different a FindWindow( ) function will
be utilized to find the handle.

=item CaptureWindowRect( $hwnd | $title, $x, $y, $width, $height )

Captures a part of the window. Pass the window handle or the window
title as the function parameter. If the parameter is a number it will
be used directly as a handle to identify the window, if it's something
different a FindWindow( ) function will be utilized to find the handle.
The [0, 0] coordinate is the upper-left corner of the window. The [$x,
$y] defines the the upper-left corner of the rectangle to be captured.

=back

=head2 Capturing helper functions

Functions for working with raw bitmap data. These functions are not
exported by default, import them with C<:raw> tag.

=over 8

=item CaptureHwndRect( $hwnd, $x, $y, $width, $height )

The function captures the part of the screen and returns
a list of ($width, $height, $screendata). Where $width and
$height are the dimensions of the bitmap in pixels and
$screendata is a buffer filled with RGBA (4-bytes) data
representing the bitmap (Alpha is always 0xFF).

=item JoinRawData( $width1, $width2, $height, $raw1, $raw2 )

The function joins two bitmaps of the same height and return
the new bitmap data.

=item CreateImage( $width, $height, $rawdata )

Creates a new Image::Magick object from provided data and
calls all listed post-processing handlers. The function
returns the processed object.

=item PostProcessImage( $image )

Calls all listed post-processing handlers. The function
returns the processed object.

=back

=head2 Post-processing handlers

See L<Image::Magick> for other image processing functions. Typically
you can use methods like C<Label>, C<Quantize> and C<Set> to post-process
all captured images and then simply C<Write> the image to the file.

  push @POST_PROCESS, sub {
    $_[0]->Quantize( colors=>80, dither=>0 );
    $_[0]->Set('quality', 100);
  };

=over 8

=item ppResize( $ratio )

Resizes the image by the specified ratio. It uses Lanczos
filter and default ratio 0.74.

=item ppOuterGlow( $outercolor, $innercolor, $size )

Draws a glow around the screenshot. If any parameter is undef a default value is used.
By default outercolor is white, the innercolor is a color of pixel on position [0, 0]
and the glow is 17 pixels wide.

=back

=head2 Windows helper functions

These function enumerates all windows and returns a LoH with windows properties.

	for ( ListWindows( ) ) {
	  printf "%1s %8d x:%-4d y:%-4d w:%-4d h:%-4d %s\n",
	    $_->{visible} ? '#' : '-',
	    $_->{hwnd},
	    @{$_->{rect}},
	    $_->{title}
	  ;

	  for (ListChilds($_->{hwnd})) {
	    printf "    %1s %8d x:%-4d y:%-4d w:%-4d h:%-4d %s\n",
	      $_->{visible} ? '#' : '-',
	      $_->{hwnd},
	      @{$_->{rect}},
	      $_->{title}
	    ;
	  }
	}

These functions are exported by default.

=over 8

=item ListWindows( )

Lists all top windows on the desktop.

=item ListChilds( $hwnd )

Lists all child windows of the parent top window.

=back

=head2 Win32 API functions

Look into Win32 API documentation for more details.
These function are not exported by default, import them with C<:api> tag.

=over 8

=item WindowFromPoint( $x, $y )

The function retrieves a handle to the window that contains the
specified point.

=item GetForegroundWindow( )

The function returns a handle to the foreground window (the window
with which the user is currently working).

=item GetDesktopWindow( )

The GetDesktopWindow function returns a handle to the desktop window.
The desktop window covers the entire screen. The desktop window is the
area on top of which all icons and other windows are painted.

=item GetActiveWindow( )

The function retrieves the window handle to the active window attached
to the calling thread's message queue.

=item GetWindow( $hwnd, GW_* constant )

The GetWindow function retrieves a handle to a window that has the
specified relationship (Z-Order or owner) to the specified window

=item FindWindow( $class, $title )

The FindWindow function retrieves a handle to the top-level window
whose class name and window name match the specified strings. This
function does not search child windows. This function does not perform
a case-sensitive search.

=item ShowWindow( $hwnd, SW_* constant )

The function sets the specified window's show state.

=item GetCursorPos( )

The function retrieves the cursor's position, in screen coordinates.

=item SetCursorPos( $x, $y )

The function moves the cursor to the specified screen coordinates.

=item GetClientRect( $hwnd )

The function retrieves the coordinates of a window's client area. The
client coordinates specify the upper-left and lower-right corners
of the client area. Because client coordinates are relative to the
upper-left corner of a window's client area, the coordinates of the
upper-left corner are (0,0).

=item GetWindowRect( $hwnd )

The function retrieves the dimensions of the bounding rectangle of the
specified window. The dimensions are given in screen coordinates that
are relative to the upper-left corner of the screen.

=item BringWindowToTop( $hwnd )

The function brings the specified window to the top of the Z order.
If the window is a top-level window, it is activated. If the window
is a child window, the top-level parent window associated with the
child window is activated.

=item GetWindowText( $hwnd )

The function copies the text of the specified window's title bar (if
it has one) into a buffer. If the specified window is a control, the
text of the control is copied. However, GetWindowText cannot retrieve
the text of a control in another application.

=item IsVisible( $hwnd )

The function retrieves the visibility state of the specified window.
Calls IsWindowVisible API function.

=item GetTopWindow( )

The function examines the Z order of the child windows
associated with the specified parent window and retrieves a handle
to the child window at the top of the Z order.

=item Restore( )

The function restores a minimized (iconic) window to its previous size
and position; it then activates the window. Calls OpenIcon API
function.

=item Minimize( )

The function minimizes (but does not destroy) the specified window.
Calls CloseWindow API function.

=item ScrollWindow( $hwnd, $dx, $dy )

The function scrolls the contents of the specified window's client
area. Calls ScrollWindowEx API function.

=back

=head1 SEE ALSO

=over 8

=item Win32::GUI

It was a good inspiration for me. I borrowed some code from the module.

=item Image::Magick

The raw data from the screen are loaded into Image::Magick object. You
have a lot of possibilities what to do with the captured image.

=item MSDN

http://msdn.microsoft.com/library

=item L<Win32::CaptureIE|Win32::CaptureIE>

Package that utilizes Win32::Screenshot to capture web pages or its
parts rendered by Internet Explorer.

=back

=head1 AUTHOR

P.Smejkal, E<lt>petr.smejkal@seznam.czE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by P.Smejkal

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

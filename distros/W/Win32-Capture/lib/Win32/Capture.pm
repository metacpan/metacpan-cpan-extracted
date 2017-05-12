package Win32::Capture;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(CaptureScreen CaptureRect CaptureWindow CaptureWindowRect IsWindowVisible FindWindowLike SearchWindowText GetWindowText GetWindowRect GetClassName);

use Win32::API;
use Win32::GUI::DIBitmap;

$VERSION = '1.6';

BEGIN {
    $GetDC                 = new Win32::API('user32', 'GetDC', ['N'], 'N');
    $GetTopWindow          = new Win32::API('user32', 'GetTopWindow', ['N'], 'N');
    $FindWindow            = new Win32::API('user32', 'FindWindow', ['P', 'P'], 'N');
    $GetWindow             = new Win32::API('user32', 'GetWindow', ['N', 'N'], 'N');
    $GetDesktopWindow      = new Win32::API('user32', 'GetDesktopWindow', [], 'N');
    $GetClassName          = new Win32::API('user32', 'GetClassName', ['N', 'P', 'N'], 'N');
    $GetWindowText         = new Win32::API('user32', 'GetWindowText', ['N', 'P', 'N'], 'N');
    $GetWindowRect         = new Win32::API('user32', 'GetWindowRect', ['N', 'P'], 'N');
    $SetForegroundWindow   = new Win32::API('user32', 'SetForegroundWindow', ['N'], 'N');
    $IsWindowVisible       = new Win32::API('user32', 'IsWindowVisible', ['N'], 'N');
}

sub IsWindowVisible {
    return $IsWindowVisible->Call($_[0]);
}

sub CaptureScreen() {
    my $dc  = $GetDC->Call(0);
    my $dib = newFromDC Win32::GUI::DIBitmap($dc) or return undef;
    return $dib;
}

sub CaptureRect($$$$) {
    my $dc  = $GetDC->Call(0);
    my $dib = newFromDC Win32::GUI::DIBitmap($dc, $_[0], $_[1], $_[2], $_[3]) or return undef;
    return $dib;
}

sub CaptureWindow($$$) {
    my $win = $_[0];
    $SetForegroundWindow->Call($win);
    sleep $_[1];
    my $dib = newFromWindow Win32::GUI::DIBitmap($win, $_[2]) or return undef;
    return $dib;
}

sub CaptureWindowRect($$$$$$) {
    my $win = $_[0];
    $SetForegroundWindow->Call($win);
    sleep $_[1];
    my $dc  = $GetDC->Call($win);
    my $dib = newFromDC Win32::GUI::DIBitmap($dc, $_[2], $_[3], $_[4], $_[5]) or return undef;
    return $dib;
}


sub FindWindowLike {
    my $pattern = shift;
    my @array=();
    my $parent = $GetDesktopWindow->Call();
    my $hwnd = $GetWindow->Call($parent, 5);

    while($hwnd) {
        my $windowname = SearchWindowText($hwnd, $pattern);
        if ($windowname ne '') {
            push(@array, $hwnd);
        }
        $hwnd = $GetWindow->Call($hwnd, 2);
    }

    return @array;
}

sub SearchWindowText {
    my $hwnd = shift;
    my $pattern = shift;
    my $title = " " x 1024;
    my $titleLen = 1024;
    my $result = $GetWindowText->Call($hwnd, $title, $titleLen);
    $title=~s/\s+$//;
    if ($title=~/\Q$pattern\E/i) {
        return $title;
    } else {
        return '';
    }
}

sub GetWindowText {
    my $hwnd = shift;
    my $title = " " x 1024;
    my $titlelen = 1024;
    my $result = $GetWindowText->Call($hwnd, $title, $titlelen);
    $title=~s/\s+$//;
    return $title;
}

sub GetWindowRect {
    my $hwnd = shift;
    my $RECT = pack("iiii", 0, 0);
    $GetWindowRect->Call($hwnd, $RECT);
    return wantarray ? unpack("iiii", $RECT) : $RECT;
}

sub GetClassName {
    my $hwnd = shift;
    my $name = " " x 1024;
    my $namelen = 1024;
    my $result = $GetClassName->Call($hwnd, $name, $namelen);
    $name=~s/\s+$//;
    return $name;
}

1;

__END__

=head1 NAME

Win32::Capture - Capture screen and manipulate it with Win32::GUI::DIBitmap instance.

=head1 SYNOPSIS

  use Win32::Capture;

  $image = CaptureScreen(); # Capture whole screen.
  $image->SaveToFile('screenshot.png');

  # or

  $image = CaptureRect($x, $y, $width, $height); # Capture a portion of window.
  $image->SaveToFile('screenshot.png');

  # or

  @hwnds = FindWindowLike('CPAN');  # Invoke helper function to get HWND array.

  if ($#hwnds<0) {
       print "Not found";
  } else {
        foreach (@hwnds) {
            my $image = CaptureWindowRect($_, 2, 0, 0, 400, 300);
            $image->SaveToFile("$_.jpg", JPEG_QUALITYSUPERB);
        }
  }

=head1 DESCRIPTION

The purposes of package are similar to L<Win32::Screenshot|Win32::Screenshot>.
But you can manipulate screen shot image with L<Win32::GUI::DIBitmap|Win32::GUI::DIBitmap> instance.

=head2 Screen capture functions

All of these functions are returning a new L<Win32::GUI::DIBitmap|Win32::GUI::DIBitmap> instance
on success or undef (a.k.a undefined variables) on failure. All functions are exported by default.

=over 8

=item CaptureRect($x, $y, $width, $height)

Capture a portion of the screen. The [0, 0] coordinate is on the upper-left
corner of the screen. The [$x, $y] defines the the upper-left corner
of the rectangle to be captured.

=item CaptureScreen()

Capture whole screen include taskbar.

=item CaptureWindow($hWND, $dur, $flag)

Capture whole window include title bar and window border, or client window region only.

Set $dur to wait for a while before capturing.

TIPS: Invoke FindWindowLike($text) helper function to find $hWND value.

  $flag = 0 : Entire window will be captured (with border)
  $flag = 1 : Only client window region will be captured.

=item CaptureWindowRect($hWND, $dur, $x, $y, $width, $height)

Capture a portion of the window.

TIPS: Invoke FindWindowLike($text) helper function to find $hWND value.

=back

=head2 Capturing helper function

=over 8

=item FindWindowLike($text)

  @hwnds = FindWindowLike('CPAN');

  if ($#hwnds<0) {
       print "Not found";
  } else {
        foreach (@hwnds) {
            my $image = CaptureWindowRect($_, 2, 0, 0, 400, 300);
            $image->SaveToFile("$_.jpg", JPEG_QUALITYSUPERB);
        }
  }

The $text argument stands for a part of window title. FindWindowLike will return an array holds HWND elements.

=back

=head1 SEE ALSO

=over 8

=item Win32::Screenshot

Some documentation refer from here.

=item Win32::GUI::DIBitmap

The raw data from the screen will be loaded into Win32::GUI::DIBitmap instance.

See Win32::GUI::DIBitmap for more details.

=item MSDN

http://msdn.microsoft.com/library

=back

=head1 AUTHOR

Lilo Huang

=head1 COPYRIGHT AND LICENSE

Copyright 2014 by Lilo Huang All Rights Reserved.

You can use this module under the same terms as Perl itself.

=cut
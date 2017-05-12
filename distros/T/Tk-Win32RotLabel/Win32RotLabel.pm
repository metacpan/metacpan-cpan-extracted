package Tk::Win32RotLabel;

our $VERSION = 0.4;

use Tk;
use Tk::widgets qw/Label/;
use base qw/Tk::Derived Tk::Label/;
use Win32::API;

use strict;
use Carp;

our (
     $CreateFont,
     $SelectObject,
     $DeleteObject,
     $GetDC,
     $ReleaseDC,
     $ExtTextOut,
     $GetTextExtent,
     $SetBkColor,
     $SetTextColor,

     %configured,
    );

Construct Tk::Widget 'Win32RotLabel';

# load the proper Win32::API suroutines at init.
sub ClassInit {
  my ($class, $mw) = @_;

  $class->SUPER::ClassInit($mw);

  $CreateFont    = new Win32::API('gdi32' , 'CreateFont',   [('N') x 13,
							     'P'], 'N');
  $SelectObject  = new Win32::API('gdi32' , 'SelectObject', [qw/N N/], 'N');
  $DeleteObject  = new Win32::API('gdi32' , 'DeleteObject', ['P'], 'I');
  $GetDC         = new Win32::API('user32', 'GetDC',        ['N'], 'N');
  $ReleaseDC     = new Win32::API('user32', 'ReleaseDC',    [qw/N N/], 'I');
  $ExtTextOut    = new Win32::API('gdi32' , 'ExtTextOut',   [qw/N I I N P P
							     I P/], 'I');
  $GetTextExtent = new Win32::API('user32', 'GetTabbedTextExtent', [qw/N P N
								    N P/], 'I');
  $SetBkColor    = new Win32::API('gdi32', 'SetBkColor', [qw/N N/], 'N');
  $SetTextColor  = new Win32::API('gdi32', 'SetTextColor', [qw/N N/], 'N');
}

sub Populate {
  my ($w, $args) = @_;

  # clean up any images the user adds .. that's not the point.
  delete $args->{-image};
  $args->{-bitmap} = 'transparent';

  $w->SUPER::Populate($args);

  $w->ConfigSpecs(
    -angle        => [qw/METHOD angle Angle/, 0],
    -text         => [qw/METHOD text Text/, ''],
    -textvariable => [qw/METHOD textvariabel Textvariable/, undef],
    -font         => [qw/PASSIVE font Font/, ['Times New Roman']],
   );

  my $top = $w->toplevel;
  unless ($configured{$top}) {
    $top->bind('<Configure>'  => [\&_updateDescendants, $top]);
    $configured{$top} = 1;
  }
}

sub angle {
  my ($w, $a) = @_;

  if (defined $a) {
    # should check if it's numeric .. TBD
    $a = 0   if $a < 0;
    $a = 360 if $a > 360;

    $w->{ANGLE} = $a;
  }
  $w->{ANGLE};
}
sub text {
  my ($w, $t) = @_;

  if (defined $t) {
    $w->{TEXT} = $t;
  }
  $w->{TEXT};
}

sub textvariable {
  my ($w, $tv) = @_;

  if (defined $tv) {
    $w->{TEXTV} = $tv;
  }
  $w->{TEXTV};
}

sub configure {
  my $w = shift;
  $w->SUPER::configure(@_);

  # update label if there is anything worthy.
  my %a = @_;
  $w->_updateMe if $a{-text} || $a{-textvariable} || $a{-font} || $a{-angle};
}

# called by the top level.
# simply called _updateMe for every descendant Win32RotLabel widget.
sub _updateDescendants {
  my $m = shift;

  ref $_ eq 'Tk::Win32RotLabel' && $_->_updateMe for $m->children;
}

# this method draws the text.
sub _updateMe {
  my $w = shift;
  return unless $w->toplevel->ismapped;

  # first off, get the background and foreground colors
  # in rgb syntax.
  my $depth = $w->screendepth;
  my @vis   = $w->visualsavailable;
  my $bg    = $w->cget('-bg');
  my $fg    = $w->cget('-fg') || 'black';
  my @bgRGB = $w->rgb($bg);
  my @fgRGB = $w->rgb($fg);

  $_ = int(255 * $_ / 65535) for @bgRGB, @fgRGB;

  # Tk    uses #RGB
  # Win32 uses #BGR ... don't ask me why.
  my $wbg   = sprintf "0x%02X%02X%02X" => reverse @bgRGB;
  my $wfg   = sprintf "0x%02X%02X%02X" => reverse @fgRGB;

  # get the angle.
  my $angle = $w->{ANGLE};

  # get the font object.
  my $fontO  = $w->cget('-font');
  my $family = $w->fontActual($fontO, '-family');
  my $size   = $w->fontActual($fontO, '-size');
  my $weight = $w->fontActual($fontO, '-weight');
  my $slant  = $w->fontActual($fontO, '-slant');
  my $uline  = $w->fontActual($fontO, '-underline');
  my $strike = $w->fontActual($fontO, '-overstrike');

  # get the device context.
  $w->update;
  my $id  = eval($w->id);
  my $hdc = $GetDC->Call($id);

  # create the logical font.
  my $font = $CreateFont->Call(int($size * 108 / 72),  # by trial and error
          0, $angle * 10, 0,
          ($weight eq 'normal' ? 400 : 700),
          ($slant  eq 'roman'  ?   0 :   1),
          $uline,
          $strike,
          0, 0, 0, 0, 0,
          $family);

  # select the font into the device context.
  my $old = $SelectObject->Call($hdc, $font);

  # set the bg/fg colors.
  $SetBkColor  ->Call($hdc, eval $wbg);
  $SetTextColor->Call($hdc, eval $wfg);

  # get the text string.
  my $text;
  if (defined $w->{TEXTV} && ref($w->{TEXTV}) eq 'SCALAR') {
    $text = ${$w->{TEXTV}};
  } else {
    $text = $w->{TEXT};
  }
  my $len = length $text;

  # get the extent of the text.
  my $r = $GetTextExtent->Call($hdc, $text, $len, 0, 0);
  my $y = $r >> 16;
  my $x = $r & 65535;

  # calculate the desired size of the label.
  my $cos = abs(cos $angle * 3.14159 / 180);
  my $sin = abs(sin $angle * 3.14159 / 180);

  my $W = $x * $cos + $y * $sin;
  my $H = $y * $cos + $x * $sin;

  $w->configure(-width  => $W,
		-height => $H);

  $w->update;

  # get actual size.
  $W = $w->reqwidth;
  $H = $w->reqheight;

  # determine the location of the text.
  my ($X, $Y) = (0, 0);
  if ($angle <= 90) {
    $Y = $x * $sin;
  } elsif ($angle <= 180) {
    $Y = $H;
    $X = $x * $cos;
  } elsif ($angle <= 270) {
    $X = $W;
    $Y = $H - $x * $sin;
  } else {
    $X = $W - $x * $cos;
  }
  # dump out the text.
  $ExtTextOut->Call(
      $hdc,
      int $X,
      int $Y,
      0,
      0,
      $text, $len,
      0
     );

  # clean up.
  $SelectObject->Call($hdc, $old);
  $DeleteObject->Call($font);
  $ReleaseDC   ->Call($id, $hdc);
}

__END__

=head1 NAME

Tk::Win32RotLabel - A widget that allows rotated labels on the Win32 platform.

=head1 SYNOPSIS

  use Tk::Win32RotLabel;
  $top->Win32RotLabel(-text  => 'Anything you want',
                      -angle => 45)->pack;

=head1 DESCRIPTION

This widget extends a simple Label to allow rotated text.
It is Win32-specific since a solution already exists on *nix systems
(search for Tk::CanvasRottext and Tk::RotX11Font by Slaven Rezic).
Please see the L<"BUGS"> section below.

=head1 PREREQUISITES

This module requires the Win32::API module, which is available from your local mirror.

=head1 WIDGET-SPECIFIC OPTIONS

This widget accepts all options that a Tk::Label accepts, but adds one
more option to specify the angle of the text. Some options are ignored.
See the L<"LIMITATIONS"> section for more information.

=over 4

=item B<-angle>

This option specifies the angle (in degrees) of the text measured in
a counter-clockwise fashion. Valid values
are 0 to 360 inclusive. Values below 0 will be treated as 0, and values
above 360 are treated as 360. Defaults to 0 degrees which means no
rotation.

=back

=head1 LIMITATIONS

I am no expert in Win32-specific graphics. This module was implemented by
trial and error, and there is some behaviour that I do not understand fully.
As a result, there are some limitations:

=over 4

=item Text Position

The text will ALWAYS be displayed flushed along either the left edge
or the right edge of label, depending on the angle.

=item Label Size

The size of the label will always be computed and forced onto the label
such that it creates the smallest possible bounding box around the
text.

=back

The combination of the above two limitations implies that the label will always
be as small as possible, and the text centered in the label. Options such
as I<-padx|pady>, I<-anchor>, I<-justify>, etc, are ignored. But, options
given to the layout manager (pack/place/grid/form) are NOT ignored, which
can lead to non-intuitive results.

For example, this:

  $top->Label(-text => 'test')->pack(qw/-fill x/);

will center the text in the label. While this:

  $top->Win32RotLabel(-text => 'test')->pack(qw/-fill x/);

will have the text flushed to the left. It is easy to rectify this problem
though by placing the Win32RotLabel in a Frame:

  my $f = $top->Frame->pack(qw/-fill x/);
  $f->Win32RotLabel(-text => 'test')->pack;

Important: Not all fonts support rotation. Please see the L<"BUGS"> section
for more information.

=head1 BUGS

Through my trials I found out that not all fonts support rotation. It seems
that only True-Type fonts support this. So, if you try to use a font and
get weird results, try a different font. Times New Roman, the default, should
work fine.

If you set the size of your MainWindow, via a call to geometry() for
example, and then create a Win32RotLabel widget as a child of your MainWindow,
then the label will appear empty until you move or resize the MainWindow. As a
workaround, either resize the MainWindow I<after> creating the Win32RotLabel
object, or create a Frame, and make it the parent of your Win32RotLabel object.

Sometimes, when resizing the toplevel, the text might appear to flicker. That
is normal. In some cases though, the text disappears. I do not understand
why this happens. To fix this, you can simply minimize and re-maximize the
window, or resize it again, and all should be fine.

I wrote this, and tested it on two WindowsXP machines (with SP-1 and the latest
security patches). It works. I did not test on any other platform, but I got
reports that it fails on Win2k. I'm investigating.

If you can comment on any of the bugs above, then I would be happy to hear from
you (especially if you know how to fix things ;)

=head1 INSTALLATION

Either the usual:

perl Makefile.PL
make
make install

or just stick it somewhere in @INC where perl can find it. It's in pure Perl.

=head1 AUTHOR

Ala Qumsieh I<aqumsieh@cpan.org>

=head1 COPYRIGHTS

Copyright (c) 2008 Ala Qumsieh. All rights reserved.
This module is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.

=cut

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..3\n"; }
END {print "not ok 1\n" unless $loaded;}
use X11::Protocol;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

# This isn't really proper test code, just a simple example.

# A rough perl translation of the `basicwin' program from ORA's _Xlib
# Programming Manual_, chapter 3.

use X11::Protocol;

%args = @ARGV;

$display = $args{'-d'} || $args{'-display'} || $ENV{DISPLAY};

$x = X11::Protocol->new($display);

while (my $id = int rand(2**24)) {
    # Check that we can continue after an error without crashing or
    # getting stuck. Because of a regression in versions 0.54 and
    # 0.55, this would get stuck in an infinite loop.
    my($result,) = $x->robust_req('GetGeometry', $id);
    if (not ref $result) {
	print "ok 2\n";
	last;
    }
}

$x->event_handler('queue');

$d_width = $x->width_in_pixels;
$d_height = $x->height_in_pixels;

$w = $d_width / 2;
$h = $d_height / 3;

$win = $x->new_rsrc;
$x->CreateWindow($win, $x->root, 'InputOutput', $x->root_depth,
		 'CopyFromParent', (0, 0), $w, $h, 4,
		 'background_pixel' => $x->white_pixel,
		 'bit_gravity' => 'Static',
		 'event_mask' =>
		   $x->pack_event_mask('Exposure', 'KeyPress', 'ButtonPress',
				       'StructureNotify'));

$x->ChangeProperty($win, $x->atom('WM_ICON_NAME'),
		   $x->atom('STRING'), 8, 'Replace', "basicwin");
$x->ChangeProperty($win, $x->atom('WM_NAME'), $x->atom('STRING'),
		   8, 'Replace', "Basic Window Program");
$x->ChangeProperty($win, $x->atom('WM_NORMAL_HINTS'),
		   $x->atom('WM_SIZE_HINTS'), 32, 'Replace',
		   pack("Ix16IIx44", 4|8|16, 320, 200));
$x->ChangeProperty($win, $x->atom('WM_HINTS'), $x->atom('WM_HINTS'),
		   32, 'Replace', pack("IIIx24", 1|2, 1, 1));

$progname = $0;
$progname =~ s[^.*/][];
$name = $args{'-name'} || $ENV{'RESOURCE_NAME'} || $progname;

$x->ChangeProperty($win, $x->atom('WM_CLASS'), $x->atom('STRING'),
		   8, 'Replace', "$name\0Basicwin");


$font = $x->new_rsrc;
$x->OpenFont($font, "9x15");

# $cursorfont = $x->new_rsrc;
# $x->OpenFont($cursorfont, "cursor");
# $cursor = $x->new_rsrc;
# $x->CreateGlyphCursor($cursor, $cursorfont, $cursorfont, 4, 5,
# 		      (65535,65535,65535), (0,0,0));
# $x->ChangeWindowAttributes($win, 'cursor' => $cursor);

$gc = getGC($win, $font);

$x->MapWindow($win);

while (1)
  {
    $x->handle_input until %e = $x->dequeue_event;
    if ($e{name} eq "Expose")
      {
	next unless $e{count} == 0;
	if ($win_size eq "TOO_SMALL")
	  {
	    TooSmall($win, $gc, $font);
	  }
	else
	  {
	    place_text($win, $gc, $font, $w, $h);
	    place_graphics($win, $gc, $w, $h);
	  }
      }
    elsif ($e{name} eq "ConfigureNotify")
      {
	$w = $e{width};
	$h = $e{height};
	if ($w < 320 or $h < 200)
	  {
	    $win_size = "TOO_SMALL";
	  }
	else
	  {
	    $win_size = "BIG_ENOUGH";
	  }

	$x->ClearArea($win, (0, 0), $w, $h, 1); # Shouldn't be necessary 
      }
    elsif ($e{name} eq "ButtonPress" or $e{name} eq "KeyPress")
      {
	$x->CloseFont($font);
	$x->FreeGC($gc);
	undef $x;
	print "ok 3\n";
	exit;
      }
  }

sub getGC
  {
    my($win, $font) = @_;
    my($gc) = $x->new_rsrc;

    $x->CreateGC($gc, $win, 'font' => $font, 'foreground' => $x->black_pixel,
		 'line_width' => 6, 'line_style' => 'OnOffDash',
		 'cap_style' => 'Round', 'join_style' => 'Round');
    $x->SetDashes($gc, 0, (12, 24));
    return $gc;
  }

sub text_width
  {
    my($font, $text) = @_;
    $text =~ s/(.)/\0$1/g; # 8-bit -> 16-bit
    my(%extents) = $x->QueryTextExtents($font, $text);
    return $extents{overall_width};
  }

sub place_text
  {
    my($win, $gc, $font, $w, $h) = @_;

    my $string1 = "Hi! I'm a window, who are you?";
    my $string2 = "To terminate program, press any key";
    my $string3 = "or button while in this window";
    my $string4 = "Screen Dimensions:";

    my(%font_info) = $x->QueryFont($font);
    my($font_h) = $font_info{font_ascent} + $font_info{font_descent};

    $x->PolyText8($win, $gc, ($w - text_width($font, $string1))/2,
		  $font_h, [0, $string1]);
    $x->PolyText8($win, $gc, ($w - text_width($font, $string2))/2,
		  $h - 2 * $font_h, [0, $string2]);
    $x->PolyText8($win, $gc, ($w - text_width($font, $string3))/2,
		  $h - $font_h, [0, $string3]);

    my $cd_height = " Height - @{[$x->height_in_pixels]} pixels";
    my $cd_width =  " Width  - @{[$x->width_in_pixels]} pixels";
    my $cd_depth =  " Depth  - @{[$x->root_depth]} plane(s)";

    my($y0) = $h / 2 - $font_h - $font_info{font_descent};
    my($x_off) = $w / 4;

    $x->PolyText8($win, $gc, $x_off, $y0, [0, $string4]);
    $x->PolyText8($win, $gc, $x_off, $y0 + $font_h, [0, $cd_height]);
    $x->PolyText8($win, $gc, $x_off, $y0 + 2 * $font_h, [0, $cd_width]);
    $x->PolyText8($win, $gc, $x_off, $y0 + 3 * $font_h, [0, $cd_depth]);
  }

sub place_graphics
  {
    my($win, $gc, $w, $h) = @_;

    my($height) = $h / 2;
    my($width) = 3 * $w / 4;
    my($ex) = $w/2 - $width/2;
    my($y) = $h/2 - $height/2;
    $x->PolyRectangle($win, $gc, [$ex, $y, $width, $height]);
  }

sub TooSmall
  {
    my($win, $gc, $font) = @_;
    my(%font_info) = $x->QueryFont($font);

    my($y_off) = $font_info{font_ascent};
    my($x_off) = 2;

    $x->PolyText8($win, $gc, $x_off, $y_off, [0, "Too Small"]);
  }





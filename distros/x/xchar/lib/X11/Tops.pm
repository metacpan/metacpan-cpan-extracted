# $Source: /home/keck/lib/perl/X11/RCS/Tops.pm,v $
# $Revision: 3.25 $$Date: 2007/07/07 07:52:11 $
# Contents
#   1 standard           13 X                25 command
#   2 constants          14 match            26 monitor changes
#   3 new                15 active           27 raise & lower
#   4 fetch_ids          16 stacking         28 geometry
#   5 update_ids         17 gravity          29 frame_geometry
#   6 update_from_props  18 monitor changes  30 wm_normal_hints
#   7 update             19 X11::Top         31 parse_geometry
#   8 byid               20 instance         32 requested geometry
#   9 choosechar         21 class            33 move
#   10 sort              22 title            34 expand
#   11 sorted            23 icon             35 notes
#   12 bychar            24 char             36 pod

# ----------------------------------------------------------------------

#1# standard

package X11::Tops;

use X11::Protocol;
use Carp;
use Data::Dumper;
use strict;
use warnings;

our $VERSION = 0.2;

# ----------------------------------------------------------------------

#2# constants

my @getpropconst = ('AnyPropertyType', 0, -1, 0);

# ----------------------------------------------------------------------

#3# new

sub new {
  my $X = shift;
  $X = X11::Protocol->new() unless ref $X;
  my $xtops;
  $xtops->{X} = $X;
  $xtops->{root} = $X->root; # assumes only 1 screen
  $xtops->{$_} = $X->InternAtom($_, 0) for qw(
    _NET_CLIENT_LIST
    _XCHAR_CHAR
    _XCHAR_COMMAND
  );
  $xtops->{$_} = $X->atom($_) for qw(
    _WIN_CLIENT_LIST
    _NET_ACTIVE_WINDOW
    _NET_CLIENT_LIST_STACKING
    WM_CLASS
    WM_NAME
    WM_ICON_NAME
    STRING
    WM_NORMAL_HINTS
    WM_SIZE_HINTS
  );
  $xtops->{$_} || croak("failed to create atom $_") for qw(
    _XCHAR_CHAR
    _XCHAR_COMMAND
  );
  bless $xtops;
}

# ----------------------------------------------------------------------

#4# fetch_ids

sub fetch_ids {
  my $xtops = shift;
  my $X = $xtops->{X};
  my $root = $xtops->{root};
  my $_NET_CLIENT_LIST = $xtops->{_NET_CLIENT_LIST};
  my ($value, $type, $format, $bytes_after) =
    $X->GetProperty($root, $_NET_CLIENT_LIST, @getpropconst);
  my @ids = unpack('L*', $value);
  \@ids;
}

# ----------------------------------------------------------------------

#5# update_ids

sub update_ids {
  my $xtops = shift;
  my $ids = $xtops->fetch_ids;
  $xtops->{byid}{$_} =
      bless { xtops => $xtops, id => $_ }, 'X11::Top'
    for @$ids;
  $xtops;
}

# ----------------------------------------------------------------------

#6# update_from_props

sub update_from_props {
  my $xtops = shift;
  $xtops->update_ids;
  for my $xtop (values %{$xtops->{byid}}) {
    $xtop->class;
    $xtop->char;
  }
  $xtops;
}

# ----------------------------------------------------------------------

#7# update

sub update {
  my $xtops = shift;
  my @deleted = ();
  my $newids = $xtops->fetch_ids;
  if ($xtops->{byid}) {
    my %seen;
    for my $id (@$newids) {
      $seen{$id} = 1;
      $xtops->{byid}{$id} =
          bless { xtops => $xtops, id => $id }, 'X11::Top'
        unless $xtops->{byid}{$id};
    }
    for my $id (keys %{$xtops->{byid}}) {
      push(@deleted, $xtops->{byid}{$id}) unless $seen{$id};
    }
    for my $xtop (@deleted) {
      delete $xtops->{byid}{$xtop->{id}};
      delete $xtops->{chars_in_use}{$xtop->{char}};
    }
  } else {
    for my $id (@$newids) {
      $xtops->{byid}{$id} =
        bless { xtops => $xtops, id => $id }, 'X11::Top';
    }
  }
  for my $xtop (values %{$xtops->{byid}}) {
    $xtop->{instance} = $xtop->instance unless
      defined $xtop->{instance};
    $xtop->{char} = $xtops->choosechar($xtop) unless
      defined $xtop->{char};
  }
  $xtops->sort;
  @deleted;
}

# ----------------------------------------------------------------------

#8# byid

sub byid {
  my $xtops = shift;
  $xtops->{byid};
}

# ----------------------------------------------------------------------

#9# choosechar

# assume instances set

sub choosechar {
  my ($xtops, $xtop) = @_;
  $xtops->{char} = sub { ['a' .. 'z', '0' .. '9'] }
    unless $xtops->{char};
  my $instance = $xtop->{instance};
  croak("\$xtop->{instance} not set for \$xtop->{id} = $xtop->{id}")
    unless defined $instance;
  my $char = &{$xtops->{char}}($instance);
  if (ref $char) {
    for my $c (@$char) {
      $char = $c, last unless $xtops->{chars_in_use}{$c};
    }
  }
  croak("no char matches instance '$instance'") unless defined $char;
  $xtops->{chars_in_use}{$char} = 1;
  $xtop->char($char);
  $char;
}

# ----------------------------------------------------------------------

#10# sort

# assume chars chosen, as after update()

sub sort {
  my $xtops = shift;
  my $order = $xtops->{order}; # hashref char->integer
  my $max = -1;
  if ($order) {
    for (values %$order) {
      croak(
        "values in order hash should be nonnegative integers," .
        " not '$_'"
      ) unless /^\d+$/;
      $max = $_ if $max < $_; 
    } 
  }
  for my $n (0 .. 127) {
    my $char = chr($n);
    next if defined $order->{$char};
    $order->{$char} = $max + 1 + $n;
  }
  @{$xtops->{sorted}} =
    sort { $order->{$a->{char}} <=> $order->{$b->{char}} }
      values %{$xtops->byid};
}

# ----------------------------------------------------------------------

#11# sorted

sub sorted {
  my $xtops = shift;
  $xtops->sort unless $xtops->{sorted};
  $xtops->{sorted};
}

# ----------------------------------------------------------------------

#12# bychar

# assume chars chosen, as after update()

sub bychar {
  my $xtops = shift;
  my $bychar = {};
  for my $xtop (values %{$xtops->byid}) {
    $bychar->{$xtop->{char}} = $xtop;
  }
  $bychar;
}

# ----------------------------------------------------------------------

#13# X

sub X {
  my $xtops = shift;
  $xtops->{X};
}

# ----------------------------------------------------------------------

#14# match

sub match {
  my ($xtops, $prop, $regex) = @_;
  for my $xtop (values %{$xtops->{byid}}) {
    my $value = $xtop->{$prop};
    $value = eval "\$xtop->$prop" unless defined $value;
    return $xtop if $value =~ $regex;
  }
}

for my $sub (qw(class instance title icon char)) {
  no strict 'refs';
  *$sub = sub {
    my ($xtops, $regex) = @_;
    $xtops->match($sub, $regex);
  }
}

# ----------------------------------------------------------------------

#15# active

# argument normally $xtops, but not used except to find this

sub active {
  my $xtops = shift;
  my $X = $xtops->{X};
  my $root = $xtops->{root};
  my $_NET_ACTIVE_WINDOW = $xtops->{_NET_ACTIVE_WINDOW};
  my ($value, $type, $format, $bytes_after) =
    $X->GetProperty($root, $_NET_ACTIVE_WINDOW, @getpropconst);
  unpack('L*', $value);
}

# ----------------------------------------------------------------------

#16# stacking

# see raise & lower

# argument normally $xtops, but not used except to find this

sub stacking {
  my $xtops = shift;
  my $X = $xtops->{X};
  my $root = $xtops->{root};
  my $_NET_CLIENT_LIST_STACKING = $xtops->{_NET_CLIENT_LIST_STACKING};
  my ($value, $type, $format, $bytes_after) =
    $X->GetProperty($root, $_NET_CLIENT_LIST_STACKING, @getpropconst);
  unpack('L*', $value);
}

# ----------------------------------------------------------------------

#17# gravity

sub NorthWest () { 1; }
sub North () { 2; }
sub NorthEast () { 3; }
sub West () { 4; }
sub Center () { 5; }
sub East () { 6; }
sub SouthWest () { 7; }
sub South () { 8; }
sub SouthEast () { 9; }

sub Gravity {
  my $arg = shift;
  $arg = shift if ref $arg;
  return undef unless $arg =~ /^\d$/;
  ( undef,
    qw(
      NorthWest
      North
      NorthEast
      West
      Center
      East
      SouthWest
      South
      SouthEast
    )
  )[$arg];
}

# ----------------------------------------------------------------------

#18# monitor changes

# also X11::Top method

sub monitor_property_change {
  my $xtops = shift;
  my $X = $xtops->{X};
  my $id = $xtops->{root};
  $X->ChangeWindowAttributes(
    $id,
    event_mask => $X->pack_event_mask('PropertyChange')
  );
}
# ----------------------------------------------------------------------

#19# X11::Top

package X11::Top;
use Data::Dumper;

sub id {
  my $xtop = shift;
  $xtop->{id}
}

# ----------------------------------------------------------------------

#20# instance

sub instance {
  my $xtop = shift;
  my $xtops = $xtop->{xtops};
  my $X = $xtops->{X};
  my $WM_CLASS = $xtops->{WM_CLASS};
  return $xtop->{instance} if defined $xtop->{instance};
  my ($value, $type, $format, $bytes_after) =
    $X->GetProperty($xtop->{id}, $WM_CLASS, @getpropconst);
  my ($instance, $class) = split "\0", $value;
  $xtop->{instance} = $instance;
  $xtop->{class} = $class;
  $instance;
}

# ----------------------------------------------------------------------

#21# class

sub class {
  my $xtop = shift;
  my $xtops = $xtop->{xtops};
  return $xtop->{class} if defined $xtop->{class};
  my $X = $xtops->{X};
  my $WM_CLASS = $xtops->{WM_CLASS};
  my ($value, $type, $format, $bytes_after) =
    $X->GetProperty($xtop->{id}, $WM_CLASS, @getpropconst);
  croak("failed to fetch WM_CLASS for window $xtop") unless $value;
  my ($instance, $class) = split "\0", $value;
  $xtop->{instance} = $instance;
  $xtop->{class} = $class;
  $class;
}

# ----------------------------------------------------------------------

#22# title

sub title {
  my $xtop = shift;
  my $xtops = $xtop->{xtops};
  my $X = $xtops->{X};
  my $WM_NAME = $xtops->{WM_NAME};
  my ($value, $type, $format, $bytes_after) =
    $X->GetProperty($xtop->{id}, $WM_NAME, @getpropconst);
  $value;
}

# ----------------------------------------------------------------------

#23# icon

sub icon {
  my $xtop = shift;
  my $xtops = $xtop->{xtops};
  my $X = $xtops->{X};
  my $WM_ICON_NAME = $xtops->{WM_ICON_NAME};
  my ($value, $type, $format, $bytes_after) =
    $X->GetProperty($xtop->{id}, $WM_ICON_NAME, @getpropconst);
  $value;
}

# ----------------------------------------------------------------------

#24# char

sub char {
  my ($xtop, $char) = @_;
  my $xtops = $xtop->{xtops};
  my $X = $xtops->{X};
  my $_XCHAR_CHAR = $xtops->{_XCHAR_CHAR};
  unless (defined $char) {
    return $xtop->{char} if defined $xtop->{char};
    my ($value, $type, $format, $bytes_after) =
      $X->GetProperty($xtop->{id}, $_XCHAR_CHAR, @getpropconst);
    return $xtop->{char} = $value;
  }
  $xtop->{char} = $char;
  my $STRING = $xtops->{STRING};
  $X->ChangeProperty(
    $xtop->{id},  # window
    $_XCHAR_CHAR,   # property
    $STRING,      # type
    8,            # format
    'Replace',    # mode
    $char,        # data
  );
}

# ----------------------------------------------------------------------

#25# command

sub command {
  my ($xtop, $command) = @_;
  my $xtops = $xtop->{xtops};
  my $X = $xtops->{X};
  my $_XCHAR_COMMAND = $xtops->{_XCHAR_COMMAND};
  my $STRING = $xtops->{STRING};
  unless (defined $command) {
    my ($value, $type, $format, $bytes_after) =
      $X->GetProperty($xtop->{id}, $_XCHAR_COMMAND, @getpropconst);
    return $value;
  }
  $X->ChangeProperty(
    $xtop->{id},    # window
    $_XCHAR_COMMAND,  # property
    $STRING,        # type
    8,              # format
    'Replace',      # mode
    $command,       # data
  );
}

# ----------------------------------------------------------------------

#26# monitor changes

# also X11::Tops method
sub monitor_property_change {
  my $xtop = shift;
  my $xtops = $xtop->{xtops};
  my $X = $xtops->{X};
  my $id = $xtop->{id};
  $X->ChangeWindowAttributes(
    $id,
    event_mask => $X->pack_event_mask('PropertyChange')
  );
}

sub monitor_property_and_visibility_change {
  my $xtop = shift;
  my $xtops = $xtop->{xtops};
  my $X = $xtops->{X};
  my $id = $xtop->{id};
  $X->ChangeWindowAttributes(
    $id,
    event_mask =>
      $X->pack_event_mask('PropertyChange', 'VisibilityChange')
  );
}

# doesn't work with fvwm [+taskbar3] or twm [+taskbar4] ...
sub monitor_property_and_structure_change {
  my $xtop = shift;
  my $xtops = $xtop->{xtops};
  my $X = $xtops->{X};
  my $id = $xtop->{id};
  $X->ChangeWindowAttributes(
    $id,
    event_mask =>
      $X->pack_event_mask('PropertyChange', 'SubstructureNotifyMask')
  );
}

sub attributes {
  my $xtop = shift;
  my $xtops = $xtop->{xtops};
  my $X = $xtops->{X};
  my $id = $xtop->{id};
  $X->GetWindowAttributes($id); # %attributes
}

# ----------------------------------------------------------------------

#27# raise & lower

# see stacking

sub raise {
  my $xtop = shift;
  my $xtops = $xtop->{xtops};
  my $X = $xtops->{X};
  my $id = $xtop->{id};
  $X->MapWindow($id);
  $X->ConfigureWindow($id, stack_mode => 'Above');
}

# if call $xtop->geometry then mouse & focus often don't move  ...
sub raise_and_focus {
  my $xtop = shift;
  my $xtops = $xtop->{xtops};
  my $X = $xtops->{X};
  my $id = $xtop->{id};
  $X->MapWindow($id);
  $X->ConfigureWindow($id, stack_mode => 'Above');
  my %geometry = $X->GetGeometry($id);
  my $x = int($geometry{width} / 2);
  my $y = int($geometry{height} / 2);
  $X->WarpPointer('None', $id, 0, 0, 0, 0, $x, $y);
  $X->SetInputFocus($id, 'RevertToPointerRoot', 'CurrentTime');
}

sub lower {
  my $xtop = shift;
  my $xtops = $xtop->{xtops};
  my $X = $xtops->{X};
  my $id = $xtop->{id};
  $X->ConfigureWindow($id, stack_mode => 'Below');
}

# ----------------------------------------------------------------------

#28# geometry

sub geometry {
  my $xtop = shift;
  my $xtops = $xtop->{xtops};
  my $X = $xtops->{X};
  my $id = $xtop->{id};
  my %geom = $X->GetGeometry($id);
  my ($root2, $parent, @kids) = $X->QueryTree($id);
  my ($same_screen, $child, $x, $y) =
    $X->TranslateCoordinates($parent, $root2, $geom{x}, $geom{y});
  return ($geom{width}, $geom{height}, $x, $y);
}

# ----------------------------------------------------------------------

#29# frame_geometry

sub frame_geometry {
  my $xtop = shift;
  my $xtops = $xtop->{xtops};
  my $X = $xtops->{X};
  my $frame = $xtop->{id};
  while (1) {
    my ($root2, $parent, @kids) = $X->QueryTree($frame);
    last if $parent == $root2;
    $frame = $parent;
  }
  my %geom = $X->GetGeometry($frame);
  ($geom{width}, $geom{height}, $geom{x}, $geom{y});
}

# ----------------------------------------------------------------------

#30# wm_normal_hints

our @wm_normal_hints = qw(
  flags
  user_x user_y user_w user_h
  min_width min_height
  max_width max_height
  width_inc height_inc
  min_aspect_num min_aspect_den
  max_aspect_num max_aspect_den
  base_width base_height
  gravity
);

my @wm_normal_hints_flags = (
  [qw(user_x user_y)],                  # USPosition
  [qw(user_w user_h)],                  # USSize
  [],                                   # PPosition
  [],                                   # PSize
  [qw(min_width min_height)],           # PMinSize
  [qw(max_width max_height)],           # PMaxSize
  [qw(width_inc height_inc)],           # PResizeInc
  [qw(min_aspect_num min_aspect_den
      max_aspect_num max_aspect_den)],  # PAspect
  [qw(base_width base_height)],         # PBaseSize
  [qw(gravity)],                        # PWinGravity
);

sub wm_normal_hints {
  my $xtop = shift;
  my $xtops = $xtop->{xtops};
  my $X = $xtops->{X};
  my $WM_NORMAL_HINTS = $xtops->{WM_NORMAL_HINTS};
  my $WM_SIZE_HINTS = $xtops->{WM_SIZE_HINTS};
  my %wm_normal_hints = @_;
  if (%wm_normal_hints) {
    my $value =
      pack('L*', map { $wm_normal_hints{$_} || 0 } @wm_normal_hints);
    $X->ChangeProperty(
      $xtop->{id},                # window
      $WM_NORMAL_HINTS,           # property
      $WM_SIZE_HINTS,             # type
      32,                         # format
      'Replace',                  # mode
      $value                      # data
    );
    return;
  }
  my ($value, $type, $format, $bytes_after) =
    $X->GetProperty($xtop->{id}, $WM_NORMAL_HINTS, @getpropconst);
  my %xxx;
  @xxx{@wm_normal_hints} = unpack('L*', $value);
  my $flags = $wm_normal_hints{flags} = $xxx{flags};
  for my $i (@wm_normal_hints_flags) {
    $wm_normal_hints{$_} = $flags & 1 ? $xxx{$_} : undef for @$i;
    $flags >>= 1;
  }
  %wm_normal_hints
}

# ----------------------------------------------------------------------

#31# parse_geometry

sub parse_geometry {
  my ($xtop, $geometry) = @_;
  my $X = $xtop->{xtops}{X};
  my ($w, $h, $x, $y) =
    $geometry =~ /^(\d+)x(\d+)([+-]-?\d+)([+-]-?\d+)$/;
  my $g; # gravity
  my $screenwidth = $X->width_in_pixels;
  my $screenheight = $X->height_in_pixels;

  if ($w == 0 || $h == 0 || $x eq '00' || $y eq '00') {
    my %xtop;
    @xtop{qw(w h x y)} = $xtop->geometry;
    $w = $xtop{w} if $w == 0;
    $h = $xtop{h} if $h == 0;
    $x = $xtop{x} if $x eq '00';
    $y = $xtop{y} if $y eq '00';
  }

  if (my ($a) = $x =~ /^-\+?(-?\d+)/) {
    if (my ($b) = $y =~ /^-\+?(-?\d+)/) {
      $g = X11::Tops::SouthEast;
      $x = $screenwidth - $w - $a;
      $y = $screenheight - $h - $b;
     } else {
      $g = X11::Tops::NorthEast;
      $x = $screenwidth - $w - $a;
      $y =~ s/^\+//;
      $y = 0 + $y;
     }
  } else {
    if (my ($b) = $y =~ /^-\+?(-?\d+)/) {
      $g = X11::Tops::SouthWest;
      $x =~ s/^\+//;
      $x = 0 + $x;
      $y = $screenheight - $h - $b;
    } else {
      $g = X11::Tops::NorthWest;
      $x =~ s/^\+//;
      $y =~ s/^\+//;
      $x = 0 + $x;
      $y = 0 + $y;
    }
  }
  ($w, $h, $x, $y, $g);
}

# ----------------------------------------------------------------------

#32# requested geometry

sub requested_geometry {
  my $xtop = shift;

  my %geometry;
  @geometry{qw(w h x y)} = $xtop->geometry;

  my %frame_geometry;
  @frame_geometry{qw(w h x y)} = $xtop->frame_geometry;

  my %wm_normal_hints = $xtop->wm_normal_hints;
  my $gravity = $wm_normal_hints{gravity};

  my $w = $geometry{w};
  my $h = $geometry{h};

  my $x =
    $gravity == X11::Tops::NorthWest || $gravity == X11::Tops::SouthWest ?
      $frame_geometry{x} :
    $gravity == X11::Tops::NorthEast || $gravity == X11::Tops::SouthEast ?
      $frame_geometry{x} - $frame_geometry{w} + $geometry{w} :
    croak("unknown gravity '$gravity'");

  my $y =
    $gravity == X11::Tops::NorthWest || $gravity == X11::Tops::NorthEast ?
      $frame_geometry{y} :
    $gravity == X11::Tops::SouthEast || $gravity == X11::Tops::SouthWest ?
      $frame_geometry{y} - $frame_geometry{h} + $geometry{h} :
    croak("unknown gravity '$gravity'");

  ($w, $h, $x, $y, $gravity);
}

# ----------------------------------------------------------------------

#33# move

# +taskbar7

sub move {
  my ($xtop, $geometry) = @_; # (src, dst)
  my $X = $xtop->{xtops}{X};

  my %src_wm_normal_hints = $xtop->wm_normal_hints;

  my %dst;
  @dst{qw(w h x y g)} = $xtop->parse_geometry($geometry);

  my %dst_wm_normal_hints = %src_wm_normal_hints;
  $dst_wm_normal_hints{gravity} = $dst{g};

  $xtop->wm_normal_hints(%dst_wm_normal_hints);

  $X->ConfigureWindow(
    $xtop->{id},
    width => $dst{w}, height => $dst{h},
    x => $dst{x}, y => $dst{y}
  );
}

# ----------------------------------------------------------------------

#34# expand

# +taskbar[78]

sub expand {
  my ($xtop, $geometry) = @_; # (src, dst)
  my $X11 = $xtop->{xtops}{X};

  my %src;
  @src{qw(w h x y g)} = $xtop->requested_geometry;
  $src{X} = $src{x} + $src{w};
  $src{Y} = $src{y} + $src{h};

  my %dst;
  @dst{qw(w h x y g)} = $xtop->parse_geometry($geometry);
  $dst{X} = $dst{x} + $dst{w};
  $dst{Y} = $dst{y} + $dst{h};

  my $x = $src{x} < $dst{x} ? $src{x} : $dst{x};
  my $y = $src{y} < $dst{y} ? $src{y} : $dst{y};
  my $X = $src{X} > $dst{X} ? $src{X} : $dst{X};
  my $Y = $src{Y} > $dst{Y} ? $src{Y} : $dst{Y};
  my $w = $X - $x;
  my $h = $Y - $y;

  my %wm_normal_hints = $xtop->wm_normal_hints;
  my %base;
  $base{w} = $wm_normal_hints{base_width};
  $base{h} = $wm_normal_hints{base_height};
  my %inc;
  $inc{w} = $wm_normal_hints{width_inc};
  $inc{h} = $wm_normal_hints{height_inc};
  if ($inc{w} && $inc{h}) {
    $w += ($base{w} - $w) % $inc{w};
    $h += ($base{h} - $h) % $inc{h};
  }

  $wm_normal_hints{gravity} = X11::Tops::NorthWest;
  $wm_normal_hints{user_w} = $w;
  $wm_normal_hints{user_h} = $h;
  $wm_normal_hints{user_x} = $x;
  $wm_normal_hints{user_y} = $y;
  $wm_normal_hints{max_width} = $w;
  $wm_normal_hints{max_height} = $h;

  $xtop->wm_normal_hints(%wm_normal_hints);

  $X11->ConfigureWindow($xtop->{id},
    width => $w,
    height => $h,
    x => $x,
    y => $y
  );
}

# ----------------------------------------------------------------------

1;
__END__

#35# notes

# 1.13
#   moved reading of .xls to here from gen/xls
#   changed sort method
#   _XLS_CHAR getting less interesting
#   +taskbar3
# 1.16
#   $xtops->active
# 1.18
#   xls instance name
# 1.23
#   lower()
# 1.24
#   initial clients work with twm (but not later clients) [+taskbar4]
# 1.32
#   geometry()
# 1.33
#   frame_geometry()
#   wm_normal_hints()
# 1.37
#   move() [+taskbar7]
# 1.42
#   uses Xtops1.pm [+taskbar7]
# 2.1
#   +taskbar7
# 3.1
#   +taskbar7
#   doesn't work yet
# 3.16
#   changed _XLS_ to _XCHAR_

# $Revision: 3.25 $

# ----------------------------------------------------------------------

#36# pod

=head1 NAME

X11::Tops - handle top level X windows

=head1 WARNING

The high level part of the interface is currently (xchar 0.2) clumsy,
and will probably be changed.

=head1 SYNOPSIS

  use X11::Tops;
  $xtops = X11::Tops->new;

  use X11::Tops;
  $X = X11::Protocol->new;
  $xtops = X11::Tops->new($X);

  $xtops->update;
  for $xtop (@{$xtops->sorted}) {
    print join("\t",
      $xtop->class, $xtop->instance, $xtop->title, $stop->icon
    ),
    "\n"
  }

  $xtop = $xtops->match('instance', qr/gecko/i);
  $xtop = $xtops->instance(qr/gecko/i);
  $xtop = $xtops->icon(qr/apod/i);

  $xtop->char('q');
  $xtop->char;

  @deleted = $xtops->update; # list of X ids

  $xtops->monitor_property_change;
  $xtop->monitor_property_change

=head1 DESCRIPTION

X11:Tops handles all the top level windows reported by the window
manager via the root window _NET_CLIENT_LIST property.  Most of the
methods are general, but there's also support for the xchar(1) system
(which is currently insufficiently separated from the general methods).
It is built on top of the X11::Protocol module.

It's designed to handle long-lived programs that keep track of changes
in the population of top level windows (such as xtb(1)) and short-lived
programs that just want a snapshot (such as xup(1) and xmv(1)).

An X11::Tops object C<$xtops> contains a set of X11::Top objects
C<$xtop>.  The latter can be reached with several methods of the former:

    $xtops->sorted  returns a reference to an array of $xtop
    $xtops->byid    returns a hashref, each value an $xtop
    $xtops->bychar  returns a hashref, each value an $xtop

The construction of $xtops can take one or several steps, and can be partial
or complete.  As mentioned in the warning above, this is currently clumsy.

The following constructs it completely:

    $xtops = X11::Tops->new;
    $xtops->update;

This fetches all (toplevel) window ids and all their WM_CLASS properties,
calculating a character for each & setting the _XCHAR_CHAR property on
it accordingly.

The following also constructs it completely:

    $xtops = X11::Tops->new;
    $xtops->update_from_props;

the difference being that the per-window characters aren't computed
as above but fetched from the _XCHAR_CHAR propertes.

The construction used by the C<update> method above uses a hardwired
algorithm for assigning characters to windows.  The algorithm can
instead be flexibly specified:

    $xtops = X11::Tops->new;
    $xtops->{char} = sub { $instance = shift; ...; return $char; };
    $xtops->update;

The C<sort> method mentioned above uses a hardwired sort algorithm that
can be over-ridden:

    $xtops = X11::Tops->new;
    $xtops->{char} = sub { $instance = shift; ...; return $char; };
    $xtops->update;
    $xtops->{order} = ['a' .. 'z', 0 .. 9, 'A' .. 'Z'];
    @xtops = $xtops->sort;

Partial construction, as for snapshotting, is typically:

    $xtops = X11::Tops->new->update_ids;
    for $xtop (values %{$xtops->byid}) { ... }

Both X11::Tops and X11::Top have class, instance, title & icon methods.
They only get, not set.  For X11::Tops there is a regex argument & the
method returns an X11::Top object whose corresponding property matches
the regex.  For X11::Top there is no argument (other than the object) &
the corresponding property is returned.  Class & instance are handled
separately even though they come from the same property (WM_CLASS).
Values of class & instance are assumed not to change (so are cached).

The X11::Top method C<char> gets or sets a (non-standard) property
_XCHAR_CHAR.  Normally the character name of a toplevel is derived from
the instance name via $xtops->{char} as above.

=head1 OTHER X11::Xtops METHODS

=over

=item X()

returns the associated X11::Protocol object

=item active()

returns the X id of the active window

=item stacking()

returns the array of X ids in stacking order (bottom first)

=item monitor_property_change()

asks for root PropertyChange events

=back

=head1 OTHER X11::Xtop METHODS

=over

=item command()

gets or sets the _XCHAR_COMMAND property

=item attributes()

X11::Protocol::GetWindowAttributes

=item raise()

=item raise_and_focus()

=item lower()

=item geometry()

=item frame_geometry()

=item wm_normal_hints()

=item parse_geometry()

=item requested_geometry()

=item move()

=item expand()

=item monitor_property_change()

asks for PropertyChange events

=item monitor_property_and_visibility_change()

asks for PropertyChange & VisibilityChange events

=item monitor_property_and_structure_change()

asks for PropertyChange & SubstructureNotifyMask events

=back

=head1 AUTHOR

Brian Keck E<lt>bwkeck@gmail.comE<gt>

=head1 VERSION

 $Source: /home/keck/lib/perl/X11/RCS/Tops.pm,v $
 $Revision: 3.25 $
 $Date: 2007/07/07 07:52:11 $
 xchar 0.2

=cut


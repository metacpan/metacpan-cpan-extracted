# $Source: /home/keck/lib/perl/X11/RCS/Screens.pm,v $
# $Revision: 4.18 $$Date: 2007/07/06 17:00:30 $
# Contents
#   1 standard     7 current     13 font          19 Screen::Client
#   2 new          8 Screen      14 managers      20 geometry
#   3 screen       9 current     15 translations  21 fonts
#   4 names        10 name       16 sunfun        22 notes
#   5 match_loose  11 width etc  17 x             23 pod
#   6 match_tight  12 clients    18 unicode

# ----------------------------------------------------------------------

#1# standard

use strict;
use warnings;

package X11::Screens;

use Carp;
use Data::Dumper;

our $VERSION = 0.2;

# ----------------------------------------------------------------------

#2# new

sub new {
  my $screens = (require "$ENV{HOME}/.xscreens");
  croak("failed to read $ENV{HOME}/.xscreens") unless $screens;
  for my $name (keys %$screens) {
    my $screen = $screens->{$name};
    bless $screen, 'X11::Screen';
    $screen->{name} = $name;
    my $clients = $screen->{clients};
    for my $client (values %$clients) {
      $client = { geometry => $client } unless ref $client eq 'HASH';
      my $geometry = $client->{geometry};
      if (ref $geometry) {
        my ($w0, $h0) = $geometry->[0] =~ /(\d+)x(\d+)/;
	croak("bad geometry '$geometry->[0]'") unless defined $h0;
        my ($w1, $h1) = $geometry->[1] =~ /(\d+)x(\d+)/;
	croak("bad geometry '$geometry->[1]'") unless defined $h1;
        croak("bizarre geometries") if
          ($w0 > $w1 && $h0 < $h1) || ($w0 < $w1 && $h0 > $h1);
        if ($w0 < $w1 || $h0 < $h1) {
          $client->{geometry} =
	    { chars => $geometry->[0], pixels => $geometry->[1] };
        } else {
          $client->{geometry} =
	    { chars => $geometry->[1], pixels => $geometry->[0] };
        }
      } else {
        $client->{geometry} = { chars => undef, pixels => $geometry };
      }
      $client->{screens} = $screens;
      bless $client, 'X11::Screen::Client';
    }
  }
  bless $screens;
}

# ----------------------------------------------------------------------

#3# screen

sub screen {
  my ($screens, $name) = @_;
  $screens->{name}
}

# ----------------------------------------------------------------------

#4# names

sub names {
  my $screens = shift;
  keys %$screens;
}

# ----------------------------------------------------------------------

#5# match_loose

sub match_loose {
  my $screens = shift;
  my %given = @_;
  my @return;
  for my $screen (values %$screens) {
    my $match = 1;
    my $hashref = $screen;
    DOTTED: for my $dotted (keys %given) {
      my $got;
      my @keys = split /\./, $dotted;
      for my $i (0 .. $#keys) {
        my $key = $keys[$i];
	next DOTTED unless ref $hashref;
	$got = $hashref->{$key}, last if $i == $#keys;
        my $hashref = $hashref->{$key};
      }
      next unless defined $got;
      next if ref $got;
      $match = 0 unless $got eq $given{$dotted};
    }
    push(@return, $screen) if $match;
  }
  @return;
}

# ----------------------------------------------------------------------

#6# match_tight

sub match_tight {
  my $screens = shift;
  my %given = @_;
  my @return;
  SCREEN: for my $screen (values %$screens) {
    my $hashref = $screen;
    DOTTED: for my $dotted (keys %given) {
      my $got;
      my @keys = split /\./, $dotted;
      for my $i (0 .. $#keys) {
        my $key = $keys[$i];
	next SCREEN unless ref $hashref;
	$got = $hashref->{$key}, last if $i == $#keys;
        my $hashref = $hashref->{$key};
      }
      next SCREEN unless defined $got;
      next SCREEN if ref $got;
      next SCREEN unless $got eq $given{$dotted};
    }
    push @return, $screen;
  }
  @return;
}

# ----------------------------------------------------------------------

#7# current

# X11::Screens->current
# $screens->current
# X11::Screens->current($tkmain)
# $screens->current($tkmain)

sub current {
  my $screens = shift;
  $screens = X11::Screens->new unless ref $screens;
  my $tkmain = shift;
  my $current = X11::Screen->current($tkmain);
  my $screen;
  for my $name (keys %$screens) {
    my $s = $screens->{$name};
    next if defined $s->{width} &&
      $s->{width} != $current->{width};
    next if defined $s->{height} &&
      $s->{height} != $current->{height};
    next if defined $s->{depth} &&
      $s->{depth} != $current->{depth};
    next if defined $s->{resolution} &&
      $s->{resolution} != $current->{resolution};
    $screen = $s;
  }
  croak("no entry in $ENV{HOME}/.xscreens matching current screen")
    unless $screen;
  $screen->{$_} = $current->{$_} for
    qw(tkmain width height depth resolution);
  $screen;
}

# ----------------------------------------------------------------------

#8# Screen

package X11::Screen;

use Carp;

# ----------------------------------------------------------------------

#9# current

sub current {
  my $tkmain = shift;
  $tkmain = shift unless ref $tkmain;
  if (defined $tkmain) {
    croak("argument not a Tk::MainWindow reference")
      unless ref $tkmain eq 'Tk::MainWindow';
  } else {
    require Tk;
    $tkmain = Tk::MainWindow->new;
    croak("Tk::MainWindow->new failed") unless $tkmain;
  }
  my $screen = {
    tkmain => $tkmain,
    width => $tkmain->screenwidth,
    height => $tkmain->screenheight,
    depth => $tkmain->screendepth,
    resolution => $tkmain->pixels('1i'),
  };
  bless $screen;
}

# ----------------------------------------------------------------------

#10# name

sub name {
  my $screen = shift;
  $screen->{name};
}

# ----------------------------------------------------------------------

#11# width etc

sub width {
  my $screen = shift;
  $screen->{width}
}

sub height {
  my $screen = shift;
  $screen->{height}
}

sub depth {
  my $screen = shift;
  $screen->{depth}
}

sub resolution {
  my $screen = shift;
  $screen->{resolution}
}

# ----------------------------------------------------------------------

#12# clients

# keys added by X11::Screens->new

sub clients {
  my $screen = shift;
  $screen->{clients}
}

# ----------------------------------------------------------------------

#13# font

sub font {
  my $screen = shift;
  $screen->{font}
}

# ----------------------------------------------------------------------

#14# managers

sub managers {
  my $screen = shift;
  $screen->{managers}
}

# ----------------------------------------------------------------------

#15# translations

sub translations {
  my $screen = shift;
  $screen->{translations}
}

# ----------------------------------------------------------------------

#16# sunfun

sub sunfun {
  my $screen = shift;
  $screen->{sunfun}
}

# ----------------------------------------------------------------------

#17# x

sub x {
  my $screen = shift;
  $screen->{x}
}

# ----------------------------------------------------------------------

#18# unicode

sub unicode {
  my $screen = shift;
  $screen->{unicode}
}

# ----------------------------------------------------------------------

#19# X11::Screen::Client

package X11::Screen::Client;

# ----------------------------------------------------------------------

#20# geometry

# keys added by X11::Screens->new

sub geometry {
  my ($client, $units) = @_;
  $client->{geometry}{$units};
}

# ----------------------------------------------------------------------

#21# fonts

sub normal { my $client = shift; $client->{normal}; }
sub bold { my $client = shift; $client->{bold}; }

sub font {
  my $client = shift;
  my $weight = shift || 'normal';
  $client->{$weight};
}

# ----------------------------------------------------------------------

1;
__END__

#22# notes

# used by gen/screen, which is used by .xinitrc among others
# +xwin/config +perl/tk +xterm2

# 1.1
#   works
# 1.2
#   all() & ALL()
# 1.3
#   depth(), unicode()
# 2.1
#   much improved
#   all() & ALL() renamed to screen() & xwin()
#   dropped unconditional initialization, since xwin() doesn't need
#     a window
# 2.2
#   netscape()
# 3.1
#   renamed from Xwin.pm to Screen.pm: XXII128
# 3.3
#   changed screenwidth to width etc so all 1st letters are different
#   PS: but not (name & netscape)
# 3.5
#   most functions take name argument as well as none
#   most functions now methods too
# 3.12
#   allowed any of width, height, pixels, & depth to be unspecified
# 3.23
#   per-xterm fonts
# 3.29
#   Screen::screen($mainwindow) for gen/xls [+xwin/config]
# 3.33
#   allow both char & pixel geometries, for xmv
# 3.34
#   'xterms' changed to 'chars'
#   'pixels' changed to 'dpi'
#   Screen::Xterm changed to Screen::Client
#   +taskbar8
# 4.13
#   renamed this from Screens to X11::Screens [+taskbar9]

# $Revision: 4.18 $

# ----------------------------------------------------------------------

#23# pod

=head1 NAME

X11::Screens - extract information for configuring X clients from ~/.xscreens

=head1 SYNOPSIS

  require X11::Screens;
  $screens = X11::Screens->new;
  @screen_names = $screens->names;
  $screen = $screens->screen('vaio');
  $current_screen = $screens->current;
  $current_screen = X11::Screens->current;
  $current_screen = $screens->current($tkmain);
  $current_screen = X11::Screens->current($tkmain);

  $current_screen = X11::Screen->current; # requires Tk
  $current_screen = X11::Screen->current($tkmain);

  $name = $screen->name;

  $width = $screen->width;
  $height = $screen->height;
  $depth = $screen->depth;
  $resolution = $screen->resolution;
  $clients = $screen->clients;
  $font = $screen->font;
  $x = $screen->x;
  $unicode = $screen->unicode;
  $managers = $screen->managers;
  $translations = $screen->translations;
  $sunfun = $screen->sunfun;

  $char = 'a';
  $client = $screen->{$char};
  $geometry = $client->geometry;
  $geometry = $client->geometry('pixels'); # default
  $geometry = $client->geometry('chars'); # default
  $normal_font = $client->normal;
  $bold_font = $client->bold;
  $font = $client->font; # normal if exists otherwise bold

  perl -MX11::Screens -e 'print X11::Screens->current->width, "\n"'
  perl -MData::Dumper -MX11::Screens -e 'print Dumper (X11::Screens->current)'
  perl -MData::Dumper -MX11::Screens -e '
    $Data::Dumper::Terse = 1;
    $Data::Dumper::Indent = 1;
    $Data::Dumper::Quotekeys = 0;
    $Data::Dumper::Sortkeys = sub {
      my @grep_v = sort grep !/^(tkmain|screens)$/, keys %{$_[0]};
      \@grep_v;
    };
    print Dumper (X11::Screens->current);
  '
  perl -MX11::Screens -e '
    map { print $_->{name}, "\n" }
      X11::Screens->new->match_loose(height => 768, depth => 24);
  '
  perl -MX11::Screens -e '
    map { print $_->{name}, "\n" }
      X11::Screens->new->match_tight(height => 768, height => 1368);
  '

=head1 DESCRIPTION

X11::Screens.pm defines packages X11::Screen & X11::Screen::Client as
well as X11::Screens.

Typical use of X11::Screens is to look up information about the current
X screen in ~/.xscreens, though this is not necessary.  One exception is
to fetch the width, height, depth & resolution (dpi) of the current
screen, without using ~/.xscreens (of course there are many other ways
to do this).  Another is to generate other configuration files (such as
Xdefaults and window manager configfiles) for all the screens listed in
~/.xscreens, regardless of the current X screen.

The only method that communicates with the X server is C<current()>.

The configfile ~/.xscreens is a perl fragment ending in an expression
returning a reference to a hash whose keys are screen names (like 'vaio'
above).  This hashref is returned by X11::Screens->new.

The values are themselves hashrefs, & are essentially X11::Screen
instances.  The keys of a X11::Screen object depend on how the object is
obtained.  If C<current()> is used then all of width, height, depth &
resolution occur.  If ~/.xscreens is used then others occur, but not
necessarily all these 4, commonly because width & height are enough to
distinguish screens.

The 'clients' value of a X11::Screen is a hashref, with key/value pairs
like:

      a => {
        geometry => ['72x57+-1+0', '436x745+-1+0'],
        normal => '-*-*-medium-r-*--13-*-*-*-c-60-iso10646-*',
        bold => '-*-*-bold-r-*--13-*-*-*-c-60-iso10646-*',
        unicode => 1,
      },

Here the geometry value is an arrayref, width & height being in
characters for one element & in pixels for the other (order doesn't
matter).  It can also be a string, which is taken to use pixel units.

If no fonts are specified for a char value, a X11::Screen top level
'font' key is looked for.

=head1 AUTHOR

Brian Keck E<lt>bwkeck@gmail.comE<gt>

=head1 VERSION

 $Source: /home/keck/lib/perl/X11/RCS/Screens.pm,v $
 $Revision: 4.18 $
 $Date: 2007/07/06 17:00:30 $
 xchar 0.2

=cut


package Tk::VisualBrowser;

$VERSION = "0.14";

# TODO Font, anchor für Label per option 
#
use Carp;
use File::Basename;
use Tk;
use Tk::Event;
use Tk::Balloon;
#use Tk::ErrorDialog;
use Tk::XPMs qw(:arrows);

require Tk::Frame;
use base qw(Tk::Frame);

use strict;
use constant NORMAL => 0;
use constant MOVE   => 1;
my $state = NORMAL;
my $save_cursor;
my $cursor;

my $do_scroll = 1;

# PDO {{{


=head1 NAME

Tk::VisualBrowser - Visual Browser for image directories

=head1 SYNOPSIS

 use Tk;
 use Tk::VisualBrowser;

 my $top = MainWindow->new();

 my $vsb = $top->VisualBrowser;

 my @PICTURES = qw( f1.jpg f2.jpg f3.gif);

 $vsb->configure(
   -rows => 5,  -cols => 6,
   -pictures          => \@PICTURES,
   -thumbnail         => \&thumbnail_handler,
   -special_color         => \&special_color_handler,
   -b1_handler        => \&my_b1_handler,
   -b2_handler        => \&my_b2_handler,
   -b3_handler        => \&my_b3_handler,
   -double_b1_handler => \&my_bdouble_1_handler,
   -double_b2_handler => \&my_bdouble_2_handler,
   -double_b3_handler => \&my_bdouble_3_handler,
 );

 $vsb->scroll(0);  # scroll to first picture
                   # this will implicitely load the pictures


=head1 DESCRIPTION

C<Tk::VisualBrowser> is a megawidget which displays a matrix of 
(C<-rows>) x (C<-cols>) Labels with thumbnail images. It can be used,
for example, to create a visual directory browser for image directories
or an interactive program for sorting images (dia-sorter.pl).

The application program must provide a reference to a list of image
filenames and a handler which returns the filename of a corresponding
thumbnail GIF image for a given image filename.
C<Tk::VisualBrowser> displays the thumbnail pictures and provides some
navigation buttons for scrolling linewise or pagewise through the list.
A scrollbar is also attached to the widget.

It is possible to select thumbnails with the left moust button or to
select ranges of thumbnails with shift-click (as you would select files in
normal file browser). Ctrl-click allows adding or removing single thumbnails
from a selection.

The selected thumbnails may be moved around with the left mouse button.
The cursor image changes and all thumbnails which are currently under the
mouse will be highlighted while moving around. Releasing the mouse button
inserts the selected thumbnails before the current position.

When moving around, an automatic scroll up or down is triggered when the
mouse comes close to the upper or lower margin of the C<VisualBrowser>.
But only one linewise scroll is triggered at a time (in order to avoid the
scrollbar from running away). Try going back and forth with the mouse
to trigger further scrolls as needed.

=head1 CONFIGURATION

There are the following possibilities for configuring the C<VisualBrowser>:

=head2 Rows and Columns

Use C<-rows> and C<-cols> to specify the number of rows and columns
of the C<VisualBrowser:>

  $vsb->configure(-rows => 4, -cols => 8);

NOTE: C<-cols> and/or C<-rows> B<must> be configured in order to
get the C<VisualBrowser> up and running: Only when configuring
columns or rows the C<VisualBrowser> will be (re-)built.

=head2 List of Images

The list of images to be displayed is passed as a reference via 
the C<-pictures> option:

  $vsb->configure(-pictures => \@PICTURES);

The C<VisualBrowser> needs GIF images for each image filename in the list.
To this end a handler is specified which returns the name of the
corresponding GIF image when fed with an image filename:

  $vsb->configure(-thumbnail => \&thumbnail_handler);

  sub thumbnail_handler {
    my ($image_filename) = @_;

    # for example: (assuming that the thumbnails are
    # in the same directory but with .gif extension):

    $image_filename =~ s/\.jpg/.gif/i;
    return $image_filename;
  }

It could also be arranged that the thumbnail_handler creates the GIF
images when they do not yet exist. So the viewing of an image directory
would automatically create the thumbnails (with Image::Magick, for example).

NOTE: The names in the @PICTURES array need not be valid filenames, 
although they normally are. The names of the GIF files
provided by the thumbnail_handler must be valid filenames,
either relative to the current working directory or absolute
pathnames.

=head2 Handlers for Mouse Button Events

The application can specify its own handlers for mousebutton events, e. g.:

  $vsb->configure(-doubel_b1_handler => \&my_double_1);

  sub my_double_1 {
    my ($image_filename) = @_;

    # display $image_filename in a Toplevel Window:
    require Tk::JPEG;
    my $show = $top->Toplevel();
    my $image = $top->Photo('-format' => "jpeg", 
                         -file => $image_filename);
    $show->Label(-image => $image)->pack;
  }

=head2 Colors

The following table shows the possible color options:

  -highlight     => "#rrggbb"    color for moving around
  -active_color  => "#rrggbb"    color for selected thumbs
  -bg_color1     => "#rrggbb"    background color for plane
  -bg_color      => "#rrggbb"    background color for thumbs
  -cursor_bg     => "#rrggbb"    background color for cursor
  -cursor_fg     => "#rrggbb"    foreground color for cursor

When you have selected some thumbnails, they are colored with the
C<-active_color> option. Moving them around will highlight the
thumbnail under the cursor with C<-highlight> color to indicate the
current insert position.

NOTE: Color options must be specified at the very beginning, when the
C<VisualBrowser> is instantiated. Later reconfigurations may have no effect.

It is possible to provide a handler which makes sure that certain images
get a different background color (for example to indicate that these
images have been changed recently):

  $vsb->configure(-special_color => \&my_color_hdlr);

  sub my_color_hdlr {
    my ($image_filename) = @_;

    # decide if $image_filname needs to be displayed with a different
    # background color:
    if ( -M $image_filename < 7 ) {
      return "#cc2222"; # use special bg color
    }

    return 0; # no special color
  }

=head2 Labels and Balloons

It is possible to use Labels for each image and to have balloon messages on each image (i. e.
a small window with text pops up when the cursor hovers over an image). In order to activate this
features use the following options:

  -use_labels      => 1
  -use_balloons    => 1

The default text for labels and balloons are the basenames of the image filenames. You can, however,
set the labels and balloon texts indiviually by passing references to corresponding arrays the the
VisualBrowser:

  -balloon_texts => \@Array_with_balloon_texts
  -label_texts   => \@Array_with_label_texts

This may be used, for example, to prepare an array with text for each image which contains the filename
and EXIF information for the image.

=head1 METHODS

The following methods are available:

=cut

# }}}

Construct Tk::Widget 'VisualBrowser';

# Public Methods
# ==============

sub get_selected { # {{{

=head2 my @SELECTED = $vsb->get_selected;

Returns the list of currently selected images. The list contains the 
filenames of the selected pictures. This might be useful for the
creation of a slideshow control file with the names of the selected
images.

=cut

  my ($w) = @_;
  my @LIST = ();
  for (my $i=0; $i < @{$w->{SEL}}; $i++){
    push @LIST, $w->{pictures}[$i] if $w->{SEL}[$i]; 
  } # for $i
  return @LIST; 
} # get_selected }}}

sub get_selected_idx{ # {{{

=head2 my @SELECTED = $vsb->get_selected_idx;

Returns the list of currently selected images. The list contains the index numbers, 
not the filenames.

=cut

  my ($w) = @_;
  my @LIST = ();
  for (my $i=0; $i < @{$w->{SEL}}; $i++){
    push @LIST, $i if $w->{SEL}[$i]; 
  } # for $i
  return @LIST; 
} # get_selected_idx }}}

sub select { # {{{

=head2 $vsb->select($idx);

Select specified picture with index $idx. Note that other pictures are not
deselected automatically.

=cut

  my ($w, $z) = @_;
  $w->{SEL}[$z] = 1;
  _select_pic($w, $z, 1);
} # select }}}

sub select_all { # {{{

=head2 $vsb->select_all;

Selectes all pictures together.

=cut

  my ($w) = @_;
  for ( my $z = 0; $z <= $#{$w->{pictures}}; $z++ ){
      $w->{SEL}[$z] = 1;
      _select_pic($w, $z, 1);
  }
} # select_all }}}

sub deselect_all { # {{{

=head2 $vsb->deselect_all;

Deselectes all pictures.

=cut

  my ($w) = @_;
  for ( my $z = 0; $z <= $#{$w->{pictures}}; $z++ ){
      $w->{SEL}[$z] = 0;
      _select_pic($w, $z, 0);
  }
} # deselect_all }}}

sub remove_selected { # {{{

=head2 $vsb->remove_selected;

This command removes the selected images from the list of pictures.
Note that the original list is changed because you passed a reference to
this list via C<-pictures>.

=cut

  my ($w) = @_;
  # delete all selected pictures from list
  # when there are labels and/or balloons: delete from theses lists also
  for (my $i = @{$w->{SEL}} -1; $i>=0; $i--){
      if ($w->{SEL}[$i]) {
      splice( @{ $w->cget('-pictures') }, $i, 1) ;
      my $lref = $w->cget('-label_texts');
      if ($lref and ref($lref) eq 'ARRAY' and @$lref) {
        splice( @{ $w->cget('-label_texts') }, $i, 1) ;
      }
      my $bref = $w->cget('-balloon_texts');
      if ($bref and ref($bref) eq 'ARRAY' and @$bref and $bref != $lref) {
        splice( @{ $w->cget('-balloon_texts') }, $i, 1) ;
      }
    }
  }
  @{$w->{SEL}}  = map {0} @{$w->cget('-pictures')};

  scroll($w, $w->{posi});

}# remove_selected }}}

sub swap_selected { # {{{

=head2 $vsb->swap_selected;

Swaps two selected pictures. Returns 1 in case of success and 0 otherwise.
NOTE: The user must have selected exactly two pictures.

=cut

  my ($w) = @_;
  my @SL; # indices of selected pics

  # Ermitteln, welche beiden Bilder selektiert sind.
  for (my $i=0; $i < @{$w->{SEL}}; $i++){
      push @SL, $i if $w->{SEL}[$i];
  } # for $i

  if (scalar(@SL) != 2){
    return 0;    # not ok, need exactly two selected images
  }

  # ok: swap pics and display again
  my $pref = $w->cget('-pictures');
  ($$pref[ $SL[0] ], $$pref[ $SL[1] ]) =
  ($$pref[ $SL[1] ], $$pref[ $SL[0] ]);

  # if we have labels and/or ballons: swap also:
  my $lref = $w->cget('-label_texts');
  if ($lref and ref($lref) eq 'ARRAY' and @$lref) {
    ($$lref[ $SL[0] ], $$lref[ $SL[1] ]) =
    ($$lref[ $SL[1] ], $$lref[ $SL[0] ]);
  }
  my $bref = $w->cget('-balloon_texts');
  if ($bref and ref($bref) eq 'ARRAY' and @$bref and $bref != $lref) {
    ($$bref[ $SL[0] ], $$bref[ $SL[1] ]) =
    ($$bref[ $SL[1] ], $$bref[ $SL[0] ]);
  }
  $w->{SEL}[ $SL[0] ] = 0;  # deselect ...
  $w->{SEL}[ $SL[1] ] = 0;  # deselect ...
  
  scroll($w, $w->{posi});
  return 1; # ok
} # swap_selected }}}

sub scroll { # {{{

=head2 $vsb->scroll(<position>);

Scrolls the C<VisualBrowser> to the specified position.
<position> may have the following values:

 <number>  adjust the view so that the image with index <number>
           appears in the upper left corner.
 "p"       go back one line (previous line)
 "pp"      go back one page (previous page)
 "n"       scroll forward one line (next line)
 "nn"      scroll forward one page (next page)
 "l"       scroll to last image

In order to go to the first image, you should use the numeric value 0.

=cut


# Scroll to absolute position or scroll page wise or line wise.

  my ($w, $pos) = @_;
  return unless $do_scroll;
  my $thmb;
  my $k = 0;
  my ($r,$c) = ($w->cget('-rows'), $w->cget('-cols'));
  return unless defined $w->{Photo}[0][0];
  return unless defined $c;
  return unless defined $r;
  return unless defined $w->cget("-pictures");

# print "  scroll: pos: $pos\n";
  my $ps = $w->{posi};
  my $picref = $w->cget('-pictures');
  my $max = $#{$picref};
  my $blnref = $w->cget('-balloon_texts');
  my $lblref = $w->cget('-label_texts');

  my $anz = $r * $c;
  if ($pos =~ /^\d+$/){ # absolute
    $k = trim_pos($w, $pos);
  } elsif ( $pos eq "p") { # prev line
    $k = trim_pos($w, $ps -$c);
  } elsif ( $pos eq "pp") { # prev page
    $k = trim_pos($w, $ps-$anz);
  } elsif ( $pos eq "n") { # next line
    $k = trim_pos($w, $ps +$c);
  } elsif ( $pos eq "nn") { # next page
    $k = trim_pos($w, $ps+$anz);
  } elsif ( $pos eq "l") { # last page
    $k = trim_pos($w, $max+1-$anz);
  } else {
  }
  $w ->{posi} = $k;

  # Picture with index $k is placed in upper left corner
  my ($color, $relief) = ("#CCCCCC", "flat");
  $do_scroll = 0;
  my $use_balloon = $w->cget('-use_balloons');
  my $use_labels  = $w->cget('-use_labels');
  for (my $i = 0; $i < $r; $i++){
    for (my $j = 0; $j < $c; $j++){
      if ( $k <= $max and $k >= 0 ){
        my $special_color = $w->Callback(-special_color => $$picref[$k]) || $w->cget("-bg_color");;
        $relief = $w->{SEL}[$k] ? "groove" : "flat";
        $color  = $w->{SEL}[$k] ? $w->cget("-active_color") : $special_color;
        $thmb = $w->Callback( -thumbnail => $$picref[$k]);
        if (! -e $thmb){
          $thmb = $w->{pic_path}."/vis-dummy.gif";
        }
        my $name = basename($$picref[$k]);

        $w->{Photo}[$i][$j] -> configure( -file => $thmb );
        if ($use_labels) {
          if ( @{ $w->cget('-label_texts')} ) {
            $name = $$lblref[$k];
          }
          $w->{Label}[$i][$j]  = $name;
        }

        if ($use_balloon) {
          if ( @{ $w->cget('-balloon_texts')} ) {
            $name = $$blnref[$k];
          }
          $w->{bln}->detach( $w->{Thmb}[$i][$j]);
          $w->{bln}->attach( $w->{Thmb}[$i][$j], -balloonmsg => "$name");
        }
        $w->{Thmb}[$i][$j]  -> configure(
                                         -width => 80,
                                         -height => 80,
                                         -background =>$color,
                                         -relief => $relief,
                                         -image => $w->{Photo}[$i][$j]
                              );
      } else { # empty pictures after the end of our list
        $thmb = $w->{pic_path}."/vis-empty.gif";
        if ($use_labels) {
          $w->{Label}[$i][$j]  = "";
        }
        if ($use_balloon) {
          $w->{bln}->detach( $w->{Thmb}[$i][$j]);
        }
        $w->{Photo}[$i][$j] -> configure( -file => $thmb );
        $w->{Thmb}[$i][$j]  -> configure(
                                         -width => 80,
                                         -height => 80,
                                         -background =>  $w->cget("-bg_color"),
                                         -relief => "flat",
                                         -image => $w->{Photo}[$i][$j]
                              );
      }
      $k++; # next picture
     #$w->MainWindow->update;
     #$w->{Thmb}[$i][$j]->update; # same effect

#     ACHTUNG: Unter Windows:
#       wenn update Aktiv ist, tritt derselbe Effekt auf, wie unter Linux ....
#       Beim Klick auf Scrollbar-Pfeil läuft der Rollbalken weg (Dauerscroll ...)
    } # $i
  } # $j
# print "  end\n";
  $do_scroll = 1;
} # scroll }}}

# Private Methods 
# ===============

sub Populate { # {{{
  my ($w, $args) = @_;
  $w->SUPER::Populate($args);

  $w->{posi} = 0;
  $w->{state} = NORMAL;
  $w->{pic_path} = $INC{"Tk/VisualBrowser.pm"};
  $w->{pic_path} =~ s/VisualBrowser.pm//;

  $w->ConfigSpecs(
    -cols => [METHOD => undef, undef, 5],
    -rows => [METHOD => undef, undef, 4],
    -b1_handler        => [CALLBACK => undef, undef, undef],
    -b2_handler        => [CALLBACK => undef, undef, undef],
    -b3_handler        => [CALLBACK => undef, undef, undef],
    -double_b1_handler => [CALLBACK => undef, undef, undef],
    -double_b2_handler => [CALLBACK => undef, undef, undef],
    -double_b3_handler => [CALLBACK => undef, undef, undef],
    -pictures          => [METHOD => undef, undef, []],
    -thumbnail         => [CALLBACK => undef, undef, sub{ return "nix is" }],
    -special_color     => [CALLBACK => undef, undef, sub{ return 0 }],
    -highlight         => [PASSIVE => undef, undef, "#3F8856"],
    -active_color      => [PASSIVE => undef, undef, "#2222CC"],
    -bg_color          => [PASSIVE => undef, undef, "#CCCCCC"],
    -bg_color1         => [PASSIVE => undef, undef, "#BBBBBB"],
    -cursor_fg         => [PASSIVE => undef, undef, "white"],
    -cursor_bg         => [PASSIVE => undef, undef, "brown"],
    -use_labels        => [PASSIVE => undef, undef, 0],
    -use_balloons      => [PASSIVE => undef, undef, 0],
    -balloon_texts     => [METHOD => undef, undef, []],
    -label_texts       => [METHOD => undef, undef, []],
  );

} # Populate }}}

sub rebuild { # {{{
  my ($w, $rows_old, $cols_old) = @_;

  my $cols = $w->cget("-cols");
  my $rows = $w->cget("-rows");

# print "---- rebuild $rows, $cols\n";
  return unless defined $rows_old;
  return unless defined $cols_old;
  return unless defined $rows;
  return unless defined $cols;


  # is it really necessary?
  if ($cols_old == $cols  and $rows_old == $rows) {
    return ;
  }

  # remove all buttons and labels
  $w->{ysb}->destroy if defined $w->{ysb};
    # scrollbar must be destroyed before all other objects
    # because its enclosing frame $frm_pan is handled in the following list

  foreach my $obj ( @{ $w->{OBJECTS} } ){
    $obj->destroy;
  }
  undef $w->{OBJECTS};

  # free Photo Objects
  for (my $i = 0; $i < $rows_old; $i++){
    for (my $j = 0; $j < $cols_old; $j++){
      undef $w->{Photo}[$i][$j];
    }
  }

  # rebuild all:
  my $pfeil_first = $w->Pixmap(-data => arrow_first_xpm);
  my $pfeil_last  = $w->Pixmap(-data => arrow_last_xpm);
  my $pfeil_ll = $w->Pixmap(-data => arrow_ppage_xpm);
  my $pfeil_nn = $w->Pixmap(-data => arrow_npage_xpm);
  my $pfeil_l  = $w->Pixmap(-data => arrow_prev_xpm);
  my $pfeil_n  = $w->Pixmap(-data => arrow_next_xpm);

  my $frm_but = $w->Frame()->pack;

  if ($w->cget('-use_balloons')) {
    $w->{bln} = $w->Balloon;
  }

  my $mm = $rows * $cols;
  my $b_fst = $frm_but->Button(#-text => "|<",
                              -image => $pfeil_first,
               -command => sub { scroll($w, 0);
                                 set_sb($w, 0, $mm);
                               }
              )->pack(-side => "left");
               push @{ $w->{OBJECTS} }, $b_fst;

  my $b_pp  = $frm_but->Button(#-text => "<<",
                              -image => $pfeil_ll,
               -command => sub { scroll($w, "pp");
                                 set_sb($w, $w->{posi}, $mm);
                               }
              )->pack(-side => "left");
               push @{ $w->{OBJECTS} }, $b_pp;

  my $b_p   = $frm_but->Button(#-text => "<",
                              -image => $pfeil_l,
               -command => sub { scroll($w, "p");
                                 set_sb($w, $w->{posi}, $mm);
                               }
              )->pack(-side => "left");
               push @{ $w->{OBJECTS} }, $b_p;
  my $b_n   = $frm_but->Button(#-text => ">",
                              -image => $pfeil_n,
               -command => sub { scroll($w, "n");
                                 set_sb($w, $w->{posi}, $mm);
                               }
              )->pack(-side => "left");
               push @{ $w->{OBJECTS} }, $b_n;
  my $b_nn  = $frm_but->Button(#-text => ">>",
                              -image => $pfeil_nn,
               -command => sub { scroll($w, "nn");
                                 set_sb($w, $w->{posi}, $mm);
                               }
              )->pack(-side => "left");
               push @{ $w->{OBJECTS} }, $b_nn;
  my $b_lst = $frm_but->Button(#-text => ">|",
                              -image => $pfeil_last,
               -command => sub { scroll($w, "l");
                       my $picref = $w->cget('-pictures');
                       my $max = $#{$picref};
                       set_sb($w, $max-$mm, $mm);
                               }
              )->pack(-side => "left");
               push @{ $w->{OBJECTS} }, $b_lst;

  push @{ $w->{OBJECTS} }, $frm_but;
    # push frames after their widgets so that destroy is applied
    # in reverse order ...

  my $frm_pan = $w->Frame()->pack;
  my $frm_pic = $frm_pan->Frame(-bg => $w->cget(-bg_color1) )->pack(-side => "left");

  $w->{ysb} = $frm_pan->Scrollbar( -command => [yview=>$w], );
  $w->{ysb} -> pack(-side => 'left', -fill => 'y');
  my $use_labels = $w->cget('-use_labels');
  my $row_fakt = $use_labels ? 2 : 1;

# print " === rows: $rows,  cols: $cols\n";

  for (my $i = 0; $i < $rows; $i++){
    for (my $j = 0; $j < $cols; $j++){
  #   push @{ $w->{OBJECTS} },
      $w->{Photo}->[$i][$j] = $w->Photo(-file => $w->{pic_path}."/vis-empty.gif");
      push @{ $w->{OBJECTS} },
      $w->{Thmb} ->[$i][$j] = $frm_pic->Label(
        -width  => 80,
        -height => 80,
        -background => $w->cget("-bg_color"),
        -image      => $w->{Photo}[$i][$j],
      ) -> grid( -column => $j, -row => $i*$row_fakt, 
                 -sticky => "w", -padx => 3, -pady => 3);

      if ($use_labels ) {
        $w->{Label}->[$i][$j] = "$i $j";
        push @{ $w->{OBJECTS} },
        $w->{Lbl} ->[$i][$j] = $frm_pic->Label(
        -width  => 12,
        -anchor => "center",
        -background => $w->cget("-bg_color"),
        -textvariable      => \$w->{Label}[$i][$j],
        ) -> grid( -column => $j, -row => $i*2 + 1, 
                 -sticky => "w", -padx => 3, -pady => 3);

      }


      my $kx = $i*($cols) + $j;
      my ($ii, $jj) = ($i, $j);
      $w->{Thmb}[$i][$j] ->bind("<Shift-Button-1>", sub{b1($w, $kx, 1)});
      $w->{Thmb}[$i][$j] ->bind("<Control-Button-1>", sub{b1($w, $kx, 2)});
      $w->{Thmb}[$i][$j] ->bind("<Double-Button-1>", sub{dbl_b1($w, $kx)});
      $w->{Thmb}[$i][$j] ->bind("<Double-Button-2>", sub{dbl_b2($w, $kx)});
      $w->{Thmb}[$i][$j] ->bind("<Double-Button-3>", sub{dbl_b3($w, $kx)});
      $w->{Thmb}[$i][$j] ->bind("<Button-1>", sub{b1($w, $kx)});
      $w->{Thmb}[$i][$j] ->bind("<Button-2>", sub{b2($w, $kx)});
      $w->{Thmb}[$i][$j] ->bind("<Button-3>", sub{b3($w, $kx)});

      $w->{Thmb}[$i][$j] ->bind("<ButtonRelease-1>", [\&b1_release, $w, $ii, $jj]);
   #  first parameter for b1_release is the widget handle of the thumbnail:
   #  $w->{Thmb}[$i][$j]

      $w->{Thmb}[$i][$j] ->bind("<B1-Motion>", [\&b1_motion, $w, $ii, $jj]);
    }
  }
  push @{ $w->{OBJECTS} }, $frm_pic;
  push @{ $w->{OBJECTS} }, $frm_pan;
  scroll($w, 0);  # loads the pictures

} # rebuild }}}

sub _move_selected { # {{{
  my ($w, $pos) = @_;
# print "move to pos $pos ...\n";

  # first of all: remove selected pics from array and save to a new array
  # calculate the insert position during this action.
  # Then insert new list at insert position.
  #
  my @MOVE_PICS;
  my $pos_back = $pos;

  # handle label texts {{{
  @MOVE_PICS = ();
  $pos = $pos_back;
  my $lref = $w->cget('-label_texts');
  if ($lref and ref($lref) eq 'ARRAY' and @$lref) {
    for (my $i = @{$w->{SEL}} -1; $i>=0; $i--){
        if ($w->{SEL}[$i]) {
          push @MOVE_PICS, splice( @{ $w->cget('-label_texts') }, $i, 1) ;
          $pos -- if $pos ne "end" and $pos > $i;
      }
    }
    if ($pos eq "end"){
      push @{ $w->cget('-label_texts') }, reverse @MOVE_PICS;
    } else {
      splice @{ $w->cget('-label_texts') }, $pos, 0, reverse @MOVE_PICS;
    }
  } # }}}

  # handle balloon texts {{{
  @MOVE_PICS = ();
  $pos = $pos_back;
  my $bref = $w->cget('-balloon_texts');
  if ($bref and ref($bref) eq 'ARRAY' and @$bref and $bref != $lref) {
    for (my $i = @{$w->{SEL}} -1; $i>=0; $i--){
        if ($w->{SEL}[$i]) {
          push @MOVE_PICS, splice( @{ $w->cget('-balloon_texts') }, $i, 1) ;
          $pos -- if $pos ne "end" and $pos > $i;
      }
    }
    if ($pos eq "end"){
      push @{ $w->cget('-balloon_texts') }, reverse @MOVE_PICS;
    } else {
      splice @{ $w->cget('-balloon_texts') }, $pos, 0, reverse @MOVE_PICS;
    }
  } # }}}

  # the same procedure has to be done for the pictures
  @MOVE_PICS = ();
  $pos = $pos_back;
  for (my $i = @{$w->{SEL}} -1; $i>=0; $i--){
      if ($w->{SEL}[$i]) {
        push @MOVE_PICS, splice( @{ $w->cget('-pictures') }, $i, 1) ;
        $pos -- if $pos ne "end" and $pos > $i;
    }
  }
  if ($pos eq "end"){
    push @{ $w->cget('-pictures') }, reverse @MOVE_PICS;
    scroll($w, $w->{posi});
  } else {
    splice @{ $w->cget('-pictures') }, $pos, 0, reverse @MOVE_PICS;
    scroll($w, $w->{posi});
  }

  deselect_all($w);

}# _move_selected }}}

# scrollbar handling

sub yview { # {{{
# print "yview call: @_\n";
  my $w = shift;
  my $dir = shift;


  my ($r,$c) = ($w->cget('-rows'), $w->cget('-cols'));
  my $mm = $r * $c;
  my $picref = $w->cget('-pictures');
  my $mmax = scalar(@{$picref});

  my $n;
  my $unit;
  if ($dir eq "moveto") {
     $n = shift;
#    print "   moveto --> $n\n";
     my $pos = int($n*$mmax);
       $pos = 0 if $pos < 0;
       $pos =  $mmax if $pos > $mmax;
     scroll($w, $pos);
     set_sb($w, $pos, $mm);
  } elsif ($dir eq "scroll") {
     $n = shift;
     $unit = shift;
#    print "  scroll  --> $n $unit\n";
     if ($n == 1){
       if ($unit eq "pages"){
         scroll($w, "nn");
         set_sb($w, $w->{posi}, $mm);
       } else {
         scroll($w, "n");
         set_sb($w, $w->{posi}, $mm);
       }
     } else {
       if ($unit eq "pages"){
         scroll($w, "pp");
         set_sb($w, $w->{posi}, $mm);
       } else {
         scroll($w, "p");
         set_sb($w, $w->{posi}, $mm);
       }
     }
  }
} # yview }}}

sub set_sb { # {{{
  my $w = shift;
  return unless defined $w->{ysb};
  my $val = shift;
  my $mm = shift;
  my $picref = $w->cget('-pictures');
  my $mmax = scalar(@{$picref}) || 1;
  $w->{ysb}->set(  $val/$mmax, ($val + $mm)/$mmax);
} # set_sb }}}

# option handlers

sub pictures { # {{{
  my ($w, $ref) = @_;

  if ($#_ > 0){ # configure
    @{$w->{SEL}} = map {0} @$ref;
    $w->{pictures} = $ref;
    set_sb($w, 0, $w->cget("-cols") * $w->cget("-rows"));
    scroll($w, 0);
  } else { # cget request
    $w->{pictures} 
  }
} # pictures }}}

sub balloon_texts { # {{{
  my ($w, $ref) = @_;

  if ($#_ > 0){ # configure
    $w->{balloon_texts} = $ref;
  } else { # cget request
    $w->{balloon_texts} 
  }
} # balloon_texts }}}

sub label_texts { # {{{
  my ($w, $ref) = @_;

  if ($#_ > 0){ # configure
    $w->{label_texts} = $ref;
  } else { # cget request
    $w->{label_texts} 
  }
} # label_texts }}}

sub rows { # {{{
  my ($w, $r) = @_;

  if ($#_ > 0){ # configure
    croak "number of rows must be greater 0\n" unless $r > 0;
    my $c_old = $w->{cols};
    my $r_old = $w->{rows};
    $w->{rows} = $r;
    rebuild($w, $r_old, $c_old);
    set_sb($w, 0, $w->cget("-cols") * $w->cget("-rows")) if defined $w->{pictures};
  } else { # cget request
    $w->{rows} 
  }
} # rows }}}

sub cols { # {{{
  my ($w, $c) = @_;

  if ($#_ > 0){ # configure
    croak "number of columns must be greater 0\n" unless $c > 0;
    my $c_old = $w->{cols};
    my $r_old = $w->{rows};
    $w->{cols} = $c;
    rebuild($w, $r_old, $c_old);
    set_sb($w, 0, $w->cget("-cols") * $w->cget("-rows")) if defined $w->{pictures};
  } else { # cget request
    $w->{cols} 
  }
} # cols }}}

# mouse button handlers


# Button Events:
sub b1 { # {{{
  my ($w, $pos, $sh) = @_;
  #  $w      Object Handle
  #  $pos    Position in Thumbs-Matrix: 0, 1, ..., cols*rows-1
  #  $sh     Shift-Button pressed
  #
  # select/deselect current picture
  my ($c, $r);
  $r = int($pos/$w->cget("-cols")); # current row
  $c = $pos%$w->cget("-cols");      # current column
# print " ---- b1: \n";

# print "shift-" if defined $sh;
# print "b1 pos: $pos   $c, $r\n";

  my $idx = list_index($w, $pos); # click position in PICS array

  my $sel = 0;
# Shift-Klick
# ===========
  if (defined $sh and $sh == 1){ # select area
    # ersten und letzten selection index ermitteln:
    $w->{SEL}[$idx] = 1;
    my ($i1, $i2) = (9999999, -1);
    for ( my $z = 0; $z <= $#{$w->{pictures}}; $z++ ){
      if ( $w->{SEL}[$z]){
        $i1 = $z; last;
      }
    }
    for ( my $z = $#{$w->{pictures}}; $z >=0; $z-- ){
      if ( $w->{SEL}[$z]){
        $i2 = $z; last;
      }
    }
#   print "**1 $i1 bis $i2\n";
    if ($idx < $i1) {
      $i1 = $idx;
    }
    if ($idx > $i1) {
      $i2 = $idx;
    }
#   print "**2 $i1 bis $i2\n";

    # erst mal alle deselektieren
    for ( my $z = 0; $z <= $#{$w->{pictures}}; $z++ ){
      $w->{SEL}[$z] = 0;
      _select_pic($w, $z, 0);
    }
    # dann den Bereich selektieren
    for ( my $z = $i1; $z <= $i2; $z++ ){
      $w->{SEL}[$z] = 1;
      _select_pic($w, $z, 1);
    }

# Ctrl-Klick
# ==========
  } elsif (defined $sh and $sh == 2){ # ctrl B1, add/remove
#   print "##### ctrl     \n";
    $w->{SEL}[$idx] = 1 - $w->{SEL}[$idx] if $idx > -1;
    my $relief = _is_selected($w, $pos) ? "groove" : "flat";
    my $picref = $w->cget('-pictures');
    my $special_color = $w->Callback(-special_color => $$picref[$idx]) || $w->cget("-bg_color");;
    my $color  = _is_selected($w, $pos) ? $w->cget("-active_color") : $special_color;
    $w->{Thmb}[$r][$c] ->configure(
       -relief =>$relief,
       -background => $color,
    );

# Button-1
# ========
  } else { # single select
# wenn man in ein nicht selektierte Bils kilckt:
# neues Bild wird als einziges selektiert
    if (! $w->{SEL}[$idx]) {
      for ( my $z = 0; $z <= $#{$w->{pictures}}; $z++ ){
        $w->{SEL}[$z] = 0;
        _select_pic($w, $z, 0);
      }
      _select_pic($w, $idx, 1);
      $w->{SEL}[$idx] = 1;
    } else {
# andernfalls: klick auf selektiertes Bild:
# gehe in den MOVE-Zustand: Aktuelle Auswahl wird via
# B1-Motion bewegt:
      $state = MOVE;
# Cursor ändern:
      $save_cursor = $w->MainWindow->cget('-cursor');
      $cursor = 'mouse';
      if ($^O !~ /Win/i){
        if (scalar get_selected($w) == 1){
          $cursor = ['@'. $w->{pic_path} ."/move1.xbm" ,
                          $w->{pic_path} ."move1_mask.xbm", $w->cget(-cursor_bg), $w->cget(-cursor_fg)];
        } else {
          $cursor = ['@'. $w->{pic_path} ."/move.xbm" , 
                          $w->{pic_path} ."move_mask.xbm", $w->cget(-cursor_bg), $w->cget(-cursor_fg)];
        }
      }
      $w->MainWindow->configure(-cursor => $cursor);
    }
  }

  # Call user's b1 handler if applicable:
  my $jpg =  ${$w->{pictures}}[$idx];
  $w->Callback( -b1_handler => $jpg);
} # b1 }}}

sub b1_motion { # {{{

  my ($thb, $w, $ii, $jj) = @_;
  return unless $state == MOVE; # only then ...

  my $rows = $w->cget('-rows');
  my $cols = $w->cget('-cols');
  my $e = $thb->XEvent;  # coordinates relativ to Thmb Label !!


THMB:
    for (my $i = 0; $i < $rows; $i++){
      for (my $j = 0; $j < $cols; $j++){
        my $idx = $w->{posi} + $i * $cols + $j;
        my $upper_left_x = $w->{Thmb}[$i][$j]->x;
        my $upper_left_y = $w->{Thmb}[$i][$j]->y;
        my $width  = $w->{Thmb}[$i][$j]->width;
        my $height = $w->{Thmb}[$i][$j]->height;
        if (_enclosed($upper_left_x, $upper_left_y,
            $width, $height, 
            $e->x + $jj * $width,    # auf linkes oberes Label beziehen ...
            $e->y + $ii * $height))  # daher Korrektursummanden ...
        {
          # highlight background
          $w->{Thmb}[$i][$j]  -> configure(
                                         -background =>$w->cget("-highlight"),
                                         -relief => "sunken",
                              );
        } elsif ($w->{SEL}[$idx] ) {
          # selection background for thumbs which are selected
          $w->{Thmb}[$i][$j]  -> configure(
                                         -background => $w->cget("-active_color"),
                                         -relief => "groove",
                              );
        } else {
          # normal background for thumbs which are not selected
          my $picref = $w->cget('-pictures');
          my $special_color = $w->Callback(-special_color => $$picref[$idx]) || $w->cget("-bg_color");;
          $w->{Thmb}[$i][$j]  -> configure(
                                         -background => $special_color,
                                         -relief => "flat",
                              );
        }
      }
    } 


# scroll when we approche the lower margin
#
  my $mm = $rows * $cols;
  my $height =$thb->height;
  my $y_pos = $e->y + $ii*$height;
  if ( $y_pos < $height/2 ){
#   print " <<<<<<\n";
    if ($w->{up}) {
      $w->scroll("p");
      set_sb($w, $w->{posi}, $mm);
      $w->{up} = 0;
    }
  } elsif ($y_pos > $height*0.55) { # Hysterese
      $w->{up} = 1;
  }
  if ( $y_pos >  $rows * $height - $height/2 ){
#   print " >>>>>>\n";
    if ($w->{down}) {
      $w->scroll("n");
      set_sb($w, $w->{posi}, $mm);
      $w->{down} = 0;
    }
  } elsif ( $y_pos < $rows*$height - 0.55*$height) { # Hysterese
      $w->{down} = 1;
  }

  # update cursor image
  $w->MainWindow->configure(-cursor => $cursor);
} # b1_motion }}}

sub b1_release { # {{{
  my ($thb, $w, $ii, $jj) = @_;
  if ($state == MOVE) {
# Versuche herauszubekommen, über welchem Label sich der
# Cursor gerade befindet:
    my $e = $thb->XEvent;  # Koordinaten relativ zum Thumb Label !!
#   print "x: ", $e->x, "  y: ", $e->y, "\n";
# ok, soweit so gut. Jetzt muss man die Koordiaten mit den umfassenden
# Rechtecken aller Thmb Labels vergleichen und daraus die Release-Position
# eritteln:
    my $rows = $w->cget('-rows');
    my $cols = $w->cget('-cols');
THMB:
    for (my $i = 0; $i < $rows; $i++){
      for (my $j = 0; $j < $cols; $j++){
        my $upper_left_x = $w->{Thmb}[$i][$j]->x;
        my $upper_left_y = $w->{Thmb}[$i][$j]->y;
        my $width  = $w->{Thmb}[$i][$j]->width;
        my $height = $w->{Thmb}[$i][$j]->height;
    #   print " ux $upper_left_x, uy $upper_left_y\n";
        my $kx = $cols * $i + $j;
        if (_enclosed($upper_left_x, $upper_left_y,
            $width, $height, 
            $e->x + $jj * $width,    # auf linkes oberes Label beziehen ...
            $e->y + $ii * $height))  # daher Korrektursummanden ...
        {
#           print " #### $kx\n" ;
            my $idx = list_index($w, $kx); # click position in PICS array
            _move_selected($w, $idx);
            last THMB;
        }
      }
    } 
  }
  $state = NORMAL;
  $w->MainWindow->configure(-cursor => $save_cursor);
} # b1_release }}}

sub _enclosed { # {{{
  # check, if ($x, $y) is within the rectangle
  my ($ulx, $uly, $width, $height, $x, $y) = @_;
  return 1 if
    $ulx <= $x and $x <= $ulx + $width and
    $uly <= $y and $y <= $uly + $height;
  return 0;
} # _enclosed }}}

sub b2 { # {{{
  my ($w, $pos) = @_;
  my $idx = list_index($w, $pos); # click position in PICS array
  # Call user's b1 handler if applicable:
  my $jpg =  ${$w->{pictures}}[$idx];
# print " ---- b2: $jpg\n";
  $w->Callback( -b2_handler => $jpg);
} # b2 }}}

sub b3 { # {{{
  my ($w, $pos) = @_;
  my $idx = list_index($w, $pos); # click position in PICS array
  # Call user's b1 handler if applicable:
  my $jpg =  ${$w->{pictures}}[$idx];
# print " ---- b3: $jpg\n";
  $w->Callback( -b3_handler => $jpg);
} # b3 }}}

sub dbl_b1 { # {{{
  my ($w, $pos) = @_;
  my $idx = list_index($w, $pos); # click position in PICS array
  my $jpg =  ${$w->cget("-pictures")}[$idx];
# print " ---- dbl_b1: $jpg\n";

  # select only current picture:
  _select_only($w, $pos);
  
  # Call user's double-b1 handler if applicable:
# $jpg =  ${$w->{pictures}}[$idx];
  $w->Callback( -double_b1_handler => $jpg);
} # dbl_b1 }}}

sub dbl_b2 { # {{{
  my ($w, $pos) = @_;
  my $idx = list_index($w, $pos); # click position in PICS array
  my $jpg =  ${$w->{pictures}}[$idx];
# print " ---- dbl_b2: $jpg\n";

  # select only current picture:
  _select_only($w, $pos);
  
  # Call user's double-b2 handler if applicable:
  $w->Callback( -double_b2_handler => $jpg);
} # dbl_b2 }}}

sub dbl_b3 { # {{{
  my ($w, $pos) = @_;
  my $idx = list_index($w, $pos); # click position in PICS array
  my $jpg =  ${$w->{pictures}}[$idx];
# print " ---- dbl_b3: $jpg\n";

  # select only current picture:
  _select_only($w, $pos);
  
  # Call user's double-b3 handler if applicable:
  $w->Callback( -double_b3_handler => $jpg);
} # dbl_b3 }}}

#  auxiliary functions

sub _is_selected { # {{{
  my ($w, $pos) = @_;
  my $idx = list_index($w, $pos);
  return 0 if $idx < 0;
  return $w->{SEL}[$idx];
} # _is_selected }}}

sub _select_pic { # {{{
  my ($w, $z, $sel) = @_;
  #  $z    position in PICs array
  #  $sel  select/deselect
  return if $z < $w->{posi} 
         or $z > $w->{posi}+$w->cget("-rows")*$w->cget("-cols")-1;

  my $pos = $z - $w->{posi};  # position in thumbs matrix
  my ($c, $r);
  $r = int($pos/$w->cget("-cols")); # current row
  $c = $pos%$w->cget("-cols");      # current column
# print "_select_pic: $r, $c  z: $z pos: $pos\n";
  my $relief = $sel ? "groove" : "flat";
          my $picref = $w->cget('-pictures');
          my $special_color = $w->Callback(-special_color => $$picref[$z]) || $w->cget("-bg_color");;
  my $color  = $sel ? $w->cget("-active_color") : $special_color;
  return unless defined $w->{Thmb}[$r][$c];
  $w->{Thmb}[$r][$c] ->configure(
       -relief => $relief,
       -background => $color,
  );
} # _select_pic }}}

sub _select_only { # {{{
  my ($w, $pos) = @_;
  # select only current picture:
  for ( my $z = 0; $z <= $#{$w->{pictures}}; $z++ ){
    $w->{SEL}[$z] = 0;
    _select_pic($w, $z, 0);
  }
  _select_pic($w, $pos, 1);
  $w->{SEL}[$pos] = 1;
} # _select_only }}}

sub trim_pos{ # {{{
  # calculate position in PICS array, check boundaries
  my ($w, $pos) = @_;
  return 0 if $pos < 0;
  my $picref = $w->cget('-pictures');
  my $max = scalar(@{$picref});
  return $max if $pos > $max;
  return $pos;
} # trim_pos }}}

sub list_index { # {{{
  # Position of current pic in list PICS
  my ($w, $pos) = @_;
  my $idx = $w->{posi}+$pos;
  my $picref = $w->cget('-pictures');
  my $max = scalar(@{$picref});
  return -1 if $idx > $max;
  return $idx;
} # list_index }}}

1;

__END__

# POD {{{

=head1 AUTHOR

Lorenz Domke, E<lt>lorenz.domke@gmx.deE<gt>

=head1 BUGS AND KNOWN ISSUES

Sure you will find some ...

Most important: it is not possible to specify the rows and columns during instantiation:

 $vb = $parent->VisualBrowser(-rows => 3, -cols => 4);

does not work! You B<must> configure rows and columns after that:

 $vb->configure(-rows => 3, -cols => 4);

It is not yet possible to use PNG files or other formats for the
thumbnail pictures. Maybe in one of the next releases.

The options C<-use_labels> and C<-use_balloons> must be specified durung instantiation:

 $vb = $parent->VisualBrowser(-use_labels => 1, -use_balloons => 1);

It is not possible to change this via $vb->configure.
 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Lorenz Domke

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

# }}}

 vim:ft=perl:foldmethod=marker:foldcolumn=4


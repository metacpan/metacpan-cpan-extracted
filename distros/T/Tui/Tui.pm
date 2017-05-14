#
# Tui.pm
# (c) 1999 R.F. Lens, All rights reserved
#
# This program is free softeware, you can redistribute it
# and/or modify it under the same terms as Perl itself
#
# If something doesn't work, email me at ronald@ronaldlens.com but don't
# blame and/or flame me please;)
#
# inspired by the PV module by Ashish Gulhati
#
# version 0.4 Aug 20, 1999
#


=head1 NAME

  Tui - Text user interface toolkit

=head1 SYNSOPSIS

  #!/usr/bin/perl
  use Curses;
  use Tui;

  Tui::init;
  Tui::background;
  refresh;
  Tui::msgbox("Title","Message");
  
  my ($label) = new Tui::Label("Label",2,2);
  my ($entry) = new Tui::Entryfield("Name",2,4,20,20);
  my ($ok) = new Tui::Button("OK",18,5);
  my ($form) = new Tui::Form("A form",1,1,27,10,1);
  $form->add($label,$entry,$ok);
  my ($result,$widgetno) = $form->run;
  my ($name) = $entry->data;
  
  endwin;
  print "your name is $name\n";


=head1 GENERAL FUNCTIONS

Described here are some general functions which can be used in 
a script. They're also used within the other objects.

=cut

# make sure we're in the right package
# use the Curses module

package Tui;
use Curses;

=head2 Tui::init

Initializes some stuff needed for operating the Tui toolkit.

=over 2

=item Input Parameters

 1 none

=item Output Parameters

 1 none

=back

=cut     

sub init {

  # initialize curses
  # set tty to raw mode
  # no echo of keystrokes
  # set keypad on
  # try to define colors

  initscr();
  raw();
  noecho();
  eval {
    keypad(1);
  };
  eval {
    start_color();
    init_pair(1,COLOR_BLACK,COLOR_WHITE);
    init_pair(2,COLOR_WHITE,COLOR_WHITE);
    init_pair(3,COLOR_BLACK,COLOR_CYAN);
    init_pair(4,COLOR_WHITE,COLOR_CYAN);
    init_pair(5,COLOR_BLUE,COLOR_WHITE);
    init_pair(6,COLOR_WHITE,COLOR_BLUE);
    init_pair(7,COLOR_BLUE,COLOR_CYAN);
  };
}

=head2 Tui::background

=over 2

=item Input Parameters

  1 color (defaults to 1)

=item Output Parameters

  1 none


=back

=cut

sub background {

  # get the color

  my ($color) = shift || 1;

  # set the attribute to the color
  # for each line
  # draw a horizontal line

  attron(COLOR_PAIR($color));
  foreach (0..$LINES-1) {
    move($_,0);
    hline(" ",$COLS);
  }
}

=head2 Tui::drawbox

Draws a box.

=over 2

=item Input Parameters

  1 x1,y1 topleft coordinate
  3 x2,y2 bottomright coordinate
  4 color
  6 style raised or lowered
  7 window (defaults to stdscr)
  8 keepclear, if true doesn't clear inside

=item Output Parameters

  1 none


=back

=cut

sub drawbox {

  # get parameters

  my ($x1) = shift;
  my ($y1) = shift;
  my ($x2) = shift;
  my ($y2) = shift;
  my ($color) = shift;
  my ($style) = shift;
  my ($window) = shift;
  my ($keepclear) = shift;

  # get number of lines

  my ($lines) = $x2 - $x1;
  my ($j);
  my ($TOPL,$BOTR);
  
  # set the style attribute

  if ($style) {
    $TOPL=1; 
    $BOTR=0
  } else {
    $TOPL=0; 
    $BOTR=1
  }
  
  # draw it

  move ($window,$y1,$x1); 
  attron ($window,COLOR_PAIR(1+$TOPL+$color*2));
  $TOPL ? attron ($window,A_BOLD) : attroff ($window,A_BOLD);
  addch ($window,ACS_ULCORNER); hline ($window,ACS_HLINE, $lines-1); 
  attron ($window,COLOR_PAIR(1+$BOTR+$color*2));
  $BOTR ? attron ($window,A_BOLD) : attroff ($window,A_BOLD);
  move ($window,$y1,$x1+$lines); 
  addch ($window,ACS_URCORNER); 
  move ($window,$y1+1,$x1);
  attron ($window,COLOR_PAIR(1+$TOPL+$color*2));
  $TOPL ? attron ($window,A_BOLD) : attroff ($window,A_BOLD);
  vline ($window,ACS_VLINE, $y2-$y1-1);
  move ($window,$y1+1,$x1+$lines);
  attron ($window,COLOR_PAIR(1+$BOTR+$color*2));
  $BOTR ? attron ($window,A_BOLD) : attroff ($window,A_BOLD);
  vline ($window,ACS_VLINE, $y2-$y1-1);
  move ($window,$y2,$x1); 
  attron ($window,COLOR_PAIR(1+$TOPL+$color*2));
  $TOPL ? attron ($window,A_BOLD) : attroff ($window,A_BOLD);
  addch ($window,ACS_LLCORNER); 
  attron ($window,COLOR_PAIR(1+$BOTR+$color*2));
  $BOTR ? attron ($window,A_BOLD) : attroff ($window,A_BOLD);
  hline ($window,ACS_HLINE, $lines-1);
  move ($window,$y2,$x1+$lines); 
  addch ($window,ACS_LRCORNER); 

  # if !keep clear
  # fill the window with spaces

  if (!$keepclear) {
    for ($j=$y1+1; $j<$y2; $j++) {
      move ($window,$j,$x1+1);
      addstr ($window," " x ($lines-1));
    }
  }
  
  # turn of bold attr

  attroff ($window,A_BOLD);
}

=head2 Tui::xyprint

Prints a line on a certain position in a certain color.

=over 2

=item Input Parameters

  1 x coordinate where to print
  2 y coordinate where to print
  3 line, the text to print
  4 color, (defaults to 1)
  5 bold, flag whether to use bold

=item Output Parameters

  1 


=back

=cut

sub xyprint {
  
  # get the arguments

  my ($x) = shift;
  my ($y) = shift;
  my ($line) = shift;
  my ($color) = shift | 1;
  my ($bold) = shift;

  # set the color
  # set bold if need be
  # move to the place
  # write the string
  # turn off bold attr

  attron(COLOR_PAIR($color));
  ($bold) &&(attron(A_BOLD));
  move($y,$x);
  addstr($line);
  attroff(A_BOLD);
}

=head2 Tui::vscrollbar

Draws a vertical scrollbar

=over 2

=item Input Parameters

  1 x coordinate at the top
  2 y coordinate at the top
  3 height, the height
  4 total, the total of the scale
  5 pos, position of thumbnail within the scale
  6 color (defaults to 1)
  7 win (defaults to stdscr)

=item Output Parameters

  1 none

=back

=cut

sub vscrollbar {
  
  # fetch the arguments

  my ($x) = shift;
  my ($y) = shift;
  my ($height) = shift;
  my ($total) = shift;
  my ($pos) = shift;
  my ($color) = shift || 1;
  my ($window) = shift || stdscr;
  my ($thumbpos);

  # move to the right location
  # set the color
  # draw a vertical line of checkerboard chars
  # calculate the thumbnail positions
  # correct it if it is past the end
  # move to the thumbnail position
  # set the bold attr
  # write the thumbnail
  # turn off the bold attr

  move($window,$y,$x);
  attron($window,COLOR_PAIR($color));
  vline($window,ACS_CKBOARD,$height);
  $total = ($total == -1) ? 0 : $total;
  $thumbpos = int($height * $pos / ($total+1));
  $thumbpos = ($thumbpos > $height - 1) ? $height - 1 : $thumbpos;
  move($window,$y + $thumbpos,$x);
  attron($window,A_BOLD);
  addch($window,ACS_CKBOARD);
  attroff($window,A_BOLD);
}

=head2 Tui::hscrollbar

Draws a horizontal scrollbar

=over 2

=item Input Parameters

  1 x coordinate at the left
  2 y coordinate at the left
  3 length, the length
  4 total, the total of the scale
  5 pos, position of thumbnail within the scale
  6 color (defaults to 1)
  7 win (defaults to stdscr)

=item Output Parameters

  1 none

=back

=cut

sub hscrollbar {
  my ($x) = shift;
  my ($y) = shift;
  my ($length) = shift;
  my ($total) = shift;
  my ($pos) = shift;
  my ($color) = shift || 1;
  my ($window) = shift || stdscr;
  my ($thumbpos);

  # move to the right location
  # set the color
  # draw a horizontal line of checkerboard chars
  # calculate the thumbnail positions
  # correct it if it is past the end
  # move to the thumbnail position
  # set the bold attr
  # write the thumbnail
  # turn off the bold attr

  move($window,$y,$x);
  attron($window,COLOR_PAIR($color));
  hline($window,ACS_CKBOARD,$length);
  $total = ($total == -1) ? 0 : $total;
  $thumbpos = int($length * $pos / ($total+1));
  $thumbpos = ($thumbpos > $length - 1) ? $length - 1 : $thumbpos;
  move($window,$y, $x + $thumbpos);
  attron($window,A_BOLD);
  addch($window,ACS_CKBOARD);
  attroff($window,A_BOLD);
}


=head2 Tui::getkey

Retrieves the keycode and key.

=over 2

=item Input Parameters

  1 none

=item Output Parameters

  1 key, contains the actual key
  2 keycode, contains a code for special keys

=item Keycodes

  1   home
  2   insert
  3   delete
  4   end
  5   pageup
  6   pagedown
  7   up
  8   down
  9   right
  10  left
  11  backspace
  12  M-q
  13  M-b
  14..M-d
  15  M-v    
  16  M-<    
  17  M->    
  18  M-h    
  19  M-x    
  20  M-f    
  21  M-i    
  22  M-w    
  23  M-a    
  24  M-e    
  50  M-enter
  200  $key gives the keypress as a character  

=back

=cut

sub getkey {			# Gets a keystroke and returns a code
  my $key = getch();		# and the key if it's printable.
  my $keycode = 0;
  if ($key == KEY_HOME) {
    $keycode = 1;
  } elsif ($key == KEY_IC) {
    $keycode = 2;
  } elsif ($key == KEY_DC) {
    $keycode = 3;
  } elsif ($key == KEY_END) {
    $keycode = 4;
  } elsif ($key == KEY_PPAGE) {
    $keycode = 5;
  } elsif ($key == KEY_NPAGE) {
    $keycode = 6;
  } elsif ($key == KEY_UP) {
    $keycode = 7;
  } elsif ($key == KEY_DOWN) {
    $keycode = 8;
  } elsif ($key == KEY_RIGHT) {
    $keycode = 9;
  } elsif ($key == KEY_LEFT) {
    $keycode = 10;
  } elsif ($key == KEY_BACKSPACE) {
    $keycode = 11;
  } elsif ($key eq "\e") {
    $key = getch();
    if ($key =~ /[WwBbFfIiQqVv<>DdXxHhAaEe \n]/) { # Meta keys
      ($key =~ /[Qq]/) && ($keycode = 12);   # M-q
      ($key =~ /[Bb]/) && ($keycode = 13);   # M-b
      ($key =~ /[Dd]/) && ($keycode = 14);   # M-d
      ($key =~ /[Vv]/) && ($keycode = 15);   # M-v
      ($key eq "<")    && ($keycode = 16);   # M-<
      ($key eq ">")    && ($keycode = 17);   # M->
      ($key =~ /[Hh]/) && ($keycode = 18);   # M-h
      ($key =~ /[Xx]/) && ($keycode = 19);   # M-x
      ($key =~ /[Ff]/) && ($keycode = 20);   # M-f
      ($key =~ /[Ii]/) && ($keycode = 21);   # M-i
      ($key =~ /[Ww]/) && ($keycode = 22);   # M-w
      ($key =~ /[Aa]/) && ($keycode = 23);   # M-a
      ($key =~ /[Ee]/) && ($keycode = 24);   # M-e
      ($key =~ /[ \n]/) && ($keycode = 50);  # M-enter
    } else {
     $keycode = 100;
    }
  } elsif($key =~ /[A-Za-z0-9_ \t\n\r~\`!@#\$%^&*()\-+=\\|{}[\];:'"<>,.\/?]/) {
    ($keycode = 200);
  }
  return ($key, $keycode);
}

=head2 Tui::msgbox

Draws a message box with an OK button.

=over 2

=item Input Parameters

  1 title
  2 text of the message

=item Output Parameters

  1 none

=back

=cut

sub msgbox {
  my ($title) = shift | "";
  my ($text) = shift;
  my ($center) = shift;
  
  my ($x,$y,$c,$r);
  my (@lines) = split(/\n/,$text);
  my ($maxlength) = 0;
  foreach (@lines) {
    $maxlength = (length($_) > $maxlength) ? length($_) : $maxlength;
  }
  $maxlength = ($maxlength < 18) ? 20 : $maxlength + 2;

  my ($label) = new Tui::Label($text,2,1);
  my ($ok) = new Tui::Button("OK", int($maxlength / 2) - 2,$#lines + 3);
  $x = int($COLS / 2) - int($maxlength / 2);
  $y = int($LINES / 2) - int($#lines + 5);
  $c = $maxlength + 1;
  $r = $#lines + 6;
  my ($form) = new Tui::Form($title,$x,$y,$c,$r);
  $form->add($label,$ok)->exitonenter->exitonaltenter->run;
}

=head2 Tui::yesnobox

Draws a dialog with Yes and No buttons.

=over 2

=item Input Parameters

  1 title
  2 text of the message

=item Output Parameters

  1 result, 1 is yes, 0 is no


=back

=cut

sub yesnobox {
  my ($title) = shift | "";
  my ($text) = shift;
  
  my ($x,$y,$c,$r);
  my (@lines) = split(/\n/,$text);
  my ($maxlength) = 0;
  foreach (@lines) {
    $maxlength = (length($_) > $maxlength) ? length($_) : $maxlength;
  }
  $maxlength = ($maxlength < 18) ? 20 : $maxlength + 2;

  my ($label) = new Tui::Label($text,2,1);
  my ($ok) = new Tui::Button("Yes", int($maxlength / 2) + 4,$#lines + 3);
  my ($cancel) = new Tui::Button("No", int($maxlength / 2) - 3, $#lines + 3);
  $x = int($COLS / 2) - int($maxlength / 2);
  $y = int($LINES / 2) - int($#lines + 5);
  $c = $maxlength + 1;
  $r = $#lines + 6;
  my ($form) = new Tui::Form($title,$x,$y,$c,$r);
  $form->add($label,$ok,$cancel)->exitonenter->exitonaltenter;
  if (($form->run)[1] == 1) {
    return 1;
  } else {
    return 0;
  }

}

=head2 Tui::okcancelbox

Draws a dialog box with OK and Cancel buttons

=over 2

=item Input Parameters

  1 title
  2 message in the box

=item Output Parameters

  1 result, 1 for ok, 0 for cancel

=back

=cut

sub okcancelbox {
  my ($title) = shift | "";
  my ($text) = shift;
  
  my ($x,$y,$c,$r);
  my (@lines) = split(/\n/,$text);
  my ($maxlength) = 0;
  foreach (@lines) {
    $maxlength = (length($_) > $maxlength) ? length($_) : $maxlength;
  }
  $maxlength = ($maxlength < 18) ? 20 : $maxlength + 2;

  my ($label) = new Tui::Label($text,2,1);
  my ($ok) = new Tui::Button("OK", int($maxlength / 2) + 3,$#lines + 3);
  my ($cancel) = new Tui::Button("Cancel", int($maxlength / 2) - 7, 
    $#lines + 3);
  $x = int($COLS / 2) - int($maxlength / 2);
  $y = int($LINES / 2) - int($#lines + 5);
  $c = $maxlength + 1;
  $r = $#lines + 6;
  my ($form) = new Tui::Form($title,$x,$y,$c,$r);
  $form->add($label,$ok,$cancel)->exitonenter->exitonaltenter;
  if (($form->run)[1] == 1) {
    return 1;
  } else {
    return 0;
  }

}

=head2 Tui::entrybox

Provide a simple dialog to enter a string.

=over 2

=item Input Paramters

  1 title
  2 label text
  3 prompt
  4 length of the entrypart (defaults to 20)
  5 maxlength of the entry (defaults to 20)
  6 whether it is a password (* will be echoed)
  7 whether to use a cancel button
  8 default text (optional)

=item Ouput Parameters

  if no cancel button :                                
  1 the entry
  otherwise 
  1 the entry
  2 result (1 = ok, 0 is cancel pressed)

=back

=cut

sub entrybox {
  my ($title) = shift;
  my ($labeltext) = shift;
  my ($prompt) = shift;
  my ($length) = shift | 20;
  my ($maxlength) = shift | 20;
  my ($ispassword) = shift;
  my ($usecancel) = shift;
  my ($defaulttext) = shift;

  my ($result,$exitcode,$widgetno);
  my ($x,$y,$c,$r,$width);
  
  # we're at least 6 rows high
  # we're as wide as the length of the entry thingie + 4
  # if there is a label
  # make it to an array (for getting dimensions)
  # increase height by number of lines in label
  # get the maximum width and adjust dialog if need be
  # center the dialog 

  $r = 6;
  $c = length($prompt) + $length + 4;
  $width = length($prompt);
  if ($labeltext) {
    my (@lines) = split(/\n/,$labeltext);
    $r += 1 + $#lines;
    foreach (@lines) {
      if (length($_) + 4 > $c ) {
        $c = length($_) + 4;
      }
    }
  }
  
  $x = int($COLS / 2) - int ($c / 2);
  $y = int($LINES / 2) - int ($r / 2);

  # create the form
  # allow it to exit on enter
  # if there is a labeltext create label and add it to the dialog

  my ($dialog) = new Tui::Form($title,$x,$y,$c,$r);
  $dialog->exitonenter;
  if ($labeltext) {
    my ($label) = new Tui::Label($labeltext,2,1);
    $dialog->add($label);
  }

  # create the entryfield, passwordfield if need be
  # add it to the form

  my ($entry);
  if ($ispassword) {
    $entry = new Tui::Passwordfield($prompt,2,$r - 4,$length,$maxlength,
      $defaulttext);
  } else {
    $entry = new Tui::Entryfield($prompt,2,$r - 4,$length,$maxlength,
      $defaulttext);
  }
  $dialog->add($entry);

  # if we're to have a cancel button
  # create and add it
  # create the ok button and add it

  if ($usecancel) {
    my ($cancel) = new Tui::Button("Cancel",$c - 18, $r - 3);
    $dialog->add($cancel);
  }
  my ($ok) = new Tui::Button("OK",$c - 6,$r - 3);
  $dialog->add($ok);

  # run the dialog
  # get the entry
  # if there is a cancel button, check whether it was pressd
  # and return the results (compensate for possible label)
  # otherwise just return the entry

  ($result,$widgetno) = $dialog->run;
  my ($entrytext) = $entry->data;
  if ($usecancel) {
    if ($labeltext) {
      $exitcode = ($widgetno == 2) ? 0 : 1;
    } else {
      $exitcode = ($widgetno == 1) ? 0 : 1;
    }
    return ($entrytext,$exitcode);
  } else {
    return $entrytext;
  }
}

########################################################

=head1 CLASS Tui::Widget

an abstract class from which all other widgets are derived

=cut

package Tui::Widget;

=head2 Tui::Widget::new

Constructor

=over 2

=item Input Paramters

  1 none

=item Ouput Parameters

  1 reference to object

=back

=cut

sub new {
  my ($class) = shift;
  my ($self) = {};
  bless $self,$class;
  $self;
}

=head2 Tui::Widget::exitonaltx

Sets the flag that will make the widget exit when alt-X is pressed

=over 2

=item Input Paramters

  1 none

=item Ouput Parameters

  1 reference to object

=back

=cut

sub exitonaltx {
  my ($self) = shift;
  $self->{exitonaltx} = 1;
  $self;
}

=head2 Tui::Widget::exitonalth

Sets the flag that will make the widget exit when alt-H is pressed

=over 2

=item Input Paramters

  1 none

=item Ouput Parameters

  1 reference to object

=back

=cut

sub exitonalth {
  my ($self) = shift;
  $self->{exitonalth} = 1;
  $self;
}

=head2 Tui::Widget::exitonaltenter

Sets the flag that will make the widget exit when alt-enter is pressed

=over 2

=item Input Paramters

  1 none

=item Ouput Parameters

  1 reference to object

=back

=cut


sub exitonaltenter {
  my ($self) = shift;
  $self->{exitonaltenter} = 1;
  $self;
}

=head2 Tui::Widget::exitonenter

Sets the flag that will make the widget exit when enter is pressed

=over 2

=item Input Paramters

  1 none

=item Ouput Parameters

  1 reference to object

=back

=cut


sub exitonenter {
  my ($self) = shift;
  $self->{exitonenter} = 1;
  $self;
}

=head2 Tui::Widget::setwin

Sets $self->{win} to a supplied window.

=over 2

=item Input Paramters

  1 window

=item Ouput Parameters

  1 reference to object

=back

=cut

sub setwin {
  my ($self) = shift;
  my ($win) = shift;
  $self->{win} = $win;
  $self;
}

=head2 Tui::Widget::runnable

returns whether this widget is runnable, labels and boxes are not.

=over 2

=item Input Paramters

  1 none

=item Ouput Parameters

  1 boolean whether widget is runnable

=back

=cut

sub runnable {
  my ($self) = shift;
  return 1;
}


########################################################

=head1 CLASS Tui::Label

Provides a label widget. It can contain several newlines as long
as it fits within the provided coordinates.

Inherits from L<CLASS Tui::Widget>.

=cut

package Tui::Label;


use Curses;

@ISA = (Tui::Widget);

=head2 Tui::Label::new

Constructor of this class.

=over 2

=item Input Paramters

  1 text which is to be printed
  2,3 x,y coordinates
  4 color (defaults to 1)


=item Ouput Parameters

  1 reference to object

=back

=cut

sub new {
  my ($class) = shift;
  my ($self) = {};
  bless $self,$class;

  $self->{text} = shift;
  $self->{x1} = shift;
  $self->{y1} = shift;
  $self->{color} = shift | 1;
  $self->{win} = stdscr;
  $self;
}

=head2 Tui::Label::draw

Draws the widget.

=over 2

=item Input Paramters

  1 none

=item Ouput Parameters

  1 reference to object

=back

=cut

sub draw {
  my ($self) = shift;

  my (@lines) = split/\n/,$self->{text};
  attron($self->{win},COLOR_PAIR($self->{color}));
  foreach (0..$#lines) {
    move($self->{win},$self->{y1}+$_,$self->{x1});
    addstr($self->{win},$lines[$_]);
  }
  $self;
}

=head2 Tui::Label::runnable

Returns whether widget is runnable.

=over 2

=item Input Paramters

  1 none

=item Ouput Parameters

  1.0, widget is not runnable

=back

=cut

sub runnable {
  my ($self) = shift;
  return 0;
}

########################################################

=head1 CLASS Tui::Box

A box, does nothing besides being boxlike;)

Inherits from L<CLASS Tui::Widget>.

=cut

package Tui::Box;


use Curses;
@ISA = (Tui::Widget);

=head2 Tui::Box::new

Constructor for the box widget

=over 2

=item Input Paramters

  1 x coordinate of left top
  2 y coordinate of left top
  3 number of columns
  4 number of rows
  5 color
  6 style (raised or lowered)

=item Ouput Parameters

  1

=back

=cut

sub new {
  my ($class) = shift;
  my ($self) = {};
  bless $self,$class;

  $self->{x1} = shift;
  $self->{y1} = shift;
  $self->{cols} = shift;
  $self->{rows} = shift;
  $self->{color} = shift;
  $self->{style} = shift;
  $self->{win} = stdscr;
  $self;
}

=head2 Tui::Box::draw

Draws the box

=over 2

=item Input Paramters

  1 none

=item Ouput Parameters

  1 reference of the object

=back

=cut

sub draw {
  my ($self) = shift;
  
  Tui::drawbox($self->{x1},$self->{y1}, $self->{x1} + $self->{cols} - 1,
    $self->{y1} + $self->{rows} -1 ,$self->{color},$self->{style},
    $self->{win},1);
  $self;
}


sub runnable {
  my ($self) = shift;
  
  # a box can't run!

  return 0;
}


########################################################

=head1 CLASS Tui::Button

A pushbutton widget.

Inherits from L<CLASS Tui::Widget>.

=cut

package Tui::Button;

use Curses;
@ISA = (Tui::Widget);

=head2 Tui::Button::new

Constructor of the Button widget.

=over 2

=item Input Paramters

  1 text of label
  2 x coordinate
  3 y coordinate

=item Ouput Parameters

  1 reference to object

=back

=cut

sub new {
  my ($class) = shift;
  my ($self) = {};
  bless $self,$class;

  $self->{text} = shift;
  $self->{x1} = shift;
  $self->{y1} = shift;
  $self->{x2} = $self->{x1} + length($self->{text}) + 3;
  $self->{y2} = $self->{y1} + 2;
  $self->{color} = 0;
  $self->{win} = stdscr;

  $self->{exitonaltx} = 0;
  $self->{exitonalth} = 0;
  $self->{exitonaltenter} = 0;
  $self->{exitonenter} = 0;

  $self;
}

=head2 Tui::Button::draw

Draws the actual button widget.

=over 2

=item Input Paramters

  1 boolean whether the widget has the focus
  2 boolean whether it is pushed

=item Ouput Parameters

  1 reference to object

=back

=cut

sub draw {
  my ($self) = shift;
  my ($focus) = shift;
  my ($pushed) = shift;

  if ($pushed) {
    Tui::drawbox($self->{x1},$self->{y1},$self->{x2},$self->{y2},
      $self->{color},0,$self->{win});
  } else {
    Tui::drawbox($self->{x1},$self->{y1},$self->{x2},$self->{y2},
      $self->{color},1,$self->{win});
  }
  
  if ($focus) {
    attron($self->{win},COLOR_PAIR(1));
    attron($self->{win},A_BOLD);
  } else {
    attron($self->{win},COLOR_PAIR(1));
  }
  move($self->{win},$self->{y1} + 1, $self->{x1} + 2);
  addstr($self->{win},$self->{text});
  if ($focus) {
    attroff($self->{win},A_BOLD);
  }
  refresh($self->{win});
  $self;
}

=head2 Tui::Button::push

Pushes the button, prints it depressed, waits a bit and then redraws it.

=over 2

=item Input Paramters

  1 none

=item Ouput Parameters

  1 reference to object

=back

=cut

sub push {
  my ($self) = shift;
  $self->draw(1,1);
  select (undef,undef,undef,0.2);
  $self->draw(1);
  $self;
}

=head2 Tui::Button::run

Actually run the widget

=over 2

=item Input Paramters

  1 none

=item Ouput Parameters

  1 result code

=back

=cut

sub run {
  my ($self) = shift;
  $self->draw(1);
  my ($key,$keycode,$result);
  
  while (1) {
    
    ($key,$keycode) = Tui::getkey;

    if (($key =~ /[\t]/) && ($keycode == 200)) {
      $result = 7;
      last;
    } elsif ($keycode == 13) {
      $result = 6;
      last;
    } elsif ($self->{exitonaltx} && $keycode == 19) {
      $result = 9;
      last;
    } elsif ($self->{exitonalth} && $keycode == 18) {
      $result = 10;
      last;
    } elsif ($self->{exitonaltenter} && $keycode == 50) {
      $result = 11;
      last;
    } elsif (($key =~ /[ \n]/) && ($keycode == 200)) {
      $self->push;
      select (undef,undef,undef,0.2);
      $result = 8;
      last;
    }
  }
  $self->draw;
  $result;
}

########################################################

=head1 CLASS Tui::Checkbox

This widget provides a checkbox

Inherits from L<CLASS Tui::Widget>.

=cut

package Tui::Checkbox;

use Curses;
@ISA = (Tui::Widget);

=head2 Tui::Checkbox::new

Constructor of the checkbox widget.

=over 2

=item Input Paramters

  1 label to be used
  2 x coordinate
  3 y coordinate
  4 if true, the checkbox will be checked

=item Ouput Parameters

  1 reference to the object

=back

=cut

sub new {
  my ($class) = shift;
  my ($self) = {};
  bless $self,$class;

  $self->{label} = shift;
  $self->{x1} = shift;
  $self->{y1} = shift;
  $self->{set} = shift;
  $self->{win} = stdscr;

  $self->{exitonaltx} = 0;
  $self->{exitonalth} = 0;
  $self->{exitonaltenter} = 0;
  $self->{exitonenter} = 0;

  $self;
}

=head2 Tui::Checkbox::draw

Draw the checkbox widget

=over 2

=item Input Paramters

  1 whether the widget has the focus

=item Ouput Parameters

  1 reference to the object

=back

=cut

sub draw {
  my ($self) = shift;
  my ($focus) = shift;

  move($self->{win},$self->{y1},$self->{x1});
  if ($focus) {
    attron($self->{win},COLOR_PAIR(1));
    attron($self->{win},A_BOLD);
    addstr($self->{win},"[");
    #attroff($self->{win},A_BOLD);
    attron($self->{win},COLOR_PAIR(3));
    ($self->{set}) && addch($self->{win},'x');
    ($self->{set}) || addstr($self->{win}," ");
    attron($self->{win},COLOR_PAIR(1));
    #attron($self->{win},A_BOLD);
    addstr($self->{win},"] ");
    attron($self->{win},COLOR_PAIR(1));
    addstr($self->{win},$self->{label});
    move($self->{win},$self->{y1},$self->{x1} + 1);
  
  } else {
    attron($self->{win},COLOR_PAIR(1));
    attron($self->{win},A_BOLD);
    addstr($self->{win},"[");
    attroff($self->{win},A_BOLD);
    attron($self->{win},COLOR_PAIR(1));
    ($self->{set}) && addch($self->{win},'x');
    ($self->{set}) || addstr($self->{win}," ");
    attron($self->{win},COLOR_PAIR(1));
    attron($self->{win},A_BOLD);
    addstr($self->{win},"] ");
    attroff($self->{win},A_BOLD);
    attron($self->{win},COLOR_PAIR(1));
    addstr($self->{win},$self->{label});
  }
  $self;
}

=head2 Tui::Checkbox::select

Toggles the checkbox

=over 2

=item Input Paramters

  1 none

=item Ouput Parameters

  1 reference to the object

=back

=cut

sub select {
  my ($self) = shift;
  $self->{set} = $self->{set} ? 0 : 1;
  $self;

}

=head2 Tui::Checkbox::run

Runs the checkbox widget

=over 2

=item Input Parameters

  1 none

=item Output Parameters

  1 result code of the run

=back

=cut

sub run {
  my ($self) = shift;
  my ($result,$key,$keycode);

  # do until we bail out

  while (1) {

    # redraw ourselves
    $self->draw(1);
    refresh($self->{win});

    # draw the widget
    #move($self->{win},$self->{y1},$self->{x1} + 1);
    #attron($self->{win},COLOR_PAIR(3));
    #attron($self->{win},A_BOLD);
    #($self->{set}) && addch($self->{win},'x');
    #($self->{set}) || addstr($self->{win}," ");
    #move($self->{win},$self->{y1},$self->{x1} + 1);
    #refresh($self->{win});
    
    # get a keypress
    # process it

    ($key,$keycode) = Tui::getkey;
    if (($key =~ /[\t]/) && ($keycode == 200)) {
      $result = 7;
      last;
    } elsif ($keycode == 13) {
      $result = 6;
      last;
    } elsif (($key eq ' ') && ($keycode == 200)) {
      $self->select;
    } elsif ($self->{exitonaltx} && $keycode == 19) {
      $result = 9;
      last;
    } elsif ($self->{exitonalth} && $keycode == 18) {
      $result = 10;
      last;
    } elsif ($self->{exitonaltenter} && $keycode == 50) {
      $result = 11;
      last;
    } elsif ($self->{exitonenter} && $keycode == 200 && $key eq "\n") {
      $result = 12;
      last;
    }
  }

  # redraw ourselves without focus
  # return result

  $self->draw;
  $result;
}

=head2 Tui::Checkbox::data

Returns a boolean whether the checkbox is checked

=over 2

=item Input Paramters

  1 none

=item Ouput Parameters

  1 result

=back

=cut

sub data {
  my ($self) = shift;
  return $self->{set};
}

########################################################

=head1 CLASS Tui::Radiobutton

A radiobutton widget

Inherits from L<CLASS Tui::Widget>.

=cut

package Tui::Radiobutton;


use Curses;
@ISA = (Tui::Widget);

=head2 Tui::Radiobutton::new

Radiobutton widget constructor

=over 2

=item Input Paramters

  1 label
  2 x coordinate
  3 y coordinate

=item Ouput Parameters

  1 reference to the object

=back

=cut

sub new {
  my ($class) = shift;
  my ($self) = {};
  bless $self,$class;

  $self->{label} = shift;
  $self->{x1} = shift;
  $self->{y1} = shift;
  $self->{set} = 0;
  $self->{win} = stdscr;
  
  $self->{exitonaltx} = 0;
  $self->{exitonalth} = 0;
  $self->{exitonaltenter} = 0;
  $self->{exitonenter} = 0;

  $self;
}

=head2 Tui::Radiobutton::setgroup

Sets the group to which this radiobutton belongs

=over 2

=item Input Paramters

  1 reference to the Tui::Radiogroup

=item Ouput Parameters

  1 refernece to the object

=back

=cut

sub setgroup {
  my ($self) = shift;
  $self->{group} = shift;
  $self->{index} = shift;
  $self;
}

=head2 Tui::Radiobutton::draw

Draws the widget

=over 2

=item Input Paramters

  1 boolean whether the widget has the focus

=item Ouput Parameters

  1 refernece to the object

=back

=cut

sub draw {
  my ($self) = shift;
  my ($focus) = shift;

  # move to the right position
  # if we have the focus
  # draw the thing
  # otherwise
  # draw it unfocussed

  move($self->{win},$self->{y1},$self->{x1});
  if ($focus) {
    attron($self->{win},COLOR_PAIR(1));
    attron($self->{win},A_BOLD);
    addstr($self->{win},"(");
    attroff($self->{win},A_BOLD);
    attron($self->{win},COLOR_PAIR(3));
    ($self->{set}) && addch($self->{win},ACS_DIAMOND);
    ($self->{set}) || addstr($self->{win}," ");
    attron($self->{win},COLOR_PAIR(1));
    attron($self->{win},A_BOLD);
    addstr($self->{win},") ");
    attron($self->{win},COLOR_PAIR(1));
    addstr($self->{win},$self->{label});
  
  } else {
    attron($self->{win},COLOR_PAIR(1));
    attron($self->{win},A_BOLD);
    addstr($self->{win},"(");
    attroff($self->{win},A_BOLD);
    attron($self->{win},COLOR_PAIR(1));
    ($self->{set}) && addch($self->{win},ACS_DIAMOND);
    ($self->{set}) || addstr($self->{win}," ");
    attron($self->{win},COLOR_PAIR(1));
    attron($self->{win},A_BOLD);
    addstr($self->{win},") ");
    attroff($self->{win},A_BOLD);
    attron($self->{win},COLOR_PAIR(1));
    addstr($self->{win},$self->{label});
  }
  $self;
}

=head2 Tui::Radiobutton::select

Select the radio button, also unsets the selected one in the radiogroup

=over 2

=item Input Paramters

  1 none

=item Ouput Parameters

  1 reference to the object

=back

=cut

sub select {
  my ($self) = shift;

  # if we're not set
  # get the group
  # set the one that is us
  # redraw the group
  # redraw ourselves
  # refresh the output

  if (!$self->{set}) {
    my ($group) = $self->{group};
    $group->set($self->{index});
    $group->redraw;
    $self->draw(1);
    refresh($self->{win});

  }

  # return self

  $self;
}

=head2 Tui::Radiobutton::isselected

Returns whether this radiobutton is selected.

=over 2

=item Input Parameters

  1 none

=item Output Parameters

  1 boolean whether we're selected

=back

=cut

sub isselected {
  my ($self) = shift;
  return $self->{set};
}

=head2 Tui::Radiobutton::set

Set the button to on or off

=over 2

=item Input Parameters

  1 boolean whether to tunr on or off

=item Output Parameters

  1 reference to the object

=back

=cut

sub set {
  my ($self) = shift;
  $self->{set} = shift;
}

=head2 Tui::Radiobutton::run

Run the radiobutton widget, it makes no sense to use this on its own.
You need a radiogroup with it to make any use of it.

=over 2

=item Input Parameters

  1 none

=item Output Parameters

  1 result of the run operation

=back

=cut

sub run {
  my ($self) = shift;
  $self->draw(1);
  refresh($self->{win});
  my ($result,$key,$keycode);
  while (1) {
    move($self->{win},$self->{y1},$self->{x1} + 1);
    attron($self->{win},COLOR_PAIR(3));
    attron($self->{win},A_BOLD);
    ($self->{set}) && addch($self->{win},ACS_DIAMOND);
    ($self->{set}) || addstr($self->{win}," ");
    move($self->{win},$self->{y1},$self->{x1} + 1);
    refresh($self->{win});
    ($key,$keycode) = Tui::getkey;
    if (($key =~ /[\t]/) && ($keycode == 200)) {
      $result = 7;
      last;
    } elsif ($keycode == 13) {
      $result = 6;
      last;
    } elsif (($key eq ' ') && ($keycode == 200)) {
      $self->select;
    } elsif ($self->{exitonaltx} && $keycode == 19) {
      $result = 9;
      last;
    } elsif ($self->{exitonalth} && $keycode == 18) {
      $result = 10;
      last;
    } elsif ($self->{exitonaltenter} && $keycode == 50) {
      $result = 11;
      last;
    } elsif ($self->{exitonenter} && $keycode == 200 && $key eq "\n") {
      $result = 12;
      last;
    }
  }
  
  # redraw widget unfocused
  # return result

  $self->draw;
  $result;
}

=head2 Tui::Radiobutton::data

Retrieve whether this button was selected.

=over 2

=item Input Parameters

  1 none

=item Output Parameters

  1 boolean whether it's selected

=back

=cut

sub data {
  my ($self) = shift;
  return $self->{set};
}

########################################################

=head1 CLASS Tui::Radiogroup

A class to group radiobuttons together

Doesn't inherit from anything.

=cut

package Tui::Radiogroup;

=head2 Tui::Raduigroup::new

Constructor for the radiogroup widget

=over 2

=item Input Parameters

  1 list of readiobutton widgets to add to group

=item Output Parameters

  1 reference to the object

=back

=cut

sub new {
  my ($class) = shift;
  my ($self) = {};
  bless $self,$class;

  @{$self->{widgets}} = @_;
  foreach (0..$#{$self->{widgets}}) {
    ${$self->{widgets}}[$_]->setgroup($self,$_);
  }
  ${$self->{widgets}}[0]->set(1);
  $self;
}

=head2 Tui::Radiogroup::add

Add radiobuttons to the group.

=over 2

=item Input Parameters

  1 list of radiobuttons to add to the group

=item Output Parameters

  1 reference to the object

=back

=cut

sub add {
  my ($self) = shift;

  # add the list of widgets to the group
  # set the group attribute of those widgets to us
  # select the 1st one
  # return object

  push @{$self->{widgets}},@_;
  foreach (0..$#{$self->{widgets}}) {
    ${$self->{widgets}}[$_]->setgroup($self,$_);
  }
  ${$self->{widgets}}[0]->set(1);
  $self;
}

=head2 Tui::Radiogroup::set

Set a certain radiobutton within the group as selected.

=over 2

=item Input Parameters

  1 index of the radiobutton to be selected

=item Output Parameters

  1 reference to the object

=back

=cut

sub set {
  my ($self) = shift;

  # get the index of the radiobutton to set
  # unset all of first
  # set the selected one
  # return reference to the object

  my ($index) = shift;
  foreach (0..$#{$self->{widgets}}) {
    ${$self->{widgets}}[$_]->set(0);
  }
  ${$self->{widgets}}[$index]->set(1);
  $self;
}

=head2 Tui::Radiogroup::redraw

Redraws the radiobuttons within the group

=over 2

=item Input Parameters

  1 none

=item Output Parameters

  1 reference to the object

=back

=cut

sub redraw {
  my ($self) = shift;

  # go though all widgets
  # redraw them
  # return reference to self

  foreach (0..$#{$self->{widgets}}) {
    ${$self->{widgets}}[$_]->draw;
  }
  $self;
}

=head2 Tui::Radiogroup::data

Return the index of the radiobutton that is selected.

=over 2

=item Input Parameters

  1 none

=item Output Parameters

  1 index of the radiobutton that is selected

=back

=cut

sub data {
  my ($self) = shift;
  return $self->{index};
}


########################################################

=head1 CLASS Tui::Listbox

This is a listbox widget. It will draw scrollbars if need be 
(and allowed).

Inherits from L<CLASS Tui::Widget>.

=cut

package Tui::Listbox;

use Curses;
@ISA = (Tui::Widget);

=head2 Tui::Listbox::new

Constructor for the listbox widget.

=over 2

=item Input Paramters

  1 label to print in the top
  2 x coordinate of lefttop
  3 y coordinate of lefttop
  4 columns of the box
  5 rows of the box

=item Ouput Parameters

  1 reference to the object

=back

=cut

sub new {
  my ($class) = shift;
  my ($self) = {};
  bless $self,$class;

  $self->{label} = shift;
  $self->{x1} = shift;
  $self->{y1} = shift;
  $self->{cols} = shift;
  $self->{rows} = shift;

  $self->{entries} = [];
  $self->{entriesstat} = [];
  $self->{pos} = 0;
  $self->{start} = 0;
  $self->{win} = stdscr;
  $self->{color} = 0;
  $self->{style} = 0;
  $self->{drawvscrollbar} = 1;
  $self->{drawhscrollbar} = 1;
  $self->{drawbox} = 1;
  $self->{vscrollbar} = 0;
  $self->{hscrollbar} = 0;
  $self->{maxwidth} = 0;
  $self->{xpos} = 0;
  $self->{wraparound} = 0;

  $self->{exitonaltx} = 0;
  $self->{exitonalth} = 0;
  $self->{exitonaltenter} = 0;
  $self->{exitonenter} = 0;

  $self;
}

=head2 Tui::Listbox::add

Add some entried to the listbox.

=over 2

=item Input Paramters

  1 list of strings to add.

=item Ouput Parameters

  1 reference to object

=back

=cut

sub add {
  my ($self) = shift;

  # add the list of entries to the exisiting ones
  # decide whether to use a vertical scrollbar
  # calculate maxwidth
  # decide whether to use a horizontal scrollbar
  # return self

  push @{$self->{entries}},@_;
  if ($#{$self->{entries}} > $self->{rows} - 3) {
    $self->{vscrollbar} = 1;
  }
  foreach (@{$self->{entries}}) {
    if (length($_) > $self->{maxwidth}) {
      $self->{maxwidth} = length($_);
    }
  }
  if ($self->{maxwidth} > $self->{cols} - 1) {
    $self->{hscrollbar} = 1;
  }
  $self;
}

=head2 Tui::Listbox::setscrollbars

Turns both scrollbars on or off (they'll only be drawn if necessary)

=over 2

=item Input Paramters

  1 boolean whether to turn them on or off 

=item Ouput Parameters

  1 reference to the object

=back

=cut

sub setscrollbars {
  my ($self) = shift;
  my ($mode) = shift;
  $self->{drawhscrollbar} = $mode ? 1 : 0;
  $self->{drawvscrollbar} = $mode ? 1 : 0;
  $self;
}

=head2 Tui::LIstbox::sethscrollbar

Turns the horizontal scrollbar on or off

=over 2

=item Input Paramters

  1 boolean whether to turn the scrolbar on or off

=item Ouput Parameters

  1 refernece to the object

=back

=cut

sub sethscrollbar {
  my ($self) = shift;
  my ($mode) = shift;
  $self->{drawhscrollbar} = $mode ? 1 : 0;
  $self;
}

=head2 Tui::LIstbox::setvscrollbar

Turns the vertical scrollbar on or off

=over 2

=item Input Paramters

  1 boolean whether to turn the scrolbar on or off

=item Ouput Parameters

  1 refernece to the object

=back

=cut

sub setvscrollbar {
  my ($self) = shift;
  my ($mode) = shift;
  $self->{drawvscrollbar} = $mode ? 1 : 0;
  $self;
}

=head2 Tui::Listbox::setdrawbox

Turns on or off the drawing of a box.

=over 2

=item Input Paramters

  1 boolean whether to draw the box

=item Ouput Parameters

  1 reference to the object

=back

=cut

sub setdrawbox {
  my ($self) = shift;
  my ($mode) = shift;
  $self->{drawbox} = $mode ? 1 : 0;
  $self->setscrollbars($mode);
  $self;
}

=head2 Tui::Listbox::setwraparound

Sets whether the widget will wrap around or not. Defaults to off.

=over 2

=item Input Parameters

  1 boolean whether to turn it on or off

=item Output Parameters

  1 reference to the object

=back

=cut

sub setwraparound {
  my ($self) = shift;
  my ($mode) = shift;
  $self->{wraparound} = $mode ? 1 : 0;
  $self;
}

=head2 Tui::Listbox::set

Set the selected entry

=over 2

=item Input Paramters

  1 index of the entry to be selected

=item Ouput Parameters

  1 reference to the object

=back

=cut

sub set {
  my ($self) = shift;
  $self->{pos} = shift;
  if ($self->{pos} > $self->{rows} - 3) {
    $self->{start} = $self->{pos} - $self->{rows} + 3;
  }
  $self;
}

=head2 Tui::Listbox::reset

Clears the contents of the list box

=over 2

=item Input Parameters

  1 none

=item Output Parameters

  1 reference to the object

=back

=cut

sub reset {
  my ($self) = shift;
  $self->{entries} = [];
  $self->{entriesstat} = [];
  $self;
}

sub draw {
  my ($self) = shift;
  my ($focus) = shift;
  my ($to,$line,$style);

  if ($#{$self->{entries}} > $self->{rows} - 3) {
    $to = $self->{rows} - 3 + $self->{start};
  } else {
    $to = $#{$self->{entries}};
  }

  if ($focus) {
    $style = 0;
  } else {
    $style = 1;
  }
  
  if ($self->{drawbox}) {
    Tui::drawbox($self->{x1},$self->{y1}, $self->{x1} + $self->{cols} - 1,
      $self->{y1} + $self->{rows} -1 ,$self->{color},$style,$self->{win});
  }
  foreach ($self->{start}..$to) {
    $line = ${$self->{entries}}[$_] . 
      " " x ($self->{maxwidth} - length(${$self->{entries}}[$_]));
    $line = substr($line,$self->{xpos},$self->{cols} - 2);
    if ($focus) {
      if ($self->{pos} == $_) {
        attron($self->{win},COLOR_PAIR(3));
      } else {
        attron($self->{win},COLOR_PAIR(1));
      }
      move($self->{win},$_ - $self->{start} + $self->{y1} + 1, 
        $self->{x1} + 1);
      addstr($self->{win},$line);
    } else {
      attron($self->{win},COLOR_PAIR(1));
      if ($self->{pos} == $_) {
        attron($self->{win},A_BOLD);
      }
      move($self->{win},$_ - $self->{start} + $self->{y1} + 1, 
        $self->{x1} + 1);
      addstr($self->{win},$line);
      attroff($self->{win},A_BOLD);
    }
  }
  if ($focus) {
    if ($self->{vscrollbar} && $self->{drawvscrollbar}) { 
      Tui::vscrollbar($self->{x1} + $self->{cols} - 1, $self->{y1} + 1,
        $self->{rows} - 2,$#{$self->{entries}},$self->{pos},1,$self->{win});
    }
    if ($self->{hscrollbar} && $self->{drawhscrollbar}) {
      Tui::hscrollbar($self->{x1} + 1, $self->{y1} + $self->{rows} - 1,
        $self->{cols} - 2,$self->{maxwidth} - $self->{cols} + 2,
        $self->{xpos},1,$self->{win});
    }
  }
  move($self->{win},$self->{y1} + $self->{rows} - 1, 
    $self->{x1} + $self->{cols} - 1);
}

=head2 Tui::Listbox::run

Runs the listbox widget

=over 2

=item Input Parameters

  1 none

=item Output Parameters

  1 result of the run

=back

=cut

sub run {
  my ($self) = shift;

  $self->draw(1);
  refresh($self->{win});
  my ($key,$keycode,$result);
  while (1) {
    ($key,$keycode) = Tui::getkey;
    if (($key =~ /[\t]/) && ($keycode == 200)) {
      $result = 7;
      last;
    } elsif ($keycode == 13) {
      $result = 6;
      last;
    } elsif ($keycode == 7) {
      if ($self->{pos}) {
        $self->{pos}--;
        if ($self->{pos} < $self->{start}) {
          $self->{start}--;
        }
      } elsif ($self->{wraparound}) {
        $self->{pos} = $#{$self->{entries}};
        $self->{start} = $self->{pos} - $self->{rows} + 3;
        ($self->{start} < 0) && ($self->{start} = 0);

      }
    
    } elsif ($keycode == 8) {
      if ($self->{pos} < $#{$self->{entries}}) {
        $self->{pos}++;
        if ($self->{pos} - $self->{start} > $self->{rows} - 3) {
          $self->{start}++;
        }
      } elsif ($self->{wraparound}) {
        $self->{pos} = 0;
        $self->{start} = 0;
      }
    } elsif ($keycode == 9) { # right
      if ($self->{hscrollbar}) {
        if ($self->{xpos} < $self->{maxwidth} - $self->{cols} + 2) {
          $self->{xpos}++;
        }
      }

    } elsif ($keycode == 10) { # left
      if ($self->{hscrollbar}) {
        if ($self->{xpos}) {
          $self->{xpos}--;
        }
      }
    } elsif ($self->{exitonaltx} && $keycode == 19) {
      $result = 9;
      last;
    } elsif ($self->{exitonalth} && $keycode == 18) {
      $result = 10;
      last;
    } elsif ($self->{exitonaltenter} && $keycode == 50) {
      $result = 11;
      last;
    } elsif ($self->{exitonenter} && $keycode == 200 && $key eq "\n") {
      $result = 12;
      last;
    }

    $self->draw(1);
    refresh($self->{win});
  }

  $self->draw;
  refresh($self->{win});

  return $result;
}

=head2 Tui::Listbox::data

Returns the index of the selected entry

=over 2

=item Input Paramters

  1 none

=item Ouput Parameters

  1 index of the selected entry

=back

=cut

sub data {
  my ($self) = shift;
  if ($#{$self->{entries}} == -1) {
    return -1;
  }
  return $self->{pos};
}

########################################################

=head1 CLASS Tui::Mlistbox

This widget is very much like the listbox widget, except that it allows
multiple selections.

Inherits from L<CLASS Tui::Listbox>.

=cut

package Tui::Mlistbox;

use Curses;
@ISA = (Tui::Listbox);

=head2 Tui::Mlistbox::new

Constructor for the multiple selection listbox widget.

(inherited from L<CLASS Tui::Listbox>).

=over 2

=item Input Paramters

  1 label to print in the top
  2 x coordinate of lefttop
  3 y coordinate of lefttop
  4 columns of the box
  5 rows of the box

=item Ouput Parameters

  1 reference to the object

=back

=cut

=head2 Tui::Mlistbox::add

Add some entried to the multiple selction listbox.

=over 2

=item Input Paramters

  1 list of strings to add.

=item Ouput Parameters

  1 reference to object

=back

=cut

sub add {
  my ($self) = shift;
  
  # add the entries
  # decide whether to use a veritcal scrollbar
  # get the maximum width
  # decide whether to use a horizontal scrollbar
  # set all selctions to false
  # return self

  push @{$self->{entries}},@_;
  if ($#{$self->{entries}} > $self->{rows} - 3) {
    $self->{vscrollbar} = 1;
  }
  foreach (@{$self->{entries}}) {
    if (length($_) > $self->{maxwidth}) {
      $self->{maxwidth} = length($_);
    }
  }
  if ($self->{maxwidth} > $self->{cols} - 1) {
    $self->{hscrollbar} = 1;
  }
  
  foreach (0..$#{$self->{entries}}) {
    ${$self->{entriesstat}}[$_] = 0;
  }
  $self;
}


=head2 Tui::Mlistbox::set

Set the entries which are to be selected.

=over 2

=item Input Paramters

  1 list of indeces that are to be selected

=item Ouput Parameters

  1 reference to the object

=back

=cut

sub set {
  my ($self) = shift;
  my (@list) = @_;
  foreach (0..$#{$self->{entries}}) {
    ${$self->{entriesstat}}[$_] = 0;
  }
  foreach (@list) {
    ${$self->{entriesstat}}[$_] = 1;
  }
  $self;
}

=head2 Tui::Mlistbox::draw

Draws the multiple selction listbox widget

=over 2

=item Input Parameters

  1 boolean whether the widget has the focus

=item Output Parameters

  1 reference to the object

=back

=cut

sub draw {
  my ($self) = shift;
  my ($focus) = shift;
  my ($to,$line,$style);

  
  if ($#{$self->{entries}} > $self->{rows} - 3) {
    $to = $self->{rows} - 3 + $self->{start};
  } else {
    $to = $#{$self->{entries}};
  }

  if ($focus) {
    $style = 0;
  } else {
    $style = 1;
  }
  
  if ($self->{drawbox}) {
    Tui::drawbox($self->{x1},$self->{y1}, $self->{x1} + $self->{cols} - 1,
      $self->{y1} + $self->{rows} -1 ,$self->{color},$style,$self->{win});
  }
  foreach ($self->{start}..$to) {
    $line = ${$self->{entries}}[$_] . 
      " " x ($self->{maxwidth} - length(${$self->{entries}}[$_]));
    $line = substr($line,$self->{xpos},$self->{cols} - 2);
    if ($focus) {
      if ($self->{pos} == $_) {
        attron($self->{win},COLOR_PAIR(3));
      } else {
        attron($self->{win},COLOR_PAIR(1));
      }
      if (${$self->{entriesstat}}[$_]) {
        attron($self->{win}, A_BOLD);
      }
      move($self->{win},$_ - $self->{start} + $self->{y1} + 1, 
        $self->{x1} + 1);
      addstr($self->{win},$line);
      attroff($self->{win}, A_BOLD);
    } else {
      attron($self->{win},COLOR_PAIR(1));
      if (${$self->{entriesstat}}[$_]) {
        attron($self->{win},A_BOLD);
      }
      move($self->{win},$_ - $self->{start} + $self->{y1} + 1, 
        $self->{x1} + 1);
      addstr($self->{win},$line);
      attroff($self->{win},A_BOLD);
    }
  }
  
  # if we have the focus
  # if need be draw the scrollbars

  if ($focus) {
    if ($self->{vscrollbar} && $self->{drawvscrollbar}) { 
      Tui::vscrollbar($self->{x1} + $self->{cols} - 1, $self->{y1} + 1,
        $self->{rows} - 2,$#{$self->{entries}},$self->{pos},1,$self->{win});
    }
    if ($self->{hscrollbar} && $self->{drawhscrollbar}) {
      Tui::hscrollbar($self->{x1} + 1, $self->{y1} + $self->{rows} - 1,
        $self->{cols} - 2,$self->{maxwidth} - $self->{cols} + 2,
        $self->{xpos},1,$self->{win});
    }
  }
  
  # move the cusrsor to a place where it doesn't bother
  # return reference to the object

  move($self->{win},$self->{y1} + $self->{rows} - 1, 
    $self->{x1} + $self->{cols} - 1);
  $self;
}

=head2 Tui::Mlistbox::run

Runs the multiple selection listbox widget

=over 2

=item Input Parameters

  1 none

=item Output Parameters

  1 result of the run

=back

=cut

sub run {
  my ($self) = shift;

  $self->draw(1);
  refresh($self->{win});
  my ($key,$keycode,$result);
  while (1) {
    ($key,$keycode) = Tui::getkey;
    if (($key =~ /[\t]/) && ($keycode == 200)) {
      $result = 7;
      last;
    } elsif ($keycode == 13) {
      $result = 6;
      last;
    } elsif ($keycode == 7) {
      if ($self->{pos}) {
        $self->{pos}--;
        if ($self->{pos} < $self->{start}) {
          $self->{start}--;
        } 
      } elsif ($self->{wraparound}) {
        $self->{pos} = $#{$self->{entries}};
        $self->{start} = $self->{pos} - $self->{rows} + 3;
        ($self->{start} < 0) && ($self->{start} = 0);

      }

    
    } elsif ($keycode == 8) {
      if ($self->{pos} < $#{$self->{entries}}) {
        $self->{pos}++;
        if ($self->{pos} - $self->{start} > $self->{rows} - 3) {
          $self->{start}++;
        }
      } elsif ($self->{wraparound}) {
        $self->{pos} = 0;
        $self->{start} = 0;
      }

    } elsif ($keycode == 9) { # right
      if ($self->{hscrollbar}) {
        if ($self->{xpos} < $self->{maxwidth} - $self->{cols} + 2) {
          $self->{xpos}++;
        }
      }

    } elsif ($keycode == 10) { # left
      if ($self->{hscrollbar}) {
        if ($self->{xpos}) {
          $self->{xpos}--;
        }
      }
    } elsif ($self->{exitonaltx} && $keycode == 19) {
      $result = 9;
      last;
    } elsif ($self->{exitonalth} && $keycode == 18) {
      $result = 10;
      last;
    } elsif ($self->{exitonaltenter} && $keycode == 50) {
      $result = 11;
      last;
    } elsif ($self->{exitonenter} && $keycode == 200 && $key eq "\n") {
      $result = 12;
      last;
    } elsif ($keycode == 200 && $key =~ /[ \n]/) {
      ${$self->{entriesstat}}[$self->{pos}] = 
        ${$self->{entriesstat}}[$self->{pos}] ? 0 : 1;
    }

    $self->draw(1);
    refresh($self->{win});
  }

  $self->draw;
  refresh($self->{win});

  return $result;
}

=head2 Tui::Mlistbox::data

Return a list of indeces of the selected entries

=over 2

=item Input Paramters

  1 none

=item Ouput Parameters

  1 list of selected entries (the index of them!)

=back

=cut

sub data {
  my ($self) = shift;
  my (@list) = ();
  foreach (0..$#{$self->{entries}}) {
    if (${$self->{entriesstat}}[$_]) {
      push @list,$_;
    }
  }
  @list;
}

########################################################

=head1 CLASS Tui::Dropbox

This widget is sometimes also known als a combobox. When it
recieved the focus, a listbox will dropdown where the user can make
a choice. The only restriction is that the dropbox MUST fit into the 
Form where it is used when used within a form.

Inherits from L<CLASS Tui::Widget>.

=cut

package Tui::Dropbox;

use Curses;
@ISA = (Tui::Widget);

=head2 Tui::Dropbox::new

Contructor for the dropbox widget

=over 2

=item Input Paramters

  1 x coordinate of the left top
  2 y coordinate of the left top
  3 width of the widget
  4 heigth of the dropbox (defaults to 6)

=item Ouput Parameters

  1 reference to the object

=back

=cut

sub new {
  my ($class) = shift;
  my ($self) = {};
  bless $self,$class;

  $self->{x1} = shift;
  $self->{y1} = shift;
  $self->{width} = shift;
  $self->{rows} = shift || 6;
  $self->{entries} = [];
  $self->{pos} = 0;
  $self->{start} = 0;
  $self->{win} = stdscr;
  $self->{color} = 0;
  $self->{style} = 0;
  $self->{vscrollbar} = 0;
  $self->{hscrollbar} = 0;
  $self->{drawvscrollbar} = 1;
  $self->{drawhscrollbar} = 1;
  $self->{showscrollbar} = 1;
  $self->{maxwidth} = 0;
  $self->{xpos} = 0;
  $self->{current} = 0;
  $self->{subwin} = stdscr;
  $self->{wraparound} = 0;
  
  $self->{exitonaltx} = 0;
  $self->{exitonalth} = 0;
  $self->{exitonaltenter} = 0;
  $self->{exitonenter} = 0;

  $self;
}


=head2 Tui::Dropbox::add

Adds a list of entries to the dropbox

=over 2

=item Input Parameters

  1 list of strings to add

=item Output Parameters

  1 reference to the object

=back

=cut

sub add {
  my ($self) = shift;
  push @{$self->{entries}},@_;
  if ($#{$self->{entries}} > $self->{rows} - 2) {
    $self->{vscrollbar} = 1;
  }
  foreach (@{$self->{entries}}) {
    if (length($_) > $self->{maxwidth}) {
      $self->{maxwidth} = length($_);
    }
  }
  if ($self->{maxwidth} > $self->{width} - 1) {
    $self->{hscrollbar} = 1;
  }
  $self;
}

=head2 Tui::Dropbox::setwraparound

Sets whether the widget will wrap around or not. Defaults to off.

=over 2

=item Input Parameters

  1 boolean whether to turn it on or off

=item Output Parameters

  1 reference to the object

=back

=cut

sub setwraparound {
  my ($self) = shift;
  my ($mode) = shift;
  $self->{wraparound} = $mode ? 1 : 0;
  $self;
}


=head2 Tui::Dropbox::set

Set the selction in the dropbox.

=over 2

=item Input Parameters

  1 index of the entry to be selected

=item Output Parameters

  1 reference to the object

=back

=cut

sub set {
  my ($self) = shift;
  $self->{pos} = shift;
  $self;
}

=head2 Tui::Dropbox::setscrollbars

Turns on or off both scrollbars (they're on by default but
will only be drawn if needed).

=over 2

=item Input Parameters

  1 boolean whether to turn them on or off

=item Output Parameters

  1 reference to the object

=back

=cut

sub setscrollbars {
  my ($self) = shift;
  my ($mode) = shift;
  $self->{drawhscrollbar} = $mode ? 1 : 0;
  $self->{drawvscrollbar} = $mode ? 1 : 0;
  $self;
}

=head2 Tui::Dropbox::sethscrollbar

Turn on or off the horizontal scrollbar (it's on by default)

=over 2

=item Input Parameters

  1 boolean whether to turn it on or off

=item Output Parameters

  1 refrence to the object

=back

=cut

sub sethscrollbar {
  my ($self) = shift;
  my ($mode) = shift;
  $self->{drawhscrollbar} = $mode ? 1 : 0;
  $self;
}

=head2 Tui::Dropbox::setvscrollbar

Turn on or off the vertical scrollbar (it's on by default)

=over 2

=item Input Parameters

  1 boolean whether to turn it on or off

=item Output Parameters

  1 refrence to the object

=back

=cut

sub setvscrollbar {
  my ($self) = shift;
  my ($mode) = shift;
  $self->{drawvscrollbar} = $mode ? 1 : 0;
  $self;
}

=head2 Tui::Dropbox::draw

Draws the dropbox widget

=over 2

=item Input Parameters

  1 boolean indicating whether this widget has the focus

=item Output Parameters

  1 reference to the object

=back

=cut

sub draw {
  my ($self) = shift;
  my ($focus) = shift;
  my ($to,$line);

  if ($focus) {
    Tui::drawbox(0,0,$self->{width},$self->{rows} - 1, 
      $self->{color},$self->{style},$self->{subwin});
    if ($#{$self->{entries}} > $self->{rows} - 2) {
      $to = $self->{rows} - 3 + $self->{start};
    } else {
      $to = $#{$self->{entries}};
    }

    foreach ($self->{start}..$to) {
      $line = ${$self->{entries}}[$_] . 
        " " x ($self->{maxwidth} - length(${$self->{entries}}[$_]) + 1);
      $line = substr($line,$self->{xpos},$self->{width} - 1);
      if ($_ == $self->{pos}) {
        attron($self->{subwin},COLOR_PAIR(3));
      } else {
        attron($self->{subwin},COLOR_PAIR(1));
      }
      move($self->{subwin},1 + $_ - $self->{start},1);
      addstr($self->{subwin},$line);
    }
    if ($self->{vscrollbar} && $self->{drawvscrollbar}) { 
      Tui::vscrollbar($self->{width}, 1,$self->{rows} - 2,
      $#{$self->{entries}},$self->{pos},1,$self->{subwin});
    }
    if ($self->{hscrollbar} && $self->{drawhscrollbar}) {
      Tui::hscrollbar(1, $self->{rows} - 1 ,$self->{width} - 2,
        $self->{maxwidth} - $self->{width} - 2,
        $self->{xpos},1,$self->{subwin});
    }
    move($self->{subwin},$self->{rows} - 1,$self->{width});
  } else {
    move($self->{win},$self->{y1},$self->{x1});
    $line = ${$self->{entries}}[$self->{pos}] . " " x ($self->{width} - 3 - 
      length(${$self->{entries}}[$self->{pos}]));
    $line = substr($line,0,$self->{width} - 2);
    attron($self->{win},COLOR_PAIR(1));
    addstr($self->{win},$line);
    attron($self->{win},COLOR_PAIR(5));
    attron($self->{win},A_BOLD);
    addstr($self->{win},"[v]");
    attroff($self->{win},A_BOLD);

  }
  $self;
}

=head2 Tui::Dropbox::run

Runs the dropbox widget

=over 2

=item Input Parameters

  1 none

=item Output Parameters

  1 result of the run

=back

=cut

sub run {
  my ($self) = shift;
  my ($xorg) = shift;
  my ($yorg) = shift;
  $self->{subwin} = newwin(6,$self->{width} + 1,$self->{y1} +  $yorg, 
    $self->{x1} + $xorg - 2);
  $self->draw(1);
  refresh($self->{subwin});
  my ($key,$keycode,$result);
  while (1) {
    ($key,$keycode) = Tui::getkey;
    if (($key =~ /[\t]/) && ($keycode == 200)) {
      $result = 7;
      last;
    } elsif ($keycode == 13) {
      $result = 6;
      last;
    } elsif ($keycode == 7) {
      if ($self->{pos}) {
        $self->{pos}--;
        if ($self->{pos} < $self->{start}) {
          $self->{start}--;
        }
      } elsif ($self->{wraparound}) {
        $self->{pos} = $#{$self->{entries}};
        $self->{start} = $self->{pos} - $self->{rows} + 3;
        ($self->{start} < 0) && ($self->{start} = 0);

      }

    
    } elsif ($keycode == 8) {
      if ($self->{pos} < $#{$self->{entries}}) {
        $self->{pos}++;
        if ($self->{pos} - $self->{start} > $self->{rows} - 3) {
          $self->{start}++;
        }
      } elsif ($self->{wraparound}) {
        $self->{pos} = 0;
        $self->{start} = 0;
      }
    } elsif ($keycode == 9) { # right
      if ($self->{hscrollbar}) {
        if ($self->{xpos} < $self->{maxwidth} - $self->{width} + 2) {
          $self->{xpos}++;
        }
      }

    } elsif ($keycode == 10) { # left
      if ($self->{hscrollbar}) {
        if ($self->{xpos}) {
          $self->{xpos}--;
        }
      }
    } elsif (($key =~ /[\n]/) && ($keycode == 200)) {
      if ($self->{exitonenter}) {
        $result = 12;
      } else {
        $result = 7;
      }
      last;
    } elsif ($self->{exitonaltx} && $keycode == 19) {
      $result = 9;
      last;
    } elsif ($self->{exitonalth} && $keycode == 18) {
      $result = 10;
      last;
    } elsif ($self->{exitonaltenter} && $keycode == 50) {
      $result = 11;
      last;
    }
    $self->draw(1);
    refresh($self->{subwin});
  }
  touchwin($self->{win});
  refresh($self->{win});
  $self->draw;
  refresh($self->{win});

  return $result;
}

=head2 Tui::Dropbox::data

Returns the index of the selected entry

=over 2

=item Input Parameters

  1 none

=item Output Parameters

  1 index of the selected entry

=back

=cut

sub data {
  my ($self) = shift;
  $self->{pos};
}

########################################################

=head1 CLASS Tui::Entryfield

A widget for entering text. The entered line can be longer than would
fit in the widget, it'll scroll as need be.

Inherits from L<CLASS Tui::Widget>.

=cut

package Tui::Entryfield;

use Curses;
@ISA = (Tui::Widget);

=head2 Tui::Entryfield::new

Constructor

=over 2

=item Input Paramters

  1 label to print before entryfield
  2 x coordinate
  3 y coordinate
  4 length of the widget
  5 maximum length of the text
  6 default text

=item Ouput Parameters

  1 reference to the object

=back

=cut

sub new {
  my ($class) = shift;
  my ($self) = {};
  bless $self,$class;

  $self->{label} = shift;
  $self->{x1} = shift;
  $self->{y1} = shift;
  $self->{length} = shift;
  $self->{maxlength} = shift;
  $self->{text} = shift;
  $self->{color} = 0;
  $self->{win} = stdscr;
  
  $self->{startx} = 0;
  $self->{pos} = 0;
  $self->{insertmode} = 1;
  
  $self->{exitonaltx} = 0;
  $self->{exitonalth} = 0;
  $self->{exitonaltenter} = 0;
  $self->{exitonenter} = 0;

  $self;
}

=head2 Tui::Entryfield::set

This will set the default text of the entryfield widget.

=over 2

=item Input Paramters

  1 the text

=item Ouput Parameters

  1 reference to the object

=back

=cut

sub set {
  my ($self) = shift;
  $self->{text} = shift;
  $self;
}

=head2 Tui::Entryfield::draw

Acutally draws the widget.

=over 2

=item Input Paramters

  1 boolean whether the widget has focus

=item Ouput Parameters

  1 reference to object

=back

=cut

sub draw {
  my ($self) = shift;
  my ($focus) = shift;

  $self->drawtext($focus);
  move($self->{win},$self->{y1},$self->{x1});
  attron($self->{win},COLOR_PAIR(1));
  if ($focus) {
    attron($self->{win},A_BOLD);
    addstr($self->{win},$self->{label});
    addstr($self->{win}," ");
    move($self->{win},$self->{y1},
      $self->{x1} + length($self->{label}) + 
      $self->{pos} - $self->{startx} + 1);
    attroff($self->{win},A_BOLD);
  } else {
    addstr($self->{win},$self->{label});
    addstr($self->{win}," ");
  }
  $self;
}

=head2 Tui::Entryfield::drawtext

This draws the actual text.

=over 2

=item Input Paramters

  1 boolean whether the widget has the focus

=item Ouput Parameters

  1 reference to object

=back

=cut

sub drawtext {
  my ($self) = shift;
  my ($focus) = shift;

  my ($text) = "." x $self->{length};
  move($self->{win},$self->{y1},$self->{x1} + length($self->{label}) + 1);

  attron($self->{win},COLOR_PAIR(1));
  if ($focus) {
    attron($self->{win},A_BOLD);
  }
  addstr($self->{win},substr($self->{text},$self->{start},$self->{length}));
  if (length($self->{text}) - $self->{start} < $self->{length}) {
    addstr($self->{win},
      "." x ($self->{length} - length($self->{text}) + $self->{start}));
  }
  if ($focus) {
    attroff($self->{win},A_BOLD);
  }
  $self;
}

=head2 Tui::Entryfield::run

Runs the widget.

=over 2

=item Input Parameters

  1 none

=item Output Parameters

  1 result code

=back

=cut

sub run {
  my ($self) = shift;
  $self->draw(1);
  move($self->{win},$self->{y1},
    $self->{x1} + length($self->{label}) +1+ $self->{pos} - $self->{start});
  refresh($self->{win});
  my ($result,$key,$keycode);
  while (1) {
    ($key,$keycode) = Tui::getkey;
    if ($keycode == 2) {
      $self->{insertmode} = $self->{insertmode} ? 0 : 1;
    } elsif ($keycode == 9) {
      if ($self->{pos} < length($self->{text})) {
        $self->{pos}++;
        if ($self->{pos} > $self->{start} + $self->{length}) {
          $self->{start}++;
        }
      }
    } elsif ($keycode == 10) {
      if ($self->{pos} > 0) {
        $self->{pos}--;
        if ($self->{pos} < $self->{start}) {
          $self->{start}--;
        }
      }
    } elsif ($keycode == 11) {
      if ($self->{pos}) {
        substr($self->{text},$self->{pos} - 1,1) = "";
        $self->{pos}--;
        if ($self->{pos} < $self->{start}) {
          $self->{start}--;
        }
      } 
    } elsif ($keycode == 3 || $keycode == 14) {
      if ($self->{pos} < length($self->{text})) {
        substr($self->{text},$self->{pos},1) = "";
      }
    } elsif ($keycode == 1 || $keycode == 23) {
      $self->{pos} = 0;
      $self->{start} = 0;
    } elsif ($keycode == 4 || $keycode == 24) {
      $self->{pos} = length($self->{text});
      if ($self->{pos} > length($self->{text})) {
        $self->{start} = length($self->{text}) - $self->{length};
      }
    } elsif ($keycode == 22) {
      $self->{text} = "";
      $self->{pos} = 0;
      $self->{start} = 0;
    } elsif ($keycode == 13) {
        $result = 6;
        last;
    } elsif ($keycode == 200) {
      if ($key eq "\t") {
        $result = 7;
        last;
      } elsif ($key eq "\n") {
        if ($self->{exitonenter}) {
          $result = 12;
          last;
        }
      } elsif ($key =~ /[\r\f]/) {

      } else {
        if (length($self->{text}) < $self->{maxlength}) {
          substr($self->{text},$self->{pos},0) = $key;
          if ($self->{pos} < $self->{maxlength}) {
            $self->{pos}++;
            if ($self->{pos} > $self->{length}) {
              $self->{start}++;
            }
          }
        }
      }
    } elsif ($self->{exitonaltx} && $keycode == 19) {
      $result = 9;
      last;
    } elsif ($self->{exitonalth} && $keycode == 18) {
      $result = 10;
      last;
    } elsif ($self->{exitonaltenter} && $keycode == 50) {
      $result = 11;
      last;
    }

    
    $self->drawtext(1);
    move($self->{win},$self->{y1},
      $self->{x1} + length($self->{label}) +1+ $self->{pos} - $self->{start});
    refresh($self->{win});

  }
  $self->draw;
  $result;
}

=head2 Tui::Entryfield::data

Retrieve the data entered in the widget.

=over 2

=item Input Paramters

  1 none

=item Ouput Parameters

  1 text entered

=back

=cut

sub data {
  my ($self) = shift;
  return $self->{text};
}

########################################################

=head1 CLASS Tui::Passwordfield

A widget for entering passwords. Provides pretty much the same 
functionality as the Entryfield widgets, except that entered
characters are shown with a '*'.

Inherits from L<CLASS Tui::Entryfield>.

=cut

package Tui::Passwordfield;


use Curses;
@ISA = (Tui::Entryfield);

=head2 Tui::Passwordfield::new

Constructor

=over 2

=item Input Paramters

  1 label to print before entryfield
  2 x coordinate
  3 y coordinate
  4 length of the widget
  5 maximum length of the text
  6 default text

=item Ouput Parameters

  1 reference to the object

=back

=cut


sub drawtext {
  my ($self) = shift;
  my ($focus) = shift;

  my ($text) = "*" x length($self->{text});
  move($self->{win},$self->{y1},$self->{x1} + length($self->{label}) + 1);

  attron($self->{win},COLOR_PAIR(1));
  if ($focus) {
    attron($self->{win},A_BOLD);
  }
  addstr($self->{win},substr($text,$self->{start},$self->{length}));
  if (length($self->{text}) - $self->{start} < $self->{length}) {
    addstr($self->{win},
      "." x ($self->{length} - length($self->{text}) + $self->{start}));
  }
  if ($focus) {
    attroff($self->{win},A_BOLD);
  }
}


########################################################

=head1 CLASS Tui::Spinner

This widget is a spinner, it contains a value and can be in-/decreased with
the cursor keys.

Inherits from L<CLASS Tui::Widget>.

=cut

package Tui::Spinner;

use Curses;
@ISA = (Tui::Widget);

=head2 Tui::Spinner::new

Constructo for the spinner widget.

=over 2

=item Input Paramters

  1 label
  2 x coordinate
  3 y coordinate
  4 width
  5 value

=item Ouput Parameters

  1 reference to object

=back

=cut

sub new {
  my ($class) = shift;
  my ($self) = {};
  bless $self,$class;

  $self->{label} = shift;
  $self->{x1} = shift;
  $self->{y1} = shift;
  $self->{width} = shift;
  
  $self->{val} = shift;
  $self->{step} = 1;
  $self->{useceiling} = 0;
  $self->{color} = 0;
  $self->{win} = stdscr;
  
  $self->{exitonaltx} = 0;
  $self->{exitonalth} = 0;
  $self->{exitonaltenter} = 0;
  $self->{exitonenter} = 0;

  $self;
}

=head2 Tui::Spinner::setstep

Sets the step value of a spinner widget.

=over 2

=item Input Paramters

  1 step value

=item Ouput Parameters

  1 reference to the object

=back

=cut

sub setstep {
  my ($self) = shift;
  $self->{step} = shift;
  $self;
}

=head2 Tui::Spinner::setlimits

Sets the floor and ceiling value of a spinner widget.

=over 2

=item Input Paramters

  1 floor
  2 ceiling

=item Ouput Parameters

  1 reference to the object

=back

=cut

sub setlimits {
  my ($self) = shift;
  $self->{floor} = shift;
  $self->{ceiling} = shift;
  $self->{useceiling} = 1;
  $self;
}

=head2 Tui::Spinner:set

Set the value of the spinner.

=over 2

=item Input Paramters

  1 value

=item Ouput Parameters

  1 reference to the object

=back

=cut

sub set {
  my ($self) = shift;
  $self->{val} = shift;
  $self;
}

=head2 Tui::Spinner::data

Retireves the value of the widget

=over 2

=item Input Paramters

  1 none

=item Ouput Parameters

  1 value

=back

=cut

sub data {
  my ($self) = shift;
  $self->{val};
}

=head2 Tui::Spinner::draw

Actually draws the widget.

=over 2

=item Input Parameters

  1 boolean whether it has the focus or not

=item Output Parameters

  1 none

=back

=cut

sub draw {
  my ($self) = shift;
  my ($focus) = shift;

  my ($line);
  my ($labellength) = 0;
  if ($self->{label}) {
    $labellength = length($self->{label}) + 1;
  }

  $line = "." x ($self->{width} - 4 - length($self->{val}))  
    . $self->{val} . " ";
  if ($labellength) {
    $line = $self->{label} . " " . $line;
  }
  attron($self->{win},COLOR_PAIR(1));
  move($self->{win},$self->{y1},$self->{x1});
  if ($focus) {
    attron($self->{win},A_BOLD);
  }
  addstr($self->{win},$line);
  attron($self->{win},COLOR_PAIR(5));
  attron($self->{win},A_BOLD);
  addch($self->{win},"[");
  addch($self->{win},ACS_DIAMOND);
  addch($self->{win},"]");
  attroff($self->{win},A_BOLD);
}

=head2 Tui::Spinner::run

Runs the spiner widget

=over 2

=item Input Parameters

  1 none

=item Output Parameters

  1 result code of the run

=back

=cut

sub run {
  my ($self) = shift;
  my ($key,$keycode,$result);
  $self->draw(1);
  refresh($self->{win});
  while (1) {
    ($key,$keycode) = Tui::getkey;
    if ($keycode == 7) {
      if ($self->{useceiling}) {
        if ($self->{val} < $self->{ceiling}) {
          $self->{val} += $self->{step};
        }
      } else {
        $self->{val} += $self->{step};
      }
    } elsif ($keycode == 8) {
      if ($self->{useceiling}) {
        if ($self->{val} > $self->{floor}) {
          $self->{val} -= $self->{step};
        }
      } else {
        $self->{val} -= $self->{step};
      }
    } elsif (($keycode == 200) && ($key eq "\t")) {
      $result = 7;
      last;
    } elsif ($self->{exitonenter} && ($keycode == 200) && ($key eq "\n")) {
      $result = 12;
      last;
    } elsif ($keycode == 13) {
      $result = 6;
      last;
    } elsif ($self->{exitonaltx} && $keycode == 19) {
      $result = 9;
      last;
    } elsif ($self->{exitonalth} && $keycode == 18) {
      $result = 10;
      last;
    } elsif ($self->{exitonaltenter} && $keycode == 50) {
      $result = 11;
      last;
    }

    $self->draw(1);
    refresh($self->{win});
  }
  $self->draw;
  $result;
}

########################################################

=head1 CLASS Tui::Viewarea

This is a widget that'll show some text. The text can be larger than 
the widget, it provides scrollbars if need be.

Inherits from L<CLASS Tui::Widget>.

=cut

package Tui::Viewarea;

use Curses;
@ISA = (Tui::Widget);

=head2 Tui::Viewarea::new

Constructor for the viewarea widget.

=over 2

=item Input Paramters

  1 x coordinate of left top
  2 y coordinate of left top
  3 number of collumns
  4 number of rows
  5 boolean whether to draw a border

=item Ouput Parameters

  1 reference to the object

=back

=cut

sub new {
  my ($class) = shift;
  my ($self) = {};
  bless $self,$class;

  $self->{x1} = shift;
  $self->{y1} = shift;
  $self->{cols} = shift;
  $self->{rows} = shift;
  $self->{drawborder} = shift;
 
  $self->{drawhscrollbar} = 1;
  $self->{drawvscrollbar} = 1;
  $self->{drawpos} = 1;
  $self->{color} = 0;
  $self->{win} = stdscr;
  
  $self->{exitonaltx} = 0;
  $self->{exitonalth} = 0;
  $self->{exitonaltenter} = 0;
  $self->{exitonenter} = 0;

  $self;
}

=head2 Tui::Viewarea::set

Sets the text of the viewarea widget

=over 2

=item Input Paramters

  1 text in 1 string, it'll be split on newlines

=item Ouput Parameters

  1 reference to the object

=back

=cut

sub set {
  my ($self) = shift;
  my ($text) = shift;
  
  # get rid of tabs by replacing them with 8 spaces
  # make a list of the text
  # init the xpos and ypos
  # get the maximum width

  $text =~ s/\t/        /sg;
  @{$self->{text}} = split(/\n/,$text);
  $self->{xpos} = 0;
  $self->{ypos} = 0;
  $self->{maxwidth} = 0;
  foreach (@{$self->{text}}) {
    if (length($_) > $self->{maxwidth}) {
      $self->{maxwidth} = length($_);
    }
  }

  # decide whether to use a vertical scrollbar
  # decide whether to use a horizontal scrollbar
  # return self

  if ($#{$self->{text}} > $self->{rows} - 2) {
    $self->{vscrollbar} = 1;
  }
  if ($self->{maxwidth} > $self->{cols} - 2) {
    $self->{hscrollbar} = 1;
  }
  $self;
}

=head2 Tui::Viewarea::sethscrollbar

Turns horizontal scrollbar on or off.(defaults to on)

=over 2

=item Input Paramters

  1 boolean whether to turn it off or on

=item Ouput Parameters

  1 reference to the object

=back

=cut

sub sethscrollbar {
  my ($self) = shift;
  my ($mode) = shift;
  $self->{drawhscrollbar} = $mode ? 1 : 0;
  $self;
}

=head2 Tui::Viewarea::setvscrollbar

Turns vertical scrollbar on or off.(defaults to on)

=over 2

=item Input Paramters

  1 boolean whether to turn it off or on

=item Ouput Parameters

  1 reference to the object

=back

=cut

sub setvscrollbar {
  my ($self) = shift;
  my ($mode) = shift;
  $self->{drawvscrollbar} = $mode ? 1 : 0;
  $self;
}

=head2 Tui::Viewarea::setpos

Turns on or off the position (percent) indicator for the widget
It defaults to on.

=over 2

=item Input Paramters

  1 boolean whether to turn on or off

=item Ouput Parameters

  1 reference to the object

=back

=cut

sub setpos {
  my ($self) = shift;
  my ($mode) = shift;
  $self->{drawpos} = $mode ? 1 : 0;
  $self;
}

=head2 Tui::Viewarea::draw

Draws the viewarea widget.

=over 2

=item Input Parameters

  1 boolean whether widget has the focus

=item Output Parameters

  1 reference to the object

=back

=cut

sub draw {
  my ($self) = shift;
  my ($focus) = shift;
  my ($to,$line,$style,$percent);

  # get the style with focus
  # if we need to draw the border, do it

  $style = $focus ? 0 : 1;
  if ($self->{drawborder}) {
    Tui::drawbox($self->{x1},$self->{y1},$self->{x1} + $self->{cols},
      $self->{y1} + $self->{rows}, $self->{color}, 
      $style, $self->{win});
  }
  
  # get point upto which we have to draw lines
  # if there are less lines than the widget is tall
  # draw all lines
  # otherwise just draw until widget is full

  if ($#{$self->{text}} < $self->{rows} - 2) {
    $to = $#{$self->{text}};
  } else {
    $to = $self->{ypos} + $self->{rows} - 2;
  }

  # set the color
  # for each line
  # get the line, pad it until the maximum width
  # get a part that will fit in the widget
  # move to the correct position
  # and draw it

  attron($self->{win},COLOR_PAIR(1));
  foreach ($self->{ypos}..$to) {
    $line = ${$self->{text}}[$_];
    $line .= " " x ($self->{maxwidth} - length($line));
    $line = substr($line,$self->{xpos},$self->{cols} - 1);
    move($self->{win},$_ - $self->{ypos} + $self->{y1} + 1,$self->{x1} + 1);
    addstr($self->{win},$line);
  }
  
  # if we have the focus
  # if we can draw a vertical scrollbars and there is one
  # draw it
  # if we can draw a horizontal scrollbars and there is one
  # draw it

  if ($focus) {
    if ($self->{drawvscrollbar} && $self->{vscrollbar}) {
      Tui::vscrollbar($self->{x1}+$self->{cols},$self->{y1} + 1,
        $self->{rows} - 1, $#{$self->{text}} - $self->{rows}, 
        $self->{ypos},1,$self->{win});
    }
    if ($self->{drawhscrollbar} && $self->{hscrollbar}) {
      Tui::hscrollbar($self->{x1} + 1,$self->{y1} + $self->{rows},
        $self->{cols} - 7, $self->{maxwidth} - $self->{cols}, 
        $self->{xpos},1,$self->{win});
    }
    
    # if we can draw the position
    # get the percentage
    # if there is 1 line it's always 100%
    # otherwise calculate it
    # make the string
    # move to the right position
    # draw it

    if ($self->{drawpos}) {
      if ($#{$self->{text}} <= $self->{rows} - 2) {
        $percent = 100;
      } else {
        $percent = int(100 * $self->{ypos}/($#{$self->{text}} - 
          $self->{rows} + 2));
      }
      $line = sprintf("%2d%%",$percent);
      attron($self->{win},COLOR_PAIR(1));
      move($self->{win},$self->{y1}+$self->{rows},
      $self->{x1} + $self->{cols} - 4);
      addstr($self->{win},$line);
    }

  }

  # move the cursor to a position where it doesn't bother too much
  # return reference to self

  move($self->{win},$self->{y1}+$self->{rows},$self->{x1} + $self->{cols});
  $self;
}

=head2 Tui::Viewarea::movecursor

Moves the cursor a supplied amount.

=over 2

=item Input Parameters

  1 delta x
  2 delta y

=item Output Parameters

  1 reference to the object

=back

=cut

sub movecursor {
  my ($self) = shift;
  my ($deltax) = shift;
  my ($deltay) = shift;

  if ($deltax) {
    if (($self->{xpos} + $deltax < $self->{maxwidth} - $self->{cols} + 3) && 
        ($self->{xpos} + $deltax >= 0)) {
      $self->{xpos} += $deltax;
    }
  }

  if ($deltay) {
    $self->{ypos} += $deltay;
    if ($self->{ypos} < 0) {
      $self->{ypos} = 0;
    } elsif ($self->{ypos} > $#{$self->{text}} - $self->{rows} + 2) {
      $self->{ypos} = $#{$self->{text}} - $self->{rows} + 2;
    }

  }
  $self;
}

=head2 Tui::Viewarea::run

Actually runs the widget.

=over 2

=item Input Parameters

  1 none

=item Output Parameters

  1 result of the run

=back

=cut

sub run {
  my ($self) = shift;
  my ($key,$keycode,$result);
  $self->draw(1);
  refresh($self->{win});
  while (1) {
    ($key,$keycode) = Tui::getkey;

    if ($keycode == 7) {
      $self->movecursor(0,-1);
    } elsif ($keycode == 8) {
      $self->movecursor(0,1);
    } elsif ($keycode == 9) {
      $self->movecursor(1,0);
    } elsif ($keycode == 10) {
      $self->movecursor(-1,0);
    } elsif ($keycode == 5) {
      $self->movecursor(0,($self->{rows} - 2) * -1);
    } elsif ($keycode == 6) {
      $self->movecursor(0, $self->{rows} - 2);
    } elsif ($keycode == 200) {
      if ($key eq "\t") {
        $result = 7;
        last;
      }
      if ($self->{exitonenter} && $key eq "\n" ) {
        $result = 12;
        last;
      }
    } elsif ($keycode == 13) {
      $result = 6;
      last;
    } elsif ($self->{exitonaltx} && $keycode == 19) {
      $result = 9;
      last;
    } elsif ($self->{exitonalth} && $keycode == 18) {
      $result = 10;
      last;
    } elsif ($self->{exitonaltenter} && $keycode == 50) {
      $result = 11;
      last;
    }
    
    $self->draw(1);
    refresh($self->{win});
  }
  $self->draw;
  refresh($self->{win});
  $result;
}

########################################################

=head1 CLASS Tui::Editarea

This widget is a small editor. It provides some basic editor
functionality. The following keys are supported:

  cursor keys : movement
  alt-a : beginning of line
  alt-e : end of line
  backspace : delete the character before the cursor
  alt-d : delete the character at the cursor
  tab : move on to the next widget

Inherits from L<CLASS Tui::Widget>.

=cut

package Tui::Editarea;

use Curses;
@ISA = (Tui::Widget);

=head2 Tui::Editarea::new

Constructor for the Editarea widget

=over 2

=item Input Paramters

  1 x coordinate of left top
  2 y coordinate of left top
  3 number of collumns
  4 number of rows
  5 whether to draw a border

=item Ouput Parameters

  1 reference to object

=back

=cut

sub new {
  my ($class) = shift;
  my ($self) = {};
  bless $self,$class;

  $self->{x1} = shift;
  $self->{y1} = shift;
  $self->{cols} = shift;
  $self->{rows} = shift;
  $self->{drawborder} = shift;
 
  $self->{drawhscrollbar} = 1;
  $self->{drawvscrollbar} = 1;
  $self->{drawpos} = 1;
  $self->{color} = 0;
  $self->{win} = stdscr;
  
  $self->{exitonaltx} = 0;
  $self->{exitonalth} = 0;
  $self->{exitonaltenter} = 0;
  $self->{exitonenter} = 0;

  $self->{xpos} = 0;
  $self->{ypos} = 0;
  $self->{xstart} = 0;
  $self->{ystart} = 0;
  $self->{text} = "";
  $self->{redrawtext} = 1;
  $self->{insertmode} = 0;

  $self;
}

=head2 Tui::Editarea::set

Sets the default text in the editarea.

=over 2

=item Input Paramters

  1 the text as 1 string

=item Ouput Parameters

  1 reference to object

=back

=cut

sub set {
  my ($self) = shift;
  my ($text) = shift;
  
  # get rid of tabs, replace by 8 spaces
  # split it all
  # get the maximum width
  # decide whether to use scrollbars

  $text =~ s/\t/        /sg;
  $self->{text} = @{$self->{lines}} = split(/\n/,$text);
  $self->{maxwidth} = 0;
  foreach (@{$self->{lines}}) {
    if (length($_) > $self->{maxwidth}) {
      $self->{maxwidth} = length($_);
    }
  }

  if ($#{$self->{lines}} > $self->{rows} - 2) {
    $self->{vscrollbar} = 1;
  }
  if ($self->{maxwidth} > $self->{cols} - 2) {
    $self->{hscrollbar} = 1;
  }
  $self;
}

=head2 Tui::Editarea::sethscrollbar

Turns horizontal scrollbar on or of (defaults to on)

=over 2

=item Input Parameters

  1 boolean whether to turn on or off

=item Output Parameters

  1 reference to the object

=back

=cut

sub sethscrollbar {
  my ($self) = shift;
  my ($mode) = shift;
  $self->{drawhscrollbar} = $mode ? 1 : 0;
  $self;
}

=head2 Tui::Editarea::setvscrollbar

Turns vertical scrollbar on or of (defaults to on)

=over 2

=item Input Parameters

  1 boolean whether to turn on or off

=item Output Parameters

  1 reference to the object

=back

=cut

sub setvscrollbar {
  my ($self) = shift;
  my ($mode) = shift;
  $self->{drawvscrollbar} = $mode ? 1 : 0;
  $self;
}

=head2 Tui::Editarea::setpos

Turn on or off the position indicator (on by default)

=over 2

=item Input Paramters

  1 boolean whether to tunr on or off

=item Ouput Parameters

  1 reference to object

=back

=cut

sub poson {
  my ($self) = shift;
  my ($mode) = shift;
  $self->{drawpos} = $mode ? 1 : 0;
  $self;
}

=head2 Tui::Editarea::data

Returns the text as 1 string

=over 2

=item Input Paramters

  1 none

=item Ouput Parameters

  1 the text

=back

=cut

sub data {

  # return all the lines joined with a newline as 1 string

  my ($self) = shift;
  join(@{$self->{lines}},"\n");
}

=head2 Tui::Editarea::draw

Draws the editarea widget.

=over 2

=item Input Parameters

  1 boolean whether the widget has the focus
  3 boolean whether to NOT clear the inside (just redraw the 
    border and scrollbars)

=item Output Parameters

  1 

=back

=cut

sub draw {
  my ($self) = shift;
  my ($focus) = shift;
  my ($dontclear) = shift;

  my ($to,$line,$style,$percent);

  # set style lowered or raised
  # if drawborder, draw it
  # if dontclear was set, don't clear it

  $style = $focus ? 0 : 1;
  if ($self->{drawborder}) {
    if ($dontclear) {
      Tui::drawbox($self->{x1},$self->{y1},$self->{x1} + $self->{cols},
        $self->{y1} + $self->{rows}, $self->{color}, 
        $style, $self->{win},1);
    } else {
      Tui::drawbox($self->{x1},$self->{y1},$self->{x1} + $self->{cols},
        $self->{y1} + $self->{rows}, $self->{color}, 
        $style, $self->{win});
    }
  }
  
  # if we have to redraw the text
  
  if ($self->{redrawtext} || !$focus) {
    $self->redrawtext;
  }


  # if we have the focus
  # if draw vscrollbar, draw it
  # if draw hscrollbar, draw it
  # if draw pos, draw it

  if ($focus) {
    
    my ($total);

    if ($self->{drawvscrollbar}) {
      $total = $#{$self->{lines}} ? 1 : $#{$self->{lines}};
      Tui::vscrollbar($self->{x1}+$self->{cols},$self->{y1} + 1,
        $self->{rows} - 1, $total, $self->{ypos},1,
        $self->{win});
    }
    
    if ($self->{drawhscrollbar}) {
      $total = $self->{maxwidth} ? 1 : $self->{maxwidth};
      Tui::hscrollbar($self->{x1} + 1,$self->{y1} + $self->{rows},
        $self->{cols} - 10, $total,$self->{xpos},1,$self->{win});
    }
    
    if ($self->{drawpos}) {

      # create the pos line
      # set the attr
      # move and write the pos
      # move up
      # write ther insert mode

      $line = ($self->{xpos} + 1) . ":" . ($self->{ypos} + 1);
      attron($self->{win},COLOR_PAIR(1));
      move($self->{win},$self->{y1}+$self->{rows},
        $self->{x1} + $self->{cols} - 8);
      addstr($self->{win},$line);
      move($self->{win},$self->{y1}+$self->{rows},
        $self->{x1} + $self->{cols} - 1);
      if ($self->{insertmode}) {
        addstr($self->{win},"O");
      } else {
        addstr($self->{win},"I");
      }
    }

    # move to the current position so the cursor will be nice

    move($self->{win}, $self->{ypos} - $self->{ystart} + $self->{y1} + 1,
      $self->{xpos} - $self->{xstart} + $self->{x1} + 1);  
  }
  $self;
}

=head2 Tui::Editarea::redrawtext

Redraws the text, not the box and possible scrollbars.

=over 2

=item Input Parameters

  1 none

=item Output Parameters

  1 reference to the object

=back

=cut

sub redrawtext {
  my ($self) = shift;

  my ($to,$emptyline,$line);

  # if there are less lines than would fit
  # go upto the last line
  # otherwise go upto the last line in the window plus the start

  if ($#{$self->{lines}} < $self->{rows} - 2) {
    $to = $#{$self->{lines}};
  } else {
    $to = $self->{ystart} + $self->{rows} - 2;
  }

  # set the attribute
  # now go through each line
  # set the line and add spaces upto the maximum width
  # chop so it'll fit in the window

  attron($self->{win},COLOR_PAIR(1));
  foreach ($self->{ystart}..$to) {
    $line = ${$self->{lines}}[$_] . " " x ($self->{maxwidth} + $self->{cols});
    $line = substr($line,$self->{xstart},$self->{cols} - 1);
    move($self->{win},$_ - $self->{ystart} + $self->{y1} + 1, 1 + $self->{x1});
    addstr($self->{win},$line);
  }

  # if the whole window wasn't filled up yet
  # make an empty line that'll fit in the window
  # do for each of the remaining lines
  # write it

  if ($to < $self->{ystart} + $self->{rows} - 2) {
    $line = " " x ($self->{cols} - 1);
    foreach ($to + 1 .. $self->{ystart} + $self->{rows} - 2) {
      move($self->{win},$_ - $self->{ystart} + $self->{y1} + 1, 
        1 + $self->{x1});
      addstr($self->{win},$line);
    }
  }
  $self->{redrawtext} = 0;
  $self;
}

=head2 Tui::Editarea::adjustxspo

Adjust xpos and xstart if needed. Makes sure that the current cursor position
is within the view

=over 2

=item Input Parameters

  1 none

=item Output Parameters

  1 reference to the object

=back

=cut

sub adjustxpos {
  my ($self) = shift;

  # if the xpos is more than the length of the current line
  # set the xpos tp the length of the line
  # if the new xpos falls left of xstart
  # set xstart to 1 area to the left of xpos
  # if it is less than 0 set to 0

  if ($self->{xpos} > length(${$self->{lines}}[$self->{ypos}])) {
    $self->{xpos} = length(${$self->{lines}}[$self->{ypos}]);
    if ($self->{xpos} < $self->{xstart} + $self->{cols} - 3) {
      $self->{xstart} = $self->{xpos} - $self->{cols} + 3;
      if ($self->{xstart} < 0) {
        $self->{xstart} = 0;
      }
      
      $self->{redrawtext} = 1;
    }
  }
  $self;
}

# find the longest line

sub calcmaxwidth {
  my ($self) = shift;

  $self->{maxwidth} = 0;
  foreach (@{$self->{lines}}) {
    $self->{maxwidth} = (length($_) > $self->{maxwidth}) ? 
      length($_) : $self->{maxwidth};
  }
  $self;
}

=head2 Tui::Editarea::insertnewline

Insert a newline at the cursor.

=over 2

=item Input Parameters

  1 x coordinate
  2 y coordinate
  3 boolean whether to leave xpos and ypos (for fute extension)

=item Output Parameters

  1 reference to the object

=back

=cut

sub insertnewline {
  my ($self) = shift;
  my ($xpos) = shift;
  my ($ypos) = shift;
  my ($nonewcoords) = shift;

  # it's a newline!
    # get the lines before and after the current line

  my (@list1, @list2);
  @list1 = ();
  @list2 = ();
  if ($self->{ypos} > 0) {
    @list1 = @{$self->{lines}}[0 .. $self->{ypos} - 1];
  }
  if ($self->{ypos} < $#{$self->{lines}}) {
    @list2 = @{$self->{lines}}[$self->{ypos} + 1 .. $#{$self->{lines}}];
  }

  # create the splitted lines
  my ($line1,$line2);
  if ($self->{xpos} == 0) {
    $line2 = ${$self->{lines}}[$self->{ypos}];
  } elsif ($self->{xpos} == length(${$self->{lines}}[$self->{ypos}])) {
    $line1 = ${$self->{lines}}[$self->{ypos}];
  } else {
    $line1 = substr(${$self->{lines}}[$self->{ypos}], 0 , $self->{xpos});
    $line2 = substr(${$self->{lines}}[$self->{ypos}], $self->{xpos},
      length(${$self->{lines}}[$self->{ypos}]));
  }
  
  # empty the lines list
  # fill it with the new lists
  # set cursor xpos to 0
  # move cursor down
  # adjust ystart if it moved offscreen
  # correct maxwidth and xpos
  # redraw the text

  @{$self->{lines}} = ();
  push @{$self->{lines}},@list1,$line1,$line2,@list2;
  if (!$nonewcoords) {
    $self->{xpos} = 0;
    $self->{ypos}++;
    if ($self->{ypos} > $self->{ystart} + $self->{rows} - 2) {
      $self->{ystart}++;
    }
    $self->calcmaxwidth;
    $self->adjustxpos;
    
  }
  
  $self->{redrawtext} = 1;
  $self;
}

=head2 Tui::Editarea::insertchar

Insert a character at the cursor taking into account the insertmode

=over 2

=item Input Parameters

  1 the character to be inserted

=item Output Parameters

  1 reference to the object

=back

=cut

sub insertchar {
  my ($self) = shift;
  my ($char) = shift;
  
  # if it's not a newline
  # insert the character into the line (obaying insetmode)
  # advance cursor
  # if cursor went out of the area, adjust the area
  # if this is the longest line now, adjust maxwidth

  if ($char ne "\n") {
    substr(${$self->{lines}}[$self->{ypos}],$self->{xpos},
      $self->{insertmode}) = $char;
    $self->{xpos}++;
    if ($self->{xpos} > $self->{xstart} + $self->{cols} - 2) {
      $self->{xstart}++;
    }
    if (length(${$self->{lines}}[$self->{ypos}]) > $self->{maxwidth}) {
      $self->{maxwidth} = length(${$self->{lines}}[$self->{ypos}]);
    }
    $self->{redrawtext} = 1;
  } else {
    
    # otherwise insert e newline

    $self->insertnewline($self->{xpos},$self->{ypos});
  }
  $self;
}

=head2 Tui::Editarea::backspace

Delete the character before the cursor

=over 2

=item Input Parameters

  1 none

=item Output Parameters

  1 reference to the object

=back

=cut

sub backspace {
  my ($self) = shift;
  
  my ($part1,$part2);
  my (@list1, @list2);

  # if it is not the 1st char on a line (which means joining 2 lines)
  # get part of line before cursor
  # get part of line after cursor
  # merge 2 parts together
  # move cursor left one pos
  # redraw text

  if ($self->{xpos} > 0) {
    $part1 = substr(${$self->{lines}}[$self->{ypos}],0,$self->{xpos} - 1);
    $part2 = substr(${$self->{lines}}[$self->{ypos}],$self->{xpos},
      $self->{maxwidth});
    ${$self->{lines}}[$self->{ypos}] = $part1 . $part2;
    $self->{xpos}--;
    if ($self->{xpos} < $self->{xstart}) {
      $self->{xstart}--;
    }
    $self->calcmaxwidth;
    $self->{redrawtext} = 1;
  
  # otherwise if we're not on the 1st line
  # get a lsit of lines before the cursor
  # if there are more lines after the line with the cursor
  # get a list of lines after
  # merge the current line with the one before it
  # empty the lines array
  # fill it with the 2 parts
  # move cursor up 1 line
  # if need be adjust ystart
  # calculate the maxwidth again
  # adjust xpos if need be
  # redraw text

  } elsif ($self->{ypos} > 0) {
    @list1 = @{$self->{lines}}[0 .. $self->{ypos} - 1];
    if ($self->{ypos} < $#{$self->{lines}}) {
      @list2 = @{$self->{lines}}[$self->{ypos} + 1 .. $#{$self->{lines}}];
    }
    $self->{xpos} = length($list1[$self->{ypos} - 1]);

    $list1[$self->{ypos} - 1] .= ${$self->{lines}}[$self->{ypos}];
    @{$self->{lines}} = ();
    push @{$self->{lines}},@list1,@list2;
    $self->{ypos}--;
    if ($self->{ypos} < $self->{ystart}) {
      $self->{ystart}--;
    }
    $self->calcmaxwidth;
    if ($self->{xpos} > $self->{xstart} + $self->{cols} - 2) {
      $self->{xstart} = $self->{xpos} - $self->{cols} + 2;
    }
    $self->{redrawtext} = 1;
  }
  $self;
}

=head2 Tui::Editarea::delchar

Delete a character at the cursor

=over 2

=item Input Parameters

  1 none

=item Output Parameters

  1 reference to the object

=back

=cut
sub delchar {
  my ($self) = shift;
  my ($part1,$part2);
  my (@list1, @list2);

  # if the cursor is not at the last character on the line
  # get the part of the line before and after the cursor
  # paste 'em back together
  # calculate max width again
  # redraw the text

  if ($self->{xpos} < length(${$self->{lines}}[$self->{ypos}])) {
    $part1 = substr(${$self->{lines}}[$self->{ypos}],0,$self->{xpos});
    $part2 = substr(${$self->{lines}}[$self->{ypos}],$self->{xpos} + 1,
      $self->{maxwidth});
    ${$self->{lines}}[$self->{ypos}] = $part1 . $part2;
    $self->calcmaxwidth;
    $self->{redrawtext} = 1;

  # otherwise we have to delete a newline if it is not the last char of the 
  # text
  # get the lines before the cursor
  # get lines after the cursor (if they exists)
  # paste the line below the cursor to the current one
  # push both linelists together again
  # calculate max width again
  # redraw the text

  } elsif ($self->{ypos} < $#{$self->{lines}}) {
    @list1 = @{$self->{lines}}[0 .. $self->{ypos}];
    if ($self->{ypos} + 1 < $#{$self->{lines}}) {
      @list2 = @{$self->{lines}}[ $self->{ypos} + 2 .. $#{$self->{lines}} ];
    }
    $list1[$self->{ypos}] .= ${$self->{lines}}[$self->{ypos} + 1];
    @{$self->{lines}} = ();
    push @{$self->{lines}},@list1,@list2;
    $self->calcmaxwidth;
    $self->{redrawtext} = 1;
  }
  $self;
}

=head2 Tui::Editarea::movecursor

Move the cursor within the editarea according to 2 delta's

=over 2

=item Input Parameters

  1 delta x
  2 delta y

=item Output Parameters

  1 reference to the object

=back

=cut
sub movecursor {
  my ($self) = shift;
  my ($deltax) = shift;
  my ($deltay) = shift;

  # if we're move an x coord

  if ($deltax) {
    
    # if the move would result in an illegal move 
    # (before column 0 or beyond the width of the line)
    # return

    if (($self->{xpos} + $deltax < 0) || 
      ($self->{xpos} + $deltax > length(${$self->{lines}}[$self->{ypos}]))) {
      return;
    }

    # move the x coord
    # if x moved beyond the screen
    # move startx
    # otherwise if x moved before screen
    # move startx
    # if we;ve moved beyond the beginning,
    # correct it

    $self->{xpos} += $deltax;
    if ($self->{xpos} > $self->{xstart} + $self->{cols} - 2) {
      $self->{xstart} += $deltax;
      $self->{redrawtext} = 1;
    } elsif ($self->{xpos} < $self->{xstart}) {
      $self->{xstart} += $deltax;
      $self->{redrawtext} = 1;
      if ($self->{xstart} < 0) {
        $self->{xstart} = 0;
      }
    }
  }

  # if we're move the y coord
  # move the coord
  # if we've moved before line 0
  # set to line 0
  # otherwise if we've moved beyond the text
  # set to end of text
  # if xpos is beyond the length of the line
  # set it to the end
  # adjust the xstart
  # if we've moved beyond the end of the window
  # adjust ystart
  # otherwise if we've moved before the window
  # adjust ystart

  if ($deltay) {
    $self->{ypos} += $deltay;
    if ($self->{ypos} < 0) {
      $self->{ypos} = 0;
    } elsif ($self->{ypos} > $#{$self->{lines}}) {
      $self->{ypos} = $#{$self->{lines}};
    }
    if ($self->{xpos} > length(${$self->{lines}}[$self->{ypos}])) {
      $self->adjustxpos;
    } 
    if ($self->{ypos} > $self->{ystart} + $self->{rows} - 2) {
      $self->{ystart} += $deltay;
      $self->{redrawtext} = 1;
    } elsif ($self->{ypos} < $self->{ystart}) {
      $self->{ystart} += $deltay;
      $self->{redrawtext} = 1;
    }

    # if ystart is < 0
    # adjust it
    # otherwise if there are more lines than rows
    # if ystart + rows larger beyond last line
    # adjust ystart

    if ($self->{ystart} < 0) {
      $self->{ystart} = 0;
    } elsif ($#{$self->{lines}} > $self->{rows} - 2) {
      if ($self->{ystart} + $self->{rows} - 2 > $#{$self->{lines}}) {
        $self->{ystart} = $#{$self->{lines}} - $self->{rows} + 2;
      }
    }
  }
  $self;
}

sub movecursorhome {
  my ($self) = shift;

  # move xpos to beginning
  # move xstart to beginning
  # redraw text
  # return object ref

  $self->{xpos} = 0;
  $self->{xstart} = 0;
  $self->{redrawtext} = 1;
  $self;
}

sub movecursorend {
  my ($self) = shift;

  # move the xpos to the end of the line
  # if the xpos is outside the view
  # adjust xstart
  # if we've overadjusted it reajust it (clear huh?)
  # set redraw text on

  $self->{xpos} = length(${$self->{lines}}[$self->{ypos}]);
  if ($self->{xpos} > $self->{xstart} + $self->{cols} - 2) {
    $self->{xstart} = $self->{xpos} - $self->{cols} + 2;
    if ($self->{xstart} < 0) {
      $self->{xstart} = 0;
    }
    $self->{redrawtext} = 1;
  }
  $self;
}


=head2 Tui::Editarea::run

Actuall run the editarea widget

=over 2

=item Input Parameters

  1 none

=item Output Parameters

  1 result code

=back

=cut

sub run {
  my ($self) = shift;

  my ($key,$keycode,$result);

  $self->draw(1);
  $self->redrawtext;
  $self->draw(1,1);
  refresh($self->{win});
  
  while (1) {
    
    # get the input

    ($key,$keycode) = Tui::getkey;

    ($keycode == 2) && ($self->{insertmode} = $self->{insertmode} ? 0 : 1);
    ($keycode == 7) && ($self->movecursor(0,-1));
    ($keycode == 8) && ($self->movecursor(0,1));
    ($keycode == 9) && ($self->movecursor(1,0));
    ($keycode == 10) && ($self->movecursor(-1,0));
    ($keycode == 5) && ($self->movecursor(0,($self->{rows} - 2) * -1));
    ($keycode == 6) && ($self->movecursor(0,$self->{rows} - 2));
    ($keycode == 11) && ($self->backspace);
    ($keycode == 3 || $keycode == 14) && ($self->delchar);
    ($keycode == 1 || $keycode == 23) && ($self->movecursorhome);
    ($keycode == 4 || $keycode == 24) && ($self->movecursorend);
    if ($keycode == 200) {
      if ($key eq "\t") {
        $result = 7;
        last;
      } elsif ($key !~ /[\r]/) {
        $self->insertchar($key);
      }
    }
    if ($keycode == 13) {
      $result = 6;
      last;
    } elsif ($self->{exitonaltx} && $keycode == 19) {
      $result = 9;
      last;
    } elsif ($self->{exitonalth} && $keycode == 18) {
      $result = 10;
      last;
    } elsif ($self->{exitonaltenter} && $keycode == 50) {
      $result = 11;
      last;
    }
      
    # redraw and refresh widget

    $self->draw(1,1);
    refresh($self->{win});
  }
  
  # redraw widget in nonfocus mode

  $self->draw;
  $self->redrawtext;
  refresh($self->{win});
  
  # return result

  $result;
}

########################################################


=head1 CLASS Tui::Menu

A sub menu widget. This is used by L<CLASS Tui::Menubar>.

Inherits from L<CLASS Tui::Widget>.

=cut

package Tui::Menu;

use Curses;
@ISA = (Tui::Widget);

=head2 Tui::Menu::new

Constructor for the menu widget, this is actually meant as a sub menu.

=over 2

=item Input Paramters

  1 x coordinate of the left top
  2 y coordinate of the left top
  3 window of the parent
  4 list of entries to put in menu

=item Ouput Parameters

  1 reference to the object

=back

=cut

sub new {
  my ($class) = shift;
  my ($self) = {};
  bless $self,$class;

  $self->{x1} = shift;
  $self->{y1} = shift;
  $self->{win} = shift;
  push @{$self->{entries}},@_;

  $self->{color} = 0;

  # get width of the thing by getting the widest entry
  # increase it by 6
  # get the amount of rows (amount of entries plus 3)
  # create a window

  $self->{cols} = 0;
  foreach (@{$self->{entries}}) {
    (length($_) > $self->{cols}) && ($self->{cols} = length($_));
  }
  $self->{cols} += 6;
  $self->{rows} = $#{$self->{entries}} + 3;
  $self->{subwin} = newwin($self->{rows},$self->{cols},$self->{y1} + 1,
    $self->{x1});

  # start at position 0
  # return object

  $self->{ypos} = 0;
  $self;
}

=head2 Tui::Menu::draw

Draws the Menu widget. You shouldn't need to call this, the run method will.

=over 2

=item Input Paramters

  1 none

=item Ouput Parameters

  1 reference to the object

=back

=cut

sub draw {
  my ($self) = shift;
  my ($line);

  # draw the box around the submenu
  # replace the topline so it flows nicely from the menubar
  # move to the left and print a UR
  # print a whole bunch of spaces
  # print a UL

  Tui::drawbox(0,0,$self->{cols} - 1,$self->{rows} - 1, 
      $self->{color},1,$self->{subwin});
  attron($self->{subwin},COLOR_PAIR(2));
  move($self->{subwin},0,0);
  addch($self->{subwin},ACS_URCORNER);
  attron($self->{subwin},COLOR_PAIR(1));
  addstr($self->{subwin}," " x ($self->{cols} - 2));
  addch($self->{subwin},ACS_ULCORNER);
  
  # now print the entries itself
  # go through each one
  # make a line longer than the width (just in case)
  # just use the needed part
  # move to the right position
  # print a space
  # if this is the currently selected one set the selected color
  # print the entry
  # go back to the normal color
  # print another space

  foreach (0..$#{$self->{entries}}) {
    $line = " " . ${$self->{entries}}[$_] . " " x ($self->{cols} - 1);
    $line = substr($line,0,$self->{cols} - 4);
    attron($self->{subwin},COLOR_PAIR(1));
    move($self->{subwin},$_ + 1,1);
    addstr($self->{subwin}," ");
    ($_ == $self->{ypos}) && (attron($self->{subwin},COLOR_PAIR(3)));
    addstr($self->{subwin},$line);
    attron($self->{subwin},COLOR_PAIR(1));
    addstr($self->{subwin}," ");

  }

  # flush the output
  # return reference to the object

  refresh($self->{subwin});
  $self
}

=head2 Tui::Menu::run

Actually runs the sub menu.

=over 2

=item Input Paramters

  1 none

=item Ouput Parameters

  1 result of the window which can be 1 of the following
    1 entry was selected
    2 menu is closed now
    3 we moved right
    4 we moved left
  2 last chosen entry

=back

=cut

sub run {
  my ($self) = shift;
  
  my ($key,$keycode);
  my ($result) = 0;

  # draw ourselves
  # until we exit do
  
  $self->draw;
  while (1) {

    # get the keypress
    # move up and down as need be
    # if we've moved before the 1st entry (close menu)
    # return 2 end exit
    # same for right and left
    # if enter was pressed return resul = 1

    ($key,$keycode) = Tui::getkey;
    ($keycode == 7) && ($self->{ypos}--);
    ($keycode == 8) && ($self->{ypos}++);
    if ($self->{ypos} < 0) {
      $result = 2;
      last;
    }
    if ($keycode == 9) {
      $result = 3;
      last;
    }
    if ($keycode == 10) {
      $result = 4;
      last;
    }
    ($self->{ypos} > $#{$self->{entries}}) && 
      ($self->{ypos} = $#{$self->{entries}});
    if ($keycode == 200 && $key eq "\n") {
      $result = 1;
      last;
    }

    # draw submenu again

    $self->draw;
  }

  # hide it
  # return result and entry

  $self->hide;
  
  ($result,$self->{ypos});
}

=head2 Tui::Menu::hide

Hide the submenu. You shouldn't need to call this normally.

=over 2

=item Input Paramters

  1 none

=item Ouput Parameters

  1 reference to the object.

=back

=cut

sub hide {
  my ($self) = shift;

  touchwin($self->{win});
  refresh($self->{win});
  $self;
}
########################################################


=head1 CLASS Tui::Menubar

The name says it all, this is a menubar.

Inherits from L<CLASS Tui::Widget>.

=cut

package Tui::Menubar;

use Curses;
@ISA = (Tui::Widget);

=head2 Tui::Menubar::new

Constructor for the menubar widget.

=over 2

=item Input Paramters

  1 x coordinate of left top (default 0)
  2 y coordinate of left top (default 0)
  3 cols (default whole screen width)

=item Ouput Parameters

  1 reference to the object

=back

=cut

sub new {
  my ($class) = shift;
  my ($self) = {};
  bless $self,$class;

  $self->{x1} = shift | 0;
  $self->{y1} = shift | 0;
  $self->{cols} = shift | $COLS - 1;
  $self->{menus} = [];
  $self->{menuentries} = [];
  $self->{xpos} = 0;
  $self->{ypos} = -1;
  $self->{color} = 0;
  $self->{win} = stdscr;
  $self;
}

=head2 Tui::Menubar::add

Adds a menu to the menubar.

=over 2

=item Input Paramters

  1 name of the submenu
  2..N list of entries in the submenu

=item Ouput Parameters

  1 reference to the object

=back

=cut

sub add {
  my ($self) = shift;

  # add the menuname to the menus attribute
  # add the menu entries joined with a \n to the menuentries 

  push @{$self->{menus}}, shift;
  push @{$self->{menuentries}}, join("\n",@_);

  $self;
}

=head2 Tui::Menubar::reset

Clears all the menus in the bar.

=over 2

=item Input Paramters

  1 none

=item Ouput Parameters

  1 reference to the object

=back

=cut

sub reset {
  my ($self) = shift;

  # clear the menus and the entries
  # return reference to the object

  $self->{menus} = [];
  $self->{menuentries} = [];
  $self;
}

=head2 Tui::Menubar::draw

Draws the menubar.

=over 2

=item Input Paramters

  1 boolean whether the menubar has the focus
  2 index of the menu that is opened (and there's no focus)

=item Ouput Parameters

  1 reference to the object

=back

=cut

sub draw {
  my ($self) = shift;
  my ($focus) = shift;
  my ($opened) = shift;

  my ($line);
  
  # draw the box surounding the menubar
  # move to the first position
  # if we have the focus
  
  Tui::drawbox($self->{x1},$self->{y1},$self->{cols},$self->{x1} + 2,
    $self->{color},1,$self->{win});
  move($self->{win},$self->{y1} + 1,$self->{x1} + 2);
  if ($focus) {

    # go through each line
    # if it is the selected one set another color
    # draw the label

    foreach (0..$#{$self->{menus}}) {
      attron($self->{win},COLOR_PAIR(1));
      ($_ == $self->{xpos}) && (attron($self->{win},COLOR_PAIR(3)));
      $line = " " . ${$self->{menus}}[$_] . " ";
      addstr($self->{win},$line);
    }
  } else {

    # otherwise just use one color
    # go through each one
    # if the current one is the openend one, use bold
    # write the label

    attron($self->{win},COLOR_PAIR(1));
    foreach (0..$#{$self->{menus}}) {
      ($opened == $_) && (attron($self->{win},A_BOLD));
      $line = " " . ${$self->{menus}}[$_] . " ";
      addstr($self->{win},$line);
      ($opened == $_) && (attroff($self->{win},A_BOLD));
    }
  }

  # refresh the output
  # return self

  refresh($self->{win});
  $self;
}

=head2 Tui::Menubar::openmenu

Opens a submenu

=over 2

=item Input Paramters

  1 none

=item Ouput Parameters

  1 result that came back from the submenu
  2 entry that came back from the submenu 

=back

=cut

sub openmenu {
  my ($self) = shift;
  my ($xpos,$submenu,$result,$entry);
  my (@entries);

  # calculate x position of the menu
  # start at pos 2
  # add label widths until we reach teh one we need

  $xpos = $self->{x1} + 2;
  if ($self->{xpos} > 0) {
    foreach (0 .. $self->{xpos} - 1) {
      $xpos += length(${$self->{menus}}[$_]) + 2;
    }
  }
  
  # split the entries string into a list
  # create the submenu
  # run it
  # return the results

  @entries = split(/\n/,${$self->{menuentries}}[$self->{xpos}]);
  $submenu = new Tui::Menu($xpos,$self->{ypos} + 2,$self->{win},@entries);
  ($result,$entry) = $submenu->run;
  ($result,$entry);
}

=head2 Tui::Menubar::run

Runs the menubar, basically keeps running it until you make a choice.

=over 2

=item Input Paramters

  1 none

=item Ouput Parameters

  1 index of the menu you chose from
  2 index of the entry within the sub menu

=back

=cut

sub run {
  my ($self) = shift;
  my ($keycode,$key);
  my ($result,$menu,$entry);

  # default to nothing for now
  # draw ourselves with focus

  $menu = $entry = -1;
  $self->draw(1);

  # until we get out of this loop do
  
  while (1) {

    # we don;t have a result yet
    # get the keypress
    # if it was to the right move right
    # wrap around if we need

    $result = 0;
    ($key,$keycode) = Tui::getkey;
    if ($keycode == 9) {
      $self->{xpos}++;
      ($self->{xpos} > $#{$self->{menus}}) && ($self->{xpos} = 0);
    }

    # if it was to the left move to the left
    # wrap around if we need

    if ($keycode == 10) {
      $self->{xpos}--;
      ($self->{xpos} < 0) && ($self->{xpos} = $#{$self->{menus}});
    }
  
    # if we pressed down or enter
    # do forever
    # draw ourselves with an open menu
    # run the submenu
    # if we moved right move right
    # wrap if need be
    # if we moved to the left move left
    # wrap if need be
    # get out of we made a choice or pressed up

    if ($keycode == 8 || ($keycode == 200 && $key eq "\n")) {
      while (1) {
        $self->draw(0,$self->{xpos});
        ($result,$entry) = $self->openmenu;
        if ($result == 3) {
          $self->{xpos}++;
          ($self->{xpos} > $#{$self->{menus}}) && ($self->{xpos} = 0);
        }
        if ($result == 4) {
          $self->{xpos}--;
          ($self->{xpos} < 0) && ($self->{xpos} = $#{$self->{menus}});
        }
        ($result == 1 || $result == 2) && (last);
      }
    }
    
    # if we made a choice, get out

    ($result == 1) && (last);
    
    # draw ourselves with focus
    # refresh ourselves

    $self->draw(1);
    refresh($self->{win});
  }
  # draw ourselves without focus
  # return the results

  $self->draw;
  ($self->{xpos},$entry);
}


########################################################

=head1 CLASS Tui::Form

Class which provides a dialog form. Widgets can be added to it after
which it can be run. When it exits, the content of the widgets can
be retrieved.

=cut

package Tui::Form;

use Curses;
@ISA = (Tui::Widget);

=head2 Tui::Form::new

Tui::Form contructor

=over 2

=item Input Paramters

  1 title of the form
  2 x coordinate of left top
  3 y coordinate of left top
  4 number of collumns
  5 number of rows
  6 boolean whether to center window
  7 boolean whether to exit on alt-enter (default false)
  8 boolean whether to exit on alt-x (default false)
  9 boolean whether to exit on alt-h (default false)
  
=item Ouput Parameters

  1 reference to object

=back

=cut

sub new {
  my ($class) = shift;
  my ($self) = {};
  bless $self,$class;

  $self->{title} = shift;
  $self->{x1} = shift;
  $self->{y1} = shift;
  $self->{cols} = shift;
  $self->{rows} = shift;
  
  my ($center) = shift;
  if ($center) {
    $self->{x1} = int($COLS / 2) - int($self->{cols} / 2);
    $self->{y1} = int($LINES / 2) - int($self->{rows} / 2);
  }

  $self->{exitonaltenter} = shift;
  $self->{exitonaltx} = shift;
  $self->{exitonalth} = shift;
  
  $self->{color} = 0;
  $self->{style} = 1;
  $self->{win} = newwin($self->{rows} + 1,$self->{cols} + 1,
    $self->{y1} - 1, $self->{x1} - 1
    );
  $self->{widgets} = [];
  $self->{widgetno} = -1;
  $self->{focuswidgetno} = -1;
  $self;
}

=head2 Tui::Form::add

Add widgets to a form. The order in which they are added also sets
the tab order. The first widget to be added gets the focus first.
(unless Tui::Form::setfocus is used).

=over 2

=item Input Paramters

  1 list of widgets

=item Ouput Parameters

  1 reference to object

=back

=cut

sub add {
  my ($self) = shift;
  push @{$self->{widgets}},@_;
  $self;
}

=head2 Tui::Form::setfocus

Sets the initial focus to the widget as supplied by index

=over 2

=item Input Paramters

  1 index of the widget to get initial focus

=item Ouput Parameters

  1 reference to the object

=back

=cut

sub setfocus {
  my ($self) = shift;
  $self->{focuswidgetno} = shift;
  $self;
}
=head2 Tui::From::draw

Draw a form, draws the form and makes each widget draw itself.

=over 2

=item Input Paramters

  1 none

=item Ouput Parameters

  1 reference to object

=back

=cut

sub draw {
  my ($self) = shift;
  my ($widget);

  # draw the box around the form
  # set the window of each widget
  # draw each widget

  Tui::drawbox(0,0, $self->{cols},$self->{rows},
    $self->{color},$self->{style},$self->{win});
  foreach $widget (@{$self->{widgets}}) {
    $widget->setwin($self->{win});
    $widget->draw;
  }
  
  # if there is a title
  # draw it
  # refresh the window so the output goes to the screen

  if ($self->{title}) {
    attron($self->{win},COLOR_PAIR(5));
    attron($self->{win},A_BOLD);
    move($self->{win},0,
      int($self->{cols} / 2) - int(length($self->{title}) / 2));
    addstr($self->{win},$self->{title});
    attroff($self->{win},A_BOLD);
  }
  refresh($self->{win});
  $self;
}

=head2 Tui::Form::xyprint

Prints a string in a form.

=over 2

=item Input Paramters

  1 text
  2 x coordinate
  3 y coordinate
  4 color
  5 boolean whether to do it bold

=item Ouput Parameters

  1 reference tot he object

=back

=cut

sub xyprint {
  my ($self) = shift;
  my ($text) = shift;
  my ($x) = shift;
  my ($y) = shift;
  my ($c) = shift;
  my ($bold) = shift;

  # move to the right place
  # set color
  # bold attribute if need be
  # write
  # turn of bold

  move($self->{win},$y,$x);
  attron($self->{win},COLOR_PAIR($c));
  ($bold) && (attron($self->{win},A_BOLD));
  addstr($self->{win},$text);
  attroff($self->{win},A_BOLD);
  $self;
}

=head2 Tui::Form::xyprintchar

Prints a character in a form.

=over 2

=item Input Paramters

  1 character
  2 x coordinate
  3 y coordinate
  4 color
  5 boolean whether to do it bold

=item Ouput Parameters

  1 reference tot he object

=back

=cut

sub xyprintchar {
  my ($self) = shift;
  my ($text) = shift;
  my ($x) = shift;
  my ($y) = shift;
  my ($c) = shift;
  my ($bold) = shift;

  # move to the right place
  # set color
  # bold attribute if need be
  # write
  # turn of bold

  move($self->{win},$y,$x);
  attron($self->{win},COLOR_PAIR($c));
  ($bold) && (attron($self->{win},A_BOLD));
  addch($self->{win},$text);
  attroff($self->{win},A_BOLD);
  $self;
}

=head2 Tui::From::getwin

Returns the window in which th form operates.

=over 2

=item Input Paramters

  1 none

=item Ouput Parameters

  1 handle of the window

=back

=cut

sub getwin {
  my ($self) = shift;
  $self->{win};
}

=head2 Tui::From::run

Runs the form.

=over 2

=item Input Paramters

  1 boolean whether to leave the dialog after run returns.

=item Ouput Parameters

  1 resultcode
  2 widgetnumber

  The result can be anyone of :

  8 enter pressed
  9 alt-x pressed
  10 alt-h pressed
  11 alt-enter pressed


=back

=cut

sub run {
  my ($self) = shift;
  my ($nohide) = shift;
  my (@runwidgets);
  my ($widget);
  my ($widgetno);
  my ($result);

  # draw the form and everything in it

  $self->draw;
  
  # make a list of runnable widgets
  # go through each widget
  # if it was appointed as the one to recieve initial focus
  # set the focus
  # set the needed exiton__ flags

  foreach (0.. $#{$self->{widgets}}) {
    if (${$self->{widgets}}[$_]->runnable) {
      push @runwidgets,$_;
    }
    if ($self->{focuswidgetno} == $_ && $self->{widgetno} != -1) {
      $self->{widgetno} = $#runwidgets;
    }
    if ($self->{exitonaltx}) {
      ${$self->{widgets}}[$_]->exitonaltx;
    }
    if ($self->{exitonalth}) {
      ${$self->{widgets}}[$_]->exitonalth;
    }
    if ($self->{exitonaltenter}) {
      ${$self->{widgets}}[$_]->exitonaltenter;
    }
    if ($self->{exitonenter}) {
      ${$self->{widgets}}[$_]->exitonenter;
    }
  }
  
  # if there was no widget appointed for initial focus
  # set it to the first one
  if ($self->{widgetno} == -1) {
    $self->{widgetno} = 0;
  }
  $widgetno = $self->{widgetno};

  # now run it until we're ready to leave
  # get the result by running the widget that has the focus
  # if it's 7 (tab) go to next widget
  # if it's 6 (alt-b) go to previous
  # else exit

  while (1) {
    $result = ${$self->{widgets}}[$runwidgets[$widgetno]]->run(
      $self->{x1},$self->{y1});
    ${$self->{widgets}}[$runwidgets[$widgetno]]->draw;
    if ($result == 7) {
      if ($widgetno == $#runwidgets) {
        $widgetno = 0;
      } else {
        $widgetno++;
      }
    } elsif ($result == 6) {
      if ($widgetno == 0) {
        $widgetno = $#runwidgets;
      } else {
        $widgetno--;
      }
    }
    if ($result == 8 || $result == 9 || $result == 10 || 
        $result == 11 || $result == 12) {
      if ($result == 12) {
        $result = 8;
      }
      last;
    }

  }

  # hide the form
  # get the widgetno
  # return 

  $self->hide;
  $widgetno = $runwidgets[$widgetno];
  ($result,$widgetno);
}

=head2 Tui::Form::hide

Hide the form dialog.

=over 2

=item Input Paramters

  1 none

=item Ouput Parameters

  1 reference to object

=back

=cut

sub hide {
  my ($self) = shift;
  touchwin(stdscr);
  refresh(stdscr);
  $self;
}

=head1 AUTHOR

Written by Ronald F. Lens ( ronald@ronaldlens.com )

=head1 HOMEPAGE

The home page is at http://www.ronaldlens.com/tui.html

=head1 TODO

  Finish pod documentation, perhaps a tutorial.
  Document the code more itself (don't know whether I'll understand it
  myself in time;).
  Navigating between the widgets with cursor keys where possible.
  Clean up the code (there is a lot of duplicate code)
  Make use of hardware scrolling in windows.
  Use the panel library, overlapping windows!
  Dialog builder.
  Get the code to live through a use strict;)

=head1 HISTORY

=over 2


=item Version 0.3 August 20th, 1999

Added L<CLASS Tui::Menu> and L<CLASS Tui::Menubar> classes

=item Version 0.4 August 20th, 1999

Added L<Tui_Form_xyprint> and L<Tui_Form_xyprintchar> method

Added L<Tui_Form_setfocus> method.

Added a lot of poddocs.

Fixed some small bugs in the default dailogs 
(they didn't return the correct values)

=item Version 0.2 August 19th, 1999

Added L<Tui_Listbox_reset> method.

Fixed some bugs with misspelled variable names.


=item Version 0.1 August 17th, 1999

  Finished initial version, added lots of poddoc.

=back

=cut

# for compiling

1;


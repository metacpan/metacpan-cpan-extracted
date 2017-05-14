package smg;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
require DynaLoader;
require AutoLoader;

@ISA = qw(Exporter DynaLoader);
# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	
);
$VERSION = '0.01';

bootstrap smg $VERSION;

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

smg - Perl extension for screen management

=head1 SYNOPSIS

  use smg;

=head1 COPYRIGHTS

 This package was released under the terms of the artistic license
 which terms are in the file copy.art.


=head1 DESCRIPTION

This package uses the OpenVMS screen management utility. Curses work in a very poorly way
on this system, while the native SMG package takes care of all the terminals
you defined in the terminal library, of all collating tables you might have defined ...

It is obvious that this package is not portable on other OSs  :-<

if you want to be informed of any new release mail to smg@tebbal.demon.co.uk

=head1 initscr

syntax 
initscr( $PbId, $KbId);

I<screen> 4bytes integer is a pointer to the main screen definition.
I<kb> 4bytes integer is a pointer to the keyboard definition.

=head1 changewinattr 

Changes the video attributes
for all or part of a window.


B<Syntax:>

           changewinattr  ($win ,$Y ,$X ,$nb_lines ,$nb_cols ,$attr );



B<Parameters:>

=over

I<$nb_cols:> Horizontal width of the rectangle which attributes are to
              be modified.

I<$nb_lines:> Vertical height of the rectangle which attributes are to
              be modified.

I<$attr:> A character string with one character/attribute:

=over 6

I<I:>  Invisible;

I<B:>  Bold;

I<R:>  Reverse;

I<U:>  Underline;

I<F:>  Flashing

I<1:>  terminal user defined feature number 1;

I<2:>  terminal user defined feature number 2;

I<4:>  terminal user defined feature number 4;

I<5:>  terminal user defined feature number 5;

I<6:>  terminal user defined feature number 6;

I<7:>  terminal user defined feature number 7;

I<8:>  terminal user defined feature number 8;

=back

  The user defined features are more often ansi colours and are
  available on Xterms or on colour terminals and colour terminal emulators
  VT2XX and over.
  For a normal rendition just send the string "\0"

I<$X:> Number of the column ( leftmost column is number 1 ) of the upper left
corner.

I<$Y:> Number of the line ( top line is number 1 ) of the upper left
corner.

I<$win:> the window you created with crewin or loadwin

=back


=head1 changewinsize  

         The function lets you change the
         dimensions of a window.


B<Syntax:>

           changewinsize  ($win ,$nb_lines ,$nb_cols);
     


B<Parameters:>

=over

I<$nb_cols:> Number of columns of the new window

I<$nb_lines:> Number of lines of the new window

I<$win:> the window you created with crewin or loadwin

=back


=head1 cremenu  

The function displays
menu choices in the window indicated, starting at the
specified line.


B<Syntax:>

           cremenu  ($win ,$choices ,$option_size ,$flags ,$Y ,$attr);

                            
       

B<Parameters:>

=over

I<$attr:> A character string with one character/attribute:

=over 6

I<I:>  Invisible;

I<B:>  Bold;

I<R:>  Reverse;


I<F:>  Flashing

I<1:>  terminal user defined feature number 1;

I<2:>  terminal user defined feature number 2;

I<3:>  terminal user defined feature number 3;

I<4:>  terminal user defined feature number 4;

I<5:>  terminal user defined feature number 5;

I<6:>  terminal user defined feature number 6;

I<7:>  terminal user defined feature number 7;

I<8:>  terminal user defined feature number 8;

=back

  The user defined features are more often ansi colours and are
  available on Xterms or on colour terminals and colour terminal emulators
  VT2XX and over.
  For a normal rendition just send the string "\0"

I<$Y:> Number of the line ( top line is number 1 )

I<$flags:> A character string with one character/option:

=over

I<D:> Double-spaced rows of menu items. The default
     is single spaced.

I<F:> Each menu item is in a fixed-length field. The is the size of the 
     largest menu item. The default is compress.

I<W:> Wide characters are used in the menu items.
     The default is normal sized characters.

I<B:> The menu items are displayed in matrix format (default).

I<V:> Each menu item is displayed on its own line.

I<H:> The menu items are displayed all on one line.

=back
   
I<$win:> the window you created with crewin or loadwin : it will contain
         the menu options.

I<$option_size:> size of every item in $choices . $choices will be sliced
         according to this value.

=back


=head1 cresubwin  

         The function creates a subwindow (called viewport in VMS terminology)
	 and associates it with a window. The location and size of
         the subwindow are specified by the caller. When the window is sent
	 to screen, only the part mapped by the subwindow will be put on the
	 screen but it will be possible to move the subwindow over the window
	 to browse all the window.


B<Syntax:>

           cresubwin  ($win ,$Y ,$X ,$nb_lines ,$nb_cols);
       



B<Parameters:>

=over

I<$nb_cols:> Number of columns to show on screen

I<$nb_lines:> Number of lines to show on screen

I<$X:> Number of the column where start the subwindow ( leftmost column is number 1 )

I<$Y:> Number of the line where start the subwindow ( top line is number 1 )

I<$win:> the window you created with crewin or loadwin and which visible part
will be reduced to the subwindow.

=back


=head1 crewin

The function creates a window and
returns its assigned display identifier (please note it will not be visible
until you use putwin() ).


B<Syntax:>
	   crewin($Y,$X,$winId,$attr)

       

B<Parameters:>

=over

I<$attr:> A character string with one character/attribute:

=over 6

I<L:>  A lined border will be drawn around the window.

I<B:>  A thick block border will be drawn around the window.

=back

Note that the window needs a border in order to have a title.

  For a normal rendition just send the string "\0"

I<$X:> Number of columns in the window (excluding the border).

I<$Y:> Number of lines in the window (excluding the border).

I<$winId:> the identifier of the window you want to create.

=back


=head1 curcol  

         The function returns the virtual
         cursor's current column position in a specified window.


B<Syntax:>

           curcol  ($win);

       

B<Parameters:>

=over

I<$win:> the window you created with crewin or loadwin

=back


=head1 curline  

         The function returns the virtual
         cursor's current line position in a specified window.


B<Syntax:>

           curline  ($win)
       

B<Parameters:>

=over

I<$win:> the window you created with crewin or loadwin

=back


=head1 delchars  

         The function deletes characters in a window.


B<Syntax:>

           delchars  ($win ,$nb_chars ,$Y ,$X);
       

B<Parameters:>

=over

I<$nb_chars:> Number of characters to delete.

I<$X:> Number of the column where is starting the deletion
( leftmost column is number 1 )

I<$Y:> Number of the line where is starting the deletion 
( top line is number 1 )

I<$win:> the window you created with crewin or loadwin

=back


=head1 delline  

         The function deletes lines from a window.


B<Syntax:>

           delline  ($win ,$Y ,$nb_lines);
       



B<Parameters:>

=over

I<$nb_lines:> Number of lines to delete.

I<$Y:> Number of the first line to delete( top line is number 1 )

I<$win:> the window you created with crewin or loadwin

=back


=head1 delmenu  

         The function ends access to the menu choices in the specified window.


B<Syntax:>

           delmenu  ($win);
       

B<Parameters:>

=over


I<$win:> the window you created with crewin or loadwin and where you created
this menu.

=back


=head1 delwin  

         The function deletes a window.


B<Syntax:>

           delwin  ($win);
       

B<Parameters:>

=over

I<$win:> the window you created with crewin or loadwin .

=back


=head1 drawline  

         The function draws a horizontal or vertical line.


B<Syntax:>

           drawline  ($win ,$Y0 ,$X0 ,$Y1 ,$X1 ,$attr);

                          
       

B<Parameters:>

=over

I<$X0:> Number of the column of line start point ( leftmost column is number 1 )

I<$Y0:> Number of the row of line start point ( top line is number 1 )

I<$X1:> Number of the column of line end point ( leftmost column is number 1 )

I<$Y1:> Number of the row of line end point ( top line is number 1 )

I<$win:> the window you created with crewin or loadwin

I<$attr:> A character string with one character/attribute:

=over 6

I<I:>  Invisible;

I<B:>  Bold;

I<R:>  Reverse;

I<U:>  Underline;

I<F:>  Flashing

I<1:>  terminal user defined feature number 1;

I<2:>  terminal user defined feature number 2;

I<3:>  terminal user defined feature number 3;

I<4:>  terminal user defined feature number 4;

I<5:>  terminal user defined feature number 5;

I<6:>  terminal user defined feature number 6;

I<7:>  terminal user defined feature number 7;

I<8:>  terminal user defined feature number 8;

=back

  The user defined features are more often ansi colours and are
  available on Xterms or on colour terminals and colour terminal emulators
  VT2XX and over.
  For a normal rendition just send the string "\0"

=back


=head1 drawbox  

         The function draws a rectangle.


B<Syntax:>

           drawbox  ($win ,$Y0 ,$X0 ,$Y1 ,$X1 ,$attr);

                               
       

B<Parameters:>

=over

I<$attr:> A character string with one character/attribute:

=over 6

I<I:>  Invisible;

I<B:>  Bold;

I<R:>  Reverse;

I<U:>  Underline;

I<F:>  Flashing

I<1:>  terminal user defined feature number 1;

I<2:>  terminal user defined feature number 2;

I<3:>  terminal user defined feature number 3;

I<4:>  terminal user defined feature number 4;

I<5:>  terminal user defined feature number 5;

I<6:>  terminal user defined feature number 6;

I<7:>  terminal user defined feature number 7;

I<8:>  terminal user defined feature number 8;

=back

  The user defined features are more often ansi colours and are
  available on Xterms or on colour terminals and colour terminal emulators
  VT2XX and over.
  For a normal rendition just send the string "\0"

I<($X0,$Y0) and ($X1,$Y1):> are coordinates of one of the box diagonals.

I<$win:> the window you created with crewin or loadwin

=back


=head1 erasechars  

         The function erases characters in a virtual
         display by replacing them with blanks.


B<Syntax:>

           erasechars  ($win ,$nb_chars ,$Y, $X);
       



B<Parameters:>

=over

I<$nb_chars:> Number of characters to erase.

I<$X:> Number of the column where the erase process starts 
( leftmost column is number 1 )

I<$Y:> Number of the line where the erase process starts 
( top line is number 1 )


I<$win:> the window you created with crewin or loadwin

=back


=head1 erasecol  

         The function erases the specified
         portion of the window from the given position to the
         end of the column. Erases the column number $X from 
	 line number $Y0 to line number $Y1


B<Syntax:>

           erasecol  ($win ,$Y0 ,$X ,$Y1 );
	   

B<Parameters:>

=over


I<$X:> Number of the column ( leftmost column is number 1 )


I<$Y0:> Number of the starting line ( top line is number 1 )

I<$Y1:> Number of the ending line ( top line is number 1 )

I<$win:> the window you created with crewin or loadwin

=back


=head1 erasewin  

         The function erases all or part of a virtual
         display by replacing text characters with blanks.


B<Syntax:>

           erasewin  ($win ,$Y0 ,$X0 ,$Y1 ,$X1);
       



B<Parameters:>

=over

I<($X0,$Y0) and ($X1,$Y1):> are coordinates of one of the diagonals of
the rectangular area to erase.

I<$win:> the window you created with crewin or loadwin

=back


=head1 eraseline  

         The function erases all or part of a line in a virtual
         display. Erase line number $Y from column $X to the end
	 of line.


B<Syntax:>

           eraseline  ($win ,$Y ,$X);
       

B<Parameters:>

=over

I<$X:> Number of the column where line erasing starts ( leftmost column is number 1 )

I<$Y:> Number of the line to erase ( top line is number 1 )

I<$win:> the window you created with crewin or loadwin

=back


=head1 clearscreen  

         The function erases the contents of a physical screen.


B<Syntax:>

           clearscreen  ($PbId);
       



B<Parameters:>

=over

I<$PbId:> The physical screen you defined in initscr

=back


=head1 insertchars  

         The function inserts characters into a virtual
         display.


B<Syntax:>

           insertchars  ($win , $string ,$Y ,$X ,$attr);
       



B<Parameters:>

=over

I<$string:> Character string to insert in window. 

I<$attr:> A character string with one character/attribute:

=over 6

I<I:>  Invisible;

I<B:>  Bold;

I<R:>  Reverse;

I<U:>  Underline;

I<F:>  Flashing

I<1:>  terminal user defined feature number 1;

I<2:>  terminal user defined feature number 2;

I<3:>  terminal user defined feature number 3;

I<4:>  terminal user defined feature number 4;

I<5:>  terminal user defined feature number 5;

I<6:>  terminal user defined feature number 6;

I<7:>  terminal user defined feature number 7;

I<8:>  terminal user defined feature number 8;

=back

  The user defined features are more often ansi colours and are
  available on Xterms or on colour terminals and colour terminal emulators
  VT2XX and over.
  For a normal rendition just send the string "\0"

I<$X:> Number of the column where the insertion starts
( leftmost column is number 1 )

I<$Y:> Number of the line where the insertion starts
( top line is number 1 )

I<$win:> the window you created with crewin or loadwin

=back


=head1 insertline  

         The function inserts a line into a window and
         scrolls the following lines or the previous lines
	 according to $direction.


B<Syntax:>

           insertline  ($win ,$Y , $string ,$direction ,$attr);
       


B<Parameters:>

=over

I<$string:> Character string containing the line to insert.

I<$direction:>A one character string:

=over 6

I<U:> Preceding will be scrolled up, the first line will be lost.

I<D:> following will be scrolled down, the last line will be lost.

=back

I<$attr:> A character string with one character/attribute:

=over 6

I<I:>  Invisible;

I<B:>  Bold;

I<R:>  Reverse;

I<U:>  Underline;

I<F:>  Flashing

I<1:>  terminal user defined feature number 1;

I<2:>  terminal user defined feature number 2;

I<3:>  terminal user defined feature number 3;

I<4:>  terminal user defined feature number 4;

I<5:>  terminal user defined feature number 5;

I<6:>  terminal user defined feature number 6;

I<7:>  terminal user defined feature number 7;

I<8:>  terminal user defined feature number 8;

=back

  The user defined features are more often ansi colours and are
  available on Xterms or on colour terminals and colour terminal emulators
  VT2XX and over.
  For a normal rendition just send the string "\0"

I<$Y:> Number of the line ( top line is number 1 ) to insert.

I<$win:> the window you created with crewin or loadwin

=back


=head1 codetoname  

         The function translates the
         key code of a key on the keyboard into its associated key name.


B<Syntax:>

           codetoname  ($code ,$name);
       

B<Parameters:>

=over

I<$name:> Ascii String Giving The name of the pressed key.

I<$code:> A 2byte integer number last pressed code; this code is 
           using 0-255 for extended ascii character set, and over for
	   the other keys (ex: F10, PF2, SELECT ...)

=back


=head1 labelwin  

         The function supplies a label for a
         window's border. Note that the window must have created with
	 a border.


B<Syntax:>

           labelwin  ($win ,$text ,$position ,$offset ,$attr );

       

B<Parameters:>

=over

I<$text:> Text of the label.

I<$position:> a one character string saying on which side is the label:

=over 6

I<T:> The label will be on the top side of the border.

I<B:> The label will be on the bottom side of the border.

I<L:> The label will be on the left side of the border.

I<R:> The label will be on the right side of the border.

=back

I<$offset:> Position where start the label.

I<$attr:> A character string with one character/attribute:

=over 6

I<I:>  Invisible;

I<B:>  Bold;

I<R:>  Reverse;

I<U:>  Underline;

I<F:>  Flashing

I<1:>  terminal user defined feature number 1;

I<2:>  terminal user defined feature number 2;

I<3:>  terminal user defined feature number 3;

I<4:>  terminal user defined feature number 4;

I<5:>  terminal user defined feature number 5;

I<6:>  terminal user defined feature number 6;

I<7:>  terminal user defined feature number 7;

I<8:>  terminal user defined feature number 8;

=back

  The user defined features are more often ansi colours and are
  available on Xterms or on colour terminals and colour terminal emulators
  VT2XX and over.
  For a normal rendition just send the string "\0"

I<$win:> the window you created with crewin or loadwin

=back


=head1 loadwin 

         The function creates a new window and loads it with a window 
	 saved with savwin.


B<Syntax:>

           loadwin  ($win ,$filespec);
       

B<Parameters:>

=over

I<$filespec:> the specification of the file containing the window saved
              with savewin (wild cards are not allowed).

I<$win:> the window you created with crewin and saved with savwin

=back


=head1 movearea  

         The Move function moves a rectangle of text from one window to 
	 another window. Given two points in opposite corners of the rectangle.
         When $win and $towin are the same windows the intersection between
	 source area and target area may not be what you expect. :-)

B<Syntax:>

           movearea  ($win ,$Y0 ,$X0 ,$Y1 ,$X1, $towin, $toY, $toX, $flags);

       



B<Parameters:>

=over

I<($X0,$Y0) and ($X1,$Y1):> are coordinates of two opposite corners of
the rectangle to move.

I<$toX:> Number of the column where to copy the area

I<$toY:> Number of the line where to copy the area.

I<$flags:> A character string with one character/option:

=over

I<C:> Just copy don't erase text from source window.

I<T:> Move only the text not the video attributes.

=back

I<$win:> the window you created with crewin or loadwin

I<$towin:> another window you created with crewin or loadwin

=back


=head1 movewin  

         The function relocates a window on a
         physical screen and preserves the pasting order.


B<Syntax:>

           movewin  ($win ,$PbId, $Y, $X);

       

B<Parameters:>

=over

I<$X,$Y:>  New position of the window on the physical screen.

I<$PbId:> The physical screen you defined in initscr

I<$win:> the window you created with crewin or loadwin

=back


=head1 nametocode  

         The function translates the
         key name of a key on the keyboard into its associated key code.


B<Syntax:>

           nametocode  ($name ,$code);
       



B<Parameters:>

=over

I<$name:> Ascii String Giving The name of the pressed key.

I<$code:> A 2byte integer number last pressed code; this code is 
           using 0-255 for extended ascii character set, and over for
	   the other keys (ex: F10, PF2, SELECT ...)

=back


=head1 putwin

         The function pastes a window to a
         physical screen.


B<Syntax:>

           putwin($Y,$X,$winId,$PbId);

       

B<Parameters:>

=over

I<$X:> Number of the column on the physical screen where to display
this window ( leftmost column is number 1 ).

I<$Y:> Number of the line on the physical screen where to display
this window ( top line is number 1 ).

I<$PbId:> The physical screen you defined in initscr

I<$winId:> the window you created with crewin or loadwin

=back


=head1 printscreen  

         The function prints the
         contents of the specified physical screen on a line printer.


B<Syntax:>

           printscreen  ($PbId ,$queue); 

       

B<Parameters:>

=over

I<$PbId:> The physical screen you defined in initscr

I<$queue:> Name of the printer queue where to submit the print job.

=back


=head1 putchars

         The function writes
         characters in a window with the text you specify.


B<Syntax:>
           putchars($winId,$SmgX,$SmgY,$SMGString,$attrib);

       



B<Parameters:>

=over

I<$SmgX:> Number of the starting column of the string 
( leftmost column is number 1 )

I<$SmgY:> Number of the line where to write the string ( top line is number 1 )

I<$SmgString:> Character string containing the text to write in the window

I<$attrib:> A character string with one character/attribute:

=over 6

I<I:>  Invisible;

I<B:>  Bold;

I<R:>  Reverse;

I<U:>  Underline;

I<F:>  Flashing

I<1:>  terminal user defined feature number 1;

I<2:>  terminal user defined feature number 2;

I<3:>  terminal user defined feature number 3;

I<4:>  terminal user defined feature number 4;

I<5:>  terminal user defined feature number 5;

I<6:>  terminal user defined feature number 6;

I<7:>  terminal user defined feature number 7;

I<8:>  terminal user defined feature number 8;

=back

  The user defined features are more often ansi colours and are
  available on Xterms or on colour terminals and colour terminal emulators
  VT2XX and over.
  For a normal rendition just send the string "\0"

I<$win:> the window you created with crewin or loadwin

=back


=head1 puthichars

         The function writes
         double-height, double-width (highwide) characters to a virtual
         display.


B<Syntax:>

           puthichars($winId,$SmgX,$SmgY,$SMGString,$attrib);


B<Parameters:>

=over

I<$SmgX:> Number of the starting column of the string 
( leftmost column is number 1 )

I<$SmgY:> Number of the line where to write the string ( top line is number 1 )

I<$SmgString:> Character string containing the text to write in the window

I<$attrib:> A character string with one character/attribute:

=over 6

I<I:>  Invisible;

I<B:>  Bold;

I<R:>  Reverse;

I<U:>  Underline;

I<F:>  Flashing

I<1:>  terminal user defined feature number 1;

I<2:>  terminal user defined feature number 2;

I<3:>  terminal user defined feature number 3;

I<4:>  terminal user defined feature number 4;

I<5:>  terminal user defined feature number 5;

I<6:>  terminal user defined feature number 6;

I<7:>  terminal user defined feature number 7;

I<8:>  terminal user defined feature number 8;

=back

  The user defined features are more often ansi colours and are
  available on Xterms or on colour terminals and colour terminal emulators
  VT2XX and over.
  For a normal rendition just send the string "\0"

I<$win:> the window you created with crewin or loadwin

=back


=head1 putfatchars

         The function writes double-width
         characters to a window.


B<Syntax:>

           putfatchars($winId,$SmgX,$SmgY,$SMGString,$attrib);

       

B<Parameters:>

=over

I<$SmgX:> Number of the starting column of the string 
( leftmost column is number 1 )

I<$SmgY:> Number of the line where to write the string ( top line is number 1 )

I<$SmgString:> Character string containing the text to write in the window

I<$attrib:> A character string with one character/attribute:

=over 6

I<I:>  Invisible;

I<B:>  Bold;

I<R:>  Reverse;

I<U:>  Underline;

I<F:>  Flashing

I<1:>  terminal user defined feature number 1;

I<2:>  terminal user defined feature number 2;

I<3:>  terminal user defined feature number 3;

I<4:>  terminal user defined feature number 4;

I<5:>  terminal user defined feature number 5;

I<6:>  terminal user defined feature number 6;

I<7:>  terminal user defined feature number 7;

I<8:>  terminal user defined feature number 8;

=back

  The user defined features are more often ansi colours and are
  available on Xterms or on colour terminals and colour terminal emulators
  VT2XX and over.
  For a normal rendition just send the string "\0"

I<$win:> the window you created with crewin or loadwin

=back


=head1 putline  

         The function writes a line of text
         to a window, beginning at the current virtual cursor
         position.


B<Syntax:>

           putline  ($win ,$text ,$advance ,$attr);
       




B<Parameters:>

=over

I<$text:> Character string containing the text to write in the window

I<$advance:> Number of line to scroll before writing. If 0 the current
line will be overwritten with $text.

I<$attr:> A character string with one character/attribute:

=over 6

I<I:>  Invisible;

I<B:>  Bold;

I<R:>  Reverse;

I<U:>  Underline;

I<F:>  Flashing

I<1:>  terminal user defined feature number 1;

I<2:>  terminal user defined feature number 2;

I<3:>  terminal user defined feature number 3;

I<4:>  terminal user defined feature number 4;

I<5:>  terminal user defined feature number 5;

I<6:>  terminal user defined feature number 6;

I<7:>  terminal user defined feature number 7;

I<8:>  terminal user defined feature number 8;

=back

  The user defined features are more often ansi colours and are
  available on Xterms or on colour terminals and colour terminal emulators
  VT2XX and over.
  For a normal rendition just send the string "\0"

I<$win:> the window you created with crewin or loadwin

=back


=head1 readkey  

         The function reads a keystroke and returns
         that keystroke's terminator code.


B<Syntax:>

           readkey  ($KbId ,$code);



B<Parameters:>

=over

I<$KbId:> The Keyboard identifier returned by the function initscr 

I<$code:> A 2byte integer number last pressed code; this code is 
           using 0-255 for extended ascii character set, and over for
	   the other keys (ex: F10, PF2, SELECT ...)

=back


=head1 read_string  

         The function reads a string off a keyboard with echo in the
         window and returns the last keystroke's terminator code.
         any unprintable key other than arrows or delete terminates
         the program.


B<Syntax:>

           read_string($win,$KbId,$Str,$Size)
           
       

B<Parameters:>

=over

I<$KbId:> The Keyboard identifier returned by the function initscr 

I<$Str:> The returned string.

I<$Size:> Maximum size of the returned string.

I<$win:> the window you created with crewin or loadwin

=back

=head1 readkeypt  

         The function reads a keystroke and returns
         that keystroke's terminator code.


B<Syntax:>

           readkeypt  ($KbId ,$code ,$prompt ,$timeout ,$win);
       

B<Parameters:>

=over

I<$prompt:> Ascii String use to prompt the user before waiting for the
key stroke.

I<$timeout:> Number of seconds to wait before returning with "TIMEOUT" as
key name.

I<$KbId:> The Keyboard identifier returned by the function initscr 

I<$code:> A 2byte integer number last pressed code; this code is 
           using 0-255 for extended ascii character set, and over for
	   the other keys (ex: F10, PF2, SELECT ...)

I<$win:> the window you created with crewin or loadwin

=back


=head1 refresh

         The function repaints the specified
         physical screen after non-SMG$ I/O has occurred.


B<Syntax:>

           refresh($PbId);
       

B<Parameters:>

=over

I<$PbId:> The physical screen you defined in initscr

=back


=head1 putwinagain

         The function moves a window
         to a new position on the physical screen. The pasting order is not
         preserved. The difference with movewin() is that the window is moved
	 and put over all the other windows.


B<Syntax:>

           putwinagain($win ,$PbId ,$Y ,$X);

       

B<Parameters:>

=over

I<$X:> Number of the physical screen column where to put the window
( leftmost column is number 1 )

I<$Y:> Number of the physical screen line where to put the window 
( top line is number 1 )

I<$PbId:> The physical screen you defined in initscr

I<$win:> the window you created with crewin or loadwin

=back


=head1 curpos  

         The function returns the current virtual
         cursor position in a specified window.


B<Syntax:>

           curpos  ($win ,$Y ,$X);
       

B<Parameters:>

=over

I<$X:> Number of the cursor current column in window $win 
( leftmost column is number 1 )

I<$Y:> Number of the cursor current line in window $win ( top line is number 1 )

I<$win:> the window you created with crewin or loadwin

=back


=head1 bell  

         The Ring the function sounds the terminal
         bell or buzzer.


B<Syntax:>

           bell  ($win ,$nbtimes);
       

B<Parameters:>

=over

I<$nbtimes:> Number of times the bell will ring on the terminal.

I<$win:> the window you created with crewin or loadwin

=back


=head1 savewin  

         The Save the function saves the contents
         of a window and stores it in a file.


B<Syntax:>

           savewin  ($win ,$filespec);
       

B<Parameters:>

=over

I<$filespec:> the specification of the file that will contain the window
              (wild cards are not allowed).

I<$win:> the window you created with crewin or loadwin

=back


=head1 scrollsubwin  

         The function scrolls a virtual
         display under its associated subwindow.


B<Syntax:>

           scrollsubwin  ($win ,$direction ,$count);
       

B<Parameters:>

=over

I<$direction:> A one character string:

=over

I<U:> Scrolls the window up $count lines 

I<D:> Scrolls the window down $count lines 

I<L:> Scrolls the window left $count lines 

I<R:> Scrolls the window right $count lines 

=cut

I<$win:> the window you created with crewin or loadwin

=back


=head1 selmenuopt  

         The Make a Selection from the function lets you move between
         the menu choices using the arrow keys and lets you make a
         selection by pressing the Return key.


B<Syntax:>

           selmenuopt  ($KbId ,$win ,$sel_nb ,$def_sel ,$flags ,$hlp); 


B<Parameters:>

=over

I<$KbId:> The Keyboard identifier returned by the function initscr 


I<$flags:> A character string with one character/option:

=over

I<I:> Returns immediately whatever is the pressed key. 

I<R:> Removes the selected option from the list.

=back

I<$win:> the window you created with crewin or loadwin

I<$sel_nb:> Number of the selected option.

I<$def_sel:> The option highlighted at start of the function.

I<$hlp:> Default VMS help library searched for the current option 
when <help:> key is pressed (this parameter is meaningless when flag I is
set.

=back


=head1 setcurpos  

         The function moves the virtual cursor
         to the specified position in a window.


B<Syntax:>

           setcurpos  ($win ,$Y ,$X);


B<Parameters:>

=over

I<$X,$Y:> Cursor new position.

I<$win:> the window you created with crewin or loadwin

=back


=head1 setcurmode  

         The function turns the physical cursor on or
         off and selects jump or smooth scrolling.


B<Syntax:>

           setcurmode  ($PbId ,$flags);
       

B<Parameters:>

=over

I<$flags:> A character string with one character/option:

=over

I<0:> The cursor will not be visible.

I<1:> The cursor will be visible.

I<J:> The srolling will be on jump mode (faster).

I<S:> The srolling will be on smooth mode (better for your eyes).

=back

I<$PbId:> The physical screen you defined in initscr

=back


=head1 remwin

         The function removes a window from
         a physical screen.


B<Syntax:>

           remwin($win ,$PbId);

B<Parameters:>

=over

I<$PbId:> The physical screen you defined in initscr

I<$win:> the window you created with crewin or loadwin
         and you put on the screen with putwin. 

=back


=head1 AUTHOR

Jean-claude Tebbal



=cut

## ====================================================================
## Copyright (C) 1998 Stephen Farrell <stephen@farrell.org>
##
## All rights reserved.  This program is free software; you can
## redistribute it and/or modify it under the same terms as Perl
## itself.
##
## ====================================================================
##
## Authors: Stephen Farrell & Jeremy Mayes (c) 1998
## Description: A Text::Graphics rendering toolkit
## RCS $Id: Graphics.pm,v 1.11 1998/06/23 01:00:16 sfarrell Exp $
##

package Text::Graphics;
$Text::Graphics::VERSION = 1.0001;

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(max min);

sub max {
  my $a = shift; my $b = shift;
  return ($a > $b) ? $a : $b;
}

sub min {
  my $a = shift; my $b = shift;
  return ($a < $b) ? $a : $b;
}



## ====================================================================  
use strict;
##
## virtual baseclass (no constructor)
##
package Text::Graphics::Component;
Text::Graphics->import();

##
## add ( panel, offx, offy )
##
## add a child panel at the given offsets.
##
sub add {
  my $this = shift;
  my $child = shift;
  my $offx = shift;
  my $offy = shift;
  $child->{offx} = ($offx > 0) ? $offx : 0;
  $child->{offy} = ($offy > 0) ? $offy : 0;
  $child->{parent} = $this;
  
  push @{ $this->{children} }, $child;
  return $this;
}

##
## setBackground ( char )
##
## set the background to the specificied char.  this works with
## _drawBackground() in base class.... if you override _drawBackground
## then you probably want to override this as well.  a background of
## undef (or "") creates a transparent panel.  if you want opaque,
## set the background to " ".
##
sub setBackground { shift->{bg} = pop }

##
## _drawBackground ( gc )
##
## draw the background.  subclasses can override this, but probably
## won't need to.
##
sub _drawBackground {
  my $this = shift;
  my $gc = shift;
  
  if ($this->{bg} ne undef) {
    $gc->fillRect($this->{bg}, 0, 0, $this->{width}, $this->{height});
  }
}

##
## _drawSelf ( gc )
##
## override this method when subclassing to do whatever it is your
## subclass does.  when you override, make sure to call
## $this->SUPER::_drawSelf() to make sure that your children are drawn
## as well.
##
sub _drawSelf {
  my $this = shift;
  my $gc = shift;
  
  foreach my $child (@{ $this->{children} }) {
    my $gss = Text::Graphics::GraphicsContextSaveState->new($gc);
    $gc->setClippingRegion($child->_getBoundaries());
    $child->_drawBackground($gc);
    $child->_drawSelf($gc);
  }
}



##
## _getBoundaries()
##
## calculate the boundaries so as to be contained in parent's
## boundaries.  this is called during rendering to set the clipping
## region for the gc.
##
sub _getBoundaries {
  my $this = shift;
  
  my $p = $this->{parent};
  ($this->{offx} < 0) and $this->{offx} = 0;
  ($this->{offy} < 0) and $this->{offy} = 0;
  
  return ($this->{offx},
	  $this->{offy},
	  min ($this->{offx} + $this->{width}, $p->{width}),
	  min ($this->{offy} + $this->{height}, $p->{height}));
}



##
## getSize ()
##
## this is a hook for a layout engine to get information about the
## size that the panel wants to be.
##
sub getSize {
  my $this = shift;
  return ($this->{width}, $this->{height});
}

##
## getOffset ()
##
## this is a hook for a layout engine to get information about the
## offset of the panel
##
sub getOffset {
  my $this = shift;
  return ($this->{offx}, $this->{offy});
}

##
## setOffset ( offx, offy )
##
## hook for layout engine to redo the offset after the panel has been
## created.  NOTE that you can pass in either value as null and it
## will be unchanged
##
sub setOffset {
  my $this = shift;
  my $offx = shift;
  my $offy = shift;
  if (defined $offx) {
    $this->{offx} = $offx;
  }
  if (defined $offy) {
    $this->{offy} = $offy;
  }
}

##
## setSize ( width, height )
##
## hook for layout engine to redo the size after the panel has been
## created. NOTE that you can pass in either value as null and it will
## be unchanged
##
sub setSize {
  my $this = shift;
  my $width = shift;
  my $height = shift;
  if (defined $width) {
    $this->{width} = $width;
  }
  if (defined $height) {
    $this->{height} = $height;
  }
}


##
## getChildren ()
##
## this is a hook for a layout engine to access children of this panel
##
sub getChildren {
  my $this = shift;
  return (@{ $this->{children} } > 0) ? @{ $this->{children} } : undef;
}


## ====================================================================  
package Text::Graphics::Page;
use vars qw ( @ISA );
@ISA = qw(Text::Graphics::Component);

##
## new(width, height)
##
sub new {
  my $this = {};
  bless $this, shift;
  $this->{width}  = shift || 0;
  $this->{height} = shift || 0;
  $this->{children} = [];
  return $this;
}

sub _getBoundaries {
  my $this = shift;
  return (0, 0, $this->{width}, $this->{height});
}

##
## render ([scalar_ref])
##
## this is what is called to cause the page to render itself, not
## _drawSelf().  _drawSelf() should be thought of what is used in
## subclasses to get their specific behavior.  render() should be
## thought of as something called externally to cause the whole
## heirarchy to display.
##
## If a scalar ref is provided, then it renders into it; otherwise it
## renders to STDOUT.
##
sub render {
  my $this = shift;
  my $scalar_ref = shift;
  my $gc = Text::Graphics::GraphicsContext->new($this->{width},
						$this->{height});
  
  $this->_drawBackground($gc);
  $this->_drawSelf($gc);
  
  if ($scalar_ref) {
    $gc->renderToScalarRef($scalar_ref);
  }
  else {
    $gc->renderToSTDOUT();
  }
}


## ====================================================================  
package Text::Graphics::Panel;
use vars qw ( @ISA );
@ISA = qw(Text::Graphics::Component);
use Carp;

##
## new(width, height)
##
sub new {
  my $this = {};
  bless $this, shift;
  $this->{width}  = shift || 0;
  $this->{height} = shift || 0;
  $this->{children} = [];
  return $this;
}



## ====================================================================  
package Text::Graphics::BorderedPanel;
use vars qw ( @ISA );
@ISA = qw(Text::Graphics::Panel);

sub _drawSelf {
  my $this = shift;
  my $gc = shift;
  
  $this->SUPER::_drawSelf($gc);
  
  ##
  ## normally you draw self and then draw children.. however borders
  ## are special b/c we want to draw them after the children have been
  ## drawn.  therefor, i need to reset the clipping region for the gc
  ## explicitely
  ##
  $gc->drawBorder(0, 0, $this->{width}, $this->{height});
}

## ====================================================================  
package Text::Graphics::TextPanel;
use vars qw ( @ISA );
@ISA = qw(Text::Graphics::Panel);
Text::Graphics->import();

##
## new(text, width, height)
##
## defaults to opaque background.  use setBackground(undef) to make
## transparent
##
sub new {
  my $this = {};
  bless $this, shift;
  $this->{text} = shift;
  $this->{width} = shift;
  $this->{height} = shift;
  return $this;
}

sub getSize {
  my $this = shift;
  
  ##
  ## analyze text string to figure out how big it is... don't return a
  ## width or height less than that provided
  ##
  
  my $text = $this->{text};
  my @lines = split (/\n/, $this->{text});
  my $width = max( $this->{width}, max ( map { length($_) } @lines ) +
		   (2 * $this->{h_pad}));
  my $height = max( $this->{height}, scalar ( @lines ) + (2 * $this->{v_pad}));
  
  return ($width, $height - 1);	# there is always 1 extra padding on bottom
}

##
## setPadding ( horizontal padding, vertical padding )
##
## set the padding around the text.  this is currently used mainly
## when there is a border around the panel, so that the text is not
## overwritten
##
sub setPadding {
  my $this = shift;
  $this->{h_pad}= shift;
  $this->{v_pad} = shift;
}

sub _drawSelf {
  my $this = shift;
  my $gc = shift;
  
  $gc->drawString($this->{text},
		  $this->{h_pad},
		  $this->{v_pad}, 
		  $this->{width} - (2 * $this->{h_pad}),
		  $this->{height} - (2 * $this->{v_pad}));
  
  $this->SUPER::_drawSelf($gc);
}



## ====================================================================  
package Text::Graphics::FilledTextPanel;
use Carp;
use Text::Wrapper;
use vars qw ( @ISA );
@ISA = qw(Text::Graphics::TextPanel);
Text::Graphics->import();

sub doWrap {
  my $this = shift;
  my $width = shift || $this->{width};
  
  ## warn "doWrap($width) $this->{text}\n";
  
  unless ($this->{text_was_wrapped}) {
    ##
    ## don't bother with wrap if no spaces ;-)--this is not so much an
    ## optimization as much as a work-around for the buggy wrapper.
    ##
    if ($width and $this->{text} =~ /\s/) {
      my $w = Text::Wrapper->new(columns=>$width);
      $this->{text} =~ s/\n/ /g;
      $this->{text} = $w->wrap($this->{text});
    }
    
    $this->{text_was_wrapped} = 1;
  }
}



##
## ONLY run this if the width is non-zero
##
sub setPadding {
  my $this = shift;
  my $h_pad = shift;
  my $v_pad = shift;
  
  if ($this->{width}) {
    $this->doWrap($this->{width} - (2 * $h_pad));
  }
  
  $this->SUPER::setPadding($h_pad, $v_pad);
}


sub setSize {
  my $this = shift;
  my $width = shift;
  my $height = shift;
  
  ##
  ## we need to re-wrap iff the width changes
  ##
  
  if (($width ne undef) and ($this->{width} != $width)) {
    delete $this->{text_was_wrapped};
  }
  
  $this->SUPER::setSize($width, $height);
}

sub getSize {
  my $this = shift;
  
  if ($this->{width}) {
    $this->doWrap();
  }
  
  return $this->SUPER::getSize();
}

sub _drawSelf {
  my $this = shift;
  my $gc = shift;
  
  if ($this->{width}) {
    $this->doWrap();
  }
  
  $this->SUPER::_drawSelf($gc);
}



## ====================================================================  
package Text::Graphics::BorderedTextPanel;
use vars qw ( @ISA );
@ISA = qw(Text::Graphics::TextPanel);

sub getSize {
  my $this = shift;
  
  my ($width, $height) = $this->SUPER::getSize();
  ##
  ## for filled text, the deal is that we give a width and ask later
  ## for the height.  so when getSize returns, it, of course, returns
  ## the width first asked for, but the height is affected by wrapping
  ## and padding for the border (the 2).  for unfilled text, the width
  ## can also change from what was requested.
  ##
  return ($width, $height + 2 * $this->{h_pad});
}

sub _drawSelf {
  my $this = shift;
  my $gc = shift;
  
  $this->setPadding(1,1);
  $this->SUPER::_drawSelf($gc);
  
  $gc->drawBorder(0, 0, $this->{width}, $this->{height});
}

## ====================================================================  
package Text::Graphics::FilledBorderedTextPanel;
use vars qw ( @ISA );
@ISA = qw(Text::Graphics::FilledTextPanel);

sub getSize {
  my $this = shift;
  
  my ($width, $height) = $this->SUPER::getSize();
  ##
  ## for filled text, the deal is that we give a width and ask later
  ## for the height.  so when getSize returns, it, of course, returns
  ## the width first asked for, but the height is affected by wrapping
  ## and padding for the border (the 2).  for unfilled text, the width
  ## can also change from what was requested.
  ##
  return ($width, $height + 2 * $this->{h_pad});
}

sub _drawSelf {
  my $this = shift;
  my $gc = shift;
  
  $this->setPadding(1, 1);	# FIXME--I don't think I want this hardcoded
  $this->SUPER::_drawSelf($gc);
  
  $gc->drawBorder(0, 0, $this->{width}, $this->{height});
}


## ====================================================================  
package Text::Graphics::GraphicsContext;
Text::Graphics->import();

##
## new(width, height)
##
sub new {
  my $this = {};
  bless $this, shift;
  $this->{width} = shift;
  $this->{height} = shift;
  $this->{charmap} = [];
  return $this;
}


##
## drawBorder (x, y, width, height)
##
sub drawBorder {
  my $this = shift;
  my $startx = $this->{x0} + shift;
  my $starty = $this->{y0} + shift;
  my $endx = $startx + shift;
  my $endy = $starty + shift;
  
  $startx = max ($startx, $this->{x0});
  $starty = max ($starty, $this->{y0});
  $endx = min ($endx, $this->{x1});
  $endy = min ($endy, $this->{y1});
  
  return if $startx >= $endx or $starty >= $endy;
  
  $this->{charmap}->[$starty]->[$startx] = "+";
  $this->{charmap}->[$starty]->[$endx] = "+";
  $this->{charmap}->[$endy]->[$startx] = "+";
  $this->{charmap}->[$endy]->[$endx] = "+";
  
  foreach my $x ($startx + 1 .. $endx - 1) {
    $this->{charmap}->[$starty]->[$x] = "-";
    $this->{charmap}->[$endy]->[$x] = "-";
  }
  foreach my $y ($starty + 1 .. $endy - 1) {
    $this->{charmap}->[$y]->[$startx] = "|";
    $this->{charmap}->[$y]->[$endx] = "|";
  }
}

##
## fillRect (char, x, y, width, height)
##
sub fillRect {
  my $this = shift;
  my $char = substr(shift, 0, 1) || return;
  my $startx = $this->{x0} + shift;
  my $starty = $this->{y0} + shift;
  my $endx = $startx + shift;
  my $endy = $starty + shift;
  
  $startx = max ($startx, $this->{x0});
  $starty = max ($starty, $this->{y0});
  $endx = min ($endx, $this->{x1});
  $endy = min ($endy, $this->{y1});
  
  return if $startx >= $endx or $starty >= $endy;
  
  foreach my $y ($starty .. $endy) {
    foreach my $x ($startx .. $endx) {
      $this->{charmap}->[$y]->[$x] = $char;
    }
  }
}


##
## drawString (text, x, y)
##
sub drawString {
  my $this = shift;
  my $text = shift;
  my $startx = $this->{x0} + shift;
  my $starty = $this->{y0} + shift;
  
  $text =~ s/\t/        /gm;	# untabify
  
  my @text_array = split(//, $text);
  
  
  my ($x, $y) = ($startx, $starty);
 CHAR: foreach my $c (@text_array) {
    if ($c eq "\n") {
      $y++;
      $x = $startx;
    }
    else {
      next CHAR if ($x > $this->{x1}) or ($y > $this->{y1});
      $this->{charmap}->[$y]->[$x++] = $c
    }
  }
}


sub setClippingRegion {
  my $this = shift;
  $this->{x0} += shift;
  $this->{y0} += shift;
  $this->{x1} += shift;
  $this->{y1} += shift;
}

sub renderToSTDOUT {
  my $this = shift;
  my $c;
  foreach my $y (0 .. $this->{height}) {
    foreach my $x (0 .. $this->{width}) {
      $c = $this->{charmap}->[$y]->[$x];
      print (defined $c ? $c : " ");
    }
    print "\n";
  }
}

sub renderToScalarRef {
  my $this = shift;
  my $scalar_ref = shift;
  my $c;
  foreach my $y (0 .. $this->{height}) {
    foreach my $x (0 .. $this->{width}) {
      $c = $this->{charmap}->[$y]->[$x];
      $$scalar_ref .= (defined $c ? $c : " ");
    }
    $$scalar_ref .= "\n";
  }
}

## ====================================================================  
package Text::Graphics::GraphicsContextSaveState;

sub new {
  my $this = {};
  bless $this, shift;
  $this->{gc} = shift;
  $this->{x0} = $this->{gc}->{x0};
  $this->{y0} = $this->{gc}->{y0};
  $this->{x1} = $this->{gc}->{x1};
  $this->{y1} = $this->{gc}->{y1};
  return $this;
}

sub DESTROY {
  my $this = shift;
  $this->{gc}->{x0} = $this->{x0};
  $this->{gc}->{y0} = $this->{y0};
  $this->{gc}->{x1} = $this->{x1};
  $this->{gc}->{y1} = $this->{y1};
}

1;

__END__

=head1 NAME

Text::Graphics -- A text graphics rendering toolkit

=head1 DESCRIPTION
 


This is a toolkit for rendering plain text via an API like that used
for graphics rendering in GUI toolkits.  This package might be used
when you want to do sophisticated rendering of plain text, e.g., for
graphing, creating of complex forms for email and fax, and so on.



=head1 SYNOPSIS


 use Text::Graphics;
 my $text = "A text graphics rendering toolkit.\n";
 my $page = Text::Graphics::Page->new( 20, 10);
 my $panel0 = Text::Graphics::BorderedPanel->new( 20, 10);
 my $panel1 =
  Text::Graphics::FilledBorderedTextPanel->new($text x 3, 25, 12);
 $panel0->setBackground("#");
 $panel1->setBackground(" ");
 $page->add($panel0);
 $page->add($panel1, 5, 2);
 $page->render();
 
 +-------------------+
 |###################|
 |####+--------------+
 |####|A text graphic|
 |####|rendering tool|
 |####|text graphics |
 |####|toolkit. A tex|
 |####|graphics rende|
 |####|toolkit.      |
 |####|              |
 +----+--------------+


=head1 User API


=head2 C<Text::Graphics::Page>

Class to represent a page.

=item C<new (width, height)>

Construct a new page with the specified width and height.

=item C<add (Panel, x_offset, y_offset)>

Add a Panel at the specified offset.

=item C<render ( [ scalar_reference ] )>

Render the page.  If an argument is given, it is assumed to be a
SCALAR REFERENCE, and rendering will be done to such reference.  e.g.,
if you want to render to $buf, you might do

 $w->render(\ $buf);

If no argument to render() is provided, then rendering is simply done
to STDOUT using C<print>.


=head2 C<Text::Graphics::Panel>

Class to represent a panel.

=item C<new (width, height)>

Construct a new panel with the specified width and height.

=item C<add (Panel, x_offset, y_offset)>

Add a Panel at the specified offset.  This child panel is contained
within its parent and will not extend beyond the parents boundaries.

=item C<setBackground ( background )>

Set the background on the panel to the specified char.

=item C<getSize ()>

Get the size of a panel.  This method is a hook for layout managers.
E.g., If you set up a wrapped text panel with height 0, then call
getSize(), then it will return the same width but the new "desired"
height.  (If you are interested in how to write a layout manager on
top of this code, please contact me (SF) as I have done so but have
not released it.)

=item C<setSize (width, height)>

Set the size of a panel.  This method is a hook for layout managers.

=item C<getOffset ()>

get the offset of a panel.  This method is a hook for layout managers. 

=item C<setOffset (x_offset, y_offset)>

set the offset of a panel.  This method is a hook for layout managers. 


=head1 Subclassing

Most of the work you might do with this module will be by subclassing
panel.  The idea is you make a new panel, like LinePanel, that has a
constructor setting character to draw and the start and end
coordinates for the line.  Then, in the LinePanels C<_drawSelf(gc)>
routine, it calls on the gc to draw a line:

 package LinePanel;
 use vars qw (@ISA);
 @ISA = qw (Panel);

 sub new {
  my $this = {};
  bless $this, shift;
  $this->{char} = shift;
  $this->{startx} = shift;
  $this->{starty} = shift;
  $this->{endx} = shift;
  $this->{endy} = shift;
  return $this;
 }

 sub _drawSelf {
  my $this = shift;
  my $gc = shift;

  $gc->drawLine($this->{char},
                $this->{startx}, $this->{starty},
		$this->{endx}, $this->{endy});

 }


There are some other subclasses included, particularly those for text
handling.

Actually the C<drawLine()> method for the GraphicsContext is not
included b/c I just do not need it, though I have a mostly working
version if anyone is interested (it is not complicated =).

GraphicsContext does include the following methods, however:

=item C<drawBorder(x_offset, y_offset, width, height)>

Draw a border with the specified coordinates.

=item C<fillRect(char, x_offset, y_offset, width, height)>

Fill the specified rectangle with the specified character.  Note that
filling with " " is a good way to get an "opaque" panel.

=item C<drawString(string, x_offset, y_offset)>

Draw the specified string at the specified offset.  If you want to
control the width then you probably want to look at FilledTextPanel.



=head1 AUTHORS

 Stephen Farrell <stephen@farrell.org>
 Jeremy Mayes

=cut


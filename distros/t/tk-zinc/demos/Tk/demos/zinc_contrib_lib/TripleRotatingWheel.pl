#!/usr/bin/perl
# TripleRotatingWheel gambling game contributed by "zentara"

# Idea derived from the wheelOfFortune.pl demo by D. Etienne etienne@cena.fr
# $Id: TripleRotatingWheel.pl,v 1.2 2004/03/05 14:54:23 etienne Exp $ 


use Tk; 
use Tk::Zinc;

my @win =(); # an array to store winning wheel values, can range from
             # () to (1,1,1) 

# We create a classical root widget called MainWindow; then we create Zinc 
# widget child with size, color and relief attributes, and we display it using
# the geometry manager called 'pack'.
my $mw = MainWindow->new;
$mw->geometry("700x600");

$mw->resizable(0,0);

my $zinc = $mw->Zinc(-width => 700, -height => 565,
                    -backcolor => 'black',
		     -borderwidth => 3, -relief => 'sunken');
$zinc->pack;

# Then we create a gray filled rectangle, in which we will display explain text.
$zinc->add('rectangle', 1 , [200, 400, 490, 490],
	   -linewidth => 2,
	   -filled => 1,
	   -fillcolor => 'SkyBlue',
	   );
my $text = $zinc->add('text', 1,
		      -position => [350, 445],
		      -anchor => 'center',
		      );

$zinc->add('rectangle', 1 , [250,275,450,325], #(xpos1,ypos1,xpos2,ypos2)
	   -linewidth => 2,
	   -filled => 1,
	   -fillcolor => 'Orange',
	   );

my $wintext = $zinc->add('text', 1,
		      -position => [350, 300],
		      -anchor => 'center',
		      );

#create winning wheel markers
#create first triangle, then clone and translate
my $tr1 = $zinc->add('triangles', 1,
                     [0,20,20,20,10,50],
                     -fan => 1,
                     -colors => 'Orange',
                     -visible => 1,
                     );
my $tr2 = $zinc->clone($tr1);
my $tr3 = $zinc->clone($tr1);
$zinc->translate($tr1,130,0);
$zinc->translate($tr2,340,0);
$zinc->translate($tr3,550,0);



# Create the Wheel object (see Wheel.pm)
my $wheel1 = Wheel->new($zinc, 350, 500,  100); #start xpos,ypos,mag
my $wheel2 = Wheel->new($zinc, 350, 500, 100);
my $wheel3 = Wheel->new($zinc, 350, 500, 100);

# Display comment
&comment("Strike any key to begin");
&wincomment("READY");

# Create Tk binding
$mw->Tk::bind('<Key>', \&openmode);


MainLoop;

# Callback bound to '<Key>' event when wheel is unmapped
sub openmode {
    # set binding to unmap the wheel
    $mw->Tk::bind('<Key>', \&closemode);
    # set binding to rotate the hand
    $zinc->bind($wheel1, '<1>', sub {spin()}); 
    $zinc->bind($wheel2, '<1>', sub {spin()});    
    $zinc->bind($wheel3, '<1>', sub {spin()});    
    # map the wheel
    $wheel1->show(140, 150);
    $wheel2->show(350, 150);
    $wheel3->show(560, 150);
    
    # and then inform user
    &comment("Click on any wheel to play.\n".
	     "Strike any key to hide the wheels.");
}

sub spin {
    return if $wheel1->ismoving;
    return if $wheel2->ismoving;
    return if $wheel3->ismoving;

  @win=();
  &wincomment("PLAYING");
          $wheel1->rotatewheel(int rand(360));
          $wheel2->rotatewheel(int rand(360));
	  $wheel3->rotatewheel(int rand(360));
#  print "\@win->@win\n";
 }    


# Callback bound to '<Key>' event when wheel is already mapped 
sub closemode {
    return if $wheel1->ismoving;
    return if $wheel2->ismoving;
    return if $wheel3->ismoving;

    # set binding to map the wheel
    $mw->Tk::bind('<Key>', \&openmode);
    # unmap the wheel
    $wheel1->hide(350, 400);
    $wheel2->hide(350, 400);
    $wheel3->hide(350, 400);
    # and then inform user
    &comment("Strike any key to show the wheel");
}

# Just display comment 
sub comment {
    my $string = shift;
    $zinc->itemconfigure($text, -text => $string);
}

# display winning comment 
sub wincomment {
    my $string = shift;
    $zinc->itemconfigure($wintext, -text => $string);
}

sub displaywin {
  if($#win == -1){&wincomment("NO WIN")}
  if($#win == 0){&wincomment("SINGLE")}
  if($#win == 1){&wincomment("DOUBLE")}
  if($#win == 2){&wincomment("TRIPLE")}
 
 #restore disabled mouse click for next spin
  $zinc->bind($wheel1, '<1>',  sub {spin()}); 
  $zinc->bind($wheel2, '<1>', sub {spin()});    
  $zinc->bind($wheel3, '<1>', sub {spin()});    
}

#=============================================================================
#                 Wheel  Class
#=============================================================================
package Wheel;

use strict 'vars';
use Carp;
#====================
# Object constructor
#====================
sub new {
    my ($proto, $widget, $x, $y, $radius) = @_;
  
    # object attributes
    my $self = {
	'widget' => $widget,   # widget reference
	'origin' => [$x, $y],  # origin coordinates
	'radius' => $radius,   # wheel radius
	'topgroup' => undef,   # top Group item
	'itemclip' => undef,   # id of item which clips the wheel
	'angle' => 0,          # delta angle
	'stepsnumber' => 20,   # animations parameters
	'afterdelay' => 30,
	'shrinkrate' => 0.8,   # zoom parameters
	'zoomrate' => 1.1,
	   
	};
    bless $self;    
    
    # First, we create a new Group item for the wheel. Why a Group item ?
    # At least two reasons. Wheel object consists of several Zinc items,  
    # we'll see below; it moves when it is mapped or unmapped, grows when  
    # you hit the jackpot. So, it's more easy to apply such transformations 
    # to a structured items set, using Group capability, rather than apply 
    # to each item separately or using canvas-like Tags mechanism.
    # Second reason refers to clipping. When it is mapped or unmapped, wheel 
    # object is drawn inside a circle with variant radius; clipping is a 
    # specific property of Group item

    # That's why we create a Group item in the top group, and set its
    # coordinates.
    $self->{topgroup} = $widget->add('group', 1, -visible => 0);
    $widget->coords($self->{topgroup}, [$x,$y]);
    
#print "  start widget coords-> $x $y\n";    
        
    # All the following items will be created in this group...
    # Create the invisible Arc item used to clip the wheel, centered on the
    # group origin.
    $self->{itemclip} = $widget->add('arc',  $self->{topgroup},
				     [-$radius, -$radius, $radius, $radius],
				     -visible => 0,
				     );
    $widget->itemconfigure($self->{topgroup}, -clip => $self->{itemclip});

    # Create the wheel with 6 filled Arc items centered on the group origin
    my $i = 0;
    for my $color (qw(magenta blue cyan green yellow red)) {
	$widget->add('arc',  $self->{topgroup},
		     [-$radius, -$radius, $radius, $radius],
		     -visible => 1,
		     -filled => 1,
		     -closed => 1,
		     -extent => 60,
		     -pieslice => 1,
		     -fillcolor => $color,
		     -linewidth => 1,
		     -startangle => 60*$i ,
		     -tags => [$self],
		     );
	$i++;
    }
    
    # Create the Text item representing the jackpot.
    $widget->add('text', $self->{topgroup},
		 -position => [0, -$radius+20],
		 -font =>
		 '-adobe-helvetica-bold-o-normal--34-240-100-100-p-182-iso8859-1',
		 -anchor => 'center',
		 -text => "\$",
		 );
    
    
    # Then we unmap the wheel; in fact, Group item is translated and its
    # clipping circle is shrunk to a point.
    $self->_clipAndTranslate($self->{shrinkrate}**$self->{stepsnumber});
    return $self;
}

#================
# Public methods
#================

# Return 1 if wheel is moving (opening or closing animation)
sub ismoving {
    my $self = shift;
    return 1 if $self->{opening} or $self->{closing} or $self->{turning};
}

# Display wheel with animation effect
sub show {
    my ($self, $x, $y) = @_;
    # simple lock management
    return if $self->{opening} or $self->{closing};
    $self->{opening} = 1;
    # start animation 
    $self->_open($x, $y, 0);
}


# Unmap wheel with animation effect
sub hide {
    my ($self, $x, $y) = @_;
    # simple lock management
    return if $self->{opening} or $self->{closing};
    $self->{closing} = 1;
    # start animation
    $self->_close($x, $y, 0);
}


# Just rotate the hand with animation effect.
sub rotatewheel {
    my $self = shift;
    #print "wheel-> $self->{topgroup}";
    my $angle = shift;
#print "  angle->$angle\n";

    return if $self->{turning};

#prevent "double-clicking", so mouse is disabled
#until current play is over
$zinc->bind($wheel1, '<1>', sub {}); 
$zinc->bind($wheel2, '<1>', sub {});    
$zinc->bind($wheel3, '<1>', sub {});    

    $angle = 0  unless $angle;
    my $oldangle = $self->{angle};
    $self->{angle} = $angle;

    if ((330 < $angle)||($angle < 30)) {
    	$self->{fortune} = 1;
        push (@win, $self->{fortune});
    }
    $self->_rotatewheel(2*3.1416*($angle + 1440 - $oldangle)/360); 
    #the 1440 above gives at least 2 full spins each play  
}

#=================
# Private methods
#=================

# Generate opening animation; see below _clipAndTranslate method for
# Zinc specific use.
sub _open {
    my ($self, $x, $y, $cnt) = @_;
    my $widget = $self->{widget};
    my $group = $self->{topgroup};
    # first step of animation
    if ($cnt == 0) {
	$widget->itemconfigure($group, -visible => 1);
	my @pos = $widget->coords($group);
	$x = ($x - $pos[0])/$self->{stepsnumber};
	$y = ($y - $pos[1])/$self->{stepsnumber};
    # last step
    } elsif ($cnt == $self->{stepsnumber}) {
	$self->{opening} = undef;
	return;
    }
    $cnt++;
    # move and grow the wheel
    $self->_clipAndTranslate(1/$self->{shrinkrate}, $x, $y);
    # process the animation using the 'after' Tk defering method
    $widget->after($self->{afterdelay}, sub {$self->_open($x, $y, $cnt)});
}


# Generate closing animation; see below _clipAndTranslate method for
# Zinc specific use.
sub _close {
    my ($self, $x, $y, $cnt) = @_;
    my $widget = $self->{widget};
    my $group = $self->{topgroup};
    # first step of animation
    if ($cnt == 0) {
	my @pos = $widget->coords($group);
	$x = ($x - $pos[0])/$self->{stepsnumber};
	$y = ($y - $pos[1])/$self->{stepsnumber};
    # last step
    } elsif ($cnt == $self->{stepsnumber}) {
	$widget->itemconfigure($group, -visible => 0);
	$self->{closing} = undef;
	return;
    }
    $cnt++;
    # move and shrink the wheel
    $self->_clipAndTranslate($self->{shrinkrate}, $x, $y);
    # process the animation using the 'after' Tk defering method
    $widget->after($self->{afterdelay}, sub {$self->_close($x, $y, $cnt)});

&main::wincomment("READY");
}

# Generate hand rotation animation.
sub _rotatewheel {
    my ($self, $angle, $cnt) = @_;
    my $widget = $self->{widget};
    my $group = $self->{topgroup};

#grab position of widget
my @pos = $widget->coords($group);
my $x = ($pos[0]);
my $y = ($pos[1]);

    $self->{turning} = 1;
    # first step of animation
    if (not $cnt) {
	$angle /= $self->{stepsnumber};
    
    # last step
    } elsif ($cnt == $self->{stepsnumber}) {
	if ($self->{fortune}) {
	    $self->_fortune;
	} else {
	    $self->{turning} = undef;
	}

        &main::displaywin();
	return;
    }
    $cnt++;
    # use 'rotation' Zinc method.

    $widget->rotate($self->{topgroup}, $angle);
# process the animation using the 'after' Tk defering method

#needed to keep wheel stationary while rotating
$widget->coords($self->{topgroup},[$x,$y]);

    $widget->after($self->{afterdelay}, sub {$self->_rotatewheel($angle, $cnt)});

}

# Generate growing animation to notify jackpot
sub _fortune {
    my ($self, $cnt) = @_;
    $cnt = 0 unless $cnt;
    my $zf;
    my $widget = $self->{widget};
    my $group = $self->{topgroup};
    my @pos = $widget->coords($group);
    # last step of animation
    if ($cnt == 6) {
	$self->{fortune} = undef;
	$self->{turning} = undef;
	return;
    # event steps : wheel grows
    } elsif ($cnt == 0 or $cnt % 2 == 0) {
	$zf = $self->{zoomrate};
    # odd steps : wheel is shrunk
    } else {
	$zf = 1/$self->{zoomrate};
    }
    $cnt++;
    
    # Now, we apply scale transformation to the Group item, using the 'scale'
    # Zinc method. Note that we reset group coords before scaling it, in order
    # that the origin of the transformation corresponds to the center of the
    # wheel. When scale is done, we restore previous coords of group.
    $widget->coords($group, [0, 0]);
    $widget->scale($group, $zf, $zf);
    $widget->coords($group, \@pos);
    
    # process the animation using the 'after' Tk defering method
    $widget->after(100, sub {print "\007";$self->_fortune($cnt)});
    &main::displaywin();
}


# Update group clipping and translation, using 'scale' and 'translate'
# Zinc methods.
sub _clipAndTranslate {
    my ($self, $shrinkfactor, $x, $y) = @_;
    $x = 0 unless $x;
    $y = 0 unless $y;
    $self->{widget}->scale($self->{itemclip}, $shrinkfactor, $shrinkfactor);
    if ($Tk::Zinc::VERSION lt "3.297") {
	$self->{widget}->translate($self->{topgroup}, $x, $y);
    } else {
	my ($xc, $yc) = $self->{widget}->coords($self->{topgroup});
	$self->{widget}->coords($self->{topgroup}, [$xc + $x, $yc + $y]);
    }
}
1;

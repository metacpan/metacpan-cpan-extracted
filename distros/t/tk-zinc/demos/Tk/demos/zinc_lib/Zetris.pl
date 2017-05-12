#!/usr/bin/perl
# Zinc port of TkTetris from Slaven Rezic
#------------------------------------------------------------------------------
#
#  Zetris - A Zinc Toy-Appli based on cool TkTetris from Slaven Rezic
#
#  $Id: Zetris.pl,v 1.9 2003/11/28 09:43:10 mertz Exp $
#
#  Copyright (C) 2002 Centre d'Etudes de la Navigation Aérienne
#  Author: Marcellin Buisson <buisson@cena.fr>
#
#  Hacked from Original Code to adapt to Tk::Zinc Widget :
#
#------------------------------------------------------------------------------
#
#  Author: Slaven Rezic
#
#  Copyright (C) 1997, 1999, 2000, 2002 Slaven Rezic. All rights reserved.
#  This program is free software; you can redistribute it and/or
#  modify it under the same terms as Perl itself.
#
#  Mail: slaven.rezic@berlin.de
#  WWW:  http://www.rezic.de/eserte/
#
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
#  What are the differences with the original TkTetris ?
#------------------------------------------------------------------------------
#
#  - This TkTetris-like uses a tk widget similar to the canvas
#    and called "Zinc". Zinc bring to Tk widgets openGL features
#    like transparency, color gradients, scaling.
#    So to use Zetris graphic enhancement, you need openGL capability.
#    Zinc comes with other features like grouping and clipping.
#
#  - A color gradient is used for Zetris background,
#
#  - Zetris balls are filled with transparently color gradients,
#    (transparency is visible when balls fall over TkZinc logo)
#
#  - Zetris balls have a little transparent shadow,
#
#  - The TkZinc logo is animated by rotation and scaling effects,
#
#  - Introducing of groups provided by Zinc for grouping items
#    This feature is particularly useful for applying transformations,
#
#  - The TkZinc logo over background isn't an image but only curves
#    and color gradients (made by <vinot@cena.fr>)
#
#  - Please feel free to provide any feedback to <buisson@cena.fr>
#  
#  - CM: Zetris now works even without openGL. It is just ugly!
#
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# ToDos :
#
#  - Complete this basic version in a full playable game like tktetris.
#  - Review conception through Zinc features.
#    (using groups capabilities for drawing blocks for instance)
#  - Adding special effects when completing a line or changing level.
#
#------------------------------------------------------------------------------
use Tk;
use Tk::Zinc;
use strict;
use Tk::Zinc::Logo;

package main;

use Getopt::Long;

use vars qw($VERSION);

$VERSION = sprintf("%d.%00d", q$Revision: 1.9 $ =~ /(\d+)\.(\d+)/);

my $max_size     = 4;
my $nmbr_blks    = 7;
my $width        = 12;
my $height       = 20;
my $geometry;

my $level;
my $just_started = 1;
my $speed;
my $base_speed = 500;

my $last_resize;
my $fontheight   = 0;

my $basefont
  = sub { sprintf "-*-helvetica-medium-r-normal--%s-*", $_[0] };
my $base2font
  = sub { sprintf "-*-courier-medium-r-normal--%s-*", $_[0] };

my $blocks = 0;
my $lines = 0;
my $mylines = 0;

my $pause = undef;
my $pause_w;
my $freefall = 0;
my $points = 0;
my $flat = 0;
my $moveable_drop = 0;

my $old_win_height;
my $draw_shadow = 1;

# Animation constants
my $afterdelay = 1;
my $stepsnumber = 10;
my $zoomrate = 1.1;

my $active_block    = undef;
my $active_block_nr = undef;
my $active_dir      = undef;
my $next_block      = undef;
my $next_block_nr   = undef;
my $next_dir        = undef;
my $posx = undef;
my $posy = undef;

my $n = 0;

my(%color_dark, %color_very_dark);
my %color_bright =
  (2 => 'red',
   3 => 'green',
   4 => 'blue',
   5 => 'cyan',
   6 => 'yellow',
   7 => 'orange',
   8 => 'pink',
  );

# Blocks matrix
my $block =
  [[[qw(0 0 0 0)],
    [qw(0 2 0 0)],
    [qw(0 2 2 0)],
    [qw(0 2 0 0)]],
   [[qw(0 0 0 0)],
    [qw(3 3 0 0)],
    [qw(0 3 0 0)],
    [qw(0 3 0 0)]],
   [[qw(0 0 0 0)],
    [qw(0 4 4 0)],
    [qw(0 4 0 0)],
    [qw(0 4 0 0)]],
   [[qw(0 0 0 0)],
    [qw(0 5 0 0)],
    [qw(0 5 5 0)],
    [qw(0 0 5 0)]],
   [[qw(0 0 0 0)],
    [qw(0 6 0 0)],
    [qw(6 6 0 0)],
    [qw(6 0 0 0)]],
   [[qw(0 7 0 0)],
    [qw(0 7 0 0)],
    [qw(0 7 0 0)],
    [qw(0 7 0 0)]],
   [[qw(0 0 0 0)],
    [qw(0 0 0 0)],
    [qw(8 8 0 0)],
    [qw(8 8 0 0)]],
  ];

my $playfield;
reset_playfield();

my $step_x = 20;
my $step_y = 20;
my $boxsize_x    = $step_x-2;
my $boxsize_y    = $step_y-2;
my $block_border = int($boxsize_x/10);
my $help_top;

my $top = MainWindow->new();
$top->minsize(181, 83);
$top->title('Zetris');

{
  my $width_height_set = 0;
  if ($geometry)
    {
      if ($geometry =~ /^(=?(\d+)x(\d+))?(([+-]\d+)([+-]\d+))?$/)
	{
	  if (defined $2 and defined $3)
	    {
	      my($width, $height) = ($2, $3);
	      $top->GeometryRequest($width, $height);
	      $width_height_set++;
	    }
	  if (defined $5 and defined $6)
	    {
	      my($x, $y) = ($5, $6);
	      $top->geometry("$x$y");
	    }
	}
      else
	{
	  die "Can't parse geometry: $geometry";
	}
    }
    if (!$width_height_set)
      {
	$top->GeometryRequest($top->screenwidth,
			      $top->screenheight);
      }
}

my $base_level = 1;

$level = level();
$speed = speed();

resize_calc();

while(my($k, $v) = each %color_bright)
  {
    $color_dark{$k} = $top->Darken($v, 80);
    $color_very_dark{$k} = $top->Darken($v, 60);
  }


# Zinc Widget (openGl rendering option set to 1)
my $tetris = $top->Zinc(-width  => $step_x*($width-2),
			-height => $step_y*($height-1),
			-backcolor => '#707070',
			-lightangle => 130,
			-render => 1,
		       )->pack;

# Zetris will no more die if there is no openGL render. I did some minor
# modification (transparency, item priority) to make all needed item
# visible, even without alpha-transparency

my $render = $tetris->cget(-render);

my $shadow_group = $tetris->add('group',1, -visible => 1);

my $pause_group = $tetris->add('group',1, -visible => 1);

my $topgroup = 1;

$tetris->pack(-fill => 'both',
	    -expand=> 1);

$tetris->add('rectangle',
	     1, # Zinc group
	     [0, 0,$step_x*($width-2) ,$step_y*($height-1)] ,
	     -filled => 1,
	     -linewidth => 0,
	     -fillcolor  => $render ? "=axial 90 |black;40|gray80;60" : "grey80",
	     -visible => 1);

my $group = $tetris->add('group', 1, );
my $logo = Tk::Zinc::Logo->new(-widget => $tetris,
			       -parent => $group,
			       -position => [$step_x*($width-2)/2-200,
					     $step_y*($height-1)/2],
			       );

$tetris->lower($group) if $render;

my $score_group = $tetris->add('group',1, -visible => 1);
my $new = $tetris->add('text',$score_group,
		       -text => "    $lines Line\n",
		       #-anchor => 'e',
		       -font => $basefont->($fontheight),
		       -position => [$width-2,10],
		      );
$tetris->add('text',$score_group,
		       -text => "Sorry, without openGL,\nZtetris is just ugly.",
		       #-anchor => 'e',
		       -font => $basefont->($fontheight),
		       -position => [$width-2,100],
	     ) if !$render;

$tetris->lower($score_group) if $render;

my $timer = $top->after(speed(), sub {
			  $old_win_height = $top->height;
			  $just_started = 0;
			  action();
			});

make_key_bindings($top);

print "\n***********************************************\n\n   For help on the game toggle pause with 'p'\n\n***********************************************\n\n";

MainLoop;

#------------------------------------------------------------------------
sub reset_playfield
  {
    my $i;
    # $fake_height: mit negativen Indices können die n-letzten Elemente
    # angesprochen werden...
    my $fake_height = $height+$max_size+1;
    for $i (0 .. $fake_height-1)
      {
	$playfield->[$i][0] = 1;
	my $j;
	for $j (1 .. $width-2)
	  {
	    $playfield->[$i][$j] = 0;
	  }
	$playfield->[$i][$width-1] = 1;
      }
    for $i (0 .. $width-1)
      {
	$playfield->[$height-1][$i] = 1;
      }
  }

sub speed
  {
    my $speed = $base_speed - ($base_speed*$level)/20;
    if ($speed <= 5) { $speed = 5 }
    $speed;
  }

sub level
  {
    int($lines / 10) + 1 + $base_level
  }

sub resize_calc
  {
    $last_resize = time();
    my $win_height;
    if ($just_started)
      {
	$win_height = $top->reqheight;
      }
    else
      {
	$win_height = $top->height;
      }
    $step_x = $step_y = int($win_height/($height+3));
    my $gap = ($step_x > 10 ? 2 : 1);
    $boxsize_x    = $step_x-$gap;
    $boxsize_y    = $step_y-$gap;
    $block_border = int($boxsize_x/10);
    if ($block_border < 1) { $block_border = 1 }
    my @font_height = (10, 11, 12, 14, 17, 18, 20, 24, 25, 34);
    my $req_fontheight = $win_height/30;
    $fontheight = 0;
    foreach (@font_height)
      {
	if ($_ > $req_fontheight)
	  {
	    $fontheight = $_;
	    last;
	  }
      }
    if (!$fontheight) { $fontheight = $font_height[$#font_height] }
    # the following line has been commented out since
    # it modify default font for every application
    # launched by zinc-demos! CM 26/3/02
    # $top->optionAdd("*font" => $basefont->($fontheight));
  }

sub make_key_bindings
  {
    my $top = shift;
#    $top->bind('<Escape>' => \&quit_game);
#    $top->bind('<q>'      => \&quit_game);
#    $top->bind('<Control-c>' => \&quit_game);
    $top->bind('<Left>'   => sub { move('left')  });
    $top->bind('<Right>'  => sub { move('right') });
    $top->bind('<Up>'     => sub { move('antiturn')  });
    $top->bind('<Down>'   => sub { move('turn')  });
    $top->bind('<j>'      => sub { move('left')  });
    $top->bind('<l>'      => sub { move('right') });
    $top->bind('<k>'      => sub { move('turn')  });
    foreach (qw/space KP_Enter/) {
      $top->bind("<$_>"  => sub { move('freefall') });
    }
    $top->bind('<p>'      => sub { toggle_pause() });
    $top->bind('<n>'      => \&stop_and_new_game);
    $top->bind('<h>'      => \&help);
    #$top->bind('all', '<F1>'     => \&help); # don't pause
    $top->bind('all', '<F2>'     => \&lost); 
    #XXX Leave und Enter herausnehmen
    $top->bind('<FocusOut>' => sub { inc_pause(1) });
    #    $top->bind('<Leave>'    => sub { inc_pause(1) });
    $top->bind('<FocusIn>'  => sub { dec_pause(1) });
    #$top->bind('<ButtonRelease>'  => sub {  toggle_pause()});
    #$top->bind('<Key-space>'  => sub {  toggle_pause()});
    #    $top->bind('<Enter>'    => sub { dec_pause(1) });
  }


sub inc_pause
  {
    my $quiet = shift;
    $pause++;
    if (!$quiet && !Tk::Exists($pause_w))
      {
	my $width  = $top->width;
	my $height = $top->height;
	$pause_w = $tetris->add('text',$pause_group,
				   -text => "PAUSE MODE :\n Type p to continue\n
\n\n\nHELP : \n\n- 'p' toggle pause\n\n- Arrow keys to move blocks\n\n- 'n' to start a new game\n\n  ",
				   -font => $basefont->($fontheight),
				   -position => [30,50],
				   -anchor => 'nw',

       );
    }
}

sub dec_pause
  {
    if ($pause)
      {
	$pause--;
	if ($pause < 1)
	  {
	    $tetris->remove($pause_w);
	    undef $pause;
	  }
      }
  }

sub toggle_pause
  {
    my $quiet = shift;
    if ($pause)
      {
	$tetris->remove($pause_w);# if Tk::Exists($pause_w);
	undef $pause;
      }
    else
      {
	
	inc_pause($quiet);
      }
  }


sub action
  {
    if (!$pause)
      {
	if (!defined $active_block_nr)
	  {
	    if (!defined $next_block_nr)
	      {
		get_next_block();
	      }
	    $active_block_nr = $next_block_nr;
	    $blocks++;
	    $active_block = [];
	    copyblock($next_block, $active_block);
	    $active_dir      = $next_dir;
	    get_next_block();
	  }
	if (defined $posx)
	  {
	    # erstes Zeichnen
	    if (testblock($active_block, $posx, $posy+1))
	      {
		drawblock($posx, $posy, 0);
		$posy++;
		drawblock($posx, $posy, 1);
	      }
	    else
	      {
		array_update(($level+1) * int(($height-$posy+5)/5),
			     $posx, $posy);
		return;
	      }
	  }
	else
	  {
	    $posx = int($width / 2) - 1;
	    $posy = -$max_size;
	  }
      }
    $timer = $top->after($freefall ? 1 : speed(), \&action);
  }

sub get_next_block
  {
    $next_block_nr = int(rand()*$nmbr_blks);
    $next_dir      = int(rand()*4);
    $next_block    = $block->[$next_block_nr];
    for (0 .. $next_dir)
      {
	turn($next_block_nr, $next_block);
      }
  }

sub turn
  {
    my($number, $block) = @_;
    my($i, $j, $help_block);
    if ($number != 6)
      {
	if ($number < 5)
	  {
	    for $i (1 .. $max_size-1)
	      {
		for $j (0 .. $max_size-2)
		  {
		    $help_block->[$max_size-1-$j][$i-1] = $block->[$i][$j];
		  }
	      }
	    for $i (1 .. $max_size-1)
	      {
		for $j (0 .. $max_size-2)
		  {
		    $block->[$i][$j] = $help_block->[$i][$j];
		  }
	      }
	  }
	else
	  {
	    for $i (0 .. $max_size-1)
	      {
		for $j (0 .. $max_size-1)
		  {
		    $help_block->[$max_size-1-$j][$i] = $block->[$i][$j];
		  }
	      }
	    copyblock($help_block, $block);
	  }
      }
  }

sub copyblock
  {
    my($from, $to) = @_;
    die if ref $from ne 'ARRAY' || ref $to ne 'ARRAY';
    my($i, $j);
    for $i (0 .. $max_size-1)
      {
	for $j (0 .. $max_size-1)
	  {
	    $to->[$i][$j] = $from->[$i][$j];
	  }
      }
  }
sub rectangle
  {
    my($x, $y, $mode, $zinc) = @_;
    $zinc->remove("$x-$y");         # Zinc command for deleting items
    $zinc->remove("ombre$x-$y");
    if ($mode)
      {
	my($xx, $yy);
	($xx, $yy) = (($x-1)*$step_x, $y*$step_y);
	my $color = $color_bright{$mode};
	# Adding new Zinc item : ball shadow
	my $ombre=$zinc->add(
			     'arc',$shadow_group,[$xx+10,$yy+10,$xx+$boxsize_x+10,$yy+$boxsize_y+10],
			     -visible=>1,
			     -filled=>1,
			     -fillcolor => $render ? "=path 50 50 |black;100 0|black;80 20|black;0 100" : "grey90", # color gradiant
			     -linewidth => 0,
			     -linecolor => 'yellow',
			     -priority => $render ? 6 : 10,
			     -tags => ["ombre$x-$y"]);
	
	$zinc->itemconfigure($shadow_group, -priority => 2);
	
	# Adding new Zinc item : ball
	my $cercle=$zinc->add(
			      'arc',$topgroup,[$xx,$yy,$xx+$boxsize_x,$yy+$boxsize_y],
			      -visible=>1,
			      -filled=>1,
			      -fillcolor => $render ? "=radial -20 -20 |white;90|$color;90" : $color,
			      -linewidth => 1,
			      -priority => 5,
			      -linecolor => "$color;80",
			      -tags => ["$x-$y"]);
      }
  }

sub testblock
  {
    my($active_block, $posx, $posy) = @_;
    for(my $i = 0; $i <= $max_size-1; $i++)
      {
	for(my $j = 0; $j <= $max_size-1; $j++)
	  {
	    if ($active_block->[$i][$j])
	      {
		if ($playfield->[$posy+$i][$posx+$j])
		  {
		    return 0;
		  }
	      }
	  }
      }
    1;
  }

sub drawblock
  {
    my($posx, $posy, $mode, $zinc) = @_;
    my $y = $posy;
    $zinc = $tetris if !$zinc;
    for(my $i = 0; $i <= $max_size-1; $i++)
      {
	my $x = $posx;
	for(my $j = 0; $j <= $max_size-1; $j++)
	  {
	    if ($active_block->[$i][$j])
	      {
		if (!$mode)
		  {
		    rectangle($x, $y, 0, $zinc);
		  }
		else
		  {
		    rectangle($x, $y, $active_block->[$i][$j], $zinc);
		  }
	      }
	    $x++;
	  }
	$y++;
      }
  }



sub new_game {
    reset_playfield();
    renew_field();
    reset_block();
    $next_block_nr = undef;
    reset_game_param();
    action();
}

sub stop_and_new_game {
    stop_game();
    new_game(),
  }

## no more used, because it quits zinc-demos
sub quit_game {

    print "Bye!\n";
    exit;
}

sub lost {
  $top->destroy;
  print "You lost :o( !\n";
  exit;
 }

sub reset_game_param {
    $points = $blocks = $lines = 0;
    $level = level();
    $speed = speed();
    $pause = undef;
}

sub stop_game {
    undef_timer();
    undef $active_block;
}

sub delete_line
  {
    my($y) = @_;
    my $yy = $y*$step_y;
    my $x;
    for $x (1 .. $width-2)
      {
	my $xx = ($x-1)*$step_x;
	$tetris->add
	  ('rectangle',1,
	   [$xx, $yy, $xx+$boxsize_x, $yy+$boxsize_y],
	   -filled => 1,
	   -fillcolor => 'orange;50',
	   -tags => ['delline'],
	  );
      }
    $tetris->idletasks;
    short_sleep(0.05);
    $tetris->remove('delline');
    my $deuxpi = 3.1416;
    my $i = 1;
    my $angle = 360;
    # special effect on TkZinc logo
    rotation($deuxpi*$angle/360);
    $mylines++;
    $tetris->itemconfigure($new,-text => "    $mylines Lines\n", -font => $basefont->($fontheight));
  }

sub rotation
  {
    my ($angle, $cnt) = @_;
    # first step of animation
    if ($cnt == $stepsnumber)
      {
	inflation(); # scaling effect
	return;
      }
    $cnt++;
    # use 'rotation' Zinc method.
    my $stepi = 360/$stepsnumber;
    $angle = $stepi*2*3.1416/360;
    $tetris->rotate($group, $angle, 250, 450 );
    # process the animation using the 'after' Tk defering method
    $tetris->after($afterdelay, sub {rotation($angle, $cnt)});
  }

sub inflation
  {
    my ($cnt) = @_;
    my @pos = $tetris->coords($group);
    my $zf;
    # last step of animation
    if ($cnt == 6)
      {
	return;
	# event steps : wheel grows
      }
    elsif ($cnt % 2 == 0)
      {
	$zf = 4*$zoomrate;
	# odd steps : wheel is shrunk
      }
    else
      {
	$zf = 1/(4*$zoomrate);
      }
    $cnt++;
    # Now, we apply scale transformation to the Group item, using the 'scale'
    # Zinc method. Note that we reset group coords before scaling it, in order
    # that the origin of the transformation corresponds to the center of the
    # wheel. When scale is done, we restore previous coords of group.
    $tetris->coords($group, [0, 0]);
    $tetris->scale($group, $zf, $zf);
    $tetris->coords($group, \@pos);
    # process the animation using the 'after' Tk defering method
    $tetris->after(100, sub {inflation($cnt)});
  }

sub game_over {
  stop_game();
  #    insert_highscore();
  #    show_highscore('Game over');
  #    save_highscore();
  #toggle_pause();
  my $width  = $top->width;
  my $height = $top->height;
  my $new = $tetris->add('text',$pause_group,
			 -font => $basefont->($fontheight),
			 -text => "You lost ! :o)\ntype 'n' to try again !",
			 -position => [20,100],
			);
  $top->update('idletasks');
  short_sleep(1);
  $tetris->remove($new);
 }

sub move {
    my($dir) = @_;
    if (!$active_block || !defined $posx || $pause) {
	$top->bell;
	return;
    }
    if ($dir eq 'right' and testblock($active_block, $posx+1, $posy)) {
	drawblock($posx, $posy, 0);
	$posx++;
	drawblock($posx, $posy, 1);
    } elsif ($dir eq 'left' and testblock($active_block, $posx-1, $posy)) {
	drawblock($posx, $posy, 0);
	$posx--;
	drawblock($posx, $posy, 1);
    } elsif ($dir eq 'turn') {
	my $help_block = [];
	copyblock($active_block, $help_block);
	turn($active_block_nr, $help_block);
	if (testblock($help_block, $posx, $posy)) {
	    drawblock($posx, $posy, 0);
	    copyblock($help_block, $active_block);
	    drawblock($posx, $posy, 1);
	}
    } elsif ($dir eq 'antiturn') {
	my $help_block = [];
	copyblock($active_block, $help_block);
	anti_turn($active_block_nr, $help_block);
	if (testblock($help_block, $posx, $posy)) {
	    drawblock($posx, $posy, 0);
	    copyblock($help_block, $active_block);
	    drawblock($posx, $posy, 1);
	}
    } elsif ($dir eq 'freefall') {
	if ($moveable_drop) {
	    $freefall = 1;
	    undef_timer();
	    action();
	} else {
	    my $free_fall = 0;
	    while (testblock($active_block, $posx, $posy+1)) {
		drawblock($posx, $posy, 0);
		$posy++;
		$free_fall++;
		drawblock($posx, $posy, 1);
		$top->idletasks;
	    }
	    array_update(($level+1)*int(($free_fall+$height-$posy+5)/5),
			 $posx, $posy);
	}
    }
  }

sub array_update
  {
    my($plus, $posx, $posy) = @_;
    my($i, $j);
    undef_timer();
    delete_shadow();
    for $i (0 .. $max_size-1)
      {
	for $j (0 .. $max_size-1) {
	    if ($active_block->[$i][$j] and $posy+$i >= 0) {
		$playfield->[$posy+$i][$posx+$j] = $active_block->[$i][$j];
	    } else {
		if ($active_block->[$i][$j]) {
		    game_over();
		    return;
		}
	    }
	}
    }
    $points += $plus;

    if ($posy >= 0) {
	for $i ($posy .. $height-2) {
	    if (to_del_line($i)) {
		delete_line($i);
		$lines++;
		$points += 10*($level+1);
		for $j (reverse(0 .. $i-1)) {
		    my $k;
		    for $k (1 .. $width-2) {
			$playfield->[$j+1][$k] = $playfield->[$j][$k];
		    }
		}
		renew_field($i);
	    }
	}
    }

    my $oldlevel = $level;
    $level = level();
    if ($oldlevel != $level) {
	my $width  = $top->width;
	my $height = $top->height;
	my $newlevel = $tetris->add('text',$pause_group,
				    -text => 'NEW LEVEL',
				    -font => $basefont->($fontheight),
				    -position => [20,20],
				  );
	$top->update('idletasks');
	short_sleep(0.5);
	$tetris->remove($newlevel);
    }
    
    reset_block();
    action();
}

sub anti_turn
  {
    my($number, $block) = @_;
    for (1 .. 3) { turn($number, $block) }
}

sub undef_timer {
    if ($timer) {
	$timer->cancel;
	undef $timer;
    }
}

sub delete_shadow {
    return if !$draw_shadow;
    for(my $x = 1; $x <= $width-1; $x++) {
#	rectangle($x, 0, 0, $shadow);
    }
}

sub to_del_line {
    my($posy) = @_;
    my $i;
    
    for $i (1 .. $width-2) {
	if ($posy >= 0 and !$playfield->[$posy][$i]) {
	    return 0;
	}
    }
    1;
}
sub reset_block {
    undef $active_block_nr;
    undef $posx;
    $freefall = 0;
}

sub short_sleep {
    my $sleep = shift;
    if ($^O =~ /win/i) {
	$top->Busy;
	my $wait = 0;
	$top->after($sleep*1000, sub { $wait = 1 });
	$top->waitVariable(\$wait);
	$top->Unbusy;
    } else {
	eval { select(undef, undef, undef, $sleep) };
    }
}

sub renew_field {
    my($max_y) = @_;
    $max_y = $height-2 if !defined $max_y;
    my($i, $j);
    for $i (0 .. $max_y) {
	for $j (1 .. $width-2) {
	    if ($playfield->[$i][$j]) {
		rectangle($j, $i, $playfield->[$i][$j], $tetris);
	    } else {
		rectangle($j, $i, 0, $tetris);
	    }
	}
    }
}

sub help
  {
    inc_pause();
    if (defined $help_top and Tk::Exists($help_top))
      {
	$help_top->raise;
	return;
      }
    require Tk::ROText;
    my $firebutton = 'Button';
    eval { require Tk::FireButton; Tk::FireButton->VERSION(1.04); };
    $help_top = $top->Toplevel(-title => 'Tetris Help');
    make_key_bindings($help_top);
    my $ti = "Zetris help :\n  - truc 1\n  - truc 2\n  - truc 3\n \n";
    my $create_but = sub {
	my($t, $command, $fire) = @_;
	my $button = ($fire ? $firebutton : 'Button');
	my $but = $tetris->add('text',$pause_group,
			       -text => $ti,
			       -font => $base2font->(12),
			       -position => [20,20],
				);
    };

    my $cb = $help_top->Button(-text => 'Close',
			       -font => $base2font->(12),
			       -command => sub { $help_top->destroy })->pack;
    $help_top->bind('<Escape>' => sub { $cb->invoke });
}

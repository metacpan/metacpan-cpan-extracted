#!/usr/bin/perl
# This simple demo has been developped by C. Schlienger <celine@intuilab.com>

package counter; # for avoiding symbol collision between different demos

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.9 $ =~ /(\d+)\.(\d+)/);

use Tk;
use Tk::Zinc;
use strict;
use constant;

my constant $PI=3.1416;

my $boldfont = '-adobe-helvetica-bold-r-normal--20-240-100-100-p-182-iso8859-1';

my $mw = MainWindow->new();

###################################################
# Zinc
###################################################

my $zinc = $mw->Zinc(-width => 700, -height => 400,
		     -font => "10x20", 
		     -borderwidth => 3, 
		     -relief => 'sunken',
		     -render => 1,
		    )->pack;

if ($zinc->cget(-render)) {
    $zinc->add('rectangle', 1,
	       [0,0,700,400],
	       -filled => 1,  -linewidth => 0,
	       -fillcolor => "=axial 90 |red;40|green;40 50|blue;40"
	       );
} else { ## no openGL rendering!
    # creating a curve in the background to demonstrate the clipping
    # of the hole in the counter
    $zinc->add('curve', 1, [30,30, 350,150, 670,30, 400,200, 670,370, 350,250, 30,370, 300,200, 30,30],
	       -filled => 1,
	       -fillcolor => "tan",
	       );
}

# The explanation displayed when running this demo
$zinc->add('text', 1,
	   -position=> [10,10],
	   -text => 'This toy-appli shows a simple counter. It is made thanks
to clipping and contours : this is the only way to do this.
You can drag the counter. Observe that the color of the background
of the counter is the same as the one of the window (use of clips)',
	   -font => "10x20",
	   );

###################################################
# Les positions
###################################################

#--------------------------------
# Carre dans lequel sera inscrit le cercle du compteur
#---------------------------------

my $x0=250;
my $y0=100;
my $x1=$x0+200;
my $y1=$y0+200;

#--------------------------------
# Rectangle dans lequel defileront les chiffres
#---------------------------------

my $x2=$x0+50;
my $y2=$y0+130;
my $x3=$x1-50;
my $y3=$y1-50;


###################################################
# Chiffres clippes
###################################################

my $general_group = $zinc->add('group',1, -visible => 1);

my $clipped_group1 = $zinc->add('group',$general_group, -visible => 1);

#--------------------------------
# Clipping items
#---------------------------------

my $clipping_item1 = $zinc->add('curve', $clipped_group1,
			       [$x2,$y2,$x3,$y2,$x3,$y3,$x2,$y3,$x2,$y2]
			      );

#--------------------------------
# Clipped items
#---------------------------------

my $group1=$zinc->add('group',$clipped_group1);

my $ecart=17;

# Il y a deux listes de chifres pour centaines, dizaines, unites,
# pour assurer l'enchainement des chiffres quand le temps passe
# (cf. : actions automatiques)

#--------------------------------
# Centaines
#---------------------------------

my $cent = $zinc->add('group',$group1, -visible => 1,);
my $xc=$x2+20;
my $yc=$y2;


my $nbc1=$zinc->add('text', $cent,
	   -font => $boldfont,
	   -text => "0
1
2
3
4
5
6
7
8
9",
	   -anchor => 'nw',
	   -position => [$xc, $yc],
);
my $nbc2=$zinc->add('text', $cent,
	   -font => $boldfont,
	   -text => "0
1
2
3
4
5
6
7
8
9",
	   -anchor => 'nw',
	   -position => [$xc, $yc+210],
);
#--------------------------------
# Dixaines
#---------------------------------

my $dix = $zinc->add('group',$group1, -visible => 1);

my $xd=$xc+30;
my $yd=$y2;
my $nbd1=$zinc->add('text', $dix,
	   -font => $boldfont,
	   -text => "0
1
2
3
4
5
6
7
8
9",
	   -anchor => 'nw',
	   -position => [$xd,$yd]);

my $nbd2=$zinc->add('text', $dix,
	   -font => $boldfont,
	   -text => "0
1
2
3
4
5
6
7
8
9",
	   -anchor => 'nw',
	   -position => [$xd,$yd+210]);
#--------------------------------
# Unites
#---------------------------------

my $unit = $zinc->add('group',$group1, -visible => 1);
my $xu=$xd+30;
my $yu=$y2;
my $nbu1=$zinc->add('text', $unit,
		    -font => $boldfont,
		    -text => "0
1
2
3
4
5
6
7
8
9",
		    -anchor => 'nw',
		    -position => [$xu, $yu]);

my $nbu2=$zinc->add('text', $unit,
		    -font => $boldfont,
		    -text => "0
1
2
3
4
5
6
7
8
9",
		    -anchor => 'nw',
		    -position => [$xu, $yu+210]);

#--------------------------------
# Clip
#---------------------------------

$zinc->itemconfigure($clipped_group1, -clip => $clipping_item1);


###################################################
# Cadran clippe
###################################################

my $clipped_group2 = $zinc->add('group',$general_group, -visible => 1);

#--------------------------------
# Clipping items
#---------------------------------

my $clipping_item2 = $zinc->add('curve', $clipped_group2,
			       [0,0,700,0,700,700,0,700,0,0],
				-linewidth=>0,
			      );

$zinc->contour($clipping_item2,"add",0,[$x2,$y2,$x3,$y2,$x3,$y3,$x2,$y3,$x2,$y2]);

#--------------------------------
# Clipped items
#---------------------------------

my $group2=$zinc->add('group',$clipped_group2);

my $cercle=$zinc->add('arc',$group2,[$x0,$y0,$x1,$y1],
			 -visible=>1,
			 -filled=>1,
			 -fillcolor=>"yellow",);

my $fleche=$zinc-> add('curve', $group2, [$x0+40,$y0+40,$x1-100,$y1-25],
		       -firstend => [10, 10, 10],
		       -linewidth => 7,
		       -linecolor=>"red",
	    );

#--------------------------------
# Clip
#---------------------------------

$zinc->itemconfigure($clipped_group2, -clip => $clipping_item2);

# this translation if for having an "interesting" background in the counter hole
# when we do not have openGL and a gradient in the background
$zinc->translate($general_group,0,21); 

###################################################
# Actions automatiques
###################################################

#--------------------------------
# Variables
#---------------------------------
# Pour le timer
my $repeat=10;

# Pour la rotation
my @centre=($x1-100,$y1-25);
my $pas=40;
my $angle=+$PI/$pas;
my $nb_tot=12;
my $nb=0;

# Pour la translation des centaines
my @c_c1=$zinc->itemcget($nbc1,-position);
my @c_c2=$zinc->itemcget($nbc2,-position);
my $nbtour_cent=2;

# Pour la translation des dizaines
my @c_d1=$zinc->itemcget($nbd1,-position);
my @c_d2=$zinc->itemcget($nbd2,-position);
my $nbtour_dix=2;

# Pour la translation des unites
my @c_u1=$zinc->itemcget($nbu1,-position);
my @c_u2=$zinc->itemcget($nbu2,-position);
my $nbtour_unit=2;


#--------------------------------
# Timer
#---------------------------------
my $timer = $zinc->repeat($repeat, [\&refresh]);

$mw->OnDestroy(\&destroyTimersub );

my $timerIsDead = 0;
sub destroyTimersub {
    $timerIsDead = 1;
    $mw->afterCancel($timer);
    # the timer is not really cancelled when using zinc-demos! 
}

#--------------------------------
# Actions
#---------------------------------
sub refresh {
  #--------------------------------
  # Rotation de la fleche
  #---------------------------------
  return if $timerIsDead;   # the timer is still running when using zinc-demos!
  $zinc->rotate($fleche,$angle,$centre[0],$centre[1]);
  $nb+=1;
  if (($nb==$nb_tot)&&($angle==$PI/$pas))
    {
      $nb=0;
      $angle=-$PI/$pas;
    } 
  else{
    if(($nb==$nb_tot)&&($angle==-$PI/$pas)){
      $nb=0;
      $angle=+$PI/$pas;
    }
  }
  #--------------------------------
  # Deplacement du texte
  #---------------------------------

  #--------------------------------
  # Centaines
  #---------------------------------
  $zinc->translate($cent,0,-0.01);

  my @coords_c1=$zinc->transform($cent,$group1,[$c_c1[0],$c_c1[1]]);
  if(int($coords_c1[1])==$yc-210){
    $zinc->itemconfigure($nbc1,-position=>[$xc,$yc+($nbtour_cent*210)]);
    $nbtour_cent+=1;
    @c_c1=$zinc->itemcget($nbc1,-position);
  }

  my @coords_c2=$zinc->transform($cent,$group1,[$c_c2[0],$c_c2[1]]);
  if($coords_c2[1]==$yc-210){
    $zinc->itemconfigure($nbc2,-position=>[$xc,$yc+($nbtour_cent*210)]);
    $nbtour_cent+=1;
    @c_c2=$zinc->itemcget($nbc2,-position);
  }

  #-------------------------------- 
  #Dixaines
  #---------------------------------
  $zinc->translate($dix,0,-0.1);

  my @coords_d1=$zinc->transform($dix,$group1,[$c_d1[0],$c_d1[1]]);
  if(int($coords_d1[1])==$yd-210){
    $zinc->itemconfigure($nbd1,-position=>[$xd,$yd+($nbtour_dix*210)]);
    $nbtour_dix+=1;
    @c_d1=$zinc->itemcget($nbd1,-position);
  }

  my @coords_d2=$zinc->transform($dix,$group1,[$c_d2[0],$c_d2[1]]);
  if($coords_d2[1]==$yd-210){
    $zinc->itemconfigure($nbd2,-position=>[$xd,$yd+($nbtour_dix*210)]);
    $nbtour_dix+=1;
    @c_d2=$zinc->itemcget($nbd2,-position);
  }


  #--------------------------------
  # Unites
  #---------------------------------
  $zinc->translate($unit,0,-1);

  my @coords_u1=$zinc->transform($unit,$group1,[$c_u1[0],$c_u1[1]]);
  if($coords_u1[1]==$yu-210){
    $zinc->itemconfigure($nbu1,-position=>[$xu,$yu+($nbtour_unit*210)]);
    $nbtour_unit+=1;
    @c_u1=$zinc->itemcget($nbu1,-position);
  }

  my @coords_u2=$zinc->transform($unit,$group1,[$c_u2[0],$c_u2[1]]);
  if($coords_u2[1]==$yu-210){
    $zinc->itemconfigure($nbu2,-position=>[$xu,$yu+($nbtour_unit*210)]);
    $nbtour_unit+=1;
    @c_u2=$zinc->itemcget($nbu2,-position);
  }

}

###################################################
# Actions manuelles
###################################################

#---------------------------------------------
# Drag and drop the counter
#---------------------------------------------

my ($prev_x, $prev_y);
$zinc -> bind($cercle,'<ButtonPress-1>'=>[\&move_on] ); 


#"move_on" state#
sub move_on{
    $prev_x=$zinc->XEvent()->x;
    $prev_y=$zinc->XEvent()->y;
    # move the counter
    $zinc -> bind($cercle,'<Motion>'=> [\&move]);
    $zinc -> bind($cercle,'<ButtonRelease-1>'=> [\&move_off]); #"move_off" state
}


#"move_off" state#
sub move_off{
  $zinc -> bind($cercle,'<Motion>'=>""); 
  $zinc -> bind($cercle,'<ButtonRelease-1>'=>"");
}

#move the counter#
sub move{
  my $x=$zinc->XEvent()->x,
  my $y=$zinc->XEvent()->y;
  $zinc->translate($clipped_group1,$x-$prev_x,$y-$prev_y);
  $zinc->translate($clipped_group2,$x-$prev_x,$y-$prev_y);
  ($prev_x,$prev_y) = ($x,$y);
}
 
Tk::MainLoop;

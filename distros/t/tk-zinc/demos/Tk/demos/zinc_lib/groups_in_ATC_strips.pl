#!/usr/bin/perl -w
#-----------------------------------------------------------------------------------
#
#      Copyright (C) 2002
#      Centre d'Études de la Navigation Aérienne
#
#      Authors: Jean-Luc Vinot <vinot@cena.fr> for whole graphic design and coding
#               Christophe Mertz <mertz@cena.fr> for adding simple animations
#                                                and integration in zinc-demos
#                 This integration is still not perfect and requires an extension in zinc
#                 We must know if a neamed gradient already exists, when launching
#                 many time the same demo in the same process!
#
# $Id: groups_in_ATC_strips.pl,v 1.9 2004/09/21 12:47:28 mertz Exp $
#-----------------------------------------------------------------------------------
#      This small application illustrates both the use of groups in combination
#         of -composescale attributes and an implementation of kind of air traffic
#         control electronic strips.
#      However it is only a simplified example given as is, without any immediate usage!
#
#      3 strips formats are accessible through "+" / "-" buttons on the right side
#
#      1.   small-format: with 2 lines of info, and reduced length
#
#      2.   normal-format: with 3 lines of info, full length
#
#      3.  extended-format: with 3 lines of infos, full length
#                           the 3 lines are zoomed
#                           an additionnel 4th lone is displayed
#
#      An additionnal 4th format (micro-format) is available when double-clicking somewhere...
#
#      Strips can be moved around by drag&drop from the callsign
#
#      When changing size, strips are animated. The animation is a very simple one,
#        which should be enhanced.... You can change the animation parameters, by modifyng
#        $delay and $steps.
#
#-----------------------------------------------------------------------------------

package groups_in_ATC_strips; # for avoiding symbol collision between different demos

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.9 $ =~ /(\d+)\.(\d+)/);

use Tk;
use Tk::Zinc;
use strict;

$| = 1;


my @stripGradiants;
my %stripFontset;
my %textures;

my $oldfkey;
my ($dx, $dy);

my $delay = 50; # ms between each animation steps
my $steps = 6;  # number of steps for the animation
my %scales;     # this hash just memorizes the current x and y scaling ratio
                # In a real appli, this should be memorized in strip objects

#----------------------
# configuration data
#----------------------
my $fnb10 = 'cenapii-digistrips-b10';
my $fnb10c = 'cenapii-digistrips-b10c';
my $fnb11 = 'cenapii-digistrips-b11';
my $fnb12 = 'cenapii-digistrips-b12';
my $fnb15 = 'cenapii-radar-b15';
my $fnm20 = 'cenapii-radar-m20';
my $fne18 = 'cenapii-radar-m18';

my @ratio2fontset = ([1.2, 'normal'],
		     [10, 'large']);

my $mwidth = 700;
my $mheight = 500;

my %stripstyle = (-gradset => {'idnt' => '=axial 90 |#ffffff 0|#ffeedd 30|#e9d1ca 90|#e9a89a',
			       'back' => '=axial 0 |#c1daff|#8aaaff',
			       ## the following shadow gradient is sub-optimal
			       'shad' => '=path -40 -40 |#000000;50 0|#000000;50 92|#000000;0 100',
			       'btn_outside' => '=axial 0 |#ffeedd|#8a9acc', 
			       'btn_inside' => '=axial 180 |#ffeedd|#8a9acc',
			       'ch1' => '=axial 0 |#8aaaff|#5B76ED',
			   },
		  
		  -fontset => {'normal' => {'callsign' => $fnb15,
					    'type1' => $fnb12,
					    'type2' => $fnb10,
					    'type3' => $fnb10c,
					},
			       
			       'large' => {'callsign' => $fnm20,
					   'type1' => $fne18,
					   'type2' => $fnb15,
					   'type3' => $fnb12,
				       },
			   },
		  
		  -width => 340,
		  -height => 86,
		  -shadowcoords => [8, 8, 374, 94],
		  -shadowcolor => 'shad',

		  -strip => {-linewidth => 3,
			     -linecolor => '#aaccff',
			     -fillcolor => 'back',
			     -relief => 'roundraised',
			 },

		  -buttons => {-coords => [340, 0],
			       -clipcoords => [0, 0, 90, 83],
			       -zone => {-coords => [0, 0, 26, 85],
					 -fillcolor => 'btn_outside',
					 -linewidth => 0,
				     },
			    
			       -btns => {'btnup' => {-coords => [0, 0, 26, 43],
						     -arrow => [14, 2, 24, 40,
								1, 40, 14, 2],
						     -linewidth => 1,
						     -linecolor => '#aabadd',
						     -fillcolor => 'btn_inside',
						     -label => {-coords => [13, 27],
								-text => "+",
								-font => $fnm20,
								-color => '#ffffff',
								-anchor => 'center',
							    },
						 },
					 
					 'btndn' => {-coords => [0, 43, 26, 86],
						     -arrow => [14, 83, 24, 43,
								1, 43, 14, 83],
						     -linewidth => 1,
						     -linecolor => '#aabadd',
						     -fillcolor => 'btn_inside',
						     -label => {-coords => [13, 56],
								-text => "-",
								-font => $fnm20,
								-color => '#ffffff',
								-anchor => 'center',
							    },
						 },
				     },
			   },
		  
		  -clipcoords => [3, 3, 332, 80],
		  -zones => {'ident' => {-coords => [3, 3, 90, 50],
					 -atomic => 1,
					 -priority => 200,
					 -sensitive => 1,
					 -tags => "move",
					 -linewidth => 1,
					 -filled => 1,
					 -relief => 'sunken',
					 -linecolor => '#ffeedd',
					 -fillcolor => 'idnt',
					 -fields => {-callsign => {-coords => [10, 18],
								   -font => 'callsign',
								   -text => 'EWG361',
								   -anchor => 'w',
								   -color => '#000000',
							       },
						     -company => {-coords => [10, 34],
								  -font => 'type2',
								  -text => 'Eurowing',
								  -anchor => 'w',
								  -color => '#444444',
							      },
						 },
				     },
			     'input' => {-coords => [3, 3, 334, 82],
					 -atomic => 1,
					 -priority => 100,
					 -sensitive => 1,
					 -tags => "scale",
					 -linewidth => 0,
					 -filled => 1,
					 -relief => 'flat',
					 -linecolor => 'white',
					 -fillcolor => 'back', #'#afb2cc',
					 -fields => {-type => {-coords => [100, 18],
							       -font => 'type1',
							       -text => 'TYPA',
							       -anchor => 'w',
							       -color => '#444444',
							   },
						     -cfmu => {-coords => [200, 18],
							       -font => 'type1',
							       -text => '08:26',
							       -anchor => 'e',
							       -color => '#444444',
							   },
						     -ptsid => {-coords => [100, 40],
							       -font => 'type2',
							       -text => 'NIPOR',
							       -anchor => 'w',
							       -color => '#444444',
							   },
						     -confsid => {-coords => [158, 40],
							       -font => 'type2',
							       -text => '8G',
							       -anchor => 'center',
							       -color => '#444444',
							   },
						     -park => {-coords => [200, 40],
							       -font => 'type2',
							       -text => 'G23',
							       -anchor => 'e',
							       -color => '#444444',
							   },
						     
						     -dest => {-coords => [10, 66],
							       -font => 'type2',
							       -text => 'DEST',
							       -anchor => 'w',
							       -color => '#555555',
							   },
						     -champ1 => {-type => 'rect',
								 -coords => [45, 56,
									     135, 76],
								 -filled => 1,
								 -fillcolor => 'ch1',
								 -linecolor => 'white',
								 -linewidth => 0,
							   },
						     -bret => {-coords => [200, 66],
							       -font => 'type2',
							       -text => 'Bret.',
							       -anchor => 'e',
							       -color => '#444444',
							   },
						 },
				     },
			     
			     'zreco' => {-coords => [210, 3, 346, 82],
					 -atomic => 1,
					 -priority => 200,
					 -texture => "stripped_texture.gif",
					 -sensitive => 1,
					 -tags => "edit",
					 -linewidth => 2,
					 -filled => 1,
					 -relief => 'sunken',
					 -linecolor => '#deecff',
					 -fillcolor => '#d3e5ff',
				     },

			     
			 },
		  
		  -zinfo => {-coords => [0, 86],
			     -rectcoords => [0, 0, 340, 20],
			     -shadowcoords => [8, 8, 348, 28],
			     -shadowcolor => 'shad',
			     -atomic => 1,
			     -priority => 200,
			     -sensitive => 1,
			     -tags => "edit2",
			     -linewidth => 2,
			     -linecolor => '#aaccff',
			     -fillcolor => 'back',
			     -relief => 'roundraised',
			     -fields => {-ssr => {-coords => [4, 10],
						  -font => 'type3',
						  -text => '7656',
						  -anchor => 'w',
						  -color => '#444444',
					      },
					 -pdep => {-coords => [47, 10],
						  -font => 'type3',
						  -text => 'G23',
						  -anchor => 'center',
						  -color => '#444444',
					      },
					 -qfu => {-coords => [73, 10],
						  -font => 'type3',
						  -text => '09R',
						  -anchor => 'center',
						  -color => '#444444',
					      },
					 -slabel => {-coords => [105, 10],
						  -font => 'type3',
						  -text => 'vit:',
						  -anchor => 'e',
						  -color => '#444444',
					      },
					 -speed => {-coords => [106, 10],
						    -font => 'type3',
						    -text => '260',
						    -anchor => 'w',
						    -color => '#444444',
					      },
					 -pper => {-coords => [142, 10],
						  -font => 'type3',
						  -text => 'EPL',
						  -anchor => 'center',
						  -color => '#444444',
					      },
					 -rfl => {-coords => [166, 10],
						  -font => 'type3',
						  -text => '210',
						  -anchor => 'center',
						  -color => '#444444',
					      },
					 -cautra => {-coords => [183, 10],
						  -font => 'type3',
						  -text => '8350',
						  -anchor => 'w',
						  -color => '#444444',
					      },
					 -nsect => {-coords => [219, 10],
						  -font => 'type3',
						  -text => 'MOD',
						  -anchor => 'w',
						  -color => '#444444',
					      },
					 -day => {-coords => [297, 10],
						  -font => 'type3',
						  -text => '21/05/02',
						  -anchor => 'e',
						  -color => '#444444',
					      },
					 -hour => {-coords => [332, 10],
						  -font => 'type3',
						  -text => '13:50',
						  -anchor => 'e',
						  -color => '#444444',
					      },
			     },
					 
			  },
		  );

# creation de la fenetre principale
my $mw;
$mw = MainWindow->new();

# The explanation displayed when running this demo
my $text = $mw->Text(-relief => 'sunken', -borderwidth => 2,
		     -setgrid => 'true', -height =>7);
$text->pack(qw/-expand yes -fill both/);

$text->insert('0.0',
'These fake air Traffic Control electronic strips illustrates
 the use of groups for an advanced graphic design.
The following interactions are possible:
   "drag&drop button1" on the callsign.
   "button 1" triangle buttons on the right side of the strips
    to modify strips size
   "double click 1" on the blueish zone to fully reduce size');

$mw->title('ATC strips using groups');


#------------------------
# creation du widget Zinc
my $zinc = $mw->Zinc(-render => 1,
		     -width => $mwidth,
		     -height => $mheight,
		     -borderwidth => 0,
		     -lightangle => 130,
		     );
		     
$zinc->pack(-fill => 'both', -expand => 1);

my $texture = $zinc->Photo('background_texture.gif',
			   -file => Tk->findINC('demos/zinc_data/background_texture.gif'));
$zinc->configure(-tile => $texture) if $texture;



my ($xn, $yn) = (10, 30);

# test Strips
for (my $index = 0; $index < 4 ; $index++) {
    
    &createStrip($index, $xn, $yn, \%stripstyle);

    $xn += 50;
    $yn += 120;

}


&initBindings('move', 'scale');


	 

Tk::MainLoop;

#----------------------------------------------------------------------- fin de MAIN


# Création du Strip
sub createStrip {
    my ($index, $x, $y, $style) = @_;

    # initialise les gradiants
    unless (@stripGradiants) {
	my %gradiants = %{$style->{'-gradset'}};
	my ($name, $gradiant);
	while (($name, $gradiant) = each(%gradiants)) {
	    # création des gradients nommés
	    $zinc->gname($gradiant, $name) unless $zinc->gname($gradiant);
	    # the previous test is usefull only
	    # when this script is executed many time in the same process
	    # (it is typically the case in zinc-demos)

	    push(@stripGradiants, $name);
	}  
    }
  
    # initialise les jeux de fontes 
    unless (%stripFontset) {
	%stripFontset = %{$style->{'-fontset'}};
    }

    # création du groupe de base : coords
    my $g1 = $zinc->add('group', 1, -priority => 100, -tags => ["base".$index]);
    $zinc->coords($g1, [$x, $y]);

    # group de transfo 1 : scaling (à partir du coin haut droit)
    my $g2 = $zinc->add('group', $g1, -tags => ["scaling".$index]);


    #-------------------------------------------------------------
    # réalisation du strip lui même (papier support + ombre portée
    #-------------------------------------------------------------
    
    # params strip
    my $stripw = $style->{'-width'};
    my $striph = $style->{'-height'};
    
    # ombre portée
    $zinc->add('rectangle', $g2,
	       $style->{'-shadowcoords'},
	       -filled => 1,
	       -linewidth => 0,
	       -fillcolor => $style->{'-shadowcolor'},
	       -priority => 10,
	       -tags => ["shadow".$index],
	       );


    # strip
    my $sstyle = $style->{'-strip'};    
    my $strip = $zinc->add('rectangle', $g2,
			   [0, 0, $stripw, $striph],
			   -filled => 1,
			   -linewidth => $sstyle->{'-linewidth'},
			   -linecolor => $sstyle->{'-linecolor'},
			   -fillcolor => $sstyle->{'-fillcolor'},
			   -relief => $sstyle->{'-relief'},
			   -priority => 20,
			   -tags => ["strip".$index],
			   );

    if ($sstyle->{'-texture'}) {
	if (!exists($textures{'-strip'})) {
	    my $texture = $zinc->Photo($sstyle->{'-texture'}, 
                                       -file => Tk->findINC("demos/zinc_data/".$sstyle->{-texture}));
	    $textures{'-strip'} = $texture;
	}
	    
	$zinc->itemconfigure($strip, -tile => $textures{'-strip'});
    }
    

    #-------------------------------------------------
    # ajout de la zone des boutons (à droite du strip)
    #-------------------------------------------------
    if ($style->{'-buttons'}) {
	my $bstyle = $style->{'-buttons'};

	# le groupe de la zone bouton
	my $btngroup = $zinc->add('group', $g2, -priority => 40);
	$zinc->coords($btngroup, $bstyle->{'-coords'});

	# sa zone de clipping
	my $btnclip = $zinc->add('rectangle', $btngroup,
				 $bstyle->{'-clipcoords'},
				 -filled => 0,
				 -visible => 0,
				 );
	
	# le clipping du groupe bouton
	$zinc->itemconfigure($btngroup, -clip => $btnclip);
	
	# zone bouton
	$zinc->add('rectangle', $btngroup,
		   $bstyle->{'-zone'}->{'-coords'},
		   -filled => 1,
		   -linewidth => $bstyle->{'-zone'}->{'-linewidth'},
		   -fillcolor => $bstyle->{'-zone'}->{'-fillcolor'},
		   -composescale => 0,
		   -tags => ["content".$index],
		   );
	

	my %btns = %{$bstyle->{'-btns'}};
	my ($name, $btnstyle);
	while (($name, $btnstyle) = each(%btns)) {
#	    print "bouton $name $btnstyle\n";

	    my $sgroup = $zinc->add('group', $btngroup,
				    -atomic => 1,
				    -sensitive => 1,
				    -composescale => 0,
				    -tags => [$name.$index, "content".$index],
				    );

	    $zinc->add('rectangle', $sgroup,
		       $btnstyle->{'-coords'},
		       -filled => 1,
		       -visible => 0,
		       -priority => 100,
		       );
	
	    $zinc->add('curve', $sgroup,
		       $btnstyle->{'-arrow'},
		       -closed => 1,
		       -filled => 1,
		       -linewidth => $btnstyle->{'-linewidth'},
		       -linecolor => $btnstyle->{'-linecolor'},
		       -fillcolor => $btnstyle->{'-fillcolor'},
		       -priority => 50,
		       );

	    $zinc->add('text', $sgroup,
		       -position => $btnstyle->{'-label'}->{'-coords'},
		       -text => $btnstyle->{'-label'}->{'-text'},
		       -font => $btnstyle->{'-label'}->{'-font'},
		       -color => $btnstyle->{'-label'}->{'-color'},
		       -anchor => $btnstyle->{'-label'}->{'-anchor'},
		       -priority => 60,
		       );
	}

	# bindings boutons Up et Down du Strip
	$zinc->bind('btnup'.$index, '<1>', \&extendedStrip);
	$zinc->bind('btndn'.$index, '<1>', \&smallStrip);
	
    }

    # construction du contenu du strip
    &buildContent($index, $g2, 100, $style);

    # et de la barre d'extension info (extended format)
    &buildExtent($index, $g2, $style->{'-zinfo'});

}


# Construction des zones internes du Strips
sub buildContent {
    my ($index, $parent, $priority, $style) = @_;
    
    # group content
    my $g3 = $zinc->add('group', $parent, -priority => $priority);

    # zone de clipping
    my $clip = $zinc->add('rectangle', $g3,
			  $style->{'-clipcoords'},
			  -filled => 0,
			  -visible => 0,
			  );
    
    # clipping du groupe content
    $zinc->itemconfigure($g3, -clip => $clip);

    # création d'un group intermédiaire pour bloquer le scaling
    my $g4 = $zinc->add('group', $g3,
			-composescale => 0,
			-tags => ["content".$index],
			);
    
    # création des zones
    my %zones = %{$style->{'-zones'}};
    my ($name, $zonestyle);
    while (($name, $zonestyle) = each(%zones)) {
	# group de zone
	my $gz = $zinc->add('group', $g4);

	if ($zonestyle->{'-atomic'}) {
	    $zinc->itemconfigure($gz, -atomic => 1,
				 -sensitive => $zonestyle->{'-sensitive'},
				 -priority => $zonestyle->{'-priority'},
				 -tags => [$name.$index, $zonestyle->{'-tags'}],
				 );
	}
	
	my $rectzone = $zinc->add('rectangle', $gz,
				  $zonestyle->{'-coords'},
				  -filled => $zonestyle->{'-filled'},
				  -linewidth => $zonestyle->{'-linewidth'},
				  -linecolor => $zonestyle->{'-linecolor'},
				  -fillcolor => $zonestyle->{'-fillcolor'},
				  -relief => $zonestyle->{'-relief'},
				  -priority => 10,
				  -tags => [$name.$index],
				  );

	if ($zonestyle->{'-texture'}) {
	    if (!exists($textures{$name})) {
		my $texture = $zinc->Photo($zonestyle->{'-texture'}, 
                                           -file => Tk->findINC("demos/zinc_data/".$zonestyle->{-texture}));
		$textures{$name} = $texture;
	    }

	    $zinc->itemconfigure($rectzone, -tile => $textures{$name});
	}


	my %fields;
	%fields = %{$zonestyle->{'-fields'}} if (defined $zonestyle->{'-fields'}) ;
	my ($field, $fieldstyle);
	my $fontsty = $stripFontset{'normal'};
	while ( ($field, $fieldstyle) = each(%fields) ) {
	    if ($fieldstyle->{'-type'} and $fieldstyle->{'-type'} eq 'rect') {
		$zinc->add('rectangle', $gz,
			   $fieldstyle->{'-coords'},
			   -filled => $fieldstyle->{'-filled'},
			   -fillcolor => $fieldstyle->{'-fillcolor'},
			   -linewidth => $fieldstyle->{'-linewidth'},
			   -linecolor => $fieldstyle->{'-linecolor'},
			   -priority => 20,
			   );
		} else {
		
		    my $font = $fieldstyle->{'-font'};
#		    print "buildContent field:$field font:$font\n";
		    $zinc->add('text', $gz,
			       -position => $fieldstyle->{'-coords'},
			       -text => $fieldstyle->{'-text'},
			       -font => $fontsty->{$font},
			       -color => $fieldstyle->{'-color'},
			       -anchor => $fieldstyle->{'-anchor'},
			       -priority => 30,
			       -tags => [$font.$index],
			       );
		}
		
	}

    }
}


# Construction de la barre d'extension info du Strip
sub buildExtent {
    my ($index, $parent, $infostyle) = @_;
    
    # group content
    my $extgroup = $zinc->add('group', $parent);
    $zinc->coords($extgroup, $infostyle->{'-coords'});

    $zinc->itemconfigure($extgroup,
			 -atomic => $infostyle->{'-atomic'},
			 -sensitive => $infostyle->{'-sensitive'},
			 -priority => $infostyle->{'-priority'},
			 -visible => 0,
			 -tags => ["zinfo".$index, $infostyle->{'-tags'}],
			 );

    # ombre portée
    $zinc->add('rectangle', $extgroup,
	       $infostyle->{'-shadowcoords'},
	       -filled => 1,
	       -linewidth => 0,
	       -fillcolor => $infostyle->{'-shadowcolor'},
	       -priority => 10,
	       -tags => ["shadow".$index],
	       );
    
    my $rectzone = $zinc->add('rectangle', $extgroup,
  			      $infostyle->{'-rectcoords'},
  			      -filled => 1,
  			      -linewidth => $infostyle->{'-linewidth'},
  			      -linecolor => $infostyle->{'-linecolor'},
  			      -fillcolor => $infostyle->{'-fillcolor'},
  			      -relief => $infostyle->{'-relief'},
  			      -priority => 20,
  			      );

    if ($infostyle->{'-texture'}) {
  	if (!exists($textures{'-zinfo'})) {
  	    my $texture = $zinc->Photo($infostyle->{'-texture'}, 
                                       -file => Tk->findINC("demos/zinc_data/".$infostyle->{-texture}));
  	    $textures{'-zinfo'} = $texture;
  	}
  	$zinc->itemconfigure($rectzone, -tile => $textures{'-zinfo'});
	
    }

    my %fields = %{$infostyle->{'-fields'}};
    my ($field, $fieldstyle);
    my $fontsty = $stripFontset{'normal'};
    while (($field, $fieldstyle) = each(%fields)) {
	if ($fieldstyle->{'-type'} and $fieldstyle->{'-type'} eq 'rect') {
	    $zinc->add('rectangle', $extgroup,
		       $fieldstyle->{'-coords'},
		       -filled => $fieldstyle->{'-filled'},
		       -fillcolor => $fieldstyle->{'-fillcolor'},
		       -linewidth => $fieldstyle->{'-linewidth'},
		       -linecolor => $fieldstyle->{'-linecolor'},
		       -priority => 40,
		       );
	} else {
	    
	    my $font = $fieldstyle->{'-font'};
#	    print "buildContent field:$field font:$font\n";
	    $zinc->add('text', $extgroup,
		       -position => $fieldstyle->{'-coords'},
		       -text => $fieldstyle->{'-text'},
		       -font => $fontsty->{$font},
		       -color => $fieldstyle->{'-color'},
		       -anchor => $fieldstyle->{'-anchor'},
		       -priority => 50,
		       -tags => [$font.$index],
		       );
	}
	
    }
    
}

# initialisation des bindings généraux dy Strip
sub initBindings {
    my ($movetag, $scaletag) = @_;

    $zinc->bind($movetag, '<1>', \&catchStrip);
    $zinc->bind($movetag, '<ButtonRelease>', \&releaseStrip);
    $zinc->bind($movetag, '<B1-Motion>', \&motionStrip);

    $zinc->bind($scaletag, '<Double-Button-1>', \&microStrip);

}
    
# Callback CATCH de début de déplacement du Strip
sub catchStrip {
    my $index = substr(($zinc->itemcget('current', -tags))[0], 5);

    my ($x, $y) = $zinc->coords("base".$index);
    my $ev = $zinc->XEvent;
    ($dx, $dy) = ($x - $ev->x, $y - $ev->y);

    $zinc->itemconfigure("base".$index, -priority => 200);

}

# Callback MOVE de fin de déplacement du Strip
sub motionStrip {
    my $index = substr(($zinc->itemcget('current', -tags))[0], 5);
    my $ev = $zinc->XEvent;
    $zinc->coords("base".$index, [$ev->x + $dx, $ev->y + $dy]);
    
}

# Callback RELEASE de fin de déplacement du Strip
sub releaseStrip {
    my $index = substr(($zinc->itemcget('current', -tags))[0], 5);
    $zinc->itemconfigure("base".$index, -priority => 100);
}

# Zoom Strip : normal format
sub normalStrip {
    my $index = substr(($zinc->itemcget('current', -tags))[0], 5);

    $zinc->itemconfigure("input".$index, -sensitive => 1);

    &displayRecoZone($index, 1);
    &displayExtentZone($index, 0);
    &configButtons($index, \&extendedStrip, \&smallStrip);
    &changeStripFormat($index, 1, 1, 0, 1);
}

# Zoom Strip : small format (lignes 1 et 2)
sub smallStrip {
    my $index = substr(($zinc->itemcget('current', -tags))[0], 5);

    &displayRecoZone($index, 0);
    &configButtons($index, \&normalStrip, 0);
    &changeStripFormat($index, 1, .63, 0, 1);
}

# Zoom Strip : micro format (zone ident)
sub microStrip {
    my $index = substr(($zinc->itemcget('current', -tags))[0], 5);
    
    &configButtons($index, \&normalStrip, 0);
    &changeStripFormat($index, .28, .63, 0, 1);
    
}

# Zoom Strip : extendedFormat
sub extendedStrip {
    my $index = substr(($zinc->itemcget('current', -tags))[0],5);

    $zinc->itemconfigure("input".$index, -sensitive => 0);
    $zinc->itemconfigure("base".$index, -priority => 150);
    &displayRecoZone($index, 0);
    &displayExtentZone($index, 1);
    &configButtons($index, 0, \&normalStrip);
    &changeStripFormat($index, 1.3, 1.3, 1, 1.3);
}


# affiche/masque la zone Reco
sub displayRecoZone {
    my ($index, $state) = @_;
    my $priority = ($state) ? 200 : 0;
    $zinc->itemconfigure("zreco".$index, -priority => $priority);
}


# affiche/masque la zone Extent
sub displayExtentZone {
    my ($index, $state) = @_;

    $zinc->itemconfigure("zinfo".$index,
			 -visible => $state,
			 -sensitive => $state);
}

# Configure affichage et callbacks des boutons du Strip
sub configButtons {
    my ($index, $funcUp, $funcDown) = @_;

    # button Up
    $zinc->itemconfigure("btnup".$index, -visible => $funcUp);
    $zinc->bind('btnup'.$index, '<1>', $funcUp) if $funcUp;

    # button Down
    $zinc->itemconfigure("btndn".$index, -visible => $funcDown);
    $zinc->bind('btndn'.$index, '<1>', $funcDown) if $funcDown;

}

    
# this function has been hacked to provide the user with an animation
# The animation is (too) simple but provide a better feedback than without
sub changeStripFormat {
    my ($index, $xratio, $yratio, $composeflag, $fontratio) = @_;

    # réinitialisation du groupe scaling
    $zinc->treset("scaling".$index);

    # configure le blocage de transformation du format des champs
    $zinc->itemconfigure("content".$index, -composescale => $composeflag);

    # applique le nouveau scaling
    $scales{$index} = [1,1] unless defined $scales{$index};
    my ($oldXratio,$oldYratio) = @{$scales{$index}};
    $scales{$index}=[$xratio, $yratio];
    my $dx = ($xratio - $oldXratio) / $steps;
    my $dy = ($yratio - $oldYratio) / $steps;
    &_resize($index, $delay, $oldXratio+$dx, $oldYratio+$dy, $dx, $dy, $steps);
}

sub _resize {
    my ($index, $delay, $newXratio, $newYratio, $dx, $dy, $steps) = @_;
    $zinc->treset("scaling".$index);
    $zinc->scale("scaling".$index, $newXratio, $newYratio);
    # jeu de fontes
    &setFontes($index, $newYratio);
    $steps--;
    $zinc->after($delay, sub {&_resize ($index, $delay, $newXratio+$dx, $newYratio+$dy, $dx, $dy, $steps)})
	if $steps > 0;
}

sub getFKey {
    my ($ratio) = @_;
    my $newfkey;
   
    foreach my $param (@ratio2fontset) {
	my ($maxratio, $fkey) = @{$param};
	$newfkey = $fkey;
	if ($ratio < $maxratio) {
	    return $newfkey;
	}
    }
	
    return $newfkey;
}


sub setFontes {
    my ($index, $ratio) = @_;
    my $newfkey = &getFKey($ratio);
    
    if (!$oldfkey or $oldfkey ne $newfkey) {
	my $fontsty = $stripFontset{$newfkey};
#	print "setFontes $oldfkey -> $newfkey\n";
	if ($fontsty) {
	    foreach my $type ('callsign', 'type1', 'type2', 'type3') {
		$zinc->itemconfigure($type.$index, -font => $fontsty->{$type});
	    }
	}
	
	$oldfkey = $newfkey;
    }
}


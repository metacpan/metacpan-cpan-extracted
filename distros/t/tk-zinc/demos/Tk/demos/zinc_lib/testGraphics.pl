#!/usr/bin/perl
#-----------------------------------------------------------------------------------
#
#      testGraphics.pl
#      Fichier test du module Graphics
#
#      Authors: Jean-Luc Vinot <vinot@cena.fr>
#
# $Id: testGraphics.pl,v 1.13 2004/09/21 12:41:55 mertz Exp $
#-----------------------------------------------------------------------------------

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.13 $ =~ /(\d+)\.(\d+)/);

use Tk;
use Tk::Zinc;
use Tk::Zinc::Graphics;
use Math::Trig;
use Getopt::Long;
use strict 'vars';


my $currenttransfo;
my $previousangle = 0;
my $rotate_angle = .1;
my $zoomfactor = .1;
my $curview;
my ($dx, $dy);

my $tabanchor = 'n';
my $tabalign = 'left';

my $font_9b = '7x13bold';
# the original font is not standard, even if it is fully free:
# my $font_9b = '-cenapii-bleriot mini-bold-r-normal--9-90-75-75-p-75-iso8859-15';

my %gradset = (# gradients zinc
	       'boitonglet' => '=axial 0|#ff7777|#ffff99',
	       'roundrect1' => '=axial 270|#a7ffa7;70 0|#ffffff;90 5|#00bd00;80 8|#b7ffb7;50 80|#ffffff;70 91|#00ac00;70 95|#006700;60 100',
	       'roundrect2' => '=axial 270|#00bd00;80 |#d7ffd7;60',
	       'roundrect3' => '=axial 270|#00bd00;100 0|#ffffff;100 14|#ffffff;100 16|#00bd00;90 25|#b7ffb7;60 100',
	       'roundrect4' => '=axial 0|#00bd00;100 0|#ffffff;100 20|#00bd00;50 30|#00bd00;90 80|#b7ffb7;60 100',
	       'roundrect4ed' => '=path 48 48|#e7ffe7;20 0 70|#007900;20',
	       'roundcurve2' => '=axial 270|#d7ffd7;60|#7777ff;80',
	       'roundcurve1' => '=axial 270|#2222ff;80 |#d7ffd7;60',
	       'roundcurve' => '=axial 270|#7777ff;80 |#d7ffd7;60',
	       'roundpolyg' => '=radial -15 -20|#ffb7b7;50|#bd6622;90',
	       'rpolyline' => '=axial 90|#ffff77;80 |#ff7700;60',
	       'pushbtn1' => '=axial 0|#cccccc;100 0|#ffffff;100 10|#5a5a6a;100 80|#aaaadd;100 100',
	       'pushbtn2' => '=axial 270|#ccccff;100 0|#ffffff;100 10|#5a5a7a;100 80|#bbbbee;100 100',
	       'pushbtn3' => '=radial -15 -15|#ffffff;100 0|#333344;100 100',
	       'pushbtn4' => '=axial 270|#ccccff;100 0|#ffffff;100 10|#7a7a9a;100 80|#bbbbee;100 100',
	       'conical_edge' => '=conical 0 0 -45|#ffffff;100 0|#888899;100 30|#555566;100 50|#888899;100 70|#ffffff;100 100',
	       'conical_ext' => '=conical 0 0 135|#ffffff;100 0|#777788;100 30|#444455;100 50|#777788;100 70|#ffffff;100 100',
	       'pushbtn_edge' => '=axial 140|#ffffff;100 0|#555566;100 100',
	       'pushbtn_edge2' => '=axial 92|#ffffff;100 0|#555566;100 100',
	       'logoshape2' => '=axial 270|#ffffff|#7192aa',
	       'logopoint2' => '=radial -20 -20|#ffffff 0|#f70000 48|#900000 80|#ab0000 100',
	       'logoptshad2' => '=path 0 0|#770000;64 0|#770000;70 78|#770000;0 100',
	      );


# contenu des pages exemples
my %pagesconf = ('Rectangle' => {'consigne' => {-itemtype => 'text',
						 -coords => [-285, 155],
						 -params => {-font => $font_9b,
							     -text => "Mouse button 1 drag objects,\nEscape key reset transfos.",
							     -color => '#2222cc',
							    },
					      },
				  # roudedrectangle simple + radius 20
				  'rr1' => {-itemtype => 'roundedrectangle',
					    -coords => [[-200, 30], [50, 130]],
					    -radius => 20,
					    -params => {-closed => 1,
							-filled => 1,
							-fillcolor => 'roundrect2',
							-linewidth => 2,
							-linecolor => '#000000',
							-priority => 20,
							-tags => ['move'],
						       },
					   },

				  # roudedrectangle 'carré' (radius automatique)
				  'rr2' => {-itemtype => 'roundedrectangle',
					    -coords => [[-250, -100], [-90, 60]],
					    -params => {-closed => 1,
							-filled => 1,
							-fillcolor => 'roundrect1',
							-linewidth => 3,
							-linecolor => '#000000',
							-priority => 30,
							-tags => ['move'],
						       },
					   },
				  # cas particulier -> hippodrome (radius = h/2)
				  'rr3' => {-itemtype => 'roundedrectangle',
						  -coords => [[-30, 80], [130, 160]],
						  -radius => 40,
						  -params => {-closed => 1,
							      -filled => 1,
							      -fillcolor => 'roundrect3',
							      -linewidth => 4,
							      -linecolor => '#000000',
							      -priority => 30,
							      -tags => ['move'],
							     },
					   },

				  # utilisation de l'option -corners (pétales de fleur)
				  'rr4a' => {-itemtype => 'roundedrectangle',
					     -coords => [[-30, -60], [110, 10]],
					     -radius => 40,
					     -params => {-closed => 1,
							 -filled => 1,
							 -fillcolor => 'roundrect3',
							 -linewidth => 3,
							 -linecolor => '#000000',
							 -priority => 30,
							 -tags => ['move'],
							},
					     -corners => [1, 0, 1, 0],
					    },
				  'rr4b' => {-itemtype => 'roundedrectangle',
					     -coords => [[118, -68], [220, -132]],
					     -radius => 40,
					     -params => {-closed => 1,
							 -filled => 1,
							 -fillcolor => 'roundrect3',
							 -linewidth => 3,
							 -linecolor => '#000000',
							 -priority => 30,
							 -tags => ['move'],
							},
					     -corners => [1, 0, 1, 0],
					    },
				  'rr4c' => {-itemtype => 'roundedrectangle',
					     -coords => [[118, -60], [190, 30]],
					     -radius => 40,
					     -params => {-closed => 1,
							 -filled => 1,
							 -fillcolor => 'roundrect3',
							 -linewidth => 3,
							 -linecolor => '#000000',
							 -priority => 30,
							 -tags => ['move'],
							},
					     -corners => [0, 1, 0, 1],
					    },
				  'rr4d' => {-itemtype => 'roundedrectangle',
					     -coords => [[40, -152], [110, -68]],
					     -radius => 40,
					     -params => {-closed => 1,
							 -filled => 1,
							 -fillcolor => 'roundrect3',
							 -linewidth => 3,
							 -linecolor => '#000000',
							 -priority => 30,
							 -tags => ['move'],
							},
					     -corners => [0, 1, 0, 1],
					    },

				  # groupe de 2 boutons avec bordure externe
				  'gr8' => {-itemtype => 'group',
					    -coords => [0, 0],
					    -params => {-priority => 10,
							-tags => ['move'],
							-atomic => 1,
						       },
					    -items => {'edge' => {-itemtype => 'roundedrectangle',
								  -coords => [[174, -36],[266, 146]],
								  -radius => 26,
								  -params => {-closed => 1,
									      -filled => 1,
									      -fillcolor => 'roundrect4ed',
									      -linewidth => 1,
									      -linecolor => '#ffffff',
									      -priority => 20,
									     },
								 },
						       'top' => {-itemtype => 'roundedrectangle',
								    -coords => [[180, -30], [260, 53]],
								    -parentgroup => 'gr8',
								    -radius => 20,
								    -params => {-closed => 1,
										-filled => 1,
										-fillcolor => 'roundrect4',
										-linewidth => 2.5,
										-linecolor => '#000000',
										-priority => 30,
									       },
								    -corners => [1, 0, 0, 1],
								   },
						       'topico' => {-itemtype => 'curve',
								    -parentgroup => 'gr8',
								    -coords => [[220, -10],[200, 30],[240, 30]],
								    -params => {-closed => 1,
										-filled => 1,
										-fillcolor => '#ffff00;80',
										-linewidth => 1,
										-linecolor => '#007900;80',
										-priority => 50,
									       },
								   },
						       'bottom' => {-itemtype => 'roundedrectangle',
								    -parentgroup => 'gr8',
								    -coords => [[180, 57], [260, 140]],
								    -radius => 20,
								    -params => {-closed => 1,
										-filled => 1,
										-fillcolor => 'roundrect4',
										-linewidth => 2.5,
										-linecolor => '#000000',
										-priority => 30,
									       },
								    -corners => [0, 1, 1, 0],
								   },
						       'bottomico' => {-itemtype => 'curve',
								       -parentgroup => 'gr8',
								       -coords => [[220, 120],[240, 80],[200, 80]],
								       -params => {-closed => 1,
										   -filled => 1,
										   -fillcolor => '#ffff00;80',
										   -linewidth => 1,
										   -linecolor => '#007900;80',
										   -priority => 50,
										  },
								      },
						      },
					   },
				 },
		 'Hippodrome' => {'consigne' => {-itemtype => 'text',
						 -coords => [-285, 165],
						 -params => {-font => $font_9b,
							     -text => "Click hippo Buttons with mouse button 1.\n",
							     -color => '#2222cc',
							    },
						},
				  'hp1' => {-itemtype => 'group',
					    -coords => [-163, -40],
					    -params => {-priority => 40,
						       },
					    -items => {'edge' => {-itemtype => 'hippodrome',
								  -coords => [[-46, -86], [46, 86]],
								  -params => {-closed => 1,
									      -filled => 1,
									      -fillcolor => 'pushbtn_edge',
									      -linewidth => 1,
									      -linecolor => '#ffffff',
									      -priority => 10,
									     },
								 },
						       'form' => {-itemtype => 'hippodrome',
								  -coords => [[-40, -80], [40, 80]],
								  -params => {-closed => 1,
									      -filled => 1,
									      -fillcolor => 'pushbtn1',
									      -linewidth => 3,
									      -linecolor => '#000000',
									      -priority => 20,
									      -tags => ['b1','pushbtn'],
									     },
								 },
						       },
					   },

				   'hp2' => {-itemtype => 'group',
					     -coords => [-40, -40],
					     -params => {-priority => 40,
							},
					    -items => {'edge' => {-itemtype => 'hippodrome',
								  -coords => [[-46, -86], [46, 86]],
								  -params => {-closed => 1,
									      -filled => 1,
									      -fillcolor => 'pushbtn_edge',
									      -linewidth => 1,
									      -linecolor => '#ffffff',
									      -priority => 10,
									     },
								 },
						       'formT' => {-itemtype => 'hippodrome',
								   -coords => [[-40, -80], [40, -28]],
								   -params => {-closed => 1,
									       -filled => 1,
									       -fillcolor => 'pushbtn1',
									       -linewidth => 3,
									       -linecolor => '#000000',
									       -priority => 20,
									       -tags => ['b2t','pushbtn'],
									      },
								   -orientation => 'vertical',
								   -trunc => 'bottom',
								  },
						       'formC' => {-itemtype => 'hippodrome',
								   -coords => [[-40, -26.5], [40, 26.5]],
								   -params => {-closed => 1,
									       -filled => 1,
									       -fillcolor => 'pushbtn1',
									       -linewidth => 3,
									       -linecolor => '#000000',
									       -priority => 20,
									       -tags => ['b2c','pushbtn'],
									      },
								   -trunc => 'both',
								  },
						       'formB' => {-itemtype => 'hippodrome',
								   -coords => [[-40, 28], [40, 80]],
								   -params => {-closed => 1,
									       -filled => 1,
									       -fillcolor => 'pushbtn1',
									       -linewidth => 3,
									       -linecolor => '#000000',
									       -priority => 20,
									       -tags => ['b2b','pushbtn'],
									      },
								   -orientation => 'vertical',
								   -trunc => 'top',
								  },
						      },
					     },
				   'hp3edge' => {-itemtype => 'hippodrome',
						 -coords => [[-204, 96], [204, 144]],
						 -params => {-closed => 1,
							     -filled => 1,
							     -fillcolor => 'pushbtn_edge2',
							     -linewidth => 1,
							     -linecolor => '#ffffff',
							     -priority => 10,
							    },
						},
				  'hp3g' => {-itemtype => 'group',
					     -coords => [-160, 120],
					     -params => {-priority => 40,
							},
					    -items => {'form' => {-itemtype => 'hippodrome',
								  -coords => [[-40, -20], [40, 20]],
								  -params => {-closed => 1,
									      -filled => 1,
									      -fillcolor => 'pushbtn2',
									      -linewidth => 2,
									      -linecolor => '#000000',
									      -priority => 20,
									      -tags => ['b3g','pushbtn'],
									     },
								  -trunc => 'right',
								 },
						       'ico' => {-itemtype => 'curve',
								 -coords => [[-20, 0],[-4, 8],[-4, -8]],
								 -params => {-closed => 1,
									     -filled => 1,
									     -fillcolor => '#000000',
									     -linewidth => 1,
									     -linecolor => '#aaaaaa',
									     -relief => 'raised',
									     -priority => 30,
									     -tags => ['b3g','pushbtn','ico'],
									    },
								 -contours =>  [['add',-1,[[0, 0],[16, 8],[16, -8]]]],
								},
						      },
					     },
				  'hp3c1' => {-itemtype => 'group',
					      -coords => [-80, 120],
					      -params => {-priority => 40,
							 },
					    -items => {'form' => {-itemtype => 'hippodrome',
								  -coords => [[-38, -20], [39, 20]],
								  -params => {-closed => 1,
									      -filled => 1,
									      -fillcolor => 'pushbtn2',
									      -linewidth => 2,
									      -linecolor => '#000000',
									      -priority => 20,
									      -tags => ['b3c1','pushbtn'],
									     },
								  -trunc => 'both',
								 },
						       'ico' => {-itemtype => 'curve',
								 -coords => [[-8, 0],[8, 8],[8, -8]],
								 -params => {-closed => 1,
									     -filled => 1,
									     -fillcolor => '#000000',
									     -linewidth => 1,
									     -linecolor => '#aaaaaa',
									     -priority => 30,
									     -relief => 'raised',
									     -tags => ['b3c1','pushbtn','ico'],
									    },
								},
						       },
					      },
				  'hp3c2' => {-itemtype => 'group',
					      -coords => [0, 120],
					      -params => {-priority => 40,
							 },
					      -items => {'form' => {-itemtype => 'hippodrome',
								  -coords => [[-39, -20], [39, 20]],
								  -params => {-closed => 1,
									      -filled => 1,
									      -fillcolor => 'pushbtn2',
									      -linewidth => 2,
									      -linecolor => '#000000',
									      -priority => 20,
									      -tags => ['b3c2','pushbtn'],
									     },
								  -trunc => 'both',
								 },
						       'ico' => {-itemtype => 'rectangle',
								 -coords => [[-6, -6],[6, 6]],
								 -params => {-filled => 1,
									     -fillcolor => '#000000',
									     -linewidth => 1,
									     -linecolor => '#aaaaaa',
									     -priority => 30,
									     -tags => ['b3c2','pushbtn','ico'],
									    },
								},
						       },
					      },
				  'hp3C3' => {-itemtype => 'group',
					      -coords => [80, 120],
					      -params => {-priority => 40,
							 },
					      -items => {'form' => {-itemtype => 'hippodrome',
								    -coords => [[-39, -20], [39, 20]],
								    -params => {-closed => 1,
										-filled => 1,
										-fillcolor => 'pushbtn2',
										-linewidth => 2,
										-linecolor => '#000000',
										-priority => 20,
										-tags => ['b3c3','pushbtn'],
									       },
								    -trunc => 'both',
								   },
							 'ico' => {-itemtype => 'curve',
								   -coords => [[8, 0],[-8, -8],[-8, 8]],
								   -params => {-closed => 1,
									       -filled => 1,
									       -fillcolor => '#000000',
									       -linewidth => 1,
									       -linecolor => '#aaaaaa',
									       -priority => 30,
									       -relief => 'raised',
									       -tags => ['b3c3','pushbtn','ico'],
									      },
								  },
							},
					     },

				  'hp3D' => {-itemtype => 'group',
					     -coords => [160, 120],
					     -params => {-priority => 40,
							 },
					     -items => {'form' => {-itemtype => 'hippodrome',
								   -coords => [[-40, -20], [40, 20]],
								   -params => {-closed => 1,
									       -filled => 1,
									       -fillcolor => 'pushbtn2',
									       -linewidth => 2,
									       -linecolor => '#000000',
									       -priority => 20,
									       -tags => ['b3d','pushbtn'],
									      },
								   -trunc => 'left',
								  },
							'ico' => {-itemtype => 'curve',
								  -coords => [[20, 0],[4, -8],[4, 8]],
								  -params => {-closed => 1,
									      -filled => 1,
									      -fillcolor => '#000000',
									      -linewidth => 1,
									      -linecolor => '#aaaaaa',
									      -priority => 30,
									      -relief => 'raised',
									      -tags => ['b3d','pushbtn','ico'],
									     },
								  -contours =>  [['add',-1,[[0,0],[-16, -8],[-16, 8]]]],
								 },
						       },
					    },

				  'hp4a' => {-itemtype => 'group',
					     -coords => [48, -97],
					     -params => {-priority => 40,
							},
					     -repeat => {-num => 2,
							 -dxy => [0, 64],
							},
					    -items => {'edge' => {-itemtype => 'hippodrome',
								  -coords => [[-29, -29], [29, 29]],
								  -params => {-closed => 1,
									      -filled => 1,
									      -fillcolor => 'pushbtn_edge',
									      -linewidth => 1,
									      -linecolor => '#ffffff',
									      -priority => 0,
									     },
								 },
						       'form' => {-itemtype => 'hippodrome',
								  -coords => [[-24, -24], [24, 24]],
								  -params => {-closed => 1,
									      -filled => 1,
									      -fillcolor => 'pushbtn3',
									      -linewidth => 3,
									      -linecolor => '#000000',
									      -priority => 30,
									      -tags => ['b4a','pushbtn'],
									     },
								 },
						      },
					    },

				  'hp4b' => {-itemtype => 'group',
					     -coords => [145, -65],
					     -params => {-priority => 40,
							},
					    -items => {'edge' => {-itemtype => 'hippodrome',
								  -coords => [[-60, -60], [60, 60]],
								  -params => {-closed => 1,
									      -filled => 1,
									      -fillcolor => 'conical_edge',
									      -linewidth => 1,
									      -linecolor => '#ffffff',
									      -priority => 0,
									     },
								 },
						       'ext' => {-itemtype => 'hippodrome',
								 -coords => [[-53, -53], [53, 53]],
								 -params => {-closed => 1,
									     -filled => 1,
									     -fillcolor => 'conical_ext',
									     -linewidth => 3,
									     -linecolor => '#000000',
									     -priority => 10,
									     -tags => ['b4b','pushbtn'],
									    },
								},
						       'int' => {-itemtype => 'hippodrome',
								 -coords => [[-41, -41], [40, 40]],
								 -params => {-closed => 1,
									     -filled => 1,
									     -fillcolor => '=path 10 10|#ffffff 0|#ccccd0 50|#99999f 80|#99999f;0 100',
									     -linewidth => 0,
									     -linecolor => '#cccccc;80',
									     -priority => 30,
									     -tags => ['b4b','pushbtn'],
									    },
								},
						      },
					    },

				  'hp5' => {-itemtype => 'group',
					    -coords => [60, 25],
					    -params => {-priority => 40,
						       },
					    -rotate => 30,
					    -repeat => {-num => 4,
							-dxy => [45, 0],
						       },
					    -items => {'edge' => {-itemtype => 'hippodrome',
								  -coords => [[-19, -34], [19, 34]],
								  -params => {-closed => 1,
									      -filled => 1,
									      -fillcolor => 'pushbtn_edge',
									      -linewidth => 1,
									      -linecolor => '#ffffff',
									      -priority => 10,
									     },
								 },
						       'form' => {-itemtype => 'hippodrome',
								  -coords => [[-15, -30], [15, 30]],
								  -params => {-closed => 1,
									      -filled => 1,
									      -fillcolor => 'pushbtn1',
									      -linewidth => 2,
									      -linecolor => '#000000',
									      -priority => 20,
									      -tags => ['b5','pushbtn'],
									     },
								 },
						       },
					   },
				 },

		 'Polygone' => {'consigne' => {-itemtype => 'text',
						 -coords => [-285, 160],
						 -params => {-font => $font_9b,
							     -text => "Click and Drag inside Polygons for rotate them\nEscape key reset transfos.",
							     -color => '#2222cc',
							    },
					      },
				'triangle' => {-itemtype => 'group',
					       -coords => [-215, -95],
					       -items => {'form' => {-itemtype => 'polygone',
								     -coords => [0, 0],
								     -numsides => 3,
								     -radius => 78,
								     -corner_radius => 10,
								     -startangle => 90,
								     -params => {-closed => 1,
										 -filled => 1,
										 -fillcolor => 'roundpolyg',
										 -linewidth => 2,
										 -linecolor => '#330000',
										 -priority => 20,
										 -tags => ['p1', 'poly'],
										},
								    },
							  'text' => {-itemtype => 'text',
								     -coords => [0, -6],
								     -params => {-font => $font_9b,
										 -text => "Triangle",
										 -anchor => 'n',
										 -alignment => 'center',
										 -color => '#660000',
										 -priority => 50,
										},
								    },
							 },
					      },

				 'carre' => {-itemtype => 'group',
					     -coords => [-80, -75],
					     -items => {'form' => {-itemtype => 'polygone',
								   -coords => [0, 0],
								   -numsides => 4,
								   -radius => 70,
								   -corner_radius => 10,
								   -startangle => 90,
								   -params => {-closed => 1,
									       -filled => 1,
									       -fillcolor => 'roundpolyg',
									       -linewidth => 2,
									       -linecolor => '#330000',
									       -priority => 20,
									       -tags => ['p2', 'poly'],
									      },
								  },
							'text' => {-itemtype => 'text',
								   -coords => [0, -6],
								   -params => {-font => $font_9b,
									       -text => "Carré",
									       -anchor => 'n',
									       -alignment => 'center',
									       -color => '#660000',
									       -priority => 50,
									      },
								  },
						       },
					    },

				'pentagone' => {-itemtype => 'group',
						-coords => [65, -75],
						-items => {'form' => {-itemtype => 'polygone',
								      -coords => [0, 0],
								      -numsides => 5,
								      -radius => 70,
								      -corner_radius => 10,
								      -startangle => 270,
								      -params => {-closed => 1,
										  -filled => 1,
										  -fillcolor => 'roundpolyg',
										  -linewidth => 2,
										  -linecolor => '#330000',
										  -priority => 20,
										  -tags => ['p3', 'poly'],
										 },
								     },
							   'text' => {-itemtype => 'text',
								      -coords => [0, -6],
								      -params => {-font => $font_9b,
										  -text => "Pentagone",
										  -anchor => 'n',
										  -alignment => 'center',
										  -color => '#660000',
										  -priority => 50,
										 },
								     },
							  },
					       },

				'hexagone' => {-itemtype => 'group',
					       -coords => [210, -75],
					       -items => {'form' => {-itemtype => 'polygone',
								     -coords => [0, 0],
								     -numsides => 6,
								     -radius => 68,
								     -corner_radius => 10,
								     -params => {-closed => 1,
										 -filled => 1,
										 -fillcolor => 'roundpolyg',
										 -linewidth => 2,
										 -linecolor => '#330000',
										 -priority => 20,
										 -tags => ['p4', 'poly'],
										},
								    },
							  'text' => {-itemtype => 'text',
								     -coords => [0, -6],
								     -params => {-font => $font_9b,
										 -text => "Hexagone",
										 -anchor => 'n',
										 -alignment => 'center',
										 -color => '#660000',
										 -priority => 50,
										},
								    },
							 },
					      },

				'heptagone' => {-itemtype => 'group',
						-coords => [-215, 85],
						-items => {'form' => {-itemtype => 'polygone',
								      -coords => [0, 0],
								      -numsides => 7,
								      -radius => 64,
								      -corner_radius => 10,
								      -params => {-closed => 1,
										  -filled => 1,
										  -fillcolor => 'roundpolyg',
										  -linewidth => 2,
										  -linecolor => '#330000',
										  -priority => 20,
										  -tags => ['p5', 'poly'],
										 },
								     },
							   'text' => {-itemtype => 'text',
								      -coords => [0, -6],
								      -params => {-font => $font_9b,
										  -text => "Heptagone",
										  -anchor => 'n',
										  -alignment => 'center',
										  -color => '#660000',
										  -priority => 50,
										 },
								     },
							  },
					       },
				

				'octogone' => {-itemtype => 'group',
					       -coords => [-76, 85],
					       -items => {'form' => {-itemtype => 'polygone',
								     -coords => [0, 0],
								     -numsides => 8,
								     -radius => 64,
								     -corner_radius => 10,
								     -params => {-closed => 1,
										 -filled => 1,
										 -fillcolor => 'roundpolyg',
										 -linewidth => 2,
										 -linecolor => '#330000',
										 -priority => 20,
										 -tags => ['p6', 'poly'],
										},
								    },
							  'text' => {-itemtype => 'text',
								     -coords => [0, -6],
								     -params => {-font => $font_9b,
										 -text => "Octogone",
										 -anchor => 'n',
										 -alignment => 'center',
										 -color => '#660000',
										 -priority => 50,
										},
								    },
							 },
					      },

				'petagone' => {-itemtype => 'group',
					       -coords => [66, 85],
					       -items => {'form' => {-itemtype => 'polygone',
								     -coords => [0, 0],
								     -numsides => 32,
								     -radius => 64,
								     -corner_radius => 10,
								     -params => {-closed => 1,
										 -filled => 1,
										 -fillcolor => 'roundpolyg',
										 -linewidth => 2,
										 -linecolor => '#330000',
										 -priority => 20,
										 -tags => ['p7', 'poly'],
										},
								    },
							  'text' => {-itemtype => 'text',
								     -coords => [0, -6],
								     -params => {-font => $font_9b,
										 -text => "32 cotés...",
										 -anchor => 'n',
										 -alignment => 'center',
										 -color => '#660000',
										 -priority => 50,
										},
								    },
							 },
					      },

				'etoile' => {-itemtype => 'group',
					     -coords => [210, 85],
					     -items => {'form' => {-itemtype => 'polygone',
								   -coords => [0, 0],
								   -numsides => 5,
								   -radius => 92,
								   -inner_radius => 36,
								   -corner_radius => 10,
								   -startangle => 270,
								   -corners => [0,1,0,1,0,1,0,1,0,1],
								   -params => {-closed => 1,
									       -filled => 1,
									       -fillcolor => 'roundpolyg',
									       -linewidth => 2,
									       -linecolor => '#330000',
									       -priority => 20,
									       -tags => ['p8', 'poly'],
									      },
								  },
							'text' => {-itemtype => 'text',
								   -coords => [0, -6],
								   -params => {-font => $font_9b,
									       -text => "Etoile",
									       -anchor => 'n',
									       -alignment => 'center',
									       -color => '#660000',
									       -priority => 50,
									      },
								  },
						       },
					    },
			       },

		 'Polyline' => {'consigne' => {-itemtype => 'text',
						 -coords => [-285, 155],
						 -params => {-font => $font_9b,
							     -text => "Mouse button 1 drag objects,\nEscape key reset transfos.",
							     -color => '#2222cc',
							    },
					      },
				 'a' => {-itemtype => 'polyline',
					 -coords => [[-200, -115],[-200, -100],[-218, -115],[-280, -115],[-280, -16],
						     [-218, -16],[-200, -31],[-200, -17.5],[-150, -17.5],[-150,-115]],
					 -corners_radius => [0, 0, 42, 47, 47, 42, 0, 0, 0, 0, 0, 0],
					 -params => {-closed => 1,
						     -filled => 1,
						     -visible => 1,
						     -fillcolor => 'rpolyline',
						     -linewidth => 2,
						     -linecolor => '#000000',
						     -priority => 50,
						     -tags => ['move'],
						    },
					 -contours => [['add', -1, [[-230, -80],[-230, -50],[-200, -50],[-200, -80]],15]],
					 },
				 'b' => {-itemtype => 'polyline',
					 -coords => [[-138, -150],[-138, -17.5],[-88, -17.5],[-88, -31],[-70, -16],
						     [-8, -16],[-8, -115],[-70, -115],[-88, -100],[-88, -150]],
					 -corners_radius => [0, 0, 0, 0, 42, 47, 47, 42, 0, 0, 0, 0, 0, 0],
					 -params => {-closed => 1,
						     -filled => 1,
						     -visible => 1,
						     -fillcolor => 'rpolyline',
						     -linewidth => 2,
						     -linecolor => '#000000',
						     -priority => 50,
						     -tags => ['move'],
						    },
					 -contours => [['add', -1, [[-88, -80],[-88, -50],[-58, -50],[-58, -80]],15]],
					},
				 'c' => {-itemtype => 'polyline',
					 -coords => [[80, -76],[80, -110],[60, -115],[0, -115],[0, -16],
						     [60, -16],[80, -21],[80, -57],[50, -47],[50, -86]],
					 -corners_radius => [0, 0, 70, 47, 47, 70, 0, 0, 14, 14, 0, 0, 0,0 ],
					 -params => {-closed => 1,
						     -filled => 1,
						     -visible => 1,
						     -fillcolor => 'rpolyline',
						     -linewidth => 2,
						     -linecolor => '#000000',
						     -priority => 50,
						     -tags => ['move'],
						    },
					},
				 'spirale' => {-itemtype => 'polyline',
					      -coords => [[215, -144],[139, -144],[139, 0],[268, 0],[268, -116],
							   [162.5, -116],[162.5, -21],[248, -21],[248, -96],[183, -96],
							  [183, -40],[231,-40],[231, -80],[199, -80],[199, -55],[215, -55]],
					       -corners_radius => [0, 76, 68, 61, 55, 50, 45, 40, 35, 30, 26, 22, 18, 14, 11],
					       -params => {-closed => 1,
							   -filled => 1,
							   -visible => 1,
							   -fillcolor => 'rpolyline',
							   -linewidth => 2,
							   -linecolor => '#000000',
							   -priority => 50,
							   -tags => ['move'],
							  },
					      },
				 'logo' => {-itemtype => 'group',
					    -coords => [0, 0],
					    -params => {-priority => 30,
							-atomic => 1,
							-tags => ['move'],
							},
					    -items => {'tkzinc' => {-itemtype => 'polyline',
								    -coords => [[-150,10],[-44,10],[-44,68],[-28,51],[6,51],
										[-19,79],[3,109],[53,51],[5,51],[5,10],[140,10],
										[52,115],[96,115],[96,47],[196,47],[196,158],
										[155,158],[155,89],[139,89],[139,160],[101, 160],
										[101,132],[85,132],[85,160],[-42,160],[-2,115],
										[-30,115],[-46,91],[-46,115],[-76,115],[-76,51],
										[-98,51],[-98,115],[-130,115],[-130,51],[-150, 51]],
								    -corners_radius => [0,0,0,0,0,0,0,0,0,0,30,0,0,50,50,
											0,0,8,8,0,0,8,8,0,27],
								    -params => {-closed => 1,
										-filled => 1,
										-visible => 1,
										-fillcolor => 'logoshape2',
										-linewidth => 2.5,
										-linecolor => '#000000',
										-priority => 10,
										-fillrule => 'nonzero',
									       },

								    -contours => [['add', 1, [[245,88],[245,47],[190,47],[190,158],
											       [259,158],[259,117],[230,117],[230,88]],
										   5, undef, [0,0,55,55,0,0,15,15]]],
								   },
						       'shad' => {-itemtype => 'arc',
								   -coords => [[75, 91],[115,131]],
								   -params => {-priority => 20,
									       -filled => 1,
									       -linewidth => 0,
									       -fillcolor => 'logoptshad2',
									       -closed => 1,
									      },
								  },
						       'point' => {-itemtype => 'arc',
								   -coords => [[70, 86],[110,126]],
								   -params => {-priority => 50,
									       -filled => 1,
									       -linewidth => 1,
									       -linecolor => '#a10000',
									       -fillcolor => 'logopoint2',
									       -closed => 1,
									      },
								  },
						      },
					    },
				 },

		 'MultiContours' => {'consigne' => {-itemtype => 'text',
						 -coords => [-285, 155],
						 -params => {-font => $font_9b,
							     -text => "Mouse button 1 drag objects,\nEscape key reset transfos.",
							     -color => '#2222cc',
							    },
					      },
				     'mc1' => {-itemtype => 'roundedcurve',
					      -coords => [[-30, -170], [-130, 0],[70, 0]],
					      -radius => 14,
					      -params => {-closed => 1,
							  -filled => 1,
							  -fillcolor => 'roundcurve2',
							  -linewidth => 1,
							  -linecolor => '#000000',
							  -priority => 20,
							  -tags => ['move'],
							  -fillrule => 'odd',
							 },
					       -contours => [['add',1,[[-30,-138],[-100,-18],[40,-18]],8],
							     ['add',1,[[-30,-130],[ -92,-22],[32,-22]],5],
							     ['add',1,[[-30,-100],[ -68,-36],[8,-36]],5],
							     ['add',1,[[-30, -92],[ -60,-40],[0,-40]],3],],
					     },
				    'mc2' => {-itemtype => 'polyline',
					      -coords => [[-250,-80], [-240,-10],[-285,-10],[-285,80],
							  [-250, 80],[-250, 40],[-170, 40],[-170,80],
							  [-100,80],[-100,40],[-20,40],[-20,80],[30,80],
							  [-10, 0],[-74, -10],[-110, -80]],
					      -corners_radius => [24,4, 40, 20, 0, 40, 40, 0, 0, 40, 40, 0, 30, 75, 0, 104],
					      -params => {-closed => 1,
							  -filled => 1,
							  -fillcolor => 'roundcurve1',
							  -linewidth => 2,
							  -linecolor => '#000000',
							  -priority => 30,
							  -tags => ['move'],
							  },
					      -contours => [['add',-1,[[-240,-72],[-230,0],[-169,0],[-185, -72]],
							     0, undef, [16, 16, 0, 0]],
							    ['add', -1, [[-175,-72],[-159,0],[-78,0],[-116, -72]],
							     0, undef, [0, 0, 8, 88]],
							    ['add', 1, [[-245,45],[-245,115],[-175,115],[-175, 45]],
							     35],
							    ['add', -1, [[-225,65],[-225,95],[-195,95],[-195, 65]],
							     15],
							    ['add', 1, [[-95,45],[-95,115],[-25,115],[-25, 45]],
							     35],
							    ['add', -1, [[-75,65],[-75,95],[-45,95],[-45, 65]],
							     15],
							   ],
					     },
				    'mc3' => {-itemtype => 'roundedcurve',
					      -coords => [[-10, 170], [256, 170],[312, 60],[48, 60]],
					      -radius => 34,
					      -params => {-closed => 1,
							  -filled => 1,
							  -fillcolor => 'roundcurve2',
							  -linewidth => 2.5,
							  -linecolor => '#000000',
							  -priority => 40,
							  -tags => ['move'],
							 },
					      -contours => [['add', -1, [[58, 62],[12, 144],[60, 172],[104, 88]],27],
							    ['add', 1, [[48, 77],[48, 119],[90, 119],[90, 77]],21],
							    ['add', -1, [[244, 58],[198, 140],[246, 168],[290, 84]],27],
							    ['add', 1, [[213, 110],[213, 152],[255, 152],[255, 110]],21],
							    ['add', -1, [[150, 60],[150, 170],[160, 170],[160, 60]],0]],
					      },
				     'mc4' => {-itemtype => 'roundedcurve',
					      -coords => [[222, -150],[138, -150],[180, -50],[138, -150],
							  [80, -92],[180, -50],[80, -92],[80, -8],
							  [180, -50],[80, -8],[138, 50],[180, -50],
							  [138, 50],[222, 50],[179.8, -50],[222, 50],
							  [280, -8],[180, -50],[280, -8],[280, -92],
							  [180, -50],[280, -92],[222,-150],[180,-50]],
					      -radius => 28,
					      -params => {-closed => 1,
							  -filled => 1,
							  -fillcolor => 'roundcurve',
							  -linewidth => 2,
							  -linecolor => '#000000',
							  -priority => 30,
							  -tags => ['move'],
							 },
					      -contours => [['add', -1, [[160, -70],[160, -30],[200, -30],[200, -70]],20]],
					      },
				    },

		 'TabBox' => {'consigne' => {-itemtype => 'text',
					     -coords => [-285, 160],
					     -params => {-font => $font_9b,
							 -text => "Click on thumbnail to select page\nChange anchor or alignment tabs options with radio buttons.\n",
							 -color => '#2222cc',
							},
					    },

			      'exemple' => {-itemtype => 'text',
					    -coords => [-165, -105],
					    -params => {-font => $font_9b,
							-text => "",
							-alignment => 'left',
							-anchor => 'nw',
							-color => '#000000',
							-priority => 500,
							-width => 350,
							-tags => ['div2', 'fontname'],
						       },
					    },

			      'bo1' => {-itemtype => 'tabbox',
					-coords => [[-240, -160], [240, 100]],
					-radius => 8,
					-tabwidth => 72,
					-tabheight => 28,
					-numpages => 8,
					-anchor => 'n',
					-alignment => 'left',
					-overlap => 3,
					-params => {-closed => 1,
						    -priority => 100,
						    -filled => 1,
						    -fillcolor => '#ffffff',
						    -linewidth => 1.2,
						    -linecolor => '#000000',
						    -tags => ['div2', 'divider'],
						   },
					-tabtitles => {-text => ['A', 'B', 'C', 'D', 'E', 'F','G','H'],
						       -params => {-text => 'titre',
								   -color => '#2222cc',
								   -font => $font_9b,
								   -anchor => 'center',
								   -alignment => 'center',
								   -priority => 400,
								   -visible => 1,
								  },
						      },
				       },

			       'back' => {-itemtype => 'roundedrectangle',
					  -coords => [[-242, -162], [242, 102]],
					  -radius => 10,
					  -params => {-closed => 1,
						      -filled => 1,
						      -fillcolor => '#777777;80',
						      -linewidth => 1,
						      -linecolor => '#777777;80',
						     },
					 },

			       'anchor' => {-itemtype => 'text',
					    -coords => [-120, 115],
					    -params => {-text => 'tabs anchor',
							-color => '#2222cc',
							-font => $font_9b,
							-anchor => 'center',
							-alignment => 'center',
							-priority => 40,
						       },
					   },

			       'anchorN' => {-itemtype => 'hippodrome',
					     -coords => [[-210, 125], [-165, 151]],
					     -params => {-closed => 1,
							 -filled => 1,
							 -fillcolor => 'pushbtn4',
							 -linewidth => 1.5,
							 -linecolor => '#000000',
							 -priority => 20,
							 -tags => ['sel1','n','btn','selector'],
							},
					     -trunc => 'right',
					    },
			       'txtanN' => {-itemtype => 'text',
					    -coords => [-187, 138],
					    -params => {-text => 'N',
							-color => '#000000',
							-font => $font_9b,
							-anchor => 'center',
							-alignment => 'center',
							-priority => 40,
							-tags => ['sel1','n','btntext','selector'],
						       },
					   },

			       'anchorE' => {-itemtype => 'hippodrome',
					     -coords => [[-163, 125], [-120, 151]],
					     -params => {-closed => 1,
							 -filled => 1,
							 -fillcolor => 'pushbtn4',
							 -linewidth => 1.5,
							 -linecolor => '#000000',
							 -priority => 20,
							 -tags => ['sel1','e','btn','selector'],
							},
					     -trunc => 'both',
					    },
			       'txtanE' => {-itemtype => 'text',
					    -coords => [-141.5, 138],
					    -params => {-text => 'E',
							-color => '#000000',
							-font => $font_9b,
							-anchor => 'center',
							-alignment => 'center',
							-priority => 40,
							-tags => ['sel1','e','btntext','selector'],
						       },
					   },

			       'anchorS' => {-itemtype => 'hippodrome',
					     -coords => [[-118, 125], [-75, 151]],
					     -params => {-closed => 1,
							 -filled => 1,
							 -fillcolor => 'pushbtn4',
							 -linewidth => 1.5,
							 -linecolor => '#000000',
							 -priority => 20,
							 -tags => ['sel1','s','btn','selector'],
							},
					     -trunc => 'both',
					    },
			       'txtanS' => {-itemtype => 'text',
					    -coords => [-96.5, 138],
					    -params => {-text => 'S',
							-color => '#000000',
							-font => $font_9b,
							-anchor => 'center',
							-alignment => 'center',
							-priority => 40,
							-tags => ['sel1','s','btntext','selector'],
						       },
					   },
			       'anchorW' => {-itemtype => 'hippodrome',
					     -coords => [[-73, 125], [-28, 151]],
					     -params => {-closed => 1,
							 -filled => 1,
							 -fillcolor => 'pushbtn4',
							 -linewidth => 1.5,
							 -linecolor => '#000000',
							 -priority => 20,
							 -tags => ['sel1','w','btn','selector'],
							},
					     -trunc => 'left',
					    },
			       'txtanW' => {-itemtype => 'text',
					    -coords => [-52, 138],
					    -params => {-text => 'W',
							-color => '#000000',
							-font => $font_9b,
							-anchor => 'center',
							-alignment => 'center',
							-priority => 40,
							-tags => ['sel1','w','btntext','selector'],
						       },
					   },
			       'alignment' => {-itemtype => 'text',
					       -coords => [120, 115],
					       -params => {-text => 'tabs alignment',
							   -color => '#2222cc',
							   -font => $font_9b,
							   -anchor => 'center',
							   -alignment => 'center',
							   -priority => 40,
							  },
					      },
			       'alignG' => {-itemtype => 'hippodrome',
					    -coords => [[30, 125], [90, 151]],
					    -params => {-closed => 1,
							-filled => 1,
							-fillcolor => 'pushbtn4',
							-linewidth => 1.5,
							-linecolor => '#000000',
							-priority => 20,
							-tags => ['sel2','left','btn','selector'],
						       },
					    -trunc => 'right',
					   },
			       'txtalG' => {-itemtype => 'text',
					    -coords => [60, 138],
					    -params => {-text => 'left',
							-color => '#000000',
							-font => $font_9b,
							-anchor => 'center',
							-alignment => 'center',
							-priority => 40,
							-tags => ['sel2','left','btntext','selector'],
						       },
					   },
			       'alignC' => {-itemtype => 'hippodrome',
					    -coords => [[92, 125], [148, 151]],
					    -params => {-closed => 1,
							-filled => 1,
							-fillcolor => 'pushbtn4',
							-linewidth => 1.5,
							-linecolor => '#000000',
							-priority => 20,
							-tags => ['sel2','center','btn','selector'],
						       },
					    -trunc => 'both',
					   },
			       'txtalC' => {-itemtype => 'text',
					    -coords => [120, 138],
					    -params => {-text => 'center',
							-color => '#000000',
							-font => $font_9b,
							-anchor => 'center',
							-alignment => 'center',
							-priority => 40,
							-tags => ['sel2','center','btntext','selector'],
						       },
					   },
			       'alignD' => {-itemtype => 'hippodrome',
					    -coords => [[150, 125], [210, 151]],
					    -params => {-closed => 1,
							-filled => 1,
							-fillcolor => 'pushbtn4',
							-linewidth => 1.5,
							-linecolor => '#000000',
							-priority => 20,
							-tags => ['sel2','right','btn','selector'],
						       },
					    -trunc => 'left',
					   },
			       'txtalD' => {-itemtype => 'text',
					    -coords => [180, 138],
					    -params => {-text => 'right',
							-color => '#000000',
							-font => $font_9b,
							-anchor => 'center',
							-alignment => 'center',
							-priority => 40,
							-tags => ['sel2','right','btntext','selector'],
						       },
					   },
			      },

		 'PathLine' => {'consigne' => {-itemtype => 'text',
					       -coords => [-285, 155],
					       -params => {-font => $font_9b,
							   -text => "Mouse button 1 drag objects,\nEscape key reset transfos.",
							   -color => '#2222cc',
							  },
					      },
				'pl1' => {-itemtype => 'pathline',
					  -metacoords => {-type => 'polygone',
							  -coords => [0, 0],
							  -numsides => 12,
							  -radius => 200,
							  -inner_radius => 100,
							  -startangle => -8,
							 },
					  -linewidth => 20,
					  -closed => 1,
					  -graduate => {-type => 'linear',
							-colors => ['#ff0000', '#ff00ff', '#0000ff', '#00ffff',
								    '#00ff00', '#ffff00', '#ff0000'],
						       },
					  -params => {-priority => 100,
						      -tags => ['move'],
						     },
					 },

				'pl2' => {-itemtype => 'group',
					  -coords => [0, 0],
					  -params => {-priority => 200,
						      -atomic => 1,
						      -tags => ['move'],
						     },
					  -items => {'in' => {-itemtype => 'pathline',
							      -coords => [[30, -60],[-30, -60],[-30, -30],
									  [-60, -30],[-60, 30],[-30, 30],
									  [-30, 60],[30, 60],[30, 30],
									  [60, 30],[60, -30],[30, -30]],
							      -linewidth => 16,
							      -closed => 1,
							      -shifting => 'left',
							      -graduate => {-type => 'transversal',
									    -colors => ['#00aa77;100', '#00aa77;0'],
									   },
							      -params => {-priority => 10,
									  },
							     },

						     'out' => {-itemtype => 'pathline',
							       -coords => [[30, -60],[-30, -60],[-30, -30],
									   [-60, -30],[-60, 30],[-30, 30],
									   [-30, 60],[30, 60],[30, 30],
									   [60, 30],[60, -30],[30, -30]],
							       -linewidth => 10,
							       -closed => 1,
							       -shifting => 'in',
							       -graduate => {-type => 'transversal',
									     -colors => ['#00aa77;100', '#00aa77;0'],
									    },
							       -params => {-priority => 10,
									   },
							      },
						    },
					 },

				'pl3' => {-itemtype => 'group',
					  -coords => [0, 0],
					  -params => {-priority => 100,
						      -atomic => 1,
						      -tags => ['move'],
						     },
					  -items => {'back' => {-itemtype => 'arc',
								-coords => [[-150, -150],[150,150]],
								-params => {-priority => 10,
									    -closed => 1,
									    -filled => 1,
									    -fillcolor => '=radial 15 15|#ffffff;40|#aaaaff;10',
									    -linewidth => 0,
									    },
							       },
						     'light' => {-itemtype => 'pathline',
								 -metacoords => {-type => 'polygone',
										 -coords => [0, 0],
										 -numsides => 30,
										 -radius => 150,
										 -startangle => 240,
										},
								 -linewidth => 20,
								 -shifting => 'in',
								 -closed => 1,
								 -graduate => {-type => 'double',
									       -colors => [['#ffffff;0', '#222299;0', '#ffffff;0'],
											   ['#ffffff;100', '#222299;70', '#ffffff;100']],
									      },
								 -params => {-priority => 50,
									    },
								},
						     'bord' => {-itemtype => 'arc',
								-coords => [[-150, -150],[150,150]],
								-params => {-priority => 100,
									    -closed => 1,
									    -filled => 0,
									    -linewidth => 2,
									    -linecolor => '#000033;80'
									    },
							       },

						    },
					 },
			       },

		);

my %tabtable = ('n' => {-numpages => 8,
			-titles => ['A','B','C','D','E','F','G','H'],
			-names => ['ATOMIC GROUP :','BIND COMMAND :','CURVE ITEMS :','DISPLAY LIST :',
				   'EVENTS SENSITIVITY :','FIT COMMAND :','GROUP ITEMS','HASTAG COMMAND'],
			-texts => ["It may seem at first that there is a contradiction in this title, but there is not. [...] So groups have a feature, the atomic  attribute, that is used to seal a group so that events cannot propagate past it downward. If an item part of an atomic group is under the pointer, TkZinc will try to trigger bindings associated with the atomic group not with the item under the pointer. This improves greatly the metaphor of an indivisible item.",
				   "This widget command is similar to the Tk bind command except that it operates on TkZinc items instead of widgets. Another difference with the bind command is that only mouse and keyboard related events can be specified (such as Enter, Leave, ButtonPress, ButtonRelease, Motion, KeyPress, KeyRelease). The bind manual page is the most accurate place to look for a definition of sequence and command and for a general understanding of how the binding mecanism works.",
				   "Items of type curve display pathes of line segments and/or cubic bezier connected by their end points. A cubic Bezier is defined by four points. The first and last ones are the extremities of the cubic Bezier. The second and the third ones are control point (i.e. they must have a third ``coordinate'' with the value 'c'). If both control points are identical, one may be omitted. As a consequence, it is an error to have more than two succcessive control points or to start or finish a curve with a control point.",
				   "The items are arranged in a display list for each group. The display list imposes a total ordering among its items. The group display lists are connected in a tree identical to the group tree and form a hierarchical display list. The items are drawn by traversing the display list from the least visible item to the most visible one.The search to find the item that should receive an event is done in the opposite direction. In this way, items are drawn according to their relative stacking order and events are dispatched to the top-most item at a given location.",
				   "An item will catch an event if all the following conditions are satisfied: * the item -sensitive must be set to true (this is the default). * the item must be under the pointer location. * the item must be on top of the display list (at the pointer location). Beware that an other item with its -visible set to false DOES catch event before any underneath items. * the item must not be clipped (at the pointer location) * the item must not belong to an atomic group, since an atomic group catchs the event instead of the item.",
				   "This command fits a sequence of Bezier segments on the curve described by the vertices in coordList and returns a list of lists describing the points and control points for the generated segments. All the points on the fitted segments will be within error  distance from the given curve. coordList should be either a flat list of an even number of coordinates in x, y order or a list of lists of point coordinates X, Y. The returned list can be directly used to create or change a curve item contour.",
				   "Groups are very powerful items. They have no graphics of their own but are used to bundle items together so that they can be manipulated easily as a whole. Groups can modify in several way how items are displayed and how they react to events. They have many uses in TkZinc. The main usages are to bundle items, to interpose a new coordinate system in a hierarchy of items, to compose some specific attributes, to apply a clipping to their children items, to manage display",
				   "This command returns a boolean telling if the item specified by tagOrId has the specified tag. If more than one item is named by tagOrId, then the topmost in display list order is used to return the result. If no items are named by tagOrId, an error is raised.",
				  ],
		       },
		'e' => {-numpages => 5,
			-titles => ['I','J','K','L','M'],
			-names => ['ITEM IDS','JOINSTYLE ATTRIBUTE','K :','LOWER COMMAND','MAP ITEM :'],
			-texts => ["Each item is associated with a unique numerical id which is returned by the add  or clone  commands. All commands on items accept those ids as (often first) parameter in order to uniquely identify on which item they should operate. When an id has been allocated to an item, it is never collected even after the item has been destroyed, in a TkZinc session two items cannot have the same id. This property can be quite useful when used in conjonction with tags, which are described below.",
				   "Specifies the form of the joint between the curve segments. This attribute is only applicable if the curve outline relief is flat. The default value is round.",
				   "No TkZinc KeyWord with K initial letter...",
				   "Reorder all the items given by tagOrId so that they will be under the item given by belowThis. If tagOrId name more than one item, their relative order will be preserved. If tagOrId doesn't name an item, an error is raised. If  belowThis name more than one item, the bottom most them is used. If belowThis  doesn't name an item, an error is raised. If belowThis is omitted the items are put at the bottom most position of their respective groups.",
				   "Map items are typically used for displaying maps on a radar display view. Maps are not be sensitive to mouse or keyboard events, but have been designed to efficiently display large set of points, segments, arcs, and simple texts. A map item is associated to a mapinfo. This mapinfo entity can be either initialized with the videomap  command or more generally created and edited with a set of commands described in the The mapinfo related commands  section.",
				  ],
		       },
		's' => {-numpages => 8,
			-titles => ['N','O','P','Q','R','S','T','U'],
			-names => ['NUMPARTS COMMAND :','OVERLAP MANAGER :','PICKAPERTURE WIDGET OPTION :','Q :',
				   'RENDER WIDGET OPTION :','SMOOTH COMMAND','TAGS :', 'UNDERLINED ATTRIBUTE :'],
			-texts => ["This command tells how many fieldId are available for event bindings or for field configuration commands in the item specified by tagOrId. If more than one item is named by tagOrId, the topmost in display list order is used to return the result. If no items are named by tagOrId, an error is raised. This command returns always 0 for items which do not support fields. The command hasfields  may be used to decide whether an item has fields.",
				   "his option accepts an item id. It specifies if the label overlapping avoidance algorithm should be allowed to do its work on the track labels and which group should be considered to look for tracks. The default is to enable the avoidance algorithm in the root group (id 1). To disable the algorithm this option should be set to 0.",
				   "Specifies the size of an area around the pointer that is used to tell if the pointer is inside an item. This is useful to lessen the precision required when picking graphical elements. This value must be a positive integer. It defaults to 1.",
				   "No TkZinc KeyWord with Q initial letter...",
				   "Specifies whether to use or not the openGL rendering. When True, requires the GLX extension to the X server. Must be defined at widget creation time. This option is readonly and can be used to ask if the widget is drawing with the GLX extension or in plain X (to adapt the application code for example). The default value is false.",
				   "This command computes a sequence of Bezier segments that will smooth the polygon described by the vertices in coordList and returns a list of lists describing thr points and control points for the generated segments. coordList should be either a flat list of an even number of coordinates in x, y order, or a list of lists of point coordinates X, Y. The returned list can be used to create or change the contour of a curve item.",
				   "Apart from an id, an item can be associated with as many symbolic names as it may be needed by an application. Those names are called tags and can be any string which does not form a valid id (an integer). However the following characters may not be used to form a tag: . * ! ( ) & | :. Tags exists, and may be used in commands, even if no item are associated with them. In contrast an item id doesn't exist if its item is no longer around and thus it is illegal to use it.",
				   "Item Text attribute. If true, a thin line will be drawn under the text characters. The default value is false.",
				  ],
		       },
		'w' => {-numpages => 5,
			-titles => ['V','W','X','Y','Z'],
			-names => ['VERTEXAT COMMAND :','WAYPOINT ITEM :','X11, OpenGL and Windows :','Y...','ZINC an advanced scriptable Canvas :'],
			-texts => ["Return a list of values describing the vertex and edge closest to the window coordinates x and y in the item described by tagOrId. If  tagOrId describes more than one item, the first item in display list order that supports vertex picking is used. The list consists of the index of the contour containing the returned vertices, the index of the closest vertex and the index of a vertex next to the closest vertex that identify the closest edge (located between the two returned vertices).",
				   "Waypoints items have been initially designed for figuring out typical fixed position objects (i.e. beacons or fixes in the ATC vocabulary) with associated block of texts on a radar display for Air Traffic Control. They supports mouse event handling and interactions. However they may certainly be used by other kinds of radar view or even by other kind of plan view with many geographical objects and associated textual information.",
				   "TkZinc was firstly designed for X11 server. Since the 3.2.2 version, TkZinc also offers as a runtime option, the support for openGL rendering, giving access to features such as antialiasing, transparency, color gradients and even a new, openGL oriented, item type : triangles  . In order to use the openGL features, you need the support of the GLX extension on your X11 server. We also succeeded in using TkZinc with openGL on the Exceed X11 server (running on windows and developped by Hummingbird) with the 3D extension. ",
				   "No TkZinc KeyWord with Y initial letter...",
				   "TkZinc widgets are very similar to Tk Canvases in that they support structured graphics. But unlike the Canvas, TkZinc can structure the items in a hierarchy, has support for affine 2D transforms, clipping can be set for sub-trees of the item hierarchy, the item set is quite more powerful including field specific items for Air Traffic systems and new rendering techniques such as transparency and gradients. If needed, it is also possible to extend the item set in an additionnal dynamic library through the use of a C api.",
				  ],
		       },
	       );


# creation de la fenetre principale
my $mw = MainWindow->new();
$mw->geometry("700x560+0+0");
$mw->title('Test Graphics Module');


# creation du widget Zinc
my $zinc = $mw->Zinc(-render => 1,
		     -width => 700,
		     -height => 560,
		     -borderwidth => 0,
		     -lightangle => 140,
		     -borderwidth => 0,
		     -backcolor => '#cccccc',);
$zinc->pack(-fill => 'both', -expand => 1);


# initialise les gradients nommés
&setGradients($zinc, \%gradset);

# création de la vue principale
my $tgroup = $zinc->add('group', 1);
$zinc->coords($tgroup, [350, 240]);

# consigne globale
$zinc->add('text', 1,
	   -position => [50, 470],
	   -text => "Global interations :\n<Up>, <Down>, <Left> and <Right> keys move content of TabBox pages\n<Plus> and <Minus> keys zoom out and zoom in this page\n<Greater> and <Less> keys rotate this page\n<Escape> key reset transfos",
	   -font => $font_9b,
	   -color => '#555555',
	   -spacing => 2,
	   );

# Création des pages d'exemples
my ($shapes, $tcoords) = &tabBoxCoords([[-315, -210],[315, 210]],
				       -numpages => 7,
				       -overlap => 2,
				       -radius => 8,
				       -tabheight => 26,
				       -tabwidth => [92,100,82,82,82,120,80],
				      );

# to find some images (used as textures) needed by this demo
my $texture = $zinc->Photo('paper.gif', -file => Tk->findINC('demos/zinc_data/paper.gif'));

# création des items zinc correspondants
my $i = scalar(@{$shapes}) - 1;
my @pagenames = ('Rectangle', 'Hippodrome', 'Polygone', 'Polyline', 'PathLine', 'MultiContours', 'TabBox');
my @pagegroups;
foreach my $shape (reverse @{$shapes}) {
  my $divgroup = $zinc->add('group', $tgroup);

  # création de l'intercalaire
  my $divider = $zinc->add('curve', $divgroup,
			   $shape,
			   -closed => 1,
			   -priority => 10,
			   -linewidth => 1,
			   -linecolor => '#000000',
			   -filled => 1,
			   -tile => $texture,
			   -tags => ['div1', 'divider', $i, 'intercalaire'],
			  );

  # groupe page clippé
  my $page = $zinc->add('group', $divgroup,
			-priority => 100,
		       -tags => ['div1', $i, 'page'],
		       );
  my $clip = $zinc->add('rectangle', $page,
			[[-300, -170],[300, 195]],
			-linewidth => 1,
			-linecolor => '#000099',
			-filled => 1,
			-fillcolor => '#000000;4',
			);
  $zinc->itemconfigure($page, -clip => $clip);

  my $pgroup = $zinc->add('group', $page,
			  -tags => ['div1', $i, 'content'],
			 );

  push(@pagegroups, $pgroup);

  $tcoords->[$i]->[1] -= 6;

  # titre de l'intercalaire
  $zinc->add('text', $divgroup,
	     -position => $tcoords->[$i],
	     -text => $pagenames[$i],
	     -font => $font_9b,
	     -alignment => 'center',
	     -anchor => 'n',
	     -color => '#000099',
	     -priority => 200,
	     -tags => ['div1', 'divider', $i, 'titre'],
	    );
    $i--;
}

# création du contenu des pages
$i = 0;
foreach my $pagename (reverse @pagenames) {
  my $pagestyle = $pagesconf{$pagename};
  if ($pagestyle) {

    my $pgroup = $pagegroups[$i];
    while (my ($itemname, $itemstyle) = each(%{$pagestyle})) {
      my $group = ($itemname eq 'consigne') ? $zinc->group($pgroup) : $pgroup;
      $itemstyle->{'-name'} = $itemname;
      &buildZincItem($zinc, $group, %{$itemstyle});
    }
  }

  $i++;
}


# initialisation de la TabBox
&clickSelector('sel1','n');
&clickSelector('sel2','left');
&selectDivider('div1', 0);

# initialisation des bindings
&setBindings;


MainLoop;
#----------------------------------------------------------------------- fin de MAIN


sub setBindings {
  # grab keyboard
  $mw->Tk::focus();

  # plus,moins : Zoom++, Zoom--
  $mw->Tk::bind('<plus>', sub {viewZoom('up');});
  $mw->Tk::bind('<minus>', sub {viewZoom('down');});

  # Up, Down, Right, Left : Translate
  $mw->Tk::bind('<KeyPress-Up>', sub {viewTranslate('up');});
  $mw->Tk::bind('<KeyPress-Down>', sub {viewTranslate('down');});
  $mw->Tk::bind('<KeyPress-Left>', sub {viewTranslate('left');});
  $mw->Tk::bind('<KeyPress-Right>', sub {viewTranslate('right');});


  # >, < : Rotate counterclockwise et clockwise
  $mw->Tk::bind('<greater>', sub {viewRotate('cw');});
  $mw->Tk::bind('<less>', sub {viewRotate('ccw');});

  # Escape : reset transfos
  $mw->Tk::bind('<Escape>', sub {$zinc->treset('move');
				 $zinc->raise('move');
				 $zinc->treset($curview);});

  $zinc->bind('divider', '<1>', sub {&selectDivider();});

  $zinc->bind('selector', '<1>', sub {&clickSelector();});

  $zinc->bind('move', '<1>', sub {&mobileStart();});
  $zinc->bind('move', '<B1-Motion>', sub {&mobileMove();});
  $zinc->bind('move', '<ButtonRelease>', sub {&mobileStop();});

  $zinc->bind('pushbtn', '<1>', sub {&pushButton();});
  $zinc->bind('pushbtn', '<ButtonRelease>', sub {&pullButton();});

  $zinc->bind('poly', '<1>', sub {&startRotatePolygone();});
  $zinc->bind('poly', '<B1-Motion>', sub {&rotatePolygone();});
}


#-----------------------------------------------------------------------------------
# Callback sur evt CLICK des items tagés 'divider'
#-----------------------------------------------------------------------------------
sub selectDivider {
  my ($divname, $numpage) = @_;
  if (!defined $divname) {
    my @tags = $zinc->itemcget('current', -tags);
    $divname = $tags[0];
    $numpage = $tags[2];
  }

  $zinc->itemconfigure("($divname && titre)", -color => '#000099');
  $zinc->itemconfigure("($divname && intercalaire)", -linewidth => 1.4);
  $zinc->itemconfigure("($divname && page)", -visible => 0);

  my $divgroup = $zinc->group("($divname && $numpage)");
  $zinc->raise($divgroup);
  $curview = "($divname && $numpage && content)";
  $zinc->itemconfigure("($divname && $numpage && titre)", -color => '#000000');
  $zinc->itemconfigure("($divname && $numpage && intercalaire)", -linewidth => 2);
  $zinc->itemconfigure("($divname && $numpage && page)", -visible => 1);

  if ($divname eq 'div2') {
    my $fontname = $tabtable{$tabanchor}->{'-names'}->[$numpage];
    my $explain = $tabtable{$tabanchor}->{'-texts'}->[$numpage];
    my $text = $fontname."\n\n".$explain;
    $zinc->itemconfigure("($divname && fontname)",
			 -text => $text);
    $zinc->raise("($divname && fontname)");
  }
}


#-----------------------------------------------------------------------------------
# Callback sur evt CLICK des items tagés 'selector'
#-----------------------------------------------------------------------------------
sub clickSelector {
  my ($btngroup, $value) = @_;

  if (!defined $btngroup and !defined $value) {
    my @tags = $zinc->itemcget('current', -tags);
    $btngroup = $tags[0];
    $value = $tags[1];
  }

  $zinc->treset($btngroup);
  $zinc->itemconfigure("($btngroup && btntext)", -color => '#444444');
  $zinc->itemconfigure("($btngroup && $value && btntext)", -color => '#2222bb');
  $zinc->translate("($btngroup && $value)", 0, 1);

  if ($value eq 'n' or $value eq 'e' or $value eq 's' or $value eq 'w') {
    $tabanchor = $value;

  } elsif ($value eq 'left' or $value eq 'center' or $value eq 'right') {
    $tabalign = $value;
  }

  my $tabtable = $tabtable{$tabanchor};
  my $numpages = $tabtable->{'-numpages'};
  my %tabparams = (-radius => 8,
		   -tabwidth => 72,
		   -tabheight => 28,
		   -numpages => $numpages,
		   -anchor => $tabanchor,
		   -alignment => $tabalign,
		   -overlap => 3,
		  );

  my ($shapes, $tcoords) = &tabBoxCoords([[-240, -160], [240, 100]], %tabparams);

  for (my $index = 7; $index >= 0; $index--) {
    my $divgroup = $zinc->group("(div2 && $index && intercalaire)");
    $zinc->itemconfigure($divgroup, -visible => ($index < $numpages));

    if ($index >= $numpages) {
      $zinc->lower($divgroup);

    } else {
      $zinc->raise($divgroup);
      $zinc->itemconfigure("(div2 && $index)", -visible => 1);
      $zinc->coords("(div2 && $index && intercalaire)", $shapes->[$index]);
      if ($zinc->type("(div2 && $index && titre)")) {
	$zinc->coords("(div2 && $index && titre)", $tcoords->[$index]);
	$zinc->itemconfigure("(div2 && $index && titre)", -text => $tabtable->{'-titles'}->[$index]);
      }
    }

  }

  &selectDivider('div2', 0);
}


#-----------------------------------------------------------------------------------
# Callback sur evt CLICK des items tagés 'pushbtn'
#-----------------------------------------------------------------------------------
sub pushButton {
  my $tag = ($zinc->itemcget('current', -tags))[0];
  if (scalar $zinc->find('withtag', $tag) > 1 and
      !$zinc->find('withtag', "($tag && ico)")) {
    $tag = 'current';
  }
  $zinc->scale($tag, .975, .975);
  $zinc->translate($tag, 1, 1);

  if ($zinc->find('withtag', "($tag && ico)")) {
    my $oldcolor = $zinc->itemcget("($tag && ico)", -fillcolor);
    $zinc->itemconfigure('ico', -fillcolor => '#000000');

    my $newcolor = ($oldcolor eq '#000000') ?'#ffff00' : '#000000';
    $zinc->itemconfigure("($tag && ico)", -fillcolor => $newcolor);
  }
}

#-----------------------------------------------------------------------------------
# Callback sur evt RELEASE des items tagés 'pushbtn'
#-----------------------------------------------------------------------------------
sub pullButton {
  my $tag = ($zinc->itemcget('current', -tags))[0];
  $zinc->treset($tag);
}


#-----------------------------------------------------------------------------------
# Callback sur evt CATCH des items tagés 'poly'
# armement de rotation des polygones
#-----------------------------------------------------------------------------------
sub startRotatePolygone {
  my $ev = $zinc->XEvent;
  my ($xref, $yref) = $zinc->transform($zinc->group('current'), 1, [0, 0]);
  $previousangle = &lineAngle([$ev->x, $ev->y], [$xref, $yref]);
}

#-----------------------------------------------------------------------------------
# Callback sur evt MOTION des items tagés 'poly'
# rotation des polygones
#-----------------------------------------------------------------------------------
sub rotatePolygone {
  my $tag = ($zinc->itemcget('current', -tags))[0];
  my $ev = $zinc->XEvent;
  my ($xref, $yref) = $zinc->transform($zinc->group('current'), 1, [0, 0]);
  my $newangle = &lineAngle([$ev->x, $ev->y], [$xref, $yref]);

  $zinc->rotate($tag, deg2rad($newangle - $previousangle));
  $previousangle = $newangle;
}

#-----------------------------------------------------------------------------------
# Callback CATCH de sélection (début de déplacement) des items tagés 'move'
#-----------------------------------------------------------------------------------
sub mobileStart {
  my $ev = $zinc->XEvent;
  ($dx, $dy) = (0 - $ev->x, 0 - $ev->y);

  $zinc->raise('current');

}


#-----------------------------------------------------------------------------------
# Callback MOVE de déplacement des items tagés 'move'
#-----------------------------------------------------------------------------------
sub mobileMove {
    my $ev = $zinc->XEvent;
    $zinc->translate('current', $ev->x + $dx, $ev->y +$dy);
    ($dx, $dy) = (0 - $ev->x, 0 - $ev->y);

}


#-----------------------------------------------------------------------------------
# Callback RELEASE de relaché (fin de déplacement) des items tagés 'move'
#-----------------------------------------------------------------------------------
sub mobileStop {
  &mobileMove;
}


#-----------------------------------------------------------------------------------
# Callback sur evénément Tk <KeyPress> flèche gauche, haut, droite, bas
# pan (translation) du contenu de la page active (TabBox)
#-----------------------------------------------------------------------------------
sub viewTranslate {
  my $way = shift;

  my $dx = ($way eq 'left') ? -10 : ($way eq 'right') ? 10 : 0;
  my $dy = ($way eq 'up') ? -10 : ($way eq 'down') ? 10 : 0;

  $zinc->translate($curview, $dx, $dy);

}

#-----------------------------------------------------------------------------------
# Callback sur evénément Tk <KeyPress> "+" ou "-"
# zoom du contenu de la page active (TabBox)
#-----------------------------------------------------------------------------------
sub viewZoom {
  my $key = shift;
  my $scaleratio = ($key eq 'up') ? 1+$zoomfactor : 1-$zoomfactor;

  $zinc->scale($curview, $scaleratio, $scaleratio);

}


#-----------------------------------------------------------------------------------
# Callback sur evénément Tk <KeyPress> ">" ou "<"
# rotation du contenu de la page active (TabBox)
#-----------------------------------------------------------------------------------
sub viewRotate {
  my $way = shift;
  my $delta_angle = $rotate_angle;

  $delta_angle *= -1 if ($way eq 'cw');

  $zinc->rotate($curview, $delta_angle);

}



1;

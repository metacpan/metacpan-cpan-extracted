package Tk::Zinc::Logo;

#---------------------------------------------------------------
#
#  Module          : Logo.pm
#  $Id: Logo.pm,v 1.6 2003/09/15 12:21:48 mertz Exp $
#
#  Copyright (C) 2001-2003
#  Centre d'Études de la Navigation Aérienne
#  Authors: Jean-Luc Vinot <vinot@cena.fr>
#
#---------------------------------------------------------------

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.6 $ =~ /(\d+)\.(\d+)/);

use strict;
use Carp;
use Math::Trig;


my @Gradiants;

# paramètres de construction graphique
my %builder = (-gradset => {'logoshape' => '=axial 270 |#ffffff;100 0 28|#66848c;100 96|#7192aa;100 100',
			    'logopoint' => '=radial -20 -20 |#ffffff;100 0|#f70000;100 48|#900000;100 80|#ab0000;100 100',
			    'logoptshad' => '=path 0 0 |#770000;64 0|#770000;70 78|#770000;0 100',
			    },

	       -shape => {-form => {-itemtype => 'curve',
				    -coords => [[0,0],[106,0],[106,58],[122,41],[156,41],[131,69],[153,99],[203,41],
						[155,41],[155,0],[225.71,0],[251.34,0,'c'],[265.17,29.63,'c'],
						[248.71,49.27],[202,105],[246,105],[246,87],[246,59.385,'c'],[268.38,37,'c'],
						[296,37],[323.62,37,'c'],[346,59.385,'c'],[346,87],[346,148],[305,148],
						[305,87],[305,82.58,'c'],[301.42,79,'c'],[297,79],[292.58,79,'c'],
						[289,82.58,'c'],[289,87],[289,150],[251,150],[251,130],[251,125.58,'c'],
						[247.42,122,'c'],[243,122],[243,122],[238.58,122,'c'],[235,125.58,'c'],
						[235,130],[235,150],[168.12,150],[144.7,150,'c'],[132.38,122.57,'c'],
						[147.94,105.06],[148,105],[120,105],[104,81],[104,105],[74,105],[74,41],
						[52,41],[52,105],[20,105],[20,41],[0,41]],

				    -contour => ['add', -1, [[395,78],[395,37],[364.62,37,'c'],[340,61.62,'c'],[340,92],
							    [340,93],[340,123.38,'c'],[364.62,148,'c'],[395,148],[409,148],
							    [409,107],[395,107],[386.72,107,'c'],[380,100.28,'c'],[380,92],
							    [380,93],[380,84.72,'c'],[386.72,78,'c'],[395,78]]],


				    -params => {-closed => 0,
						-filled => 1,
						-visible => 1,
						-fillcolor => 'logoshape',
						-linewidth => 2.5,
						-linecolor => '#000000',
						-priority => 40,
						-fillrule => 'nonzero',
						-tags => ['zinc_shape'],
					       },
				   },

			  -shadow => {-clone => '-form',
				      -translate => [6, 6],
				      -params => {-fillcolor => '#000000;18',
						  -linewidth => 0,
						  -priority => 20,
						 },
				     },
			 },

	       -point => {-coords => [240, 96],
			  -params => {-alpha => 80,
				      -priority => 100,
				     },

			  -form => {-itemtype => 'arc',
				    -coords => [[-20, -20], [20, 20]],
				    -params => {-priority => 50,
						-filled => 1,
						-linewidth => 1,
						-linecolor => '#a10000;100',
						-fillcolor => 'logopoint',
						-closed => 1,
					       },
				   },

			  -shadow => {-clone => '-form',
				      -translate => [5, 5],
				      -params => {-fillcolor => 'logoptshad',
						  -linewidth => 0,
						  -priority => 20,
						 },
				     },
			 },
	      );



sub new {
    my $proto = shift;
    my $type = ref($proto) || $proto;
    my %params = @_;

    my $self = {};
    bless ($self, $type);
    if (exists $params{'-widget'}) {
	$self->{'-widget'} = $params{'-widget'};
    } else {
	croak "in Tk::Zinc::Logo constructor, the -widget attribute must be defined\n";
    }
    $self->{'-parent'} = (exists $params{'-parent'}) ? $params{'-parent'} : 1;
    $self->{'-priority'} = (exists $params{'-priority'}) ? $params{'-priority'} : 500;
    $self->{'-position'} = (exists $params{'-position'}) ? $params{'-position'} : [0, 0];
    $self->{'-scale'} = (exists $params{'-scale'}) ? $params{'-scale'} : [1, 1];

    $self->drawLogo();

    return bless $self, $type;
}



sub drawLogo {
  my ($self) = @_;
  my $zinc = $self->{'-widget'}; 
  my $parent = $self->{'-parent'};
  my $priority = $self->{'-priority'};


  if ($builder{'-gradset'}) {
    while (my ($name, $gradiant) = each( %{$builder{'-gradset'}})) {
      # création des gradiants nommés
      $zinc->gname($gradiant, $name) unless $zinc->gname($name);
      push(@Gradiants, $name);
    }
  }

  # création des groupes logo
  # logogroup : groupe de coordonnées
  my $logogroup =  $self->{'-item'} = $zinc->add('group', $parent, -priority => $priority);
  $zinc->coords($logogroup, $self->{'-position'}) if ($self->{'-position'});

  # group de scaling
  my $group = $self->{'-scaleitem'} = $zinc->add('group', $logogroup);
  $zinc->scale($group,  @{$self->{'-scale'}}) if ($self->{'-scale'});


  # création de l'item shape (Zinc)
  my $formstyle = $builder{'-shape'}->{'-form'};
  $self->ajustLineWidth($formstyle->{'-params'});
  my $shape = $zinc->add('curve', $group,
			$formstyle->{'-coords'},
			%{$formstyle->{'-params'}},
		       );

  $zinc->contour($shape, @{$formstyle->{'-contour'}});

  # ombre portée de la shape
  my $shadstyle = $builder{'-shape'}->{'-shadow'};
  my $shadow = $zinc->clone($shape, %{$shadstyle->{'-params'}});
  $zinc->translate($shadow, @{$shadstyle->{'-translate'}}) if ($shadstyle->{'-translate'});

  # réalisation du point
  my $pointconf = $builder{'-point'};
  my $ptgroup = $zinc->add('group', $group, %{$pointconf->{'-params'}});
  $zinc->coords($ptgroup,  $pointconf->{'-coords'});

  my $pointstyle =  $pointconf->{'-form'};
  my $point = $zinc->add('arc', $ptgroup,
			 $pointstyle->{'-coords'},
			 %{$pointstyle->{'-params'}},
			 );

  my $shadpoint = $zinc->clone($point, %{$shadstyle->{'-params'}});
  $shadstyle = $pointconf->{'-shadow'};
  $zinc->translate($shadpoint, @{$shadstyle->{'-translate'}});

}


sub ajustLineWidth {
  my ($self, $style, $scale) = @_;

  if ($style->{'-linewidth'}) {
    my ($sx, $sy) = @{$self->{'-scale'}};
    my $linewidth = $style->{'-linewidth'};
    if ($linewidth >= 2) {
      my $ratio = ($sx > $sy) ? $sy : $sx;
      $style->{'-linewidth'} = $linewidth * $ratio;
    }
  }
}

1;

__END__

=head1 NAME

Tk::Zinc::Logo - a perl module for drawing the TkZinc logo. 


=head1 SYNOPSIS

 use Tk::Zinc::Logo;
 my $zinc = MainWindow->new()->Zinc()->pack;
 my $logo = $zinc->ZincLogo([options]);



=head1 OPTIONS 

=over

=item B<-parent> => zinc group

Specify the parent group. Default is 1.

=item B<-position> => [x, y]

Specify the relative position of the logo in its parent group. Default is [0, 0].

=item B<-priority> => integer

Specify the priority of the logo in its parent group. Default is 500.

=item B<-scale> => [sx, sy]

Scecify the xscale and yscale factors of the logo. Default is [1, 1].


=back
    

=head1 AUTEUR

Jean-Luc Vinot <vinot@cena.fr>




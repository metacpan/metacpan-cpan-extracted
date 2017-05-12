#-----------------------------------------------------------------------------------
#
#      Graphics.pm
#      some graphic design functions
#
#-----------------------------------------------------------------------------------
#  Functions to create complexe graphic component :
#  ------------------------------------------------
#      buildZincItem          (realize a zinc item from description hash table
#                              management of enhanced graphics functions)
#
#      repeatZincItem         (duplication of given zinc item)
#
#  Function to compute complexe geometrical forms :
#  (text header of functions explain options for each form,
#  function return curve coords using control points of cubic curve)
#  -----------------------------------------------------------------
#      roundedRectangleCoords (return curve coords of rounded rectangle)
#      hippodromeCoords       (return curve coords of circus form)
#      ellipseCoords          (return curve coords of ellipse form)
#      polygonCoords          (return curve coords of regular polygon)
#      roundedCurveCoords     (return curve coords of rounded curve)
#      polylineCoords         (return curve coords of polyline)
#      shiftPathCoords        (return curve coords of shifting path)
#      tabBoxCoords           (return curve coords of tabBox's pages)
#      pathLineCoords         (return triangles coords of pathline)
#
#  Function to compute 2D 1/2 relief and shadow :
#  function build zinc items (triangles and curve) to simulate this
#  -----------------------------------------------------------------
#      graphicItemRelief      (return triangle items simulate relief of given item)
#      polylineReliefParams   (return triangle coords and lighting triangles color list)
#      graphicItemShadow      (return triangles and curve items simulate shadow of given item))
#      polylineShadowParams   (return triangle and curve coords and shadow triangles color list))
#
#  Geometrical basic Functions :
#  -----------------------------
#      perpendicularPoint
#      lineAngle
#      lineNormal
#      vertexAngle
#      arc_pts
#      rad_point
#      bezierCompute
#      bezierSegment
#      bezierPoint
#
#  Pictorial Functions  :
#  ----------------------
#      setGradients
#      getPattern
#      getTexture
#      getImage
#      init_pixmaps
#      zincItemPredominantColor
#      ZnColorToRGB
#      hexaRGBcolor
#      createGraduate
#      pathGraduate
#      MedianColor
#      LightingColor
#      RGBtoLCH
#      LCHtoRGB
#      RGBtoHLS
#      HLStoRGB
#
#-----------------------------------------------------------------------------------
#      Authors: Jean-Luc Vinot <vinot@cena.fr>
#
# $Id: Graphics.pm,v 1.12 2004/04/16 09:06:55 mertz Exp $ 
#-----------------------------------------------------------------------------------
package Tk::Zinc::Graphics;

use vars qw( $VERSION );
($VERSION) = sprintf("%d.%02d", q$Revision: 1.12 $ =~ /(\d+)\.(\d+)/);

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(&buildZincItem &repeatZincItem &buidTabBoxItem

	     &roundedRectangleCoords &hippodromeCoords &polygonCoords &ellipseCoords
	     &roundedCurveCoords &polylineCoords &tabBoxCoords &pathLineCoords &shiftPathCoords

	     &perpendicularPoint &lineAngle &vertexAngle &rad_point &arc_pts &lineNormal
	     &curve2polylineCoords &curveItem2polylineCoords &bezierSegment &bezierCompute

	     &graphicItemRelief &graphicItemShadow

	     &setGradients &getPattern &getTexture &getImage &init_pixmaps

	     &hexaRGBcolor &createGraduate &lightingColor &zincItemPredominantColor
	     &MedianColor &RGBtoLCH &LCHtoRGB &RGBtoHLS &HLStoRGB
	     );

use strict;
use Carp;
use Tk;
use Tk::PNG;
use Tk::JPEG;
use Math::Trig;

# constante facteur point directeur (conique -> quadratique)
my $const_ptd_factor = .5523;

# constante white point (conversion couleur espace CIE XYZ)
my ($Xw, $Yw, $Zw) = (95.047, 100.0, 108.883);

# limite globale d'approximation courbe bezier
my $bezierClosenessThreshold = .2;

# initialisation et partage de ressources couleurs et images
my @Gradients;
my %textures;
my %images;
my %bitmaps;



#-----------------------------------------------------------------------------------
# Graphics::buildZincItem
# Création d'un objet Zinc de représentation
#-----------------------------------------------------------------------------------
# types d'items valides :
# les items natifs zinc : group, rectangle, arc, curve, text, icon
# les items ci-après permettent de spécifier des curves 'particulières' :
# -roundedrectangle : rectangle à coin arrondi
#       -hippodrome : hippodrome
#          -ellipse : ellipse un centre 2 rayons
#         -polygone : polygone régulier à n cotés (convexe ou en étoile)
#     -roundedcurve : curve multicontours à coins arrondis (rayon unique)
#         -polyline : curve multicontours à coins arrondis (le rayon pouvant être défini 
#                     spécifiquement pour chaque sommet)
#         -pathline : création d'une ligne 'épaisse' avec l'item Zinc triangles
#                     décalage par rapport à un chemin donné (largeur et sens de décalage)
#                     dégradé de couleurs de la ligne (linéaire, transversal ou double)
#-----------------------------------------------------------------------------------
# paramètres :
# widget : <widget> identifiant du widget Zinc
# parentgroup : <tagOrId> identifiant du group parent
#
# options :
#   -itemtype : type de l'item à construire (type zinc ou metatype)
#     -coords : <coords|coordsList> coordonnées de l'item
# -metacoords : <hastable> calcul de coordonnées par type d'item différent de -itemtype
#   -contours : <contourList> paramètres multi-contours
#     -params : <hastable> arguments spécifiques de l'item à passer au widget
#    -addtags : [list of specific tags] to add to params -tags
#    -texture : <imagefile> ajout d'une texture à l'item
#    -pattern : <imagefile> ajout d'un pattern à l'item
#     -relief : <hastable> création d'un relief à l'item invoque la fonction &graphicItemRelief()
#     -shadow : <hastable> création d'une ombre portée à l'item invoque la fonction &graphicItemShadow()
#      -scale : <scale_factor|[xscale_factor,yscale_factor]> application d'une transformation zinc->scale à l'item
#  -translate : <[dx,dy]> application d'un transformation zinc->translate à l'item.
#     -rotate : <angle> application d'une transformation zinc->rotate (en degré) à l'item
#       -name : <str> nom de l'item
# spécifiques item group :
#       -clip : <coordList|hashtable> paramètres de clipping d'un item group (coords ou item)
#      -items : <hashtable> appel récursif de la fonction permettant d'inclure des items au groupe
#-----------------------------------------------------------------------------------
#
#-----------------------------------------------------------------------------------
sub buildZincItem {
  my ($widget, $parentgroup, %options) = @_;
  $parentgroup = 1 if !$parentgroup;

  my $itemtype = $options{'-itemtype'};
  my $coords = $options{'-coords'};
  my $params = $options{'-params'};

  return unless ($widget and $itemtype and ($coords or $options{'-metacoords'}));

  my $name = ($options{'-name'}) ? $options{'-name'} : 'none';

  my $item;
  my $metatype;
  my (@items, @reliefs, @shadows);
  my @tags;


  #--------------------
  # GEOMETRIE DES ITEMS

  # gestion des types d'items particuliers et à raccords circulaires
  if ($itemtype eq 'roundedrectangle'
      or $itemtype eq 'hippodrome'
      or $itemtype eq 'polygone'
      or $itemtype eq 'ellipse'
      or $itemtype eq 'roundedcurve'
      or $itemtype eq 'polyline'
      or $itemtype eq 'curveline') {

    # par défaut la curve sera fermée -closed = 1
    $params->{'-closed'} = 1 if (!defined $params->{'-closed'});
    $metatype = $itemtype;
    $itemtype = 'curve';

    # possibilité de définir les coordonnées initiales par metatype
    if ($options{'-metacoords'}) {
      $options{'-coords'} = &metaCoords(%{$options{'-metacoords'}});

    }

  # création d'une pathline à partir d'item zinc triangles
  } elsif ($itemtype eq 'pathline') {

    $itemtype = 'triangles';
    if ($options{'-metacoords'}) {
      $coords = &metaCoords(%{$options{'-metacoords'}});

    }

    if ($options{'-graduate'}) {
      my $numcolors = scalar(@{$coords});
      $params->{'-colors'} = &pathGraduate($widget, $numcolors, $options{'-graduate'});
    }

    $coords = &pathLineCoords($coords, %options);


  # création d'une boite à onglet
  } elsif ($itemtype eq 'tabbox') {
    return &buildTabBoxItem($widget, $parentgroup, %options);

  }

  # calcul des coordonnées finales de la curve
  $coords = &metaCoords(-type => $metatype, %options) if ($metatype);


  # gestion du multi-contours (accessible pour tous les types d'items géometriques)
  if ($options{'-contours'} and $metatype) {
    my @contours = @{$options{'-contours'}};
    my $numcontours = scalar(@contours);
    for (my $i = 0; $i < $numcontours; $i++) {
      # radius et corners peuvent être défini spécifiquement pour chaque contour
      my ($type, $way, $addcoords, $radius, $corners, $corners_radius) = @{$contours[$i]};
      $radius = $options{'-radius'} if (!defined $radius);

      my $newcoords = &metaCoords(-type => $metatype,
				  -coords => $addcoords,
				  -radius => $radius,
				  -corners => $corners,
				  -corners_radius => $corners_radius
				 );

      $options{'-contours'}->[$i] = [$type, $way, $newcoords];
    }
  }


  #----------------------
  # REALISATION DES ITEMS

  # ITEM GROUP
  # gestion des coordonnées et du clipping
  if ($itemtype eq 'group') {
    $item = $widget->add($itemtype,
			 $parentgroup,
			 %{$params});

    $widget->coords($item, $coords) if $coords;

    # clipping du groupe par item ou par géometrie
    if ($options{'-clip'}) {
      my $clipbuilder = $options{'-clip'};
      my $clip;

      # création d'un item de clipping
      if ($clipbuilder->{'-itemtype'}) {
	$clip = &buildZincItem($widget, $item, %{$clipbuilder});

      } elsif (ref($clipbuilder) eq 'ARRAY' or $widget->type($clipbuilder)) {
	$clip = $clipbuilder;
      }

      $widget->itemconfigure($item, -clip => $clip) if ($clip);
    }

    # créations si besoin des items contenus dans le groupe
    if ($options{'-items'} and ref($options{'-items'}) eq 'HASH') {
      while (my ($itemname, $itemstyle) = each(%{$options{'-items'}})) {
	$itemstyle->{'-name'} = $itemname if (!$itemstyle->{'-name'});
	&buildZincItem($widget, $item, %{$itemstyle});
      }
    }


  # ITEM TEXT ou ICON
  } elsif ($itemtype eq 'text' or $itemtype eq 'icon') {
    my $imagefile;
    if ($itemtype eq 'icon') {
      $imagefile = $params->{'-image'};
      my $image = &getImage($widget, $imagefile);
      $params->{'-image'} = ($image) ? $image : "";
    }

    $item = $widget->add($itemtype,
		       $parentgroup,
		       -position => $coords,
		       %{$params},
		      );

    $params->{'-image'} = $imagefile if $imagefile;


  # ITEMS GEOMETRIQUES -> CURVE
  } else {

    $item = $widget->add($itemtype,
			 $parentgroup,
			 $coords,
			 %{$params},
			);

    if ($itemtype eq 'curve' and $options{'-contours'}) {
      foreach my $contour (@{$options{'-contours'}}) {
	$widget->contour($item, @{$contour});
      }
    }
	
    # gestion du mode norender
    if ($options{'-texture'}) {
      my $texture = &getTexture($widget, $options{'-texture'});
      $widget->itemconfigure($item, -tile => $texture) if $texture;
    }

    if ($options{'-pattern'}) {
      my $bitmap = &getBitmap($options{'-pattern'});
      $widget->itemconfigure($item, -fillpattern => $bitmap) if $bitmap;
    }

  }


  # gestion des tags spécifiques
  if ($options{'-addtags'}) {
    my @tags = @{$options{'-addtags'}};

    my $params_tags = $params->{'-tags'};
    push (@tags, @{$params_tags}) if $params_tags;

    $widget->itemconfigure($item, -tags => \@tags);

  }


  #-------------------------------
  # TRANSFORMATIONS ZINC DE L'ITEM

  # transformation scale de l'item si nécessaire
  if ($options{'-scale'}) {
    my $scale = $options{'-scale'};
    $scale = [$scale, $scale] if (ref($scale) ne 'ARRAY');
    $widget->scale($item, @{$scale}) ;
  }

  # transformation rotate de l'item si nécessaire
  $widget->rotate($item, deg2rad($options{'-rotate'})) if ($options{'-rotate'});

  # transformation translate de l'item si nécessaire
  $widget->translate($item, @{$options{'-translate'}}) if ($options{'-translate'});


  # répétition de l'item
  if ($options{'-repeat'}) {
    push (@items, $item,
	  &repeatZincItem($widget, $item, %{$options{'-repeat'}}));
  }


  #-----------------------
  # RELIEF ET OMBRE PORTEE

  # gestion du relief
  if ($options{'-relief'}) {
    my $target = (@items) ? \@items : $item;
    push (@reliefs, &graphicItemRelief($widget, $target, %{$options{'-relief'}}));
  }

  # gestion de l'ombre portée
  if ($options{'-shadow'}) {
    my $target = (@items) ? \@items : $item;
    push (@shadows, &graphicItemShadow($widget, $target, %{$options{'-shadow'}}));
  }

  push(@items, @reliefs) if @reliefs;
  push(@items, @shadows) if @shadows;

  return (@items) ? @items : $item;

}


#-----------------------------------------------------------------------------------
# Graphics::repeatZincItem
# Duplication (clonage) d'un objet Zinc de représentation
#-----------------------------------------------------------------------------------
# paramètres :
# widget : <widget> identifiant du widget zinc
#   item : <tagOrId> identifiant de l'item source
# options :
#     -num : <n> nombre d'item total (par defaut 2)
#     -dxy : <[dx, dy]> translation entre 2 duplications (par defaut [0,0])
#   -angle : <angle> rotation entre 2 duplications
# -copytag : <sting> ajout d'un tag indexé pour chaque copie
#  -params : <hashtable> {clef => [value list]}> valeur de paramètre de chaque copie
#-----------------------------------------------------------------------------------
sub repeatZincItem {
  my ($widget, $item, %options) = @_;
  my @clones;

  # duplication d'une liste d'items -> appel récursif
  if (ref($item) eq 'ARRAY') {
    foreach my $part (@{$item}) {
      push (@clones, &repeatZincItem($widget, $part, %options));
    }

    return wantarray ? @clones : \@clones;
  }

  my $num = ($options{'-num'}) ? $options{'-num'} : 2;
  my ($dx, $dy) = (defined $options{'-dxy'}) ? @{$options{'-dxy'}} : (0, 0);
  my $angle = $options{'-angle'};
  my $params = $options{'-params'};
  my $copytag = $options{'-copytag'};
  my @tags;

  if ($copytag) {
    @tags = $widget->itemcget($item, -tags);
    unshift (@tags, $copytag."0");
    $widget->itemconfigure($item, -tags => \@tags);
  }

  for (my $i = 1; $i < $num; $i++) {
    my $clone;

    if ($copytag) {
      $tags[0] = $copytag.$i;
      $clone = $widget->clone($item, -tags => \@tags);

    } else {
      $clone = $widget->clone($item);
    }

    push(@clones, $clone);
    $widget->translate($clone, $dx*$i, $dy*$i);
    $widget->rotate($clone, deg2rad($angle*$i)) if $angle;

    if ($params) {
      while (my ($attrib, $value) = each(%{$params})) {
	$widget->itemconfigure($clone, $attrib => $value->[$i]);
      }
    }
  }

  return wantarray ? @clones : \@clones;

}


#-----------------------------------------------------------------------------------
# FONCTIONS GEOMETRIQUES
#-----------------------------------------------------------------------------------

#-----------------------------------------------------------------------------------
# Graphics::metaCoords
# retourne une liste de coordonnées en utilisant la fonction du type d'item spécifié
#-----------------------------------------------------------------------------------
# paramètres : (passés par %options)
#   -type : <string> type de primitive utilisée
# -coords : <coordsList> coordonnées nécessitée par la fonction [type]Coords
#
# les autres options spécialisées au type seront passés à la fonction [type]coords
#-----------------------------------------------------------------------------------
sub metaCoords {
  my (%options) = @_;
  my $pts;

  my $type = delete $options{'-type'};
  my $coords = delete $options{'-coords'};

  if ($type eq 'roundedrectangle') {
    $pts = &roundedRectangleCoords($coords, %options);

  } elsif ($type eq 'hippodrome') {
    $pts = &hippodromeCoords($coords, %options);

  } elsif ($type eq 'ellipse') {
    $pts = &ellipseCoords($coords, %options);

  } elsif ($type eq 'roundedcurve') {
    $pts = &roundedCurveCoords($coords, %options);

  } elsif ($type eq 'polygone') {
    $pts = &polygonCoords($coords, %options);

  } elsif ($type eq 'polyline') {
    $pts = &polylineCoords($coords, %options);

  } elsif ($type eq 'curveline') {
    $pts = &curveLineCoords($coords, %options);
  }

  return $pts;
}


#-----------------------------------------------------------------------------------
# Graphics::ZincItem2CurveCoords
# retourne une liste des coordonnées 'Curve' d'un l'item Zinc
# rectangle, arc ou curve
#-----------------------------------------------------------------------------------
# paramètres :
# widget : <widget> identifiant du widget zinc
#   item : <tagOrId> identifiant de l'item source
# options :
#     -linear : <boolean> réduction à des segments non curviligne (par défaut 0)
# -realcoords : <boolean> coordonnées à transformer dans le groupe père (par défaut 0)
#     -adjust : <boolean> ajustement de la courbe de bezier (par défaut 1)
#-----------------------------------------------------------------------------------
sub ZincItem2CurveCoords {
  my ($widget, $item, %options) = @_;

  my $itemtype = $widget->type($item);
  return unless ($itemtype);

  my $linear = $options{-linear};
  my $realcoords = $options{-realcoords};
  my $adjust = (defined $options{-adjust}) ? $options{-adjust} : 1;

  my @itemcoords = $widget->coords($item);

  my $coords;
  my @multi;

  if ($itemtype eq 'rectangle') {
    $coords = &roundedRectangleCoords(\@itemcoords, -radius => 0);

  } elsif ($itemtype eq 'arc') {
    $coords = &ellipseCoords(\@itemcoords);
    $coords = &curve2polylineCoords($coords, $adjust) if $linear;

  } elsif ($itemtype eq 'curve') {
      my $numcontours = $widget->contour($item);

      if ($numcontours < 2) {
      $coords = \@itemcoords;
      $coords = &curve2polylineCoords($coords, $adjust) if $linear;


    } else {
      if ($linear) {
	@multi = &curveItem2polylineCoords($widget, $item);

      } else {
	for (my $contour = 0; $contour < $numcontours; $contour++) {
	  my @points = $widget->coords($item, $contour);
	  push (@multi, \@points);
	}
      }

      $coords = \@multi;
    }
  }

  if ($realcoords) {
    my $parentgroup = $widget->group($item);
    if (@multi) {
      my @newcoords;
      foreach my $points (@multi) {
	my @transcoords = $widget->transform($item, $parentgroup, $points);
	push(@newcoords, \@transcoords);
      }

      $coords = \@newcoords;

    } else {
      my @transcoords = $widget->transform($item, $parentgroup, $coords);
      $coords = \@transcoords;
    }

  }

  if (@multi) {
    return (wantarray) ? @{$coords} : $coords;
  } else {
    return (wantarray) ? ($coords) : $coords;
  }
}

#-----------------------------------------------------------------------------------
# Graphics::roundedRectangleCoords
# calcul des coords du rectangle à coins arrondis
#-----------------------------------------------------------------------------------
# paramètres :
# coords : <coordsList> coordonnées bbox (haut-gauche et bas-droite) du rectangle
# options :
#  -radius : <dimension> rayon de raccord d'angle
# -corners : <booleanList> liste des raccords de sommets [0 (aucun raccord)|1] par défaut [1,1,1,1]
#-----------------------------------------------------------------------------------
sub roundedRectangleCoords {
  my ($coords, %options) = @_;
  my ($x0, $y0, $xn, $yn) = ($coords->[0]->[0], $coords->[0]->[1],
			     $coords->[1]->[0], $coords->[1]->[1]);

  my $radius = $options{'-radius'};
  my $corners = $options{'-corners'} ? $options{'-corners'} : [1, 1, 1, 1];

  # attention aux formes 'négatives'
  if ($xn < $x0) {
    my $xs = $x0;
    ($x0, $xn) = ($xn, $xs);
  }
   if ($yn < $y0) {
    my $ys = $y0;
    ($y0, $yn) = ($yn, $ys);
  }

  my $height = &_min($xn -$x0, $yn - $y0);

  if (!defined $radius) {
    $radius = int($height/10);
    $radius = 3 if $radius < 3;
  }

  if (!$radius or $radius < 2) {
    return [[$x0, $y0],[$x0, $yn],[$xn, $yn],[$xn, $y0]];

  }


  # correction de radius si necessaire
  my $max_rad = $height;
  $max_rad /= 2 if (!defined $corners);
  $radius = $max_rad if $radius > $max_rad;

  # points remarquables
  my $ptd_delta = $radius * $const_ptd_factor;
  my ($x2, $x3) = ($x0 + $radius, $xn - $radius);
  my ($x1, $x4) = ($x2 - $ptd_delta, $x3 + $ptd_delta);
  my ($y2, $y3) = ($y0 + $radius, $yn - $radius);
  my ($y1, $y4) = ($y2 - $ptd_delta, $y3 + $ptd_delta);

  # liste des 4 points sommet du rectangle : angles sans raccord circulaire
  my @angle_pts = ([$x0, $y0],[$x0, $yn],[$xn, $yn],[$xn, $y0]);

  # liste des 4 segments quadratique : raccord d'angle = radius
  my @roundeds = ([[$x2, $y0],[$x1, $y0, 'c'],[$x0, $y1, 'c'],[$x0, $y2],],
		  [[$x0, $y3],[$x0, $y4, 'c'],[$x1, $yn, 'c'],[$x2, $yn],],
		  [[$x3, $yn],[$x4, $yn, 'c'],[$xn, $y4, 'c'],[$xn, $y3],],
		  [[$xn, $y2],[$xn, $y1, 'c'],[$x4, $y0, 'c'],[$x3, $y0],]);

  my @pts = ();
  my $previous;
  for (my $i = 0; $i < 4; $i++) {
    if ($corners->[$i]) {
      if ($previous) {
	# on teste si non duplication de point
	my ($nx, $ny) = @{$roundeds[$i]->[0]};
	if ($previous->[0] == $nx and $previous->[1] == $ny) {
	  pop(@pts);
	}
      }
      push(@pts, @{$roundeds[$i]});
      $previous = $roundeds[$i]->[3];

    } else {
      push(@pts, $angle_pts[$i]);
    }
  }

  return \@pts;
}

#-----------------------------------------------------------------------------------
# Graphics::ellipseCoords
# calcul des coords d'une ellipse
#-----------------------------------------------------------------------------------
# paramètres :
# coords : <coordsList> coordonnées bbox du rectangle exinscrit
# options :
# -corners : <booleanList> liste des raccords de sommets [0 (aucun raccord)|1] par défaut [1,1,1,1]
#-----------------------------------------------------------------------------------
sub ellipseCoords {
  my ($coords, %options) = @_;
  my ($x0, $y0, $xn, $yn) = ($coords->[0]->[0], $coords->[0]->[1],
			     $coords->[1]->[0], $coords->[1]->[1]);

  my $corners = $options{'-corners'} ? $options{'-corners'} : [1, 1, 1, 1];

  # attention aux formes 'négatives'
  if ($xn < $x0) {
    my $xs = $x0;
    ($x0, $xn) = ($xn, $xs);
  }
   if ($yn < $y0) {
    my $ys = $y0;
    ($y0, $yn) = ($yn, $ys);
  }

  # points remarquables
  my $dx = ($xn - $x0)/2 * $const_ptd_factor;
  my $dy = ($yn - $y0)/2 * $const_ptd_factor;
  my ($x2, $y2) = (($x0+$xn)/2, ($y0+$yn)/2);
  my ($x1, $x3) = ($x2 - $dx, $x2 + $dx);
  my ($y1, $y3) = ($y2 - $dy, $y2 + $dy);

  # liste des 4 points sommet de l'ellipse : angles sans raccord circulaire
  my @angle_pts = ([$x0, $y0],[$x0, $yn],[$xn, $yn],[$xn, $y0]);

  # liste des 4 segments quadratique : raccord d'angle = arc d'ellipse
  my @roundeds = ([[$x2, $y0],[$x1, $y0, 'c'],[$x0, $y1, 'c'],[$x0, $y2],],
		  [[$x0, $y2],[$x0, $y3, 'c'],[$x1, $yn, 'c'],[$x2, $yn],],
		  [[$x2, $yn],[$x3, $yn, 'c'],[$xn, $y3, 'c'],[$xn, $y2],],
		  [[$xn, $y2],[$xn, $y1, 'c'],[$x3, $y0, 'c'],[$x2, $y0],]);

  my @pts = ();
  my $previous;
  for (my $i = 0; $i < 4; $i++) {
    if ($corners->[$i]) {
      if ($previous) {
	# on teste si non duplication de point
	my ($nx, $ny) = @{$roundeds[$i]->[0]};
	if ($previous->[0] == $nx and $previous->[1] == $ny) {
	  pop(@pts);
	}
      }
      push(@pts, @{$roundeds[$i]});
      $previous = $roundeds[$i]->[3];

    } else {
      push(@pts, $angle_pts[$i]);
    }
  }

  return \@pts;

}


#-----------------------------------------------------------------------------------
# Graphics::hippodromeCoords
# calcul des coords d'un hippodrome
#-----------------------------------------------------------------------------------
# paramètres :
# coords : <coordsList> coordonnées bbox du rectangle exinscrit
# options :
# -orientation : orientation forcée de l'hippodrome [horizontal|vertical]
#     -corners : liste des raccords de sommets [0|1] par défaut [1,1,1,1]
#       -trunc : troncatures [left|right|top|bottom|both]
#-----------------------------------------------------------------------------------
sub hippodromeCoords {
  my ($coords, %options) = @_;
  my ($x0, $y0, $xn, $yn) = ($coords->[0]->[0], $coords->[0]->[1],
			     $coords->[1]->[0], $coords->[1]->[1]);

  my $orientation = ($options{'-orientation'}) ? $options{'-orientation'} : 'none';

  # orientation forcée de l'hippodrome (sinon hippodrome sur le plus petit coté)
  my $height = ($orientation eq 'horizontal') ? abs($yn - $y0)
    : ($orientation eq 'vertical') ? abs($xn - $x0) : &_min(abs($xn - $x0), abs($yn - $y0));
  my $radius = $height/2;
  my $corners = [1, 1, 1, 1];

  if  ($options{'-corners'}) {
    $corners = $options{'-corners'};

  } elsif ($options{'-trunc'}) {
    my $trunc = $options{'-trunc'};
    if ($trunc eq 'both') {
      return [[$x0, $y0],[$x0, $yn],[$xn, $yn],[$xn, $y0]];

    } else {
      $corners = ($trunc eq 'left') ? [0, 0, 1, 1] :
	($trunc eq 'right') ? [1, 1, 0, 0] :
	  ($trunc eq 'top') ? [0, 1, 1, 0] : 
	    ($trunc eq 'bottom') ? [1, 0, 0, 1] : [1, 1, 1, 1];

    }
  }

  # l'hippodrome est un cas particulier de roundedRectangle
  # on retourne en passant la 'configuration' à la fonction générique roundedRectangleCoords
  return &roundedRectangleCoords($coords, -radius => $radius, -corners => $corners);
}


#-----------------------------------------------------------------------------------
# Graphics::polygonCoords
# calcul des coords d'un polygone régulier
#-----------------------------------------------------------------------------------
# paramètres :
# coords : <coords> point centre du polygone
# options :
#      -numsides : <integer> nombre de cotés
#        -radius : <dimension> rayon de définition du polygone (distance centre-sommets)
#  -inner_radius : <dimension> rayon interne (polygone type étoile)
#       -corners : <booleanList> liste des raccords de sommets [0|1] par défaut [1,1,1,1]
# -corner_radius : <dimension> rayon de raccord des cotés
#    -startangle : <angle> angle de départ en degré du polygone
#-----------------------------------------------------------------------------------
sub polygonCoords {
  my ($coords, %options) = @_;

  my $numsides = $options{'-numsides'};
  my $radius = $options{'-radius'};
  if ($numsides < 3 or !$radius) {
    print "Vous devez au moins spécifier un nombre de cotés >= 3 et un rayon...\n";
    return undef;
  }

  $coords = [0, 0] if (!defined $coords);
  my $startangle = ($options{'-startangle'}) ? $options{'-startangle'} : 0;
  my $anglestep = 360/$numsides;
  my $inner_radius = $options{'-inner_radius'};
  my @pts;

  # points du polygone
  for (my $i = 0; $i < $numsides; $i++) {
    my ($xp, $yp) = &rad_point($coords, $radius, $startangle + ($anglestep*$i));
    push(@pts, ([$xp, $yp]));

    # polygones 'étoiles'
    if ($inner_radius) {
      ($xp, $yp) = &rad_point($coords, $inner_radius, $startangle + ($anglestep*($i+ 0.5)));
      push(@pts, ([$xp, $yp]));
    }
  }


  @pts = reverse @pts;

  if ($options{'-corner_radius'}) {
    return &roundedCurveCoords(\@pts, -radius => $options{'-corner_radius'}, -corners => $options{'-corners'});
  } else {
    return \@pts;
  }
}



#-----------------------------------------------------------------------------------
# Graphics::roundedAngle
# THIS FUNCTION IS NO MORE USED, NEITHER EXPORTED
# curve d'angle avec raccord circulaire
#-----------------------------------------------------------------------------------
# paramètres :
# widget : identifiant du widget Zinc
# parentgroup : <tagOrId> identifiant de l'item group parent
# coords : <coordsList> les 3 points de l'angle
# radius : <dimension> rayon de raccord
#-----------------------------------------------------------------------------------
sub roundedAngle {
  my ($widget, $parentgroup, $coords, $radius) = @_;
  my ($pt0, $pt1, $pt2) = @{$coords};

  my ($corner_pts, $center_pts) = &roundedAngleCoords($coords, $radius);
  my ($cx0, $cy0) = @{$center_pts};

  # valeur d'angle et angle formé par la bisectrice
  my ($angle)  = &vertexAngle($pt0, $pt1, $pt2);

  $parentgroup = 1 if (!defined $parentgroup);

  $widget->add('curve', $parentgroup,
	     [$pt0,@{$corner_pts},$pt2],
	     -closed => 0, 
	     -linewidth => 1,
	     -priority => 20,
	    );

}

#-----------------------------------------------------------------------------------
# Graphics::roundedAngleCoords
# calcul des coords d'un raccord d'angle circulaire
#-----------------------------------------------------------------------------------
# le raccord circulaire de 2 droites sécantes est traditionnellement réalisé par un
# arc (conique) du cercle inscrit de rayon radius tangent à ces 2 droites
#
# Quadratique :
# une approche de cette courbe peut être réalisée simplement par le calcul de 4 points
# spécifiques qui définiront - quelle que soit la valeur de l'angle formé par les 2
# droites - le segment de raccord :
# - les 2 points de tangence au cercle inscrit seront les points de début et de fin
# du segment de raccord
# - les 2 points de controle seront situés chacun sur le vecteur reliant le point de
# tangence au sommet de l'angle (point secant des 2 droites)
# leur position sur ce vecteur peut être simplifiée comme suit :
# - à un facteur de 0.5523 de la distance au sommet pour un angle >= 90° et <= 270°
# - à une 'réduction' de ce point vers le point de tangence pour les angles limites
# de 90° vers 0° et de 270° vers 360°
# ce facteur sera légérement modulé pour recouvrir plus précisement l'arc correspondant
#-----------------------------------------------------------------------------------
# coords : <coordsList> les 3 points de l'angle
# radius : <dimension> rayon de raccord
#-----------------------------------------------------------------------------------
sub roundedAngleCoords {
  my ($coords, $radius) = @_;
  my ($pt0, $pt1, $pt2) = @{$coords};

  # valeur d'angle et angle formé par la bisectrice
  my ($angle, $bisecangle)  = &vertexAngle($pt0, $pt1, $pt2);

  # distance au centre du cercle inscrit : rayon/sinus demi-angle
  my $sin = sin(deg2rad($angle/2));
  my $delta = ($sin) ? abs($radius / $sin) : $radius;

  # point centre du cercle inscrit de rayon $radius
  my $refangle = ($angle < 180) ? $bisecangle+90 : $bisecangle-90;
  my ($cx0, $cy0) = rad_point($pt1, $delta, $refangle);

  # points de tangeance : pts perpendiculaires du centre aux 2 droites
  my ($px1, $py1) = &perpendicularPoint([$cx0, $cy0], [$pt0, $pt1]);
  my ($px2, $py2) = &perpendicularPoint([$cx0, $cy0], [$pt1, $pt2]);

  # point de controle de la quadratique
  # facteur de positionnement sur le vecteur pt.tangence, sommet
  my $ptd_factor =  $const_ptd_factor;
  if ($angle < 90 or $angle > 270) {
    my $diffangle = ($angle < 90) ? $angle : 360 - $angle;
    $ptd_factor -= (((90 - $diffangle)/90) * ($ptd_factor/4)) if $diffangle > 15 ;
    $ptd_factor = ($diffangle/90) * ($ptd_factor + ((1 - $ptd_factor) * (90 - $diffangle)/90));
  } else {
    my $diffangle = abs(180 - $angle);
    $ptd_factor += (((90 - $diffangle)/90) * ($ptd_factor/3)) if $diffangle > 15;
  }

  # delta xy aux pts de tangence
  my ($d1x, $d1y) = (($pt1->[0] - $px1) * $ptd_factor, ($pt1->[1] - $py1) *  $ptd_factor);
  my ($d2x, $d2y) = (($pt1->[0] - $px2) * $ptd_factor, ($pt1->[1] - $py2) *  $ptd_factor);

  # les 4 points de l'arc 'quadratique'
  my $corner_pts = [[$px1, $py1],[$px1+$d1x, $py1+$d1y, 'c'],
		    [$px2+$d2x, $py2+$d2y, 'c'],[$px2, $py2]];


  # retourne le segment de quadratique et le centre du cercle inscrit
  return ($corner_pts, [$cx0, $cy0]);

}


#-----------------------------------------------------------------------------------
# Graphics::roundedCurveCoords
# retourne les coordonnées d'une curve à coins arrondis
#-----------------------------------------------------------------------------------
# paramètres :
# coords : <coordsList> liste de coordonnées des points de la curve
# options :
#  -radius : <dimension> rayon de raccord d'angle
# -corners : <booleanList> liste des raccords de sommets [0|1] par défaut [1,1,1,1]
#-----------------------------------------------------------------------------------
sub roundedCurveCoords {
  my ($coords, %options) = @_;
  my $numfaces = scalar(@{$coords});
  my @curve_pts;

  my $radius = (defined $options{'-radius'}) ? $options{'-radius'} : 0;
  my $corners = $options{'-corners'};

  for (my $index = 0; $index < $numfaces; $index++) {
    if ($corners and !$corners->[$index]) {
      push(@curve_pts, $coords->[$index]);

    } else {
      my $prev = ($index) ? $index - 1 : $numfaces - 1;
      my $next = ($index > $numfaces - 2) ? 0 : $index + 1;
      my $anglecoords = [$coords->[$prev], $coords->[$index], $coords->[$next]];

      my ($quad_pts) = &roundedAngleCoords($anglecoords, $radius);
      push(@curve_pts, @{$quad_pts});
    }
  }

  return \@curve_pts;

}


#-----------------------------------------------------------------------------------
# Graphics::polylineCoords
# retourne les coordonnées d'une polyline
#-----------------------------------------------------------------------------------
# paramètres :
# coords : <coordsList> liste de coordonnées des sommets de la polyline
# options :
#  -radius : <dimension> rayon global de raccord d'angle
# -corners : <booleanList> liste des raccords de sommets [0|1] par défaut [1,1,1,1],
# -corners_radius : <dimensionList> liste des rayons de raccords de sommets
#-----------------------------------------------------------------------------------
sub polylineCoords {
  my ($coords, %options) = @_;
  my $numfaces = scalar(@{$coords});
  my @curve_pts;

  my $radius = ($options{'-radius'}) ? $options{'-radius'} : 0;
  my $corners_radius = $options{'-corners_radius'};
  my $corners = ($corners_radius) ? $corners_radius : $options{'-corners'};

  for (my $index = 0; $index < $numfaces; $index++) {
    if ($corners and !$corners->[$index]) {
      push(@curve_pts, $coords->[$index]);

    } else {
      my $prev = ($index) ? $index - 1 : $numfaces - 1;
      my $next = ($index > $numfaces - 2) ? 0 : $index + 1;
      my $anglecoords = [$coords->[$prev], $coords->[$index], $coords->[$next]];

      my $rad = ($corners_radius) ? $corners_radius->[$index] : $radius;
      my ($quad_pts) = &roundedAngleCoords($anglecoords, $rad);
      push(@curve_pts, @{$quad_pts});
    }
  }

  return \@curve_pts;

}

#-----------------------------------------------------------------------------------
# Graphics::pathLineCoords
# retourne les coordonnées d'une pathLine
#-----------------------------------------------------------------------------------
# paramètres :
# coords : <coordsList> liste de coordonnées des points du path
# options :
#    -closed : <boolean> ligne fermée
#  -shifting : <out|center|in> sens de décalage du path (par défaut center)
# -linewidth : <dimension> epaisseur de la ligne
#-----------------------------------------------------------------------------------
sub pathLineCoords {
  my ($coords, %options) = @_;
  my $numfaces = scalar(@{$coords});
  my @pts;

  my $closed = $options{'-closed'};
  my $linewidth = ($options{'-linewidth'}) ? $options{'-linewidth'} : 2;
  my $shifting = ($options{'-shifting'}) ? $options{'-shifting'} : 'center';

  return undef if (!$numfaces or $linewidth < 2);

  my $previous = ($closed) ? $coords->[$numfaces - 1] : undef;
  my $next = $coords->[1];
  $linewidth /= 2 if ($shifting eq 'center');

  for (my $i = 0; $i < $numfaces; $i++) {
    my $pt = $coords->[$i];

    if (!$previous) {
      # extrémité de curve sans raccord -> angle plat
      $previous = [$pt->[0] + ($pt->[0] - $next->[0]), $pt->[1] + ($pt->[1] - $next->[1])];
    }

    my ($angle, $bisecangle) = &vertexAngle($previous, $pt, $next);

    # distance au centre du cercle inscrit : rayon/sinus demi-angle
    my $sin = sin(deg2rad($angle/2));
    my $delta = ($sin) ? abs($linewidth / $sin) : $linewidth;

    if ($shifting eq 'out' or $shifting eq 'in') {
      my $adding = ($shifting eq 'out') ? -90 : 90;
      push (@pts,  &rad_point($pt, $delta, $bisecangle + $adding));
      push (@pts,  @{$pt});

    } else {
      push (@pts,  &rad_point($pt, $delta, $bisecangle-90));
      push (@pts,  &rad_point($pt, $delta, $bisecangle+90));

    }

    if ($i == $numfaces - 2) {
      $next = ($closed) ? $coords->[0] :
	[$coords->[$i+1]->[0] + ($coords->[$i+1]->[0] - $pt->[0]), $coords->[$i+1]->[1] + ($coords->[$i+1]->[1] - $pt->[1])];
    } else {
      $next = $coords->[$i+2];
    }

    $previous = $coords->[$i];
  }

  if ($closed) {
    push (@pts, ($pts[0], $pts[1], $pts[2], $pts[3]));
  }

  return \@pts;
}

#-----------------------------------------------------------------------------------
# Graphics::curveLineCoords
# retourne les coordonnées d'une curveLine
#-----------------------------------------------------------------------------------
# paramètres :
# coords : <coordsList> liste de coordonnées des points de la ligne
# options :
#    -closed : <boolean> ligne fermée
#  -shifting : <out|center|in> sens de décalage du contour (par défaut center)
# -linewidth : <dimension> epaisseur de la ligne
#-----------------------------------------------------------------------------------
sub curveLineCoords {
  my ($coords, %options) = @_;
  my $numfaces = scalar(@{$coords});
  my @gopts;
  my @backpts;
  my @pts;

  my $closed = $options{'-closed'};
  my $linewidth = (defined $options{'-linewidth'}) ? $options{'-linewidth'} : 2;
  my $shifting = ($options{'-shifting'}) ? $options{'-shifting'} : 'center';

  return undef if (!$numfaces or $linewidth < 2);

  my $previous = ($closed) ? $coords->[$numfaces - 1] : undef;
  my $next = $coords->[1];
  $linewidth /= 2 if ($shifting eq 'center');

  for (my $i = 0; $i < $numfaces; $i++) {
    my $pt = $coords->[$i];

    if (!$previous) {
      # extrémité de curve sans raccord -> angle plat
      $previous = [$pt->[0] + ($pt->[0] - $next->[0]), $pt->[1] + ($pt->[1] - $next->[1])];
    }

    my ($angle, $bisecangle) = &vertexAngle($previous, $pt, $next);

    # distance au centre du cercle inscrit : rayon/sinus demi-angle
    my $sin = sin(deg2rad($angle/2));
    my $delta = ($sin) ? abs($linewidth / $sin) : $linewidth;

    if ($shifting eq 'out' or $shifting eq 'in') {
      my $adding = ($shifting eq 'out') ? -90 : 90;
      push (@pts,  &rad_point($pt, $delta, $bisecangle + $adding));
      push (@pts,  @{$pt});

    } else {
      @pts = &rad_point($pt, $delta, $bisecangle+90);
      push (@gopts, \@pts);
      @pts = &rad_point($pt, $delta, $bisecangle-90);
      unshift (@backpts, \@pts);
    }

    if ($i == $numfaces - 2) {
      $next = ($closed) ? $coords->[0] :
	[$coords->[$i+1]->[0] + ($coords->[$i+1]->[0] - $pt->[0]), $coords->[$i+1]->[1] + ($coords->[$i+1]->[1] - $pt->[1])];
    } else {
      $next = $coords->[$i+2];
    }

    $previous = $coords->[$i];
  }

  push(@gopts, @backpts);

  if ($closed) {
    push (@gopts, ($gopts[0], $gopts[1]));
  }

  return \@gopts;
}


#-----------------------------------------------------------------------------------
# Graphics::shiftPathCoords
# retourne les coordonnées d'un décalage de path
#-----------------------------------------------------------------------------------
# paramètres :
# coords : <coordsList> liste de coordonnées des points du path
# options :
#   -closed : <boolean> ligne fermée
# -shifting : <'out'|'in'> sens de décalage du path (par défaut out)
#    -width : <dimension> largeur de décalage (par défaut 1)
#-----------------------------------------------------------------------------------
sub shiftPathCoords {
  my ($coords, %options) = @_;
  my $numfaces = scalar(@{$coords});

  my $closed = $options{'-closed'};
  my $width = (defined $options{'-width'}) ? $options{'-width'} : 1;
  my $shifting = ($options{'-shifting'}) ? $options{'-shifting'} : 'out';

  return $coords if (!$numfaces or !$width);

  my @pts;

  my $previous = ($closed) ? $coords->[$numfaces - 1] : undef;
  my $next = $coords->[1];

  for (my $i = 0; $i < $numfaces; $i++) {
    my $pt = $coords->[$i];

    if (!$previous) {
      # extrémité de curve sans raccord -> angle plat
      $previous = [$pt->[0] + ($pt->[0] - $next->[0]), $pt->[1] + ($pt->[1] - $next->[1])];
    }

    my ($angle, $bisecangle) = &vertexAngle($previous, $pt, $next);

    # distance au centre du cercle inscrit : rayon/sinus demi-angle
    my $sin = sin(deg2rad($angle/2));
    my $delta = ($sin) ? abs($width / $sin) : $width;

    my $adding = ($shifting eq 'out') ? -90 : 90;
    my ($x, $y) = &rad_point($pt, $delta, $bisecangle + $adding);
    push (@pts,  [$x, $y]);


    if ($i > $numfaces - 3) {
      my $j = $numfaces - 1;
      $next = ($closed) ? $coords->[0] :
	[$pt->[0] + ($pt->[0] - $previous->[0]), $pt->[1] + ($pt->[1] - $previous->[1])];

    } else {
      $next = $coords->[$i+2];
    }

    $previous = $coords->[$i];
  }

  return \@pts;
}

#-----------------------------------------------------------------------------------
# Graphics::perpendicularPoint
# retourne les coordonnées du point perpendiculaire abaissé d'un point sur une ligne
#-----------------------------------------------------------------------------------
# paramètres :
# point : <coords> coordonnées du point de référence
#  line : <coordsList> coordonnées des 2 points de la ligne de référence
#-----------------------------------------------------------------------------------
sub perpendicularPoint {
  my ($point, $line) = @_;
  my ($p1, $p2) = @{$line};

  # cas partiuculier de lignes ortho.
  my $min_dist = .01;
  if (abs($p2->[1] - $p1->[1]) < $min_dist) {
    # la ligne de référence est horizontale
    return ($point->[0], $p1->[1]);

  } elsif (abs($p2->[0] - $p1->[0]) < $min_dist) {
    # la ligne de référence est verticale
    return ($p1->[0], $point->[1]);
  }

  my $a1 = ($p2->[1] - $p1->[1]) / ($p2->[0] - $p1->[0]);
  my $b1 = $p1->[1] - ($a1 * $p1->[0]);

  my $a2 = -1.0 / $a1;
  my $b2 = $point->[1] - ($a2 * $point->[0]);

  my $x = ($b2 - $b1) / ($a1 - $a2);
  my $y = ($a1 * $x) + $b1;

  return ($x, $y);

}


#-----------------------------------------------------------------------------------
# Graphics::lineAngle
# retourne l'angle d'un point par rapport à un centre de référence
#-----------------------------------------------------------------------------------
# paramètres :
# startpoint : <coords> coordonnées du point de départ du segment
#   endpoint : <coords> coordonnées du point d'extremité du segment
#-----------------------------------------------------------------------------------
sub lineAngle {
  my ($startpoint, $endpoint) = @_;
  my $angle = atan2($endpoint->[1] - $startpoint->[1], $endpoint->[0] - $startpoint->[0]);

  $angle += pi/2;
  $angle *= 180/pi;
  $angle += 360  if ($angle < 0);

  return $angle;

}


#-----------------------------------------------------------------------------------
# Graphics::lineNormal
# retourne la valeur d'angle perpendiculaire à une ligne
#-----------------------------------------------------------------------------------
# paramètres :
# startpoint : <coords> coordonnées du point de départ du segment
#   endpoint : <coords> coordonnées du point d'extremité du segment
#-----------------------------------------------------------------------------------
sub lineNormal {
  my ($startpoint, $endpoint) = @_;
  my $angle = &lineAngle($startpoint, $endpoint) + 90;

  $angle -= 360  if ($angle > 360);
  return $angle;

}



#-----------------------------------------------------------------------------------
# Graphics::vertexAngle
# retourne la valeur de l'angle formée par 3 points
# ainsi que l'angle de la bisectrice
#-----------------------------------------------------------------------------------
# paramètres :
# pt0 : <coords> coordonnées du premier point de définition de l'angle
# pt1 : <coords> coordonnées du deuxième point de définition de l'angle
# pt2 : <coords> coordonnées du troisième point de définition de l'angle
#-----------------------------------------------------------------------------------
sub vertexAngle {
  my ($pt0, $pt1, $pt2) = @_;
  my $angle1 = &lineAngle($pt0, $pt1);
  my $angle2 = &lineAngle($pt2, $pt1);

  $angle2 += 360 if $angle2 < $angle1;
  my $alpha = $angle2 - $angle1;
  my $bisectrice = $angle1 + ($alpha/2);

  return ($alpha, $bisectrice);
}


#-----------------------------------------------------------------------------------
# Graphics::arc_pts
# calcul des points constitutif d'un arc
#-----------------------------------------------------------------------------------
# paramètres :
#  center : <coordonnées> centre de l'arc,
#  radius : <dimension> rayon de l'arc,
# options :
#  -angle : <angle> angle de départ en degré de l'arc (par défaut 0)
# -extent : <angle> delta angulaire en degré de l'arc (par défaut 360),
#   -step : <dimension> pas de progresion en degré (par défaut 10)
#-----------------------------------------------------------------------------------
sub arc_pts {
    my ($center, $radius, %options) = @_;
    return unless ($radius);

    $center = [0, 0] if (!defined $center);
    my $angle = (defined $options{'-angle'}) ? $options{'-angle'} : 0;
    my $extent = (defined $options{'-extent'}) ? $options{'-extent'} : 360;
    my $step = (defined $options{'-step'}) ? $options{'-step'} : 10;
    my @pts = ();

    if ($extent > 0) {
	for (my $alpha = $angle; $alpha <= ($angle + $extent); $alpha += $step) {
	    my ($xn, $yn) = &rad_point($center, $radius,$alpha);
	    push (@pts, ([$xn, $yn]));
	}
    } else {
	for (my $alpha = $angle; $alpha >= ($angle + $extent); $alpha += $step) {
	    push (@pts, &rad_point($center, $radius, $alpha));
	}
    }

    return @pts;
}


#-----------------------------------------------------------------------------------
# Graphics::rad_point
# retourne le point circulaire défini par centre-rayon-angle
#-----------------------------------------------------------------------------------
# paramètres :
# center : <coordonnée> coordonnée [x,y] du centre de l'arc,
# radius : <dimension> rayon de l'arc,
#  angle : <angle> angle du point de circonférence avec le centre du cercle
#-----------------------------------------------------------------------------------
sub rad_point {
    my ($center, $radius, $angle) = @_;
    my $alpha = deg2rad($angle);

    my $xpt = $center->[0] + ($radius * cos($alpha));
    my $ypt = $center->[1] + ($radius * sin($alpha));

    return ($xpt, $ypt);
}


#-----------------------------------------------------------------------------------
# Graphics::curveItem2polylineCoords
# Conversion des coordonnées ZnItem curve (multicontours) en coordonnées polyline(s)
#-----------------------------------------------------------------------------------
# paramètres :
# widget : <widget> identifiant du widget zinc
#   item : <tagOrId> identifiant de l'item source
# options :
# -tunits : <integer> nombre pas de division des segments bezier (par défaut 20)
# -adjust : <boolean> ajustement de la courbe de bezier (par défaut 1)
#-----------------------------------------------------------------------------------
sub curveItem2polylineCoords {
  my ($widget, $item, %options) = @_;
  return unless ($widget and $widget->type($item));

  my @coords;
  my $numcontours = $widget->contour($item);
  my $parentgroup = $widget->group($item);

  for (my $contour = 0; $contour < $numcontours; $contour++) {
    my @points = $widget->coords($item, $contour);
    my @contourcoords = &curve2polylineCoords(\@points, %options);

    push(@coords, \@contourcoords);

  }

  return wantarray ? @coords : \@coords;
}

#-----------------------------------------------------------------------------------
# Graphics::curve2polylineCoords
# Conversion curve -> polygone
#-----------------------------------------------------------------------------------
# paramètres :
# points : <coordsList> liste des coordonnées curve à transformer
# options :
# -tunits : <integer> nombre pas de division des segments bezier (par défaut 20)
# -adjust : <boolean> ajustement de la courbe de bezier (par défaut 1)
#-----------------------------------------------------------------------------------
sub curve2polylineCoords {
  my ($points, %options) = @_;

  my $tunits = ($options{'-tunits'}) ? $options{'-tunits'} : 20;
  my $adjust = (defined $options{'-adjust'}) ? $options{'-adjust'} : 1;

  my @poly;
  my $previous;
  my @bseg;
  my $numseg = 0;
  my $prevtype;

  foreach my $point (@{$points}) {
    my ($x, $y, $c) = @{$point};
    if ($c eq 'c') {
      push(@bseg, $previous) if (!@bseg);
      push(@bseg, $point);

    } else {
      if (@bseg) {
	push(@bseg, $point);

	if ($adjust) {
	  my @pts = &bezierCompute(\@bseg, -skipend => 1);
	  shift @pts;
	  shift @pts;
	  push(@poly, @pts);

	} else {
	  my @pts = &bezierSegment(\@bseg, -tunits => $tunits, -skipend => 1);
	  shift @pts;
	  shift @pts;
	  push(@poly, @pts);

	}

	@bseg = ();
	$numseg++;
	$prevtype = 'bseg';

      } else {
	push(@poly, ([$x, $y]));
	$prevtype = 'line';
      }
    }

    $previous = $point;
  }


  return wantarray ? @poly : \@poly;
}


#-----------------------------------------------------------------------------------
# Graphics::buildTabBoxItem
# construit les items de représentations Zinc d'une boite à onglets
#-----------------------------------------------------------------------------------
# paramètres :
#      widget : <widget> identifiant du widget zinc
# parentgroup : <tagOrId> identifiant de l'item group parent
#
#    options :
#     -coords : <coordsList> coordonnées haut-gauche et bas-droite du rectangle
#               englobant du TabBox
#     -params : <hastable> arguments spécifiques des items curve à passer au widget
#    -texture : <imagefile> ajout d'une texture aux items curve
#  -tabtitles : <hashtable> table de hash de définition des titres onglets
#  -pageitems : <hashtable> table de hash de définition des pages internes
#     -relief : <hashtable> table de hash de définition du relief de forme
#
# (options de construction géometrique passées à tabBoxCoords)
#  -numpages : <integer> nombre de pages (onglets) de la boite
#    -anchor : <'n'|'e'|'s'|'w'> ancrage (positionnement) de la ligne d'onglets
# -alignment : <'left'|'center'|'right'> alignement des onglets sur le coté d'ancrage
#  -tabwidth : <'auto'>|<dimension>|<dimensionList> : largeur des onglets
#              'auto' largeur répartie, les largeurs sont auto-ajustée si besoin.
# -tabheight : <'auto'>|<dimension> : hauteur des onglets
#  -tabshift : <'auto'>|<dimension> offset de 'biseau' entre base et haut de l'onglet (défaut auto)
#    -radius : <dimension> rayon des arrondis d'angle
#   -overlap : <'auto'>|<dimension> offset de recouvrement/séparation entre onglets
#   -corners : <booleanList> liste 'spécifique' des raccords de sommets [0|1]
#-----------------------------------------------------------------------------------
sub buildTabBoxItem {
  my ($widget, $parentgroup, %options) = @_;
  my $coords = $options{'-coords'};
  my $params = $options{'-params'};
  my @tags = @{$params->{'-tags'}};
  my $texture;

  if ($options{'-texture'}) {
    $texture = &getTexture($widget, $options{'-texture'});
  }

  my $titlestyle = $options{'-tabtitles'};
  my $titles = ($titlestyle) ? $titlestyle->{'-text'} : undef ;

  return undef if (!$coords);

  my @tabs;
  my ($shapes, $tcoords, $invert) = &tabBoxCoords($coords, %options);
  my $k = ($invert) ? scalar @{$shapes} : -1;
  foreach my $shape (reverse @{$shapes}) {
    $k += ($invert) ? -1 : +1;
    my $group = $widget->add('group', $parentgroup);
    $params->{'-tags'} = [@tags, $k, 'intercalaire'];
    my $form = $widget->add('curve', $group, $shape, %{$params});
    $widget->itemconfigure($form, -tile => $texture) if $texture;

    if ($options{'-relief'}) {
      &graphicItemRelief($widget, $form, %{$options{'-relief'}});
    }

    if ($options{'-page'}) {
      my $page = &buildZincItem($widget, $group, %{$options{'-page'}});
    }	

    if ($titles) {
      my $tindex = ($invert) ? $k : $#{$shapes} - $k;
      $titlestyle->{'-itemtype'} = 'text';
      $titlestyle->{'-coords'} = $tcoords->[$tindex];
      $titlestyle->{'-params'}->{'-text'} = $titles->[$tindex],;
      $titlestyle->{'-params'}->{'-tags'} = [@tags, $tindex, 'titre'];
      &buildZincItem($widget, $group, %{$titlestyle});

    }


  }

  return @tabs;
}


#-----------------------------------------------------------------------------------
# tabBoxCoords
# Calcul des shapes de boites à onglets
#-----------------------------------------------------------------------------------
# paramètres :
# coords : <coordList> coordonnées haut-gauche bas-droite du rectangle englobant 
#          de la tabbox
# options
#  -numpages : <integer> nombre de pages (onglets) de la boite
#    -anchor : <'n'|'e'|'s'|'w'> ancrage (positionnement) de la ligne d'onglets
# -alignment : <'left'|'center'|'right'> alignement des onglets sur le coté d'ancrage
#  -tabwidth : <'auto'>|<dimension>|<dimensionList> : largeur des onglets
#              'auto' largeur répartie, les largeurs sont auto-ajustée si besoin.
# -tabheight : <'auto'>|<dimension> : hauteur des onglets
#  -tabshift : <'auto'>|<dimension> offset de 'biseau' entre base et haut de l'onglet (défaut auto)
#    -radius : <dimension> rayon des arrondis d'angle
#   -overlap : <'auto'>|<dimension> offset de recouvrement/séparation entre onglets
#   -corners : <booleanList> liste 'spécifique' des raccords de sommets [0|1]
#-----------------------------------------------------------------------------------
sub tabBoxCoords {
  my ($coords, %options) = @_;

  my ($x0, $y0, $xn, $yn) = (@{$coords->[0]}, @{$coords->[1]});
  my (@shapes, @titles_coords);
  my $inverse;

  my @options = keys(%options);
  my $numpages = $options{'-numpages'};

  if (!defined $x0 or !defined $y0 or !defined $xn or !defined $yn or !$numpages) {
    print "Vous devez au minimum spécifier le rectangle englobant et le nombre de pages\n";
    return undef;

  }

  my $anchor = ($options{'-anchor'}) ? $options{'-anchor'} : 'n';
  my $alignment = ($options{'-alignment'}) ? $options{'-alignment'} : 'left';
  my $len = ($options{'-tabwidth'}) ? $options{'-tabwidth'} : 'auto';
  my $thick = ($options{'-tabheight'}) ? $options{'-tabheight'} : 'auto';
  my $biso = ($options{'-tabshift'}) ? $options{'-tabshift'} : 'auto';
  my $radius = ($options{'-radius'}) ? $options{'-radius'} : 0;
  my $overlap = ($options{'-overlap'}) ? $options{'-overlap'} : 0;
  my $corners = $options{'-corners'};
  my $orientation = ($anchor eq 'n' or $anchor eq 's') ? 'horizontal' : 'vertical';
  my $maxwidth = ($orientation eq 'horizontal') ? ($xn - $x0) : ($yn - $y0);
  my $tabswidth = 0;
  my $align = 1;

  if ($len eq 'auto') {
    $tabswidth = $maxwidth;
    $len = ($tabswidth + ($overlap * ($numpages - 1)))/$numpages;

  } else {
    if (ref($len) eq 'ARRAY') {
      foreach my $w (@{$len}) {
	$tabswidth += ($w - $overlap);
      }
      $tabswidth += $overlap;
    } else {
      $tabswidth = ($len * $numpages) - ($overlap * ($numpages - 1));
    }

    if ($tabswidth > $maxwidth) {
      $tabswidth = $maxwidth;
      $len = ($tabswidth + ($overlap * ($numpages - 1)))/$numpages;
    }

    $align = 0 if ($alignment eq 'center' and (($maxwidth - $tabswidth) > $radius));
  }


  if ($thick eq 'auto') {
    $thick = ($orientation eq 'horizontal') ? int(($yn - $y0)/10) : int(($xn - $y0)/10);
    $thick = 10 if ($thick < 10);
    $thick = 40 if ($thick > 40);
  }

  if ($biso eq 'auto') {
    $biso = int($thick/2);
  }

  if (($alignment eq 'right' and $anchor ne 'w') or
      ($anchor eq 'w' and $alignment ne 'right')) {

    if (ref($len) eq 'ARRAY') {
      for (my $p = 0; $p < $numpages; $p++) {
	$len->[$p] *= -1;
      }
    } else {
      $len *= -1;
    }
    $biso *= -1;
    $overlap *= -1;
  }

  my ($biso1, $biso2) = ($alignment eq 'center') ? ($biso/2, $biso/2) : (0, $biso);

  my (@cadre, @tabdxy);
  my ($xref, $yref);
  if ($orientation eq 'vertical') {
    $thick *= -1 if ($anchor eq 'w');
    my ($startx, $endx) = ($anchor eq 'w') ? ($x0, $xn) : ($xn, $x0);
    my ($starty, $endy) = (($anchor eq 'w' and $alignment ne 'right') or 
			   ($anchor eq 'e' and $alignment eq 'right')) ? 
			     ($yn, $y0) : ($y0, $yn);

    $xref = $startx - $thick;
    $yref = $starty;
    if  ($alignment eq 'center') {
      my $ratio = ($anchor eq 'w') ? -2 : 2;
      $yref += (($maxwidth - $tabswidth)/$ratio);
    }

    @cadre = ([$xref, $endy], [$endx, $endy], [$endx, $starty], [$xref, $starty]);

    # flag de retournement de la liste des pts de curve si nécessaire -> sens anti-horaire
    $inverse = ($alignment ne 'right');

  } else {
    $thick *= -1 if ($anchor eq 's');
    my ($startx, $endx) = ($alignment eq 'right') ? ($xn, $x0) : ($x0, $xn);
    my ($starty, $endy) = ($anchor eq 's') ? ($yn, $y0) : ($y0, $yn);


    $yref = $starty + $thick;
    $xref = ($alignment eq 'center') ? $x0 + (($maxwidth - $tabswidth)/2) : $startx;

    @cadre = ([$endx, $yref], [$endx, $endy], [$startx, $endy], [$startx, $yref]);

    # flag de retournement de la liste des pts de curve si nécessaire -> sens anti-horaire
    $inverse = (($anchor eq 'n' and $alignment ne 'right') or ($anchor eq 's' and $alignment eq 'right'));
  }

  for (my $i = 0; $i < $numpages; $i++) {
    my @pts = ();

    # décrochage onglet
    #push (@pts, ([$xref, $yref])) if $i > 0;

    # cadre
    push (@pts, @cadre);

    # points onglets
    push (@pts, ([$xref, $yref])) if ($i > 0 or !$align);

    my $tw = (ref($len) eq 'ARRAY') ? $len->[$i] : $len;
    @tabdxy = ($orientation eq 'vertical') ?
      ([$thick, $biso1],[$thick, $tw - $biso2],[0, $tw]) : ([$biso1, -$thick],[$tw - $biso2, -$thick],[$tw, 0]);
    foreach my $dxy (@tabdxy) {
      push (@pts, ([$xref + $dxy->[0], $yref + $dxy->[1]]));
    }

    if ($radius) {
      if (!defined $options{'-corners'}) {
	$corners = ($i > 0 or !$align) ? [0, 1, 1, 0, 0, 1, 1, 0] : [0, 1, 1, 0, 1, 1, 0, 0, 0];
      }
      my $curvepts = &roundedCurveCoords(\@pts, -radius => $radius, -corners => $corners);
      @{$curvepts} = reverse @{$curvepts} if ($inverse);
      push (@shapes, $curvepts);
    } else {
      @pts = reverse @pts if ($inverse);
      push (@shapes, \@pts);
    }

    if ($orientation eq 'horizontal') {
      push (@titles_coords, [$xref + ($tw - ($biso2 - $biso1))/2, $yref - ($thick/2)]);
      $xref += ($tw - $overlap);

    } else {
      push (@titles_coords, [$xref + ($thick/2), $yref + ($len - (($biso2 - $biso1)/2))/2]);
      $yref += ($len - $overlap);
    }

  }

  return (\@shapes, \@titles_coords, $inverse);

}


#-----------------------------------------------------------------------------------
# Graphics::graphicItemRelief
# construit un relief à l'item Zinc en utilisant des items Triangles
#-----------------------------------------------------------------------------------
# paramètres :
#  widget : <widget> identifiant du widget zinc
#    item : <tagOrId> identifiant de l'item zinc
# options : <hash> table d'options
#     -closed : <boolean> le relief assure la fermeture de forme (défaut 1)
#     -profil : <'rounded'|'flat'> type de profil (defaut 'rounded')
#     -relief : <'raised'|'sunken'> (défaut 'raised')
#       -side : <'inside'|'outside'> relief interne ou externe à la forme (défaut 'inside')
#      -color : <color> couleur du relief (défaut couleur de la forme)
#   -smoothed : <boolean> facettes relief lissées ou non (défaut 1)
# -lightangle : <angle> angle d'éclairage (défaut valeur générale widget)
#      -width : <dimension> 'épaisseur' du relief en pixel
#       -fine : <boolean> mode précision courbe de bezier (défaut 0 : auto-ajustée)
#-----------------------------------------------------------------------------------
sub graphicItemRelief {
  my ($widget, $item, %options) = @_;
  my @items;

  # relief d'une liste d'items -> appel récursif
  if (ref($item) eq 'ARRAY') {
    foreach my $part (@{$item}) {
      push(@items, &graphicItemRelief($widget, $part, %options));
    }

  } else {
    my $itemtype = $widget->type($item);

    return unless ($itemtype);

    my $parentgroup = $widget->group($item);
    my $priority = (defined $options{'-priority'}) ? $options{'-priority'} :
      $widget->itemcget($item, -priority)+1;

    # coords transformés (polyline) de l'item
    my $adjust = !$options{'-fine'};
    foreach my $coords (&ZincItem2CurveCoords($widget, $item, -linear => 1,
					      -realcoords => 1,-adjust => $adjust)) {
      my ($pts, $colors) = &polylineReliefParams($widget, $item, $coords, %options);

      push(@items, $widget->add('triangles', $parentgroup, $pts,
				-priority => $priority,
				-colors => $colors));
    }


    # renforcement du contour
    if ($widget->itemcget($item, -linewidth)) {
      push(@items, $widget->clone($item, -filled => 0, -priority => $priority+1));
    }
  }

  return \@items;
}


#-----------------------------------------------------------------------------------
# Graphics::polylineReliefParams
# retourne la liste des points et des couleurs nécessaires à la construction
# de l'item Triangles du relief
#-----------------------------------------------------------------------------------
# paramètres :
#  widget : <widget> identifiant widget Zinc
#    item : <tagOrId> identifiant item Zinc
# options : <hash> table d'options
#     -closed : <boolean> le relief assure la fermeture de forme (défaut 1)
#     -profil : <'rounded'|'flat'> type de profil (defaut 'rounded')
#     -relief : <'raised'|'sunken'> (défaut 'raised')
#       -side : <'inside'|'outside'> relief interne ou externe à la forme (défaut 'inside')
#      -color : <color> couleur du relief (défaut couleur de la forme)
#   -smoothed : <boolean> facettes relief lissées ou non (défaut 1)
# -lightangle : <angle> angle d'éclairage (défaut valeur générale widget)
#      -width : <dimension> 'épaisseur' du relief en pixel
#-----------------------------------------------------------------------------------
sub polylineReliefParams {
  my ($widget, $item, $coords, %options) = @_;

  my $closed = (defined $options{'-closed'}) ? $options{'-closed'} : 1;
  my $profil = ($options{'-profil'}) ? $options{'-profil'} : 'rounded';
  my $relief = ($options{'-relief'}) ? $options{'-relief'} : 'raised';
  my $side = ($options{'-side'}) ? $options{'-side'} : 'inside';
  my $basiccolor = ($options{'-color'}) ? $options{'-color'} : &zincItemPredominantColor($widget, $item);
  my $smoothed = (defined $options{'-smooth'}) ? $options{'-smooth'} : 1;
  my $lightangle = (defined $options{'-lightangle'}) ? $options{'-lightangle'}
    : $widget->cget('-lightangle');

  my $width = $options{'-width'};
  if (!$width or $width < 1) {
    my ($x0, $y0, $x1, $y1) = $widget->bbox($item);
    $width = &_min($x1 -$x0, $y1 - $y0)/10;
    $width = 2 if ($width < 2);
  }

  my $numfaces = scalar(@{$coords});
  my $previous = ($closed) ? $coords->[$numfaces - 1] : undef;
  my $next = $coords->[1];

  my @pts;
  my @colors;
  my $alpha = 100;
  if ($basiccolor =~ /;/) {
    ($basiccolor, $alpha) = split /;/, $basiccolor;

  }

  $alpha /= 2 if (!($options{'-color'} =~ /;/) and $profil eq 'flat');

  my $reliefalphas = ($profil eq 'rounded') ? [0,$alpha] : [$alpha, $alpha];

  for (my $i = 0; $i < $numfaces; $i++) {
    my $pt = $coords->[$i];

    if (!$previous) {
      # extrémité de curve sans raccord -> angle plat
      $previous = [$pt->[0] + ($pt->[0] - $next->[0]), $pt->[1] + ($pt->[1] - $next->[1])];
    }

    my ($angle, $bisecangle) = &vertexAngle($previous, $pt, $next);

    # distance au centre du cercle inscrit : rayon/sinus demi-angle
    my $sin = sin(deg2rad($angle/2));
    my $delta = ($sin) ? abs($width / $sin) : $width;
    my $decal = ($side eq 'outside') ? -90 : 90;

    my @shift_pt = &rad_point($pt, $delta, $bisecangle+$decal);
    push (@pts,  @shift_pt);
    push (@pts,  @{$pt});

    if (!$smoothed and $i) {
      push (@pts, @shift_pt);
      push (@pts,  @{$pt});
    }

    my $faceangle = 360 -(&lineNormal($previous, $next)+90);

    my $light = abs($lightangle - $faceangle);
    $light = 360 - $light if ($light > 180);
    $light = 1 if $light < 1;

    my $lumratio = ($relief eq 'sunken') ? (180-$light)/180 : $light/180;

    if (!$smoothed and $i) {
      push(@colors, ($colors[-2],$colors[-1]));
    }

   if ($basiccolor) {
     # création des couleurs dérivées
     my $shade = &LightingColor($basiccolor, $lumratio);
     my $color0 = $shade.";".$reliefalphas->[0];
     my $color1 = $shade.";".$reliefalphas->[1];
     push(@colors, ($color0, $color1));

   } else {
      my $c = (255*$lumratio);
      my $color0 = &hexaRGBcolor($c, $c, $c, $reliefalphas->[0]);
      my $color1 = &hexaRGBcolor($c, $c, $c, $reliefalphas->[1]);
      push(@colors, ($color0, $color1));
    }

    if ($i == $numfaces - 2) {
      $next = ($closed) ? $coords->[0] :
	[$coords->[$i+1]->[0] + ($coords->[$i+1]->[0] - $pt->[0]), $coords->[$i+1]->[1] + ($coords->[$i+1]->[1] - $pt->[1])];
    } else {
      $next = $coords->[$i+2];
    }

    $previous = $coords->[$i];
  }

  if ($closed) {
    push (@pts, ($pts[0], $pts[1], $pts[2], $pts[3]));
    push (@colors, ($colors[0], $colors[1]));

    if (!$smoothed) {
      push (@pts, ($pts[0], $pts[1], $pts[2], $pts[3]));
      push (@colors, ($colors[0], $colors[1]));
    }

  }


  return (\@pts, \@colors);
}


#-----------------------------------------------------------------------------------
# Graphics::graphicItemShadow
# Création d'une ombre portée à l'item
#-----------------------------------------------------------------------------------
# paramètres :
#  widget : <widget> identifiant widget Zinc
#    item : <tagOrId> identifiant item Zinc
# options : <hash> table d'options
#    -opacity : <percent> opacité de l'ombre (défaut 50)
#     -filled : <boolean> remplissage totale de l'ombre (hors bordure) (defaut 1)
# -lightangle : <angle> angle d'éclairage (défaut valeur générale widget)
#   -distance : <dimension> distance de projection de l'ombre en pixel
#  -enlarging : <dimension> grossi de l'ombre portée en pixels (defaut 0)
#      -width : <dimension> taille de diffusion/diffraction (défaut 4)
#      -color : <color> couleur de l'ombre portée (défaut black)
#-----------------------------------------------------------------------------------
sub graphicItemShadow {
  my ($widget, $item, %options) = @_;
  my @items;

  # relief d'une liste d'items -> appel récursif
  if (ref($item) eq 'ARRAY') {
    foreach my $part (@{$item}) {
      push(@items, &graphicItemShadow($widget, $part, %options));
    }

    return \@items;

  } else {

    my $itemtype = $widget->type($item);

    return unless ($itemtype);

    # création d'un groupe à l'ombre portée
    my $parentgroup = ($options{'-parentgroup'}) ? $options{'-parentgroup'} :
      $widget->group($item);
    my $priority = (defined $options{'-priority'}) ? $options{'-priority'} :
      ($widget->itemcget($item, -priority))-1;
    $priority = 0 if ($priority < 0);

    my $shadow = $widget->add('group', $parentgroup, -priority => $priority);

    if ($itemtype eq 'text') {
      my $opacity = (defined $options{'-opacity'}) ? $options{'-opacity'} : 50;
      my $color = ($options{'-color'}) ? $options{'-color'} : '#000000';

      my $clone = $widget->clone($item, -color => $color.";".$opacity);
      $widget->chggroup($clone, $shadow);

    } else {

      # création des items (de dessin) de l'ombre
      my $filled = (defined $options{'-filled'}) ? $options{'-filled'} : 1;

      # coords transformés (polyline) de l'item
      foreach my $coords (&ZincItem2CurveCoords($widget, $item, -linear => 1, -realcoords => 1)) {
	my ($t_pts, $i_pts, $colors) = &polylineShadowParams($widget, $item, $coords, %options);

	# option filled : remplissage hors bordure de l'ombre portée (item curve)
	if ($filled) {
	  if (@items) {
	    $widget->contour($items[0], 'add', 0, $i_pts);
	
	  } else {
	    push(@items, $widget->add('curve', $shadow, $i_pts,
				      -linewidth => 0,
				      -filled => 1,
				      -fillcolor => $colors->[0],
				     ));
	  }
	}
	
	# bordure de diffusion de l'ombre (item triangles)
	push(@items, $widget->add('triangles', $shadow, $t_pts,
			      -colors => $colors));
      }
    }

    # positionnement de l'ombre portée
    my $distance = (defined $options{'-distance'}) ? $options{'-distance'} : 10;
    my $lightangle = (defined $options{'-lightangle'}) ? $options{'-lightangle'}
      : $widget->cget('-lightangle');

    my ($dx, $dy) = &rad_point([0, 0], $distance, $lightangle+180);
    $widget->translate($shadow, $dx, -$dy);

    return $shadow;

  }

}


#-----------------------------------------------------------------------------------
# Graphics::polylineShadowParams
# retourne les listes des points et de couleurs nécessaires à la construction des
# items triangles (bordure externe) et curve (remplissage interne) de l'ombre portée
#-----------------------------------------------------------------------------------
# paramètres :
#  widget : <widget> identifiant widget Zinc
#    item : <tagOrId> identifiant item Zinc
# options : <hash> table d'options
#    -opacity : <percent> opacité de l'ombre (défaut 50)
# -lightangle : <angle> angle d'éclairage (défaut valeur générale widget)
#   -distance : <dimension> distance de projection de l'ombre en pixel (défaut 10)
#  -enlarging : <dimension> grossi de l'ombre portée en pixels (defaut 2)
#      -width : <dimension> taille de diffusion/diffraction (défaut distance -2)
#      -color : <color> couleur de l'ombre portée (défaut black)
#-----------------------------------------------------------------------------------
sub polylineShadowParams {
  my ($widget, $item, $coords, %options) = @_;

  my $distance = (defined $options{'-distance'}) ? $options{'-distance'} : 10;
  my $width = (defined $options{'-width'}) ? $options{'-width'} : $distance-2;
  my $opacity = (defined $options{'-opacity'}) ? $options{'-opacity'} : 50;
  my $color = ($options{'-color'}) ? $options{'-color'} : '#000000';
  my $enlarging = (defined $options{'-enlarging'}) ? $options{'-enlarging'} : 2;

  if ($enlarging) {
    $coords = &shiftPathCoords($coords, -width => $enlarging, -closed => 1, -shifting => 'out');
  }

  my $numfaces = scalar(@{$coords});
  my $previous = $coords->[$numfaces - 1];
  my $next = $coords->[1];

  my @t_pts;
  my @i_pts;
  my @colors;
  my ($color0, $color1) = ($color.";$opacity", $color.";0");

  for (my $i = 0; $i < $numfaces; $i++) {
    my $pt = $coords->[$i];

    if (!$previous) {
      # extrémité de curve sans raccord -> angle plat
      $previous = [$pt->[0] + ($pt->[0] - $next->[0]), $pt->[1] + ($pt->[1] - $next->[1])];
    }

    my ($angle, $bisecangle) = &vertexAngle($previous, $pt, $next);

    # distance au centre du cercle inscrit : rayon/sinus demi-angle
    my $sin = sin(deg2rad($angle/2));
    my $delta = ($sin) ? abs($width / $sin) : $width;
    my $decal = 90;

    my @shift_pt = &rad_point($pt, $delta, $bisecangle+$decal);
    push (@i_pts,  @shift_pt);
    push (@t_pts,  @shift_pt);
    push (@t_pts,  @{$pt});

    push(@colors, ($color0, $color1));

    if ($i == $numfaces - 2) {
      $next = $coords->[0];
    } else {
      $next = $coords->[$i+2];
    }

    $previous = $coords->[$i];
  }

  # fermeture
  push(@t_pts, ($t_pts[0], $t_pts[1],$t_pts[2],$t_pts[3]));
  push(@i_pts, ($t_pts[0], $t_pts[1]));
  push(@colors, ($color0, $color1,$color0,$color1));

  return (\@t_pts, \@i_pts, \@colors);
}


#-----------------------------------------------------------------------------------
# Graphics::bezierSegment
# Calcul d'une approximation de segment (Quadratique ou Cubique) de bezier
#-----------------------------------------------------------------------------------
# paramètres :
#    points : <[P1, C1, <C1>, P2]> liste des points définissant le segment de bezier
#
# options :
#  -tunits : <integer> nombre pas de division des segments bezier (par défaut 20)
# -skipend : <boolean> : ne pas retourner le dernier point du segment (chainage)
#-----------------------------------------------------------------------------------
sub bezierSegment {
  my ($coords, %options) = @_;
  my $tunits = ($options{'-tunits'}) ? $options{'-tunits'} : 20;
  my $skipendpt = $options{'-skipend'};

  my @pts;

  my $lastpt = ($skipendpt) ? $tunits-1 : $tunits;
  foreach (my $i = 0; $i <= $lastpt; $i++) {
    my $t = ($i) ? ($i/$tunits) : $i;
    push(@pts, &bezierPoint($t, $coords));
  }

  return wantarray ? @pts : \@pts;

}


#-----------------------------------------------------------------------------------
# Graphics::bezierPoint
# calcul d'un point du segment (Quadratique ou Cubique) de bezier
# params :
# t = <n> (représentation du temps : de 0 à 1)
# coords = (P1, C1, <C1>, P2) liste des points définissant le segment de bezier
# P1 et P2 : extémités du segment et pts situés sur la courbe
# C1 <C2> : point(s) de contrôle du segment
#-----------------------------------------------------------------------------------
# courbe bezier niveau 2 sur (P1, P2, P3)
# P(t) = (1-t)²P1 + 2t(1-t)P2 + t²P3
#
# courbe bezier niveau 3 sur (P1, P2, P3, P4)
# P(t) = (1-t)³P1 + 3t(1-t)²P2 + 3t²(1-t)P3 + t³P4
#-----------------------------------------------------------------------------------
sub bezierPoint {
  my ($t, $coords) = @_;
  my ($p1, $c1, $c2, $p2) = @{$coords};

  # quadratique
  if (!defined $p2) {
    $p2 = $c2;
    $c2 = undef;
  }

  # extrémités : points sur la courbe
  return wantarray ? @{$p1} : $p1 if (!$t);
  return wantarray ? @{$p2} : $p2 if ($t >= 1.0);


  my $t2 = $t * $t;
  my $t3 = $t2 * $t;
  my @pt;

  # calcul pour x et y
  foreach my $i (0, 1) {

    if (defined $c2) {
      my $r1 = (1 - (3*$t) + (3*$t2) -    $t3)  * $p1->[$i];
      my $r2 = (    (3*$t) - (6*$t2) + (3*$t3)) * $c1->[$i];
      my $r3 = (             (3*$t2) - (3*$t3)) * $c2->[$i];
      my $r4 = (                          $t3)  * $p2->[$i];

      $pt[$i] = ($r1 + $r2 + $r3 + $r4);

    } else {
      my $r1 = (1 - (2*$t) +    $t2)  * $p1->[$i];
      my $r2 = (    (2*$t) - (2*$t2)) * $c1->[$i];
      my $r3 = (                $t2)  * $p2->[$i];

      $pt[$i] = ($r1 + $r2 + $r3);
    }
  }

  #return wantarray ? @pt : \@pt;
  return \@pt;

}


#-----------------------------------------------------------------------------------
# Graphics::bezierCompute
# Retourne une liste de coordonnées décrivant un segment de bezier
#-----------------------------------------------------------------------------------
# paramètres :
#     coords : <coordsList> liste des points définissant le segment de bezier
#
# options :
# -precision : <dimension> seuil limite du calcul d'approche de la courbe
#   -skipend : <boolean> : ne pas retourner le dernier point du segment (chaînage bezier)
#-----------------------------------------------------------------------------------
sub bezierCompute {
  my ($coords, %options) = @_;
  my $precision = ($options{'-precision'}) ? $options{'-precision'} : $bezierClosenessThreshold;
  my $lastit = [];

  &subdivideBezier($coords, $lastit, $precision);

  push(@{$lastit}, $coords->[3]) if (!$options{'-skipend'});

  return wantarray ? @{$lastit} : $lastit;
}

#------------------------------------------------------------------------------------
# Graphics::smallEnought
# intégration code Stéphane Conversy : calcul points bezier (précision auto ajustée)
#------------------------------------------------------------------------------------
# distance is something like num/den with den=sqrt(something)
# what we want is to test that distance is smaller than precision,
# so we have distance < precision ?  eq. to distance^2 < precision^2 ?
# eq. to (num^2/something) < precision^2 ?
# eq. to num^2 < precision^2*something
# be careful with huge values though (hence 'long long')
# with common values: 9add 9mul
#------------------------------------------------------------------------------------
sub smallEnoughBezier {
  my ($bezier, $precision) = @_;
  my ($x, $y) = (0, 1);
  my ($A, $B) = ($bezier->[0], $bezier->[3]);

  my $den = (($A->[$y]-$B->[$y])*($A->[$y]-$B->[$y])) + (($B->[$x]-$A->[$x])*($B->[$x]-$A->[$x]));
  my $p = $precision*$precision;

  # compute distance between P1|P2 and P0|P3
  my $M = $bezier->[1];
  my $num1 = (($M->[$x]-$A->[$x])*($A->[$y]-$B->[$y])) + (($M->[$y]-$A->[$y])*($B->[$x]-$A->[$x]));

  $M = $bezier->[2];
  my $num2 = (($M->[$x]-$A->[$x])*($A->[$y]-$B->[$y])) + (($M->[$y]-$A->[$y])*($B->[$x]-$A->[$x]));

  # take the max
  $num1 = $num2 if ($num2 > $num1);

  return ($p*$den > ($num1*$num1)) ? 1 : 0;

}

#-----------------------------------------------------------------------------------
# Graphics::subdivideBezier
# subdivision d'une courbe de bezier
#-----------------------------------------------------------------------------------
sub subdivideBezier {
  my ($bezier, $it, $precision, $integeropt) = @_;
  my ($b0, $b1, $b2, $b3) = @{$bezier};

  if (&smallEnoughBezier($bezier, $precision)) {
    push(@{$it}, ([$b0->[0],$b0->[1]]));

  } else {
    my ($left, $right);

    foreach my $i (0, 1) {

      if ($integeropt) {
	# int optimized (6+3=9)add + (5+3=8)shift

	$left->[0][$i] = $b0->[$i];
	$left->[1][$i] = ($b0->[$i] + $b1->[$i]) >> 1;
	$left->[2][$i] = ($b0->[$i] + $b2->[$i] + ($b1->[$i] << 1)) >> 2; # keep precision
	my $tmp = ($b1->[$i] + $b2->[$i]);
	$left->[3][$i] = ($b0->[$i] + $b3->[$i] + ($tmp << 1) + $tmp) >> 3;

	$right->[3][$i] = $b3->[$i];
	$right->[2][$i] = ($b3->[$i] + $b2->[$i]) >> 1;
	$right->[1][$i] = ($b3->[$i] + $b1->[$i] + ($b2->[$i] << 1) ) >> 2; # keep precision
	$right->[0][$i] = $left->[3]->[$i];

      } else {
	# float

	$left->[0][$i] = $b0->[$i];
	$left->[1][$i] = ($b0->[$i] + $b1->[$i]) / 2;
	$left->[2][$i] = ($b0->[$i] + (2*$b1->[$i]) + $b2->[$i]) / 4;
	$left->[3][$i] = ($b0->[$i] + (3*$b1->[$i]) + (3*$b2->[$i]) + $b3->[$i]) / 8;

	$right->[3][$i] = $b3->[$i];
	$right->[2][$i] = ($b3->[$i] + $b2->[$i]) / 2;
	$right->[1][$i] = ($b3->[$i] + (2*$b2->[$i]) + $b1->[$i]) / 4;
	$right->[0][$i] = ($b3->[$i] + (3*$b2->[$i]) + (3*$b1->[$i]) + $b0->[$i]) / 8;

      }
    }

    &subdivideBezier($left, $it, $precision, $integeropt);
    &subdivideBezier($right, $it, $precision, $integeropt);

  }
}



#-----------------------------------------------------------------------------------
# RESOURCES GRAPHIQUES PATTERNS, TEXTURES, IMAGES, GRADIENTS, COULEURS...
#-----------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------
# Graphics::getPattern
# retourne la ressource bitmap en l'initialisant si première utilisation
#-----------------------------------------------------------------------------------
# paramètres :
# filename : nom du fichier bitmap pattern
# options
# -storage : <hastable> référence de la table de stockage de patterns
#-----------------------------------------------------------------------------------
sub getPattern {
  my ($filename, %options) = @_;
  my $table = (defined $options{'-storage'} and ref($options{'-storage'}) eq 'HASH') ? 
    $options{'-storage'} : \%bitmaps;

  if (!exists($table->{$filename})) {
    my $bitmap = '@'.Tk::findINC($filename);
    $table->{$filename} = $bitmap if $bitmap;

  }

  return $table->{$filename};
}

#-----------------------------------------------------------------------------------
# Graphics::getTexture
# retourne l'image de texture en l'initialisant si première utilisation
#-----------------------------------------------------------------------------------
# paramètres :
#   widget : <widget> identifiant du widget zinc
# filename : nom du fichier texture
# options
# -storage : <hastable> référence de la table de stockage de textures
#-----------------------------------------------------------------------------------
sub getTexture {
  my ($widget, $filename, %options) = @_;
  my $table = (defined $options{'-storage'} and ref($options{'-storage'}) eq 'HASH') ? 
    $options{'-storage'} : \%textures;

  return &getImage($widget, $filename, -storage => $table);

}

#-----------------------------------------------------------------------------------
# Graphics::getImage
# retourne la ressource image en l'initialisant si première utilisation
#-----------------------------------------------------------------------------------
# paramètres :
#   widget : <widget> identifiant du widget zinc
# filename : nom du fichier image
# options
# -storage : <hastable> référence de la table de stockage d'images
#-----------------------------------------------------------------------------------
sub getImage {
  my ($widget, $filename, %options) = @_;
  my $table = (defined $options{'-storage'} and ref($options{'-storage'}) eq 'HASH') ? 
    $options{'-storage'} : \%images;

  if (!exists($table->{$filename})) {
    my $image;
    if ($filename =~ /.png|.PNG/) {
      $image = $widget->Photo(-format => 'png', -file => Tk::findINC($filename));

    } elsif ($filename =~ /.jpg|.JPG|.jpeg|.JPEG/) {
      $image = $widget->Photo(-format => 'jpeg', -file => Tk::findINC($filename));

    } else {
      $image = $widget->Photo(-file => Tk::findINC($filename));
    }

    $table->{$filename} = $image if $image;

  }

  return $table->{$filename};

}


#-----------------------------------------------------------------------------------
# Graphics::init_pixmaps
# initialise une liste de fichier image
#-----------------------------------------------------------------------------------
# paramètres :
#    widget : <widget> identifiant du widget zinc
# filenames : <filenameList> list des noms des fichier image
# options
#  -storage : <hastable> référence de la table de stockage d'images
#-----------------------------------------------------------------------------------
sub init_pixmaps {
  my ($widget, $filenames, %options) = @_;
  my @imgs = ();

  my @files = (ref($filenames) eq 'ARRAY') ? @{$filenames} : ($filenames);

  foreach (@files) {
    push(@imgs, &getImage($widget, $_, %options));
  }

  return @imgs;
}


#-----------------------------------------------------------------------------------
# Graphics::_min
# retourne la plus petite valeur entre 2 valeurs
#-----------------------------------------------------------------------------------
sub _min {
  my ($n1, $n2) = @_;
  my $mini = ($n1 > $n2) ? $n2 : $n1;
  return $mini;

}

#-----------------------------------------------------------------------------------
# Graphics::_max
# retourne la plus grande valeur entre 2 valeurs
#-----------------------------------------------------------------------------------
sub _max {
  my ($n1, $n2) = @_;
  my $maxi = ($n1 > $n2) ? $n1 : $n2;
  return $maxi;

}

#-----------------------------------------------------------------------------------
# Graphics::_trunc
# fonction interne de troncature des nombres: n = position décimale 
#-----------------------------------------------------------------------------------
sub _trunc {
  my ($val, $n) = @_;
  my $str;
  my $dec;

  ($val) =~ /([0-9]+)\.?([0-9]*)/;
  $str = ($val < 0) ? "-$1" : $1;

  if (($2 ne "") && ($n != 0)) {
    $dec = substr($2, 0, $n);
    if ($dec != 0) {
      $str = $str . "." . $dec;
    }
  }
  return $str;
}

#-----------------------------------------------------------------------------------
# Graphics::setGradients
# création de gradient nommés Zinc
#-----------------------------------------------------------------------------------
# paramètres :
#   widget : <widget> identifiant du widget zinc
#    grads : <hastable> table de hash de définition de couleurs zinc
#-----------------------------------------------------------------------------------
sub setGradients {
  my ($widget, $grads) = @_;

  # initialise les gradients de taches
  unless (@Gradients) {
    while (my ($name, $gradient) = each( %{$grads})) {
      # création des gradients nommés
      $widget->gname($gradient, $name);
      push(@Gradients, $name);
    }
  }
}


#-----------------------------------------------------------------------------------
# Graphics::RGB_dec2hex
# conversion d'une couleur RGB (255,255,255) au format Zinc '#ffffff'
#-----------------------------------------------------------------------------------
# paramètres :
#  rgb : <rgbColorList> liste de couleurs au format RGB
#-----------------------------------------------------------------------------------
sub RGB_dec2hex {
   my (@rgb) = @_;
   return (sprintf("#%04x%04x%04x", @rgb));
}

#-----------------------------------------------------------------------------------
# Graphics::pathGraduate
# création d'un jeu de couleurs dégradées pour item pathLine
#-----------------------------------------------------------------------------------
sub pathGraduate {
  my ($widget, $numcolors, $style) = @_;

  my $type = $style->{'-type'};
  my $triangles_colors;

  if ($type eq 'linear') {
    return &createGraduate($widget, $numcolors, $style->{'-colors'}, 2);

  } elsif ($type eq 'double') {
    my $colors1 = &createGraduate($widget, $numcolors/2+1, $style->{'-colors'}->[0]);
    my $colors2 = &createGraduate($widget, $numcolors/2+1, $style->{'-colors'}->[1]);
    my @colors;
    for (my $i = 0; $i <= $numcolors; $i++) {
      push(@colors, ($colors1->[$i], $colors2->[$i]));
    }

    return \@colors;

  } elsif ($type eq 'transversal') {
    my ($c1, $c2) = @{$style->{'-colors'}};
    my @colors = ($c1, $c2);
    for (my $i = 0; $i < $numcolors; $i++) {
      push(@colors, ($c1, $c2));
    }

    return \@colors;
  }
}

#-----------------------------------------------------------------------------------
# Graphics::createGraduate
# création d'un jeu de couleurs intermédiaires (dégradé) entre n couleurs
#-----------------------------------------------------------------------------------
sub createGraduate {
  my ($widget, $totalsteps, $refcolors, $repeat) = @_;
  my @colors;

  $repeat = 1 if (!$repeat);
  my $numgraduates = scalar @{$refcolors} - 1;

  if ($numgraduates < 1) {
    print "Le dégradé necessite au minimum 2 couleurs de référence...\n";
    return undef;
  }

  my $steps = ($numgraduates > 1) ? $totalsteps/($numgraduates -1) : $totalsteps;

  for (my $c = 0; $c < $numgraduates; $c++) {
    my ($c1, $c2) = ($refcolors->[$c], $refcolors->[$c+1]);

    for (my $i = 0 ; $i < $steps ; $i++) {
      my $color = MedianColor($c1, $c2, $i/($steps-1));
      for (my $k = 0; $k < $repeat; $k++) {
	push (@colors, $color);
      }
    }

    if ($c < $numgraduates - 1) {
      for (my $k = 0; $k < $repeat; $k++) {
	pop @colors;
      }
    }
  }

  return \@colors;
}

#-----------------------------------------------------------------------------------
# Graphics::LightingColor
# modification d'une couleur par sa composante luminosité
#-----------------------------------------------------------------------------------
# paramètres :
#  color : <color> couleur au format zinc
#   newL : <pourcent> (de 0 à 1) nouvelle valeur de luminosité
#-----------------------------------------------------------------------------------
sub LightingColor {
    my ($color, $newL) = @_;
    my ($H, $L, $S);

    if ($color and $newL) {
      my ($RGB) = &hexa2RGB($color);
      ($H, $L, $S) = @{&RGBtoHLS(@{$RGB})};


      $newL = 1 if $newL > 1;		
      my ($nR, $nG, $nB) = @{&HLStoRGB($H, $newL, $S)};
      return &hexaRGBcolor($nR*255, $nG*255, $nB*255);
	
    }

    return undef;
}


#-----------------------------------------------------------------------------------
# Graphics::zincItemPredominantColor
# retourne la couleur dominante d'un item ('barycentre' gradiant fillcolor)
#-----------------------------------------------------------------------------------
# paramètres :
#  widget : <widget> identifiant du widget zinc
#    item : <tagOrId> identifiant de l'item zinc
#-----------------------------------------------------------------------------------
sub zincItemPredominantColor {
  my ($widget, $item) = @_;
  my $type = $widget->type($item);

  if ($type eq 'text' or '$type' eq 'icon') {
    return $widget->itemcget($item, -color);

  } elsif ($type eq 'triangles' or
	   $type eq 'rectangle' or
	   $type eq 'arc' or
	   $type eq 'curve') {

    my @colors;

    if ($type eq 'triangles') {
      @colors =  $widget->itemcget($item, -colors);

    } else {
      my $grad =  $widget->itemcget($item, -fillcolor);
      
      return $grad if (scalar (my @unused = (split / /, $grad)) < 2);
	
      my @colorparts = split /\|/, $grad;
      foreach my $section (@colorparts) {
	if ($section !~ /=/) {
	  my ($color, $director, $position) = split / /, $section;
	  push (@colors, $color);
	}
      }
    }
	

    my ($Rs, $Gs, $Bs, $As, $numcolors) = (0, 0, 0, 0, 0);
    foreach my $color (@colors) {
      my ($r, $g, $b, $a) = ZnColorToRGB($color);
      $Rs += $r;
      $Gs += $g;
      $Bs += $b;
      $As += $a;
      $numcolors++;
    }

    my $newR = int($Rs/$numcolors);
    my $newG = int($Gs/$numcolors);
    my $newB = int($Bs/$numcolors);
    my $newA = int($As/$numcolors);

    my $newcolor = &hexaRGBcolor($newR, $newG, $newB, $newA);

    return $newcolor

  } else {
    return '#777777';
  }
}

#-----------------------------------------------------------------------------------
# Graphics::MedianColor
# calcul d'une couleur intermédiaire défini par un ratio ($rate) entre 2 couleurs
#-----------------------------------------------------------------------------------
# paramètres :
#  color1 : <color> première couleur zinc
#  color2 : <color> seconde couleur zinc
#    rate : <pourcent> (de 0  à 1) position de la couleur intermédiaire
#-----------------------------------------------------------------------------------
sub MedianColor {
  my ($color1, $color2, $rate) = @_;
  $rate = 1 if ($rate > 1);
  $rate = 0 if ($rate < 0);

  my ($r0, $g0, $b0, $a0) = &ZnColorToRGB($color1);
  my ($r1, $g1, $b1, $a1) = &ZnColorToRGB($color2);

  my $r = $r0 + int(($r1 - $r0) * $rate);
  my $g = $g0 + int(($g1 - $g0) * $rate);
  my $b = $b0 + int(($b1 - $b0) * $rate);
  my $a = $a0 + int(($a1 - $a0) * $rate);

  return &hexaRGBcolor($r, $g, $b, $a);
}


#-----------------------------------------------------------------------------------
# Graphics::ZnColorToRGB
# conversion d'une couleur Zinc au format RGBA (255,255,255,100)
#-----------------------------------------------------------------------------------
# paramètres :
#  zncolor : <color> couleur au format hexa zinc (#ffffff ou #ffffffffffff)
#-----------------------------------------------------------------------------------
sub ZnColorToRGB {
  my ($zncolor) = @_;

  my ($color, $alpha) = split /;/, $zncolor;
  my $ndigits = (length($color) > 8) ? 4 : 2;
  my $R = hex(substr($color, 1, $ndigits));
  my $G = hex(substr($color, 1+$ndigits, $ndigits));
  my $B = hex(substr($color, 1+($ndigits*2), $ndigits));

  $alpha = 100 if (!defined $alpha or $alpha eq "");

  return ($R, $G, $B, $alpha);

}

#-----------------------------------------------------------------------------------
# ALGORYTHMES DE CONVERSION ENTRE ESPACES DE COULEURS
#-----------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------
# Graphics::RGBtoLCH
# Algorythme de conversion RGB -> CIE LCH°
#-----------------------------------------------------------------------------------
# paramètres :
#  r : <pourcent> (de 0 à 1) valeur de la composante rouge de la couleur RGB
#  g : <pourcent> (de 0 à 1) valeur de la composante verte de la couleur RGB
#  b : <pourcent> (de 0 à 1) valeur de la composante bleue de la couleur RGB
#-----------------------------------------------------------------------------------
sub  RGBtoLCH {
  my ($r, $g, $b) = @_;

  # Conversion RGBtoXYZ
  my $gamma = 2.4;
  my $rgblimit = 0.03928;


  $r = ($r > $rgblimit) ? (($r + 0.055)/1.055)**$gamma : $r / 12.92;
  $g = ($g > $rgblimit) ? (($g + 0.055)/1.055)**$gamma : $g / 12.92;
  $b = ($b > $rgblimit) ? (($b + 0.055)/1.055)**$gamma : $b / 12.92;

  $r *= 100;
  $g *= 100;
  $b *= 100;

  my $X = (0.4124 * $r) + (0.3576 * $g) + (0.1805 * $b);
  my $Y = (0.2126 * $r) + (0.7152 * $g) + (0.0722 * $b);
  my $Z = (0.0193 * $r) + (0.1192 * $g) + (0.9505 * $b);


  # Conversion XYZtoLab
  $gamma = 1/3;
  my ($L, $A, $B);

  if ($Y == 0) {
    ($L, $A, $B) = (0, 0, 0);

  } else {

    my ($Xs, $Ys, $Zs) = ($X/$Xw, $Y/$Yw, $Z/$Zw);
	
    $Xs = ($Xs > 0.008856) ? $Xs**$gamma : (7.787 * $Xs) + (16/116);
    $Ys = ($Ys > 0.008856) ? $Ys**$gamma : (7.787 * $Ys) + (16/116);
    $Zs = ($Zs > 0.008856) ? $Zs**$gamma : (7.787 * $Zs) + (16/116);

    $L = (116.0 * $Ys) - 16.0;

    $A = 500 * ($Xs - $Ys);
    $B = 200 * ($Ys - $Zs);

  }

  # conversion LabtoLCH 
  my ($C, $H);


  if ($A == 0) {
    $H = 0;

  } else {

    $H = atan2($B, $A);
	
    if ($H > 0) {
      $H = ($H / pi) * 180;

    } else {
      $H = 360 - ( abs($H) / pi) * 180
    }
  }


  $C = sqrt($A**2 + $B**2);

  return [$L, $C, $H];

}


#-----------------------------------------------------------------------------------
# Graphics::LCHtoRGB
# Algorythme de conversion CIE L*CH -> RGB
#-----------------------------------------------------------------------------------
# paramètres :
#  L : <pourcent> (de 0 à 1) valeur de la composante luminosité de la couleur CIE LCH
#  C : <pourcent> (de 0 à 1) valeur de la composante saturation de la couleur CIE LCH
#  H : <pourcent> (de 0 à 1) valeur de la composante teinte de la couleur CIE LCH
#-----------------------------------------------------------------------------------
sub LCHtoRGB {
  my ($L, $C, $H) = @_;
  my ($a, $b);

  # Conversion LCHtoLab
  $a = cos( deg2rad($H)) * $C;
  $b = sin( deg2rad($H)) * $C;

  # Conversion LabtoXYZ
  my $gamma = 3;
  my ($X, $Y, $Z);

  my $Ys = ($L + 16.0) / 116.0;
  my $Xs = ($a / 500) + $Ys;
  my $Zs = $Ys - ($b / 200);


  $Ys = (($Ys**$gamma) > 0.008856) ? $Ys**$gamma : ($Ys - 16 / 116) / 7.787;
  $Xs = (($Xs**$gamma) > 0.008856) ? $Xs**$gamma : ($Xs - 16 / 116) / 7.787;
  $Zs = (($Zs**$gamma) > 0.008856) ? $Zs**$gamma : ($Zs - 16 / 116) / 7.787;


  $X = $Xw * $Xs;
  $Y = $Yw * $Ys;
  $Z = $Zw * $Zs;

  # Conversion XYZtoRGB
  $gamma = 1/2.4;
  my $rgblimit = 0.00304;
  my ($R, $G, $B);


  $X /= 100;
  $Y /= 100;
  $Z /= 100;

  $R = (3.2410 * $X) + (-1.5374 * $Y) + (-0.4986 * $Z);
  $G = (-0.9692 * $X) + (1.8760 * $Y) + (0.0416 * $Z);
  $B = (0.0556 * $X) + (-0.2040 * $Y) + (1.0570 * $Z);

  $R = ($R > $rgblimit) ? (1.055 * ($R**$gamma)) - 0.055 : (12.92 * $R);
  $G = ($G > $rgblimit) ? (1.055 * ($G**$gamma)) - 0.055 : (12.92 * $G);
  $B = ($B > $rgblimit) ? (1.055 * ($B**$gamma)) - 0.055 : (12.92 * $B);

  $R = ($R < 0) ? 0 : ($R > 1.0) ? 1.0 : &_trunc($R, 5);
  $G = ($G < 0) ? 0 : ($G > 1.0) ? 1.0 : &_trunc($G, 5);
  $B = ($B < 0) ? 0 : ($B > 1.0) ? 1.0 : &_trunc($B, 5);

  return [$R, $G, $B];

}

#-----------------------------------------------------------------------------------
# Graphics::RGBtoHLS
# Algorythme de conversion RGB -> HLS
#-----------------------------------------------------------------------------------
#  r : <pourcent> (de 0 à 1) valeur de la composante rouge de la couleur RGB
#  g : <pourcent> (de 0 à 1) valeur de la composante verte de la couleur RGB
#  b : <pourcent> (de 0 à 1) valeur de la composante bleue de la couleur RGB
#-----------------------------------------------------------------------------------
sub RGBtoHLS {
  my ($r, $g, $b) = @_;
  my ($H, $L, $S);
  my ($min, $max, $diff);


  $max = &max($r,$g,$b);
  $min = &min($r,$g,$b);

  # calcul de la luminosité
  $L = ($max + $min) / 2;

  # calcul de la saturation
  if ($max == $min) {
    # couleur a-chromatique (gris) $r = $g = $b
    $S = 0;
    $H = undef;

    return [$H, $L, $S];
  }

  # couleurs "Chromatiques" --------------------

  # calcul de la saturation
  if ($L <= 0.5) {
    $S = ($max - $min) / ($max + $min);

  } else {
    $S = ($max - $min) / (2 - $max - $min);

  }

  # calcul de la teinte
  $diff = $max - $min;

  if ($r == $max) {
    # couleur entre jaune et magenta
    $H = ($g - $b) / $diff;

  } elsif ($g == $max) {
    # couleur entre cyan et jaune
    $H = 2 + ($b - $r) / $diff;

  } elsif ($b == $max) {
    # couleur entre magenta et cyan
    $H = 4 + ($r - $g) / $diff;
  }

  # Conversion en degrés
  $H *= 60;

  # pour éviter une valeur négative
  if ($H < 0.0) {
    $H += 360;
  }

  return [$H, $L, $S];

}


#-----------------------------------------------------------------------------------
# Graphics::HLStoRGB
# Algorythme de conversion HLS -> RGB
#-----------------------------------------------------------------------------------
# paramètres :
#  H : <pourcent> (de 0 à 1) valeur de la composante teinte de la couleur HLS
#  L : <pourcent> (de 0 à 1) valeur de la composante luminosité de la couleur HLS
#  S : <pourcent> (de 0 à 1) valeur de la composante saturation de la couleur HLS
#-----------------------------------------------------------------------------------
sub HLStoRGB {
  my ($H, $L, $S) = @_;
  my ($R, $G, $B);
  my ($p1, $p2);


  if ($L <= 0.5) { 
    $p2 = $L + ($L * $S);
	
  } else {
    $p2 = $L + $S - ($L * $S);

  }

  $p1 = 2.0 * $L - $p2;

  if ($S == 0) {
    # couleur a-chromatique (gris)
    # $R = $G = $B = $L
    $R = $L;
    $G = $L;
    $B = $L;

  } else {
    # couleurs "Chromatiques"
    $R = &hlsValue($p1, $p2, $H + 120);
    $G = &hlsValue($p1, $p2, $H);
    $B = &hlsValue($p1, $p2, $H - 120);
	
  }

  return [$R, $G, $B];

}

#-----------------------------------------------------------------------------------
# Graphics::hlsValue (sous fonction interne HLStoRGB)
#-----------------------------------------------------------------------------------
sub hlsValue {
  my ($q1, $q2, $hue) = @_;
  my $value;

  $hue = &r_modp($hue, 360);

  if ($hue < 60) { 
    $value = $q1 + ($q2 - $q1) * $hue / 60;

  } elsif ($hue < 180) { 
    $value = $q2;

  } elsif ($hue < 240) { 
    $value = $q1 + ($q2 - $q1) * (240 - $hue) / 60;

  } else {
    $value = $q1;

  }

  return $value;

}


#-----------------------------------------------------------------------------------
# Graphics::hexaRGBcolor
# conversion d'une couleur RGB (255,255,255) au format Zinc '#ffffff'
#-----------------------------------------------------------------------------------
sub hexaRGBcolor {
   my ($r, $g, $b, $a) = @_;

   if (defined $a) {
     my $hexacolor = sprintf("#%02x%02x%02x", ($r, $g, $b));
     return ($hexacolor.";".$a);
   }

   return (sprintf("#%02x%02x%02x", ($r, $g, $b)));
}



sub hexa2RGB {
  my ($hexastr) = @_;
  my ($r, $g, $b);

  if ($hexastr =~ /(\w\w)(\w\w)(\w\w)/) {
    $r = hex($1);
    $g = hex($2);
    $b = hex($3);

    return [$r/255, $g/255, $b/255] if (defined $r and defined $g and defined $b);

  }

  return undef;
}

#-----------------------------------------------------------------------------------
# Graphics::max
# renvoie la valeur maximum d'une liste de valeurs
#-----------------------------------------------------------------------------------
sub max {
  my (@values) = @_;
  return undef if !scalar(@values);

  my $max = undef;

  foreach my $val (@values) {
    if (!defined $max or $val > $max) {
      $max = $val;
    }
  }

  return $max;
}


#-----------------------------------------------------------------------------------
# Graphics::min
# renvoie la valeur minimum d'une liste de valeurs
#-----------------------------------------------------------------------------------
sub min {
  my (@values) = @_;
  return undef if !scalar(@values);

  my $min = undef;

  foreach my $val (@values) {
    if (!defined $min or $val < $min) {
      $min = $val;
    }
  }

  return $min;
}


#-----------------------------------------------------------------------------------
# Graphics::r_modp
# fonction interne : renvoie le résultat POSITIF du modulo m d'un nombre x
#-----------------------------------------------------------------------------------
sub r_modp {
  my ($x, $m) = @_;

  return undef if $m == 0;

  my $value = $x%$m;

  if ($value < 0.0) {
    $value = $value + abs($m);
  }

  return $value;

}


1;


__END__


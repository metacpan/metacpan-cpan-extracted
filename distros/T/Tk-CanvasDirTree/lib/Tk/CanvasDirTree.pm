package Tk::CanvasDirTree;

our $VERSION = '0.04';
use warnings;
use strict;

use Tk::widgets qw/Canvas/;
use base  qw/Tk::Derived Tk::Canvas/;
use File::Spec;
use Tk::JPEG;
use Tk::PNG;

Construct Tk::Widget 'CanvasDirTree';

sub ClassInit
{
    my ($class, $mw) = @_;
    $class->SUPER::ClassInit($mw);
    $mw->bind($class, "<1>" =>'pick_one' );
    return $class; 
}

sub bind{
   my $self = shift;
   $self->CanvasBind(@_);
}

sub ConfigChanged {
  my ($self,$args)= @_;
  
   foreach my $opt (keys %{$args} ){
 
          if( $opt eq '-indfilla' ){ 
                    $self->{'indfilla'} = $args->{$opt}; 	  

		    my @items = $self->find('withtag','open');
		     foreach my $item (@items){
		         $self->itemconfigure($item, -fill => $args->{$opt});
                      }
		 };

          if( $opt eq '-indfilln' ){ 
	            $self->{'indfilln'} = $args->{$opt}; 	  
                    
		    my @items = $self->find('withtag','ind');
		     foreach my $item (@items){
		        my @tags = $self->gettags($item);
		        if( grep {$_ eq 'open'} @tags ){next} 
		        $self->itemconfigure($item, -fill => $args->{$opt});
                      }
                  };  
       #---------------------------------------------
    
       #----------- fontcolor updates--------------
          if( $opt eq '-fontcolora' ){ 
                    $self->{'fontcolora'} = $args->{$opt}; 	  
		    $self->itemconfigure('list', -activefill => $args->{$opt});
    	         };
        
          if( $opt eq '-fontcolorn' ){ 
	            $self->{'fontcolorn'} = $args->{$opt}; 	  
                    $self->itemconfigure('list', -fill => $args->{$opt});
                  };  
        #---------------------------------------------

       #----------- background image updates--------------
          if(( $opt eq '-backimage' ) or ( $opt eq '-imx' ) or ( $opt eq '-imy' )){ 
                   my $chipped = $opt;
	           substr $chipped, 0, 1, '' ;  #chip off - off of $opt
	           $self->{ $chipped } = $args->{$opt}; 	  
		    $self->set_background( 
                      $self->{'backimage'} ,$self->{'imx'}, $self->{'imy'}
	             );  
		 };
       #---------------------------------------------
   }
  
$self->idletasks;

} #end config changed   
    
#################################################################

sub Populate {
   my ($self, $args) = @_;
  #-------------------------------------------------------------------
   #take care of args which don't belong to the SUPER, see Tk::Derived
   foreach my $extra ('backimage','imx','imy','font','indfilla',
                      'indfilln','fontcolorn','fontcolora','floatback') {
       my $xtra_arg = delete $args->{ "-$extra" };  #delete and read same time 
     if( defined $xtra_arg ) { $self->{$extra} = $xtra_arg }
   }
   #-----------------------------------------------------------------

    $self->SUPER::Populate($args);   

    $self->ConfigSpecs(
     -indfilla => [ 'PASSIVE', undef, undef , undef],  # need to set defaults
     -indfilln => [ 'PASSIVE', undef, undef, undef],   # below for unknown
     -fontcolora => [ 'PASSIVE', undef, undef, undef], # reason ??
     -fontcolorn => [ 'PASSIVE', undef, undef, undef], #
     -backimage => [ 'PASSIVE', undef, undef, undef],
     -imx => [ 'PASSIVE', undef, undef, undef],
     -imy => [ 'PASSIVE', undef, undef, undef],
     -font => [ 'PASSIVE', undef, undef, undef],
     -floatback => [ 'PASSIVE', undef, undef, undef],
    ); 
    
     #set some defaults
     $self->{'indfilla'} ||= 'red';        
     $self->{'indfilln'} ||= 'blue'; 
     $self->{'fontcolorn'} ||= 'black';
     $self->{'fontcolora'} ||= 'red';
     $self->{'backimage'} ||= '';        
     $self->{'imx'} ||= 0; 
     $self->{'imy'} ||= 0;
     $self->{'font'} ||= 'system';
     $self->{'floatback'} ||= 0;
       
#---determine font spacing by making a capital W---
   my $fonttest =  $self->createText(0,0,
              -fill    => 'black',
              -text    => 'W',            
              -font => $self->{'font'},
              );
   
    my ($bx,$by,$bx1,$by1) = $self->bbox($fonttest);
    $self->{'f_width'} = $bx1 - $bx;
    $self->{'f_height'} = $by1 - $by;
    $self->delete($fonttest);
#--------------------------------------------------
   $self->make_trunk('.', 0); 

   $self->after(1,sub{ $self->_set_bars() });

} # end Populate

#######################################################################
sub _set_bars {
   my $self = shift;
   my $y = $self->parent->Subwidget('yscrollbar');
   $self->{'real_can'} =  $self->parent->Subwidget('scrolled');
   $self->idletasks;
   $y->configure( -command => [\&yscrollcallback,$self] );

    #account for any padding 
    $self->xviewMoveto(0);
    $self->yviewMoveto(0);
    $self->update;
}
######################################################################
sub yscrollcallback{
    #restore original function
    my ($self, @set) = @_;
    $self->yview(@set);

  #if you want the floating background
  if( $self->{'floatback'} == 1 ){ 
    my($z,$z1) = $self->yview;
    my(undef,undef,undef,$sry) = $self->cget('scrollregion');

    my $real_can_h = $self->{'real_can'}->reqheight; 
    my $div = $sry/$real_can_h;  
   
    $self->coords($self->{'background'}, 
                 $self->{'imx'},  
                 $self->{'imy'} + $div *$z * $real_can_h );
    $self->update;
  }

}
########################################################
sub adjust_background{
   my ($self, $photo_obj ) = @_;   
  
   $self->delete( $self->{'background'} );
  
   $self->{'bimage'} =  $photo_obj;
   $self->{'bimg_w'} = $self->{'bimage'}->width;
   $self->{'bimg_h'} = $self->{'bimage'}->height;

   $self->{'background'} = $self->createImage( 
         $self->{'imx'} , $self->{'imy'},
          -anchor => 'nw',
         -image  => $self->{'bimage'},
    );
 
 $self->lower($self->{'background'}, 'list');
 $self->lower($self->{'background'}, 'ind');
 
 }
############################################################
sub set_background{
    my( $self, $image ,$xim, $yim) = @_;     
        
    $self->{'backimage'} = $image;
    $self->{'imx'} = $xim; 
    $self->{'imy'} = $yim;

    if( ref $image eq  'Tk::Photo'){
           $self->adjust_background($image)
    }else{ 
          my $photo_obj =  $self->Photo( -file => $self->{'backimage'} );
          $self->adjust_background( $photo_obj ); 
	 }
}
##############################################################
sub get_subdirs{
  my ($self, $dir) = @_;

    my @subdirs;
    opendir my $dh, $dir or warn $!;

    while ( my $file = readdir($dh) ) {
        next if $file =~ m[^\.{1,2}$];
         if(-d "$dir/$file"){ 
           push @subdirs, $file;       
  	 }else{ next }
     }

  return @subdirs;
}
###########################################################
sub check_depth_2{
   my ($self, $abs_path) = @_;
    
   my $put_ind = 0;
    opendir my $dh, $abs_path or warn $!;
       while ( my $file = readdir($dh) ) {
         next if $file =~ m[^\.{1,2}$];
             if(-d "$abs_path/$file"){ 
                 $put_ind = 1;
                 last;        
  	         }
        }
 return $put_ind;
}
#############################################################
sub make_trunk{
   my ($self, $dir, $level) = @_;
   my $x = 5; my $y = $self->{'f_height'};

#make background image is needed
   if( length $self->{'backimage'} > 0 ){
       $self->set_background( 
            $self->{'backimage'},$self->{'imx'}, $self->{'imy'}
	    );  
     }

   my @subdirs = $self->get_subdirs( $dir  ); 
   my $abs_root = File::Spec->rel2abs( $dir );
   #for windows compat
   $abs_root =~ tr#\\#/#; 

   #handle special case when toplevel is / or C:/, D:/, etc
   if($abs_root eq '/'){$abs_root = ''}
   #for windows compat
   if ( $abs_root =~ m#^([ABCDEFGHIJKLMNOPQRSTUVWXYZ])\:\/$#  )
               {$abs_root = "$1:"} 

   #add a static entry for the topdir 
   my $root_tag;
   if($abs_root eq ''){$root_tag = '/'}else{ $root_tag = $abs_root }
   my $root = $self->createLine(
           $x , $y - .8 * $self->{'f_height'},
           $x + $self->{'f_height'}, $y - .8 * $self->{'f_height'},
           $x + $self->{'f_height'}, $y - .4 * $self->{'f_height'},
             -width => int( $self->{'f_height'} / 6),
             -fill    => $self->{'fontcolora'},
             -activefill => $self->{'fontcolora'},
             -activewidth => int( $self->{'f_height'} / 6) + 1,
              -arrow => 'last',
             -arrowshape => [5,5,2],
             -tags => ['list', $root_tag,],
           );

   my $max = scalar (@subdirs);
   my $count = 0;
  
    foreach my $subdir ( sort @subdirs ){
          my $abs_path = "$abs_root/$subdir";
          #see if any depth 2 subdir exists
          my $put_ind = $self->check_depth_2($abs_path);      
     
       #make open indicator if a dir --------------------------------------	 
       if( $put_ind ){
	 my $ind = $self->createPolygon(
	           $x + .1 * $self->{'f_width'} ,  $y + $y * $count - .3 * $self->{'f_height'}, 
	           $x +  .5 * $self->{'f_width'},  $y + $y * $count,
		   $x + .1 * $self->{'f_width'},  $y + $y * $count + .3 * $self->{'f_height'} ,
		  
		   -fill    => $self->{'indfilln'},
                   -activefill => 'yellow',
		   -outline => 'black',
		   -width   => 1,
		   -activewidth => 2,
                   -tags =>  ['ind', $abs_path], 
	           );
    }
#------------------------------------------------------------
	 my $id = $self->createText(
	           $x + .8 * $self->{'f_width'}, $y + $y * $count + (.5 *$self->{'f_height'}),
	           -fill    => $self->{'fontcolorn'},
		   -activefill => $self->{'fontcolora'},
                   -text    => $subdir,            
	           -font => $self->{'font'},
	           -anchor => 'sw',
	           -tags => ['list', $abs_path], 
	    );
	$count++;
   }

    my ($bx,$by,$bx1,$by1)= $self->bbox('all');
    $self->configure(-scrollregion =>[0,0,$bx1,$by1] );
    
} # end make_trunk 
############################################################################    
sub pick_one {
     my ($self) = @_;
     my $item = $self->find('withtag','current'); #returns aref
     my @tags = $self->gettags($item->[0]);
     $item = $item->[0];

     $self->{'selected'} = ''; #default is no selection

     if( grep { $_ eq 'ind' } @tags ){
        my $opened = 0;
        if( grep { $_ eq 'open'} @tags){$opened = 1}    
        @tags =  grep { $_ ne 'ind' and  $_ ne 'current' and $_ ne 'open'} @tags;
        my $dir = $tags[0];

       if( $opened ){
               $self->dtag('current', 'open' );
               $self->rotate_poly($item, -90, undef,undef);
               $self->itemconfigure($item, 'fill' => $self->{'indfilln'} );
               $self->idletasks;
	       $self->close_branch($dir,$item);
	    }else{
	       $self->addtag('open', 'withtag', 'current'  );
	       $self->rotate_poly($item, 90, undef,undef);
               $self->itemconfigure($item, 'fill' => $self->{'indfilla'} );
    	       $self->idletasks;       
	       $self->add_branch($dir);
            }
   }else{
         #picked up an indicator click by this point
         #clicks on list items will be handled by get_selected
         @tags =  grep { $_ ne 'list' and  $_ ne 'current'} @tags;
         $self->{'selected'} = $tags[0];
         $self->{'selected'} ||= '';
     }
          
} # end pick_one    
####################################################################
sub get_selected{
   my ($self) = @_;
   return $self->{'selected'};
}
###################################################################
sub add_branch{
   my ($self, $abs_path) = @_;
   $self->Busy;
  
 #for windows compat
   $abs_path =~ tr#\\#/#; 

   my $item;
   foreach my $it( $self->find('withtag', $abs_path)  ){
         my @tags =  $self->gettags($it);     
         if( grep { $_ eq 'list'} @tags ){ $item = $it }
     }
    
   my ($bx,$by,$bx1,$by1)= $self->bbox($item);
   my $x = $bx + $self->{'f_width'};
   my $y_edge = ($by + $by1)/2;
   my $y = $by1;
   my $count = 0;

   my @subdirs = $self->get_subdirs( $abs_path );  
      
   my $max = scalar @subdirs;
   my $max_add = $max * $self->{'f_height'};

   $self->make_space($y_edge,$max_add);

   # add sub entries
    foreach my $subdir (sort @subdirs  ){
        my $abs_path1 = File::Spec->rel2abs("$abs_path/$subdir");
        #for windows compat
        $abs_path1 =~ tr#\\#/#; 
        #see if any depth 2 subdir exists
        my $put_ind = $self->check_depth_2($abs_path1);      
      
      #make open indicator---------------------------------------------	 
       if( $put_ind ){
	 my $ind = $self->createPolygon(
	          $x - .9 * $self->{'f_width'} , .5*$self->{'f_height'}+ $y + $self->{'f_height'}* $count - .3 * $self->{'f_height'}, 
	          $x -  .5 * $self->{'f_width'}, .5*$self->{'f_height'}+ $y + $self->{'f_height'}* $count,
		  $x - .9 * $self->{'f_width'},  .5*$self->{'f_height'}+ $y +  $self->{'f_height'}* $count + .3 * $self->{'f_height'} ,
		  
		   -fill    => $self->{'indfilln'},
                   -activefill => 'yellow',
		   -outline => 'black',
		   -width   => 1,
		   -activewidth => 2,
                   -tags =>  ['ind', $abs_path1], 
	           );

	}
#------------------------------------------------------------
	 my $id = $self->createText(
	            $x , $y + $self->{'f_height'} * ($count + 1),
	           -fill    => $self->{'fontcolorn'},
		   -activefill => $self->{'fontcolora'},
                   -text    => $subdir,            
	           -font => $self->{'font'},
	           -anchor => 'sw',
	        #   -tags => ['list',$abs_path, $abs_path1], 
		   -tags => ['list', $abs_path1], 
	    );
	
	#add tag to upstream indicator
	
	$count++;
   }

  $self->Unbusy;

 (undef,undef,undef,$by1)= $self->bbox('list'); # get y max
 (undef,undef,$bx1,undef)= $self->bbox('all');  # get x max
  $self->configure( -scrollregion =>[0,0,$bx1,$by1] );

# a possible auto-scroll feature to open sub dirs
#    $self->yviewMoveto( ($y_edge - .5 * $self->{'f_height'})/$by1   );

$self->yscrollcallback(); #to keep background image aligned
	
} # end add_branch 
############################################################################    
sub close_branch{
  my($self, $abs_path, $ind ) = @_;

  my @y; my $x;

   foreach my $it( $self->find('all')  ){

         my @tags =  $self->gettags($it);     

	 if( grep { $_ eq 'current'} @tags ){next}
         if( grep { $_ eq $abs_path } @tags ){next}
         if( grep { $_ =~ /^$abs_path(.*)/ } @tags ){
             shift @tags; #shift off ind or list tag           

          if(scalar @tags > 0 ){
    	        my ($bx,$by,$bx1,$by1)= $self->bbox( $tags[0] );
	        push @y,$by; 
	        push @y,$by1;   
	        $self->delete($it);      
             }
          }
    }
     
  my @sorted = sort {$a<=>$b} @y ;
  my $amount = $sorted[-1] - $sorted[0];
  my ($bx,$by,$bx1,$by1)= $self->bbox('all');
 
  my @items = $self->find('enclosed',
          $bx,  $sorted[-1] - $self->{'f_height'} , 
	  $bx1, $by1 + $self->{'f_height'} ); 
 
  foreach my $move (@items){
      $self->move($move,0, -$amount);
   }

#adjust scroll region
 (undef,undef,undef,$by1)= $self->bbox('list'); # get y max
 (undef,undef,$bx1,undef)= $self->bbox('all');  # get x max
  $self->configure( -scrollregion =>[0,0,$bx1,$by1] );
 
 $self->yscrollcallback(); #to keep background image aligned
  
}
##############################################################################
sub make_space{
 my ($self, $y, $amount) = @_;
 
  my ($bx,$by,$bx1,$by1)= $self->bbox('all');
  my @items = $self->find('enclosed',$bx,$y,$bx1,$by1 + $self->{'f_height'}); 

  foreach my $move (@items){
        $self->move($move,0,$amount);
   }

}
##############################################################################

sub rotate_poly {
    my ($self, $id, $angle, $midx, $midy) = @_;
    
    # Get the old coordinates.
    my @coords = $self->coords($id);

    # Get the center of the poly. We use this to translate the
    # above coords back to the origin, and then rotate about
    # the origin, then translate back. (old)

    ($midx, $midy) = _get_CM(@coords) unless defined $midx;

    my @new;

    # Precalculate the sin/cos of the angle, since we'll call
    # them a few times.
    my $rad = 3.1416*$angle/180;
    my $sin = sin $rad;
    my $cos = cos $rad;

    # Calculate the new coordinates of the line.
    while (my ($x, $y) = splice @coords, 0, 2) {
	my $x1 = $x - $midx;
	my $y1 = $y - $midy;

	push @new => $midx + ($x1 * $cos - $y1 * $sin);
	push @new => $midy + ($x1 * $sin + $y1 * $cos);
    }

    # Redraw the poly.
    $self->coords($id, @new);
}
#################################################################
# This sub finds the center of mass of a polygon.
# I grabbed the algorithm somewhere from the web.
# I grabbed it from Slaven Reszic's RotCanvas :-)
sub _get_CM {
    my ($x, $y, $area);

    my $i = 0;

    while ($i < $#_) {
	my $x0 = $_[$i];
	my $y0 = $_[$i+1];

	my ($x1, $y1);
	if ($i+2 > $#_) {
	    $x1 = $_[0];
	    $y1 = $_[1];
	} else {
	    $x1 = $_[$i+2];
	    $y1 = $_[$i+3];
	}

	$i += 2;

	my $a1 = 0.5*($x0 + $x1);
	my $a2 = ($x0**2 + $x0*$x1 + $x1**2)/6;
	my $a3 = ($x0*$y1 + $y0*$x1 + 2*($x1*$y1 + $x0*$y0))/6;
	my $b0 = $y1 - $y0;

	$area += $a1 * $b0;
	$x    += $a2 * $b0;
	$y    += $a3 * $b0;
    }

    return split ' ', sprintf "%.0f %0.f" => $x/$area, $y/$area;
}
####################################################################
1;

__END__

=head1 NAME

Tk::CanvasDirTree - Perl Derived Canvas widget for browsing Directory Trees

=head1 SYNOPSIS

  use Tk;
  use Tk::CanvasDirTree;
 
  my $ztree = $frame->Scrolled('CanvasDirTree',
            -bg =>'lightblue',
            -width =>300,
            -height =>300,
#           -backimage => 'bridget-5a.jpg',  #either a gif,jpg,or png file 
#           -backimage => $bunny,            #or Tk::Photo object data 
            -imx => 200,           # image position relative to nw corner 
            -imy => 10,            # to place nw corner of image 
            -floatback => 1,  # makes background appear stationary in y 
	                      # direction, defaults to 0     
            -font => 'big',        # defaults to system 
#           -fontcolorn => 'cyan', # defaults to black 
#           -fontcolora => 'lightseagreen', #defaults to red 
#           -indfilln => 'hotpink',         #defaults to blue    
#           -indfilla => 'orange',          #defaults to red 
            -scrollbars =>'osw',
            )->pack(-side=>'left',-fill=>'both', -expand=>1);

#binding
 $ztree->bind('<ButtonPress-1>', sub{   
                 my $selected = $ztree->get_selected();
                 if(length $selected){print "$selected\n"}
		 });


#configuring
 $ztree->configure('-indfilla' => 'red' );
 $ztree->configure('-indfilln' => 'orange'); 
 $ztree->configure('-fontcolora' => 'white');
 $ztree->configure('-fontcolorn' => 'cyan'); 
 $ztree->configure('-bg' => 'black');     # gif, jpg, or png file
 $ztree->configure('-backimage' => $tux ); 
 $ztree->configure('-imy' => 45 ); 
 $ztree->configure('-imx' => 25 ); 

 
 
=head1 DESCRIPTION

This widget reads a directory tree, in an efficient manner, and provides
an intuitive graphical interface to selecting them. It only recurses 2 levels
at a time, so it is efficient on deeply nested trees. 
It is similar in appearance to the Gtk2 TreeView. Colors and fonts are
configurable, as well as a background image (with configurable location placement).
Also with -floatback => 1, the background image will appear to stay stationary
as the y scrollbar is moved.
Due to the wide variety of possible color schemes, creating a pleasing 
background image is left to you. See the included scripts in the scripts
directory, for examples to make charcoal or faded backgrounds.

It is a single mouse click selector( I nevered liked double-click bindings :-) ).
If a sub-directory has subdirs in it's own tree, a colored triangular shaped
indicator will be placed to the left of the subdir. Clicking on the indicator
will expand that subdir tree, and subsequent clicks will close it.

The basic operation is simple. A left mouse click on a subdirectory, will
return it's full path. You can then do what you want with the path, from 
your main script.

This widget is a derived Tk::Canvas, can be treated like a Canvas. 
It contains additional configuration options:

    -backimage => 'bridget-5a.jpg',  # either a file 
    -backimage => $bunny,            # or Tk::Photo object data 
    -imx => 200,                     # image position relative to nw corner 
    -imy => 10,                      # to place nw corner of image 
    -floatback => 1,                 # floating background, defaults to 0
    -font => 'big',                  # defaults to system 
    -fontcolorn => 'cyan',           # defaults to black 
    -fontcolora => 'lightseagreen',  # defaults to red 
    -indfilln => 'hotpink',          # defaults to blue    
    -indfilla => 'orange',           # defaults to red 

=head2 EXPORT

None.

=head1 SEE ALSO

See "perldoc Tk::Canvas" for the standard Canvas options
See perldoc Tk::Derived for information on how this module was derived.


=head1 AUTHOR

zentara, E<lt>zentara@zentara.netE<gt>
See  http://zentara.net/perlplay  for other perl script examples.

=head1 COPYRIGHT AND LICENSE

Copyright (C)April 14, 2006 by Joseph B. Milosch a.k.a zentara

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

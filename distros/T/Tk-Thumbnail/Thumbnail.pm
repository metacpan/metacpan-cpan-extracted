$Tk::Thumbnail::VERSION = '1.3';

package Tk::Thumbnail;

use Carp;
use File::Basename;
use Tk::widgets qw/ Animation JPEG LabEntry MultiMediaControls Pane PNG /;
use base qw/ Tk::Derived Tk::Pane /;
use vars qw/ $err $info /;
use strict;

Construct Tk::Widget 'Thumbnail';

sub ClassInit {

    my( $class, $mw ) = @_;

    $err  = $mw->Photo( -data => $class->err );
    $info = Tk->findINC( 'Thumbnail/images/info3.png' );

    $class->SUPER::ClassInit( $mw );

} # end ClassInit

sub Populate {

    my( $self, $args ) = @_;

    $self->SUPER::Populate( $args );

    $self->ConfigSpecs(
        -background => [ [ 'DESCENDANTS', 'SELF' ], 'background', 'Background',   undef ],
        -blank      => [ 'PASSIVE',                 'blank',      'Blank',            1 ],
        -columns    => [ 'PASSIVE',                 'columns',    'Columns',      undef ],
        -command    => [ 'CALLBACK',                'command',    'Command',  \&button1 ],
        -iheight    => [ 'PASSIVE',                 'iheight',    'Iheight',         32 ],
        -images     => [ 'PASSIVE',                 'images',     'Images',       undef ],
        -ilabels    => [ 'PASSIVE',                 'ilabels',    'Ilabels',          1 ],
        -iwidth     => [ 'PASSIVE',                 'iwidth',     'Iwidth',          32 ],
        -scrollbars => [ 'PASSIVE',                 'scrollbars', 'Scrollbars',  'osow' ],
    );

    $self->OnDestroy(
        sub {
            $err->delete;
            $self->free_photos;
        }
    );
      
} # end Populate

sub button1 {

    my( $label, $file, $bad_photo, $w, $h, $animated, $blank ) = @_;
    return if $bad_photo;

    my $tl = $label->Toplevel;
    $tl->withdraw;
    $tl->title( $file );
    $tl->minsize( 120, 120 );

    my ( $can_del, $p );
    if( UNIVERSAL::isa( $file, 'Tk::Photo' ) ) {
	$p = $file;
	$can_del = 0;
    } elsif( $animated ) {
	$p = $tl->Animation( -file => $file, -format => 'gif' );
	$p->blank( $blank );
	$can_del = 1;
    } else {
	$p = $tl->Photo( -file => $file );
	$can_del = 1;
    }
    $tl->protocol( 'WM_DELETE_WINDOW' => sub {
	$p->delete if $can_del;
	$tl->destroy;
    } );

    my $sp = $tl->Scrolled( qw/ Pane -scrollbars osoe / )->pack( qw/ -fill both -expand 1 / );
    $sp->Label( -image => $p )->pack( qw/ -fill both -expand 1 / );
    my $ctrls = $sp->Frame->pack;
    if( $animated ) {
	$ctrls->MultiMediaControls(

            # Define, from left to right, the window's controller buttons.

            -buttons                     => [ qw/ home rewind play stop fastforward / ],

            # Define callbacks for the buttons' various states.

            -fastforwardhighlightcommand => [ $p => 'fast_forward',   4 ],
            -fastforwardcommand          => [ $p => 'fast_forward',   1 ],
            -homecommand                 => [ $p => 'set_image',      0 ],
            -pausecommand                => [ $p => 'pause_animation'   ],
            -playcommand                 => [ $p => 'resume_animation'  ],
            -rewindhighlightcommand      => [ $p => 'fast_reverse',  -4 ],
            -rewindcommand               => [ $p => 'fast_reverse',   1 ],
            -stopcommand                 => [ $p => 'stop_animation'    ],

            # Define callbacks for the left and right arrow keys.

            -leftcommand                 => [ $p => 'prev_image'        ],
            -rightcommand                => [ $p => 'next_image'        ],

         )->pack;
    }
    $ctrls->Button(
        -text    => 'Get Info',
        -image   => $ctrls->Photo( -file => $info, -format => 'png' ),
        -command => [ \&photo_info, $tl, $file, $p, $w, $h, $animated ],
    )->pack;
    my( $max_width, $max_height ) = ( $tl->vrootwidth - 100, $tl->vrootheight - 100 );
    $w += 100;
    $h += 100;
    $w = ( $w > $max_width )  ? $max_width  : $w;
    $h = ( $h > $max_height ) ? $max_height : $h;
    $tl->geometry( "${w}x${h}" );
    $tl->deiconify;

} # end button1

sub photo_info {

    my( $tl, $file, $photo, $w, $h, $animated ) = @_;

    my $tl_info = $tl->Toplevel;
    if( $animated ) {
	my $fc =  $photo->frame_count;
	$fc = reverse $fc;
	$fc =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g; # commify
	$fc = scalar reverse $fc;
	$animated = "$fc frame";
	$animated .= 's' if $fc > 1;
    } else {
	$animated = 'no';
    }

    my $i = $tl_info->Labelframe( qw/ -text Image / )->pack( qw/ -fill x -expand 1 / );
    foreach my $item ( [ 'Width', $w ], [ 'Height', $h ], [ 'Multi-frame', $animated ] ) {
        my $l = $item->[0] . ':';
        my $le = $i->LabEntry(
            -label        => ' ' x ( 13 - length $l ) . $l,
            -labelPack    => [ qw/ -side left -anchor w / ],
            -labelFont    => '9x15bold',
            -relief       => 'flat',
            -textvariable => $item->[1],
            -width        => 35,
        );
        $le->pack(qw/ -fill x -expand 1 /);
    }

    my $f = $tl_info->Labelframe( qw/ -text File / )->pack( qw/ -fill x -expand 1 / );
    $file = $photo->cget( -file );
    my $size = -s $file;
    $size = reverse $size;
    $size =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g; # commify
    $size = scalar reverse $size;

    foreach my $item ( [ 'File', $file ], [ 'Size', $size ] ) {
        my $l = $item->[0] . ':';
        my $le = $f->LabEntry(
            -label        => ' ' x ( 13 - length $l ) . $l,
            -labelPack    => [ qw/ -side left -anchor w / ],
            -labelFont    => '9x15bold',
            -relief       => 'flat',
            -textvariable => $item->[1],
            -width        => 35,
        );
        $le->pack(qw/ -fill x -expand 1 /);
    }

    $tl_info->title( basename( $file ) );

} # end photo_info

sub ConfigChanged {

    # Called at the completion of a configure() command.

    my( $self, $changed_args ) = @_;
    $self->render if grep { /^\-images$/ } keys %$changed_args;

} # end ConfigChanged

sub render {

    # Create a Table of thumbnail images, having a default size of
    # 32x32 pixels.  Once we have a Photo of an image, copy a
    # subsample to a blank Photo and shrink it.  We  maintain a
    # list of our private images so their resources can be released
    # when the Thumbnail is destroyed.

    my( $self ) = @_;

    $self->clear;		# clear Table
    delete $self->{'descendants'};

    my $pxx = $self->cget( -iwidth );  # thumbnail pixel width
    my $pxy = $self->cget( -iheight ); # thumbnail pixel height
    my $lbl = $self->cget( -ilabels ); # display file names IFF true
    my $img = $self->cget( -images );  # reference to list of images
    my $col = $self->cget( -columns ); # thumbnails per row
    croak "Tk::Thumbnail: -images not defined." unless defined $img;

    for( my $i = $#{@$img}; $i >= 0; $i--  ) {
	splice @$img, $i, 1 if -d $img->[$i]; # remove directories
    }
    my $count = scalar @$img;
    my( $rows, $cols );
    if( not defined $col ) {
	$rows = int( sqrt $count );
	$rows++ if $rows * $rows != $count;
	$cols = $rows;
    } else {
	$cols = $col;
	$rows = int( $count / $cols + 0.5 );
	$rows++ if $rows * $cols < $count;
    }

  THUMB:
    foreach my $r ( 0 .. $rows - 1 ) {
	foreach my $c ( 0 .. $cols - 1 ) {
	    last THUMB if --$count < 0;

	    my $bad_photo = 0;
	    my $i = @$img[$#$img - $count];
	    my( $photo, $w, $h, $animated );

	    $animated = 0;
	    if ( UNIVERSAL::isa( $i, 'Tk::Photo' ) ) {
		$photo = $i;
	    } else {
		Tk::catch { $photo = $self->Photo( -file => $i ) };
		if ( $@ ) {
		    
		    # Re-attempt using -format.
		    
		    foreach my $f ( qw/ jpeg png / ) {
			Tkcatch { $photo = $self->Photo( -file => $i, -format => $f) };   
			last if $photo;
		    }
		    unless ( $photo ) {
			carp "Tk::Thumbnail: cannot make a Photo from '$i'.";
			$photo = $err;
			$bad_photo++;
		    }
		} else {	# see if animated GIF
		    Tk::catch { $photo = $self->Animation( -file => $i, -format => 'gif' ) };
		    $animated = 1 unless $@;
		}
	    }

	    ( $w, $h ) = ( $photo->width, $photo->height );

	    my $subsample = $self->Photo;
	    my $sw = $pxx == -1 ? 1 : ( $w / $pxx );
	    my $sh = $pxy == -1 ? 1 : ( $h / $pxy );

	    if ( $sw >= 1 and $sh >= 1 ) {
                $sw = int( $sw + 0.5 );
                $sh = int( $sh + 0.5 );
		$subsample->copy( $photo, -subsample => ( $sw, $sh ) );
	    } else {
		$sw = 1 if (1/$sw) < 1;
		$sh = 1 if (1/$sh) < 1;
		Tk::catch { $subsample->copy( $photo, -zoom => (1 / $sw, 1 / $sh ) ) };
                carp "Tk::Thumbnail: error with '$i': $@" if $@;
	    }
	    push @{$self->{photos}}, $subsample;

	    my $f = $self->Frame;
	    my $l = $f->Label( -image => $subsample )->grid;
	    
	    $l->bind( '<Button-1>' => [ $self => 'Callback', '-command',
				      $l, $i, $bad_photo, $w, $h, $animated, $self->cget( -blank ) ] );
	    my $name = $photo->cget( -file );
	    $name = ( $name ) ? basename( $name ) : basename( $i );
	    $f->Label( -text => $name )->grid if $lbl;

	    $f->grid( -row => $r, -column => $c );
	    push @{$self->{'descendants'}}, $f;
	    
            $photo->delete unless UNIVERSAL::isa( $i, 'Tk::Photo' ) or $photo == $err;

	} # forend columns
    } #forend rows
             
} # end render

sub clear {

    my $self = shift;

    $self->free_photos;		# delete previous images

    foreach my $c ( @{$self->{'descendants'}} ) {
	$c->gridForget;
	$c->destroy;
    }

    $self->update;

} # end clear

sub free_photos {

    # Free all our subsampled Photo images.

    my $self = shift;

    foreach my $photo ( @{$self->{photos}} ) {
        $photo->delete;
    }
    delete $self->{photos};

} # end free_photos

sub err {
    return <<'endof-xpm';
/* XPM */
static char * huh[] = {
"128 128 17 1",
". c #fd8101",
"# c #fd6201",
"a c #fdae01",
"b c #fd8f01",
"c c #fd2501",
"d c #fdfa01",
"e c #fd4401",
"f c #fdbd01",
"g c #fddc01",
"h c #fd0701",
"i c #fd7201",
"j c #fd5301",
"k c #fd9f01",
"l c #fd3501",
"m c #fdeb01",
"n c #fdcc01",
"o c #fd1601",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddf.ieeeej.kgdddddddddddddddddddddddddf.ieeeej.kgdddddddddddddddddddddddddddddddddddddddddd",
"ddddddddddddddddddddddddddddddddddddn#ohhhhhhhhhhhc.mdddddddddddddddddddn#ohhhhhhhhhhhc.mddddddddddddddddddddddddddddddddddddddd",
"ddddddddddddddddddddddddddddddddddm#hhhheeohhhhhhhhhobddddddddddddddddm#hhhheeohhhhhhhhhobdddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddnchhh.mdddkohhhhhhhhh#ddddddddddddddnchhh.mdddkohhhhhhhhh#ddddddddddddddddddddddddddddddddddddd",
"ddddddddddddddddddddddddddddddddgohhhbddddddmlhhhhhhhhh#ddddddddddddgohhhbddddddmlhhhhhhhhh#dddddddddddddddddddddddddddddddddddd",
"ddddddddddddddddddddddddddddddddlhhhhmdddddddnhhhhhhhhhhbdddddddddddlhhhhmdddddddnhhhhhhhhhhbddddddddddddddddddddddddddddddddddd",
"ddddddddddddddddddddddddddddddd.hhhhhkdddddddd#hhhhhhhhhomddddddddd.hhhhhkdddddddd#hhhhhhhhhomdddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddchhhhhcmdddddddahhhhhhhhhh.dddddddddchhhhhcmdddddddahhhhhhhhhh.dddddddddddddddddddddddddddddddddd",
"ddddddddddddddddddddddddddddddfhhhhhhhkdddddddmhhhhhhhhhhcddddddddfhhhhhhhkdddddddmhhhhhhhhhhcdddddddddddddddddddddddddddddddddd",
"ddddddddddddddddddddddddddddddbhhhhhhhlddddddddchhhhhhhhhhmdddddddbhhhhhhhlddddddddchhhhhhhhhhmddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddd.hhhhhhhhgdddddddehhhhhhhhhhfddddddd.hhhhhhhhgdddddddehhhhhhhhhhfddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddd.hhhhhhhhfdddddddehhhhhhhhhhfddddddd.hhhhhhhhfdddddddehhhhhhhhhhfddddddddddddddddddddddddddddddddd",
"ddddddddddddddddddddddddddddddnhhhhhhhhndddddddehhhhhhhhhhfdddddddnhhhhhhhhndddddddehhhhhhhhhhfddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddlhhhhhhcddddddddehhhhhhhhhhdddddddddlhhhhhhcddddddddehhhhhhhhhhdddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddgchhhhonddddddddchhhhhhhhhldddddddddgchhhhonddddddddchhhhhhhhhldddddddddddddddddddddddddddddddddd",
"ddddddddddddddddddddddddddddddddmbeeigdddddddddhhhhhhhhhhbddddddddddmbeeigdddddddddhhhhhhhhhhbdddddddddddddddddddddddddddddddddd",
"ddddddddddddddddddddddddddddddddddddddddddddddfhhhhhhhhhomddddddddddddddddddddddddfhhhhhhhhhomdddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddd.hhhhhhhhhbddddddddddddddddddddddddd.hhhhhhhhhbddddddddddddddddddddddddddddddddddd",
"ddddddddddddddddddddddddddddddddddddddddddddddchhhhhhhh#ddddddddddddddddddddddddddchhhhhhhh#dddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddfhhhhhhhh#ddddddddddddddddddddddddddfhhhhhhhh#ddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddehhhhhhh#dddddddddddddddddddddddddddehhhhhhh#dddddddddddddddddddddddddddddddddddddd",
"ddddddddddddddddddddddddddddddddddddddddddddfhhhhhhhbdddddddddddddddddddddddddddfhhhhhhhbddddddddddddddddddddddddddddddddddddddd",
"ddddddddddddddddddddddddddddddddddddddddddddehhhhhcnddddddddddddddddddddddddddddehhhhhcndddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddfhhhhhimddddddddddddddddddddddddddddfhhhhhimddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddehhhcfddddddddddddddddddddddddddddddehhhcfddddddddddddddddddddddddddddddddddddddddddd",
"ddddddddddddddddddddddddddddddddddddddddddghhhjmddddddddddddddddddddddddddddddghhhjmdddddddddddddddddddddddddddddddddddddddddddd",
"ddddddddddddddddddddddddddddddddddddddddddihh#ddddddddddddddddddddddddddddddddihh#dddddddddddddddddddddddddddddddddddddddddddddd",
"ddddddddddddddddddddddddddddddddddddddddddchjdddddddddddddddddddddddddddddddddchjddddddddddddddddddddddddddddddddddddddddddddddd",
"ddddddddddddddddddddddddddddddddddddddddddhhgdddddddddddddddddddddddddddddddddhhgddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddnhjdddddddddddddddddddddddddddddddddnhjdddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddfhbdddddddddddddddddddddddddddddddddfhbdddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddfhfdddddddddddddddddddddddddddddddddfhfdddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddfhmdddddddddddddddddddddddddddddddddfhmdddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddg.ddddddddddddddddddddddddddddddddddg.ddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddmffdddddddddddddddddddddddddddddddddmffdddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddnehhhh#mddddddddddddddddddddddddddddnehhhh#mddddddddddddddddddddddddddddddddddddddddddddd",
"ddddddddddddddddddddddddddddddddddddddnohhhhhhlmddddddddddddddddddddddddddnohhhhhhlmdddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddmohhhhhhhhedddddddddddddddddddddddddmohhhhhhhhedddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddbhhhhhhhhhhnddddddddddddddddddddddddbhhhhhhhhhhnddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddjhhhhhhhhhhbddddddddddddddddddddddddjhhhhhhhhhhbddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddehhhhhhhhhh.ddddddddddddddddddddddddehhhhhhhhhh.ddddddddddddddddddddddddddddddddddddddddddd",
"ddddddddddddddddddddddddddddddddddddd#hhhhhhhhhhkdddddddddddddddddddddddd#hhhhhhhhhhkddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddkhhhhhhhhhhgddddddddddddddddddddddddkhhhhhhhhhhgddddddddddddddddddddddddddddddddddddddddddd",
"ddddddddddddddddddddddddddddddddddddddlhhhhhhhhiddddddddddddddddddddddddddlhhhhhhhhidddddddddddddddddddddddddddddddddddddddddddd",
"ddddddddddddddddddddddddddddddddddddddmlhhhhhh#dddddddddddddddddddddddddddmlhhhhhh#ddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddm.lhhekdddddddddddddddddddddddddddddm.lhhekdddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd",
"dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd"};
endof-xpm
} # end err
 
1;
__END__

=head1 NAME

Tk::Thumbnail - Create a grid of shrunken images.

=for pm Tk/Thumbnail.pm

=for category Images

=head1 SYNOPSIS

 $thumb = $parent->Thumbnail(-option => value, ... );

=head1 DESCRIPTION

Create a table of thumbnail images, having a default size of 32 x 32
pixels.  Once we have a B<Photo> of an image, shrink it by copying a
subsample of the original to a blank B<Photo>. Images smaller than the
thumbnail dimensions are enlarged by zooiming.

Clicking on an image displays it full-size in a separate window with a
"Get Info" button.  The info window shows the image's width, height,
path name, size and frame count.

For multi-frame GIFs the image is shown in a Tk:: MultiMediaControls
window.  This is a QuickTime-like controller widget, allowing you to
play, pause, rewind, stop, fast-forward and fast-reverse the
animation.  The Space bar toggles play/pause.  Left and right arrow
keys step the animation frame by frame, either forward or reverse.

=over 4

=item B<-images>

A list of file names and/or B<Photo> widgets.  B<Thumbnail> creates
temporarty B<Photo> images from all the files, and destroys them when
the B<Thumbnail> is destroyed or when a new list of images is
specified in a subsequent B<configure> call.  Already existing
B<Photo>s are left untouched.

=item B<-ilabels>

A boolean, set to TRUE if you want file names displayed under the
thumbnail images.

=item B<-font>

The default font is B<fixed>.

=item B<-iwidth>

Pixel width of the thumbnails.  Default is 32. The special value -1 means
don't shrink images in the X direction.

=item B<-iheight>

Pixel height of the thumbnails.  Default is 32. The special value -1 means
don't shrink images in the Y direction.

=item B<-command>

A callback that's executed on a <Button-1> event over a thumbnail
image.  It's passed six arguments: the Label widget reference
containing the thumbnail B<Photo> image, the file name of the
B<Photo>, a boolean indicating whether or not the the B<Photo> is
valid, the B<Photo>'s pixel width and height, and a boolean indicating
whether the image is a single frame (Tk::Photo) or has multiple frames
(Tk::Animation). 

A default callback is provided that simply displays
the original image in a new Toplevel widget, along with a Get Info
Button that opens another Toplevel containing information about the
image.  If the image has multiple frames, then QuickTime-like controller
buttons are also presented to view the animation, and the left and right arrow
keys single-step the animation frame-by-frame. The space bar toggles the play/pause
button.

=item B<-columns>

Number of Photos per row. The column count is computed if not specified.

=item B<-blank>

For animated GIFs, a boolean specifying whether to blank the animation photo between movie
frames.  Default is 1.

=back

=head1 METHODS

=over 4

=item $thumb->clear;

Destroys all Frames and Labels, and deletes all the temporary B<Photo> images, in
preparation for re-populating the Thumbnail with new data.

=back

=head1 EXAMPLE

 $thumb = $mw->Thumbnail( -images => [ <images/*.ppm> ], -ilabels => 1 );


=head1 AUTHOR

sol0@Lehigh.EDU

Copyright (C) 2001 - 2005, Steve Lidie. All rights reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 CHANGES

v 1.3 2005/05/15

Added -blank option to make some Tk::Animations look better.
Added -columns option by renee.baecker@smart-websolutions.de.

=head1 KEYWORDS

thumbnail, image, QuickTime, Apple, photo, animation

=cut


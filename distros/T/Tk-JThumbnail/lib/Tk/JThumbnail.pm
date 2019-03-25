package Tk::JThumbnail;

use strict;
use warnings;
use Carp;
use File::Basename;
use Tk; # qw/Ev $XS_VERSION/;
#DEPRECIATED!:  use Tk::widgets qw/ Animation JPEG LabEntry MultiMediaControls Pane PNG /;
use Tk::widgets qw/ JPEG LabEntry Pane PNG /;
use base qw/ Tk::Derived Tk::Pane /;
use vars qw/ $VERSION $err $info $CORNER $haveAnimation/;

$VERSION = '2.01';
$haveAnimation = 0;
eval 'use Tk::widgets qw/ Animation /; $haveAnimation = 1; 1';

#x Construct Tk::Widget 'JThumbnail';
Tk::Widget->Construct('JThumbnail');

sub ClassInit {

	my( $class, $mw ) = @_;

	$err  = Tk->findINC( 'JThumbnail/images/failimg.png' );
	$info = Tk->findINC( 'JThumbnail/images/info3.png' );
	$CORNER = __PACKAGE__ . "::corner";

	$class->SUPER::ClassInit( $mw );
	$mw->XscrollBind($class);
	$mw->YscrollBind($class);
	$mw->MouseWheelBind($class); # XXX Both needed?
	$mw->YMouseWheelBind($class);
	$mw->bind($class,'<FocusIn>','focus');
	$mw->bind($class,'<FocusOut>', sub { my $self = shift; $self->{'isfocused'} = 0; });
	my $bits = pack("b15"x15,     #OPTIONAL IMAGE TO DISPLAY IN CORNER BETWEEN SCROLLBARS:
			"...............",
			".#############.",
			".############..",
			".###########...",
			".##########....",
			".#########.....",
			".########......",
			".#######.......",
			".######........",
			".#####.........",
			".####..........",
			".###...........",
			".##............",
			".#.............",
			"...............",
	);
	$mw->DefineBitmap($CORNER => 15,15, $bits);
	
	return $class;
} # end ClassInit

sub Populate {

	my( $self, $args ) = @_;

	my $takefocus = delete($args->{'-takefocus'});
	$args->{'-scrollbars'} = 'osoe'  unless (defined $args->{'-scrollbars'});
	$args->{'-takefocus'} = 0;
	$self->SUPER::Populate( $args );
	$args->{'-takefocus'} = $takefocus  if (defined $takefocus);

	$self->Delegates(
			'activate' => $self,
			'bindImages' => $self,   #APPLY BINDINGS TO THE IMAGES (NEEDED SINCE FRAME DOESN'T PASS BINDINGS TO THE IMAGE WIDGETS)
			'bindRows' => $self,     #SYNONYM FOR bindImages(), NAMED FOR COMPAT. W/Tk::HMListbox IN jfm5 (HAS NOTHING TO DO WITH "ROWS")!
			'clear' => $self,
			'curselection' => $self,
			'get' => $self,
			'getRow' => $self,       #CONVENIENCE METHOD NAMED FOR COMPAT. W/Tk::HMListbox IN jfm5 (HAS NOTHING TO DO WITH "ROWS")!
			'index' => $self,
			'indexOf' => $self,
			'isFocused' => $self,
			'isSelected' => $self,
			'selectionSet' => $self,
			'selectionToggle' => $self,
			'selectionClear' => $self,
	);  #### MUST LIST EXPORTED METHODS HERE!!!!

	$self->ConfigSpecs(
			-background => [ [ 'DESCENDANTS', 'SELF' ], 'background', 'Background',   undef ],
			-selectbackground  => [qw/PASSIVE selectBackground Background/,  $Tk::SELECT_BG ],
			-blank      => [ 'PASSIVE',                 'blank',      'Blank',            0 ],
			-columns    => [ 'PASSIVE',                 'columns',    'Columns',      undef ],
			-command    => [ 'CALLBACK',                'command',    'Command',  \&button1 ],
			-iheight    => [ 'PASSIVE',                 'iheight',    'Iheight',         32 ],
			-images     => [ 'PASSIVE',                 'images',     'Images',       undef ],
			-extimages  => [ 'PASSIVE',                 'images',     'Images',       undef ],
			-selected   => [ 'PASSIVE',                 'selected',   'Selected',     undef ],
			-ilabels    => [ 'PASSIVE',                 'ilabels',    'Ilabels',          1 ],
			-iwidth     => [ 'PASSIVE',                 'iwidth',     'Iwidth',          32 ],
			-nodirs     => [ 'PASSIVE',                 'nodirs',     'NoDirs',           0 ],
			-noexpand   => [ 'PASSIVE',                 'noexpand',   'NoExpand',         0 ],
			-scrollbars => [ qw/METHOD                  scrollbars    Scrollbars      osoe/ ], #DEFAULT SEEMS TO BE "osow" DESPITE THIS?!
			-takefocus  => [ 'PASSIVE',                 'takeFocus',  'Focus',        undef ],
			-focus      => [ 'PASSIVE',                 'takeFocus',  'Focus',        undef ],
	);
	$self->bind('<4>', sub { $self->yview(scroll => -5, 'units')});
	$self->bind('<5>', sub { $self->yview(scroll => 5, 'units')});
	$self->bind('<Button-6>', sub { $self->xview(scroll => -5, 'units')});
	$self->bind('<Button-7>', sub { $self->xview(scroll => 5, 'units')});

	$self->OnDestroy(
		sub {
		$self->free_photos;
		}
	);

} # end Populate

sub button1 {  #LEGACY Tk::Thumbnail DEFAULT MOUSE-BUTTON 1 CALLBACK TO DISPLAY IMAGE/ANIMATION FULL-SIZED IN POPUP WINDOW:
	my $self = shift;
	my( $label, $file, $bad_photo, $w, $h, $animated, $blank, $extphoto );
	if (scalar(@_) > 1) {  #KEEP THE LEGACY WAY FOR LEGACY THUMBNAIL abUSERS!:
		( $label, $file, $bad_photo, $w, $h, $animated, $blank ) = @_;
		$extphoto = 0;
	} else {
		my $indx = shift;
		$indx = $self->index($indx)  unless ($indx =~ /^\d+$/o);
		return  unless ($indx >= 0);

		my $datavec = $self->{'data'};
		my $data = ${$datavec}[$indx];
		$label = $data->{'-label'};
		$file = $data->{'-filename'};
		$bad_photo = $data->{'-bad'};
		$w = $data->{'-width'};
		$h = $data->{'-height'};
		$animated = $data->{'-animated'};
		$blank = $data->{'-blank'};
		$extphoto = $data->{'-photo'};
	}
	return if $bad_photo;

	my $tl = $label->Toplevel;
	$tl->withdraw;
	$tl->title( $file );
	$tl->minsize( 120, 120 );

	my ( $can_del, $p );
	if ( UNIVERSAL::isa( $file, 'Tk::Photo' ) ) {
		$p = $file;
		$can_del = 0;
	} elsif ( $haveAnimation && $animated ) {
		$p = $tl->Animation( -file => $file, -format => 'gif' );
		$p->set_disposal_method( $blank );
		$can_del = 1;
	} elsif ( $file =~ /\.xpm$/io) {  #BAD XPMs CAN CRASH PERL, SO JUST USE WHAT ALREADY LOADED!:
		$p = $extphoto  if ($extphoto);
		$can_del = 0;
	} else {
		Tk::catch { $p = $tl->Photo( -file => $file ); };
		if ($@ && $extphoto) {
			$p = $extphoto;
			$can_del = 0;
		} else {
			$can_del = 1;
		}
	}
	$tl->protocol( 'WM_DELETE_WINDOW' => sub {
		$p->delete if $can_del;
		$tl->destroy;
		} );

	my $sp = $tl->Scrolled( qw/ Pane -scrollbars osoe / )->pack( qw/ -fill both -expand 1 / );
	$sp->Label( -image => $p )->pack( qw/ -side top -fill both -expand 1 / );
	my $ctrls = $sp->Frame->pack(-side => 'bottom');

	my $btnframe = $ctrls->Frame;

	if ( $haveAnimation && $animated ) {
#DEPRECIATED:		my $mmedia = $ctrls->MultiMediaControls(
#DEPRECIATED:
#DEPRECIATED:		# Define, from left to right, the window's controller buttons.
#DEPRECIATED:
#DEPRECIATED:				-buttons                     => [ qw/ home rewind play stop fastforward / ],
#DEPRECIATED:
#DEPRECIATED:		# Define callbacks for the buttons' various states.
#DEPRECIATED:
#DEPRECIATED:				-fastforwardhighlightcommand => [ $p => 'fast_forward',   4 ],
#DEPRECIATED:				-fastforwardcommand          => [ $p => 'fast_forward',   1 ],
#DEPRECIATED:				-homecommand                 => [ $p => 'set_image',      0 ],
#DEPRECIATED:				-pausecommand                => [ $p => 'pause_animation'   ],
#DEPRECIATED:				-playcommand                 => [ $p => 'resume_animation'  ],
#DEPRECIATED:				-rewindhighlightcommand      => [ $p => 'fast_reverse',  -4 ],
#DEPRECIATED:				-rewindcommand               => [ $p => 'fast_reverse',   1 ],
#DEPRECIATED:				-stopcommand                 => [ $p => 'stop_animation'    ],
#DEPRECIATED:
#DEPRECIATED:		# Define callbacks for the left and right arrow keys.
#DEPRECIATED:
#DEPRECIATED:				-leftcommand                 => [ $p => 'prev_image'        ],
#DEPRECIATED:				-rightcommand                => [ $p => 'next_image'        ],
#DEPRECIATED:
#DEPRECIATED:		)->pack;
#DEPRECIATED:		$mmedia->bind('all', '<B1-Motion>', sub { print "--no mastermenu!\n"; });
#REPLACED ABOVE WITH BELOW, NOT AS KEWL, BUT WORKS!:
		my $playing = 0;
		$self->{'_playbtn'} = $btnframe->Button(
				-text    => 'Play',
				-command => sub {
					if ($playing) {
						$p->stop_animation();
						$self->{'_playbtn'}->configure(-text => 'Play');
					} else {
						$p->start_animation();
						$self->{'_playbtn'}->configure(-text => 'Stop');
					}
					$playing = $playing ? 0 : 1;
				}
				)->pack(-side => 'left');
	}

	$btnframe->Button(
			-text    => 'Get Info',
			-image   => $ctrls->Photo( -file => $info, -format => 'png' ),
			-command => [ \&photo_info, $tl, $file, $p, $w, $h, $animated ],
			)->pack(-side => 'left');
	my $closeBtn = $btnframe->Button(
			-text    => 'Close',
			-command => sub {
				$p->delete if $can_del;
				delete $self->{'_playbtn'}  if ($haveAnimation && $animated && defined $self->{'_playbtn'});
				$tl->destroy;
			}
			)->pack(-side => 'left');
	$btnframe->pack(-side => 'bottom', -pady => 20);

	my( $max_width, $max_height ) = ( $tl->vrootwidth - 100, $tl->vrootheight - 100 );
	$w += 100;
	$h += 100;
	$w = ( $w > $max_width )  ? $max_width  : $w;
	$h = ( $h > $max_height ) ? $max_height : $h;
	$tl->geometry( "${w}x${h}" );
	$closeBtn->focus();
	$tl->deiconify;

} # end button1

sub photo_info {  #LEGACY Tk::Thumbnail CALLBACK FUNCTION TO POPUP IMAGE INFO SUBWINDOW:

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
	my $filename = $file;
	$file = $photo->cget( '-file' ) || $filename;  #DOESN'T ALWAYS SEEM TO WORK?!
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

	my $closeBtn = $tl_info->Button(
			-text    => 'Close',
			-command => sub {
				$tl_info->destroy;
			}
			)->pack(-side => 'left');

	$tl_info->title( basename( $filename ) );
	$closeBtn->focus();

} # end photo_info

sub ConfigChanged {

	# Called at the completion of a configure() command.

	my( $self, $changed_args ) = @_;

	$self->{'btnnormalbg'} = $self->cget('-background');
	$self->{'btnselbg'} = $self->cget('-selectbackground') || $self->Palette->{'readonlyBackground'} || $self->Palette->{'highlightBackground'};
	$self->{'btnselbg'} = 'gray75'  if (!$self->{'btnselbg'} || $self->{'btnselbg'} eq $self->{'btnnormalbg'});
	$self->{'btnselbg'} = 'gray50'  if ($self->{'btnselbg'} eq $self->{'btnnormalbg'});
	$self->render if grep { /^\-images$/ } keys %$changed_args;
} # end ConfigChanged

sub render {

	# Create a Table of thumbnail images, having a default size of
	# 32x32 pixels.  Once we have a Photo of an image, copy a
	# subsample to a blank Photo and shrink it.  We  maintain a
	# list of our private images so their resources can be released
	# when the JThumbnail is destroyed.

	my( $self ) = @_;

	$self->clear;		# clear Table

	my $pxx = $self->cget( '-iwidth' );  # thumbnail pixel width
	my $pxy = $self->cget( '-iheight' ); # thumbnail pixel height
	my $lbl = $self->cget( '-ilabels' ); # display file names IFF true
	my $img = $self->cget( '-images' );  # reference to list of images
	my $extimg = $self->cget( '-extimages' );
	my $selected = $self->cget( '-selected' );  # reference to list of booleans whether img is "selected".
	my $binds = $self->{'_binds'}; # button keybindings
	my $col = $self->cget( '-columns' ); # thumbnails per row
	my $noexpand = $self->cget( '-noexpand' ); #don't expand small images if true
	croak "Tk::JThumbnail: -images not defined." unless defined $img;

	if ($self->cget('-nodirs')) {
		for( my $i = $#{$img}; $i >= 0; $i--  ) {
			splice @$img, $i, 1 if -d $img->[$i]; # remove directories
		}
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
	my $default;
	Tk::catch { $default = $self->Photo( -file => $err, -format => 'png' ) };
	if ($@ || !$default) {
		carp "Tk::Thumbnail: cannot make a Photo from '$err' (default image missing)?!.";
		return;
	}

	$self->{'cols'} = $cols;
	%{$self->{'selected'}} = ();
	@{$self->{'data'}} = ();
	$self->{'btnnormalbg'} = $self->cget('-background');
	my $takefocus = $self->cget('-focus');

	my $indx = 0;
	my $ext;
	THUMB:  foreach my $r ( 0 .. $rows - 1 ) {
		foreach my $c ( 0 .. $cols - 1 ) {
			last THUMB if --$count < 0;

			my $bad_photo = 0;
			my $i = @$img[$#$img - $count];
			my( $photo, $w, $h, $animated, $ext );

			$animated = 0;
			if ( UNIVERSAL::isa( $i, 'Tk::Photo' ) ) {
				$photo = $i;
			} else {
				$ext = (-d $i) ? 'dir' : ($i =~ /.\.(\w+)$/o) ? $1 : '';
				$ext =~ tr/A-Z/a-z/;
				#Tk::catch { $photo = $self->Photo( -file => $i ) };
				if ($i =~ /\.xpm$/io) {  #WORK AROUND STUPID PERL BUG THAT *SEGFAULTS* IF XPM PIXMAP DATA CONTAINS "/*"?!:
					if (open IN, $i) {
						my $img = '';
						while (<IN>) {
							$img .= $_;
						}
						close IN;
						my @imgdata = split(/\{/o, $img, 2);
						$img = '';
						$imgdata[1] =~ s#\/\*#\\\*#gs;
						Tk::catch { $photo = $self->Photo(-data => ($imgdata[0].'{'.$imgdata[1]), -format => 'xpm') };
					}
				} else {  #FOR NON-XPM IMAGES, LOAD THE NORMAL WAY:
					Tk::catch { $photo = $self->Photo( -file => $i ) };
				}
				unless ( $@ || !$haveAnimation ) {  #GOOD IMAGE, SEE IF WE'RE AN ANIMATED GIF:
					Tk::catch { $photo = $self->Animation( -file => $i, -format => 'gif' ) };
					$animated = 1 unless $@;
				}
			}

			unless ($photo) {  #WE'RE NOT AN IMAGE FILE, SO SEE IF WE HAVE AN IMAGE FOR THIS FILE'S EXTENSION:
				if ($extimg && $extimg->{$ext})
				{
					if ( UNIVERSAL::isa( $extimg->{$ext}, 'Tk::Photo' ) ) {
						$photo = $extimg->{$ext};
					} else {
						Tk::catch { $photo = $self->Photo( -file => $extimg->{$ext} ) };
					}
				}
			}
			unless ($photo) {  #WE HAVE NO IMAGE, SO USE THE DEFAULT IMAGE (failimg.png):
				$photo = $default;
				$bad_photo++;
			}
			( $w, $h ) = ( $photo->width, $photo->height );

			my $subsample;
			$subsample = $self->Photo;
			my $sw = $pxx == -1 ? 1 : ( $w / $pxx );
			my $sh = $pxy == -1 ? 1 : ( $h / $pxy );

			if ($w > $pxx || $h > $pxy) {  #ICON IS BIGGER THAN THUMBNAIL SIZE:
				my $zf = ($w > $h) ? $sw : $sh;
				$zf = int ($zf + 0.5);
				Tk::catch { $subsample->copy( $photo, -subsample => ( $zf, $zf ) ); };
				$bad_photo++  if ($@)
			} else {                       #ICON IS SMALLER THAN THUMBNAIL SIZE:
				my $zf = ($w > $h) ? $sw : $sh;
				unless ($zf =~ /[1-9]/o)
				{
					$zf = 1;
				}
				$zf = ($zf && $zf !~ /[1-9]/o) ? 1 : 1 / $zf;
				$zf = 1  if ($noexpand || $zf < 1);
				Tk::catch { $subsample->copy( $photo, -zoom => $zf, $zf) };
				#carp "Tk::JThumbnail: error with '$i': $@" if $@;
				$bad_photo++  if ($@);
			}
			push @{$self->{photos}}, $subsample;
			${$self->{'selected'}}{$i} = $selected->[$indx] || 0;
			my $b = $self->Label(
					-image => $subsample,
					-compound => 'top',
					-relief => 'flat',
					-text => $lbl ? $i : '',
					-background => (${$self->{'selected'}}{$i} ? $self->{'btnselbg'} : $self->{'btnnormalbg'}),
					-foreground => $self->cget('-foreground'),
			)->grid(-sticky => 's');

			$b->bind('<4>', sub { $self->yview(scroll => -5, 'units')});
			$b->bind('<5>', sub { $self->yview(scroll => 5, 'units')});
			$b->bind('<Button-6>', sub { $self->xview(scroll => -5, 'units')});
			$b->bind('<Button-7>', sub { $self->xview(scroll => 5, 'units')});
			$b->bind('<B1-Motion>', sub { $self->Motion(Ev('index',Ev('@')))});
			$b->bind('<ButtonPress-1>', sub {   #NEEDED FOR "MOTION-DRAG SELECT TO WORK:
					my $clickedon = $self->index('mouse');
					$self->activate($clickedon);
					if ($takefocus > 1) {   #IF -focus => 2: TAKE FOCUS WHEN CLICKED ON:
						$self->update;
						$self->focus();
						$self->parent->focus();
					}
					$self->{'anchor'} = $self->{'prev'} = $self->index('mouse');
					$self->{'deselecting'} = $self->isSelected($self->{'prev'});
			});
			$b->grid( -row => $r, -column => $c );
			push @{$self->{'descendants'}}, $b;
			${$self->{'selected'}}{$i} = $selected->[$indx] || 0;
			push @{$self->{'data'}}, {-index => $indx, -label => $b, -filename => $i, -bad => $bad_photo,
					-width => $w, -height => $h, -animated => $animated, -blankit => $self->cget( '-blank' ),
					-row => $r, -col => $c, -photo => $subsample
			};  #KEEP ALL THE DATA NEEDED BY THE LEGACY CALLBACK.

			$photo->delete unless UNIVERSAL::isa( $i, 'Tk::Photo' ) or $photo == $default;

			#BIND THE LEGACY CALLBACK (UNLESS -command => undef):
			$b->bind('<ButtonRelease-1>' => [ $self => 'Callback', '-command', $self, $indx ])
					if (defined $self->cget('-command'));  #WE NOW JUST PASS THE INDEX, ${$self->{'data'}}[$indx] HAS ALL THE DATA!

			#BIND ALL THE bindImages SEQUENCES TO EACH IMAGE SUBWIDGET (CAN OVERRIDE LEGACY CALLBACK BINDING ABOVE!):
			foreach my $bindkey (keys %{$binds}) {
				if ($binds->{$bindkey} =~ /ARRAY/o) {   #[\&callback, args...]
					my @binds = @{$binds->{$bindkey}};
					my $me = shift @binds;
					unshift @binds, $self;   #MUST PUSH OURSELF BETWEEN CALLBACK AND OTHER ARGS!
					unshift @binds, $me;
					$b->bind($bindkey => [@binds]);
				} else {                                #sub { &callback(args...) }
					$b->bind($bindkey => [$binds->{$bindkey}]);
				}
			}
			++$indx;
		} # forend columns
	} #forend rows
	$self->{'active'} = -1;
	if ($indx) {  #DEFAULT BINDINGS TO THE FRAME ITSELF (UNLESS WE'RE A COMPLETELY EMPTY LIST):
		$self->{'frame'} = ${$self->{'descendants'}}[0]->parent;
		$self->{'frame'}->bind('<Right>', sub { my $self = shift->parent; my $i = $self->index('active'); $self->activate($i+1); });
		$self->{'frame'}->bind('<Left>', sub { my $self = shift->parent; my $i = $self->index('active'); $self->activate($i-1); });
		$self->{'frame'}->parent->bind('<Up>', sub { my $self = shift->parent; my $i = $self->index('active'); $self->activate($i-$self->{'cols'}); });
		$self->{'frame'}->parent->bind('<Down>', sub { my $self = shift->parent; my $i = $self->index('active'); $self->activate($i+$self->{'cols'}); });
		$self->{'frame'}->parent->bind('<ButtonPress-1>', sub { my $self = shift; $self->focus(); })  if ($takefocus > 1);
		$self->{'frame'}->configure('-takefocus' => (defined($takefocus) && !$takefocus) ? 0 : 1);
		$self->{'frame'}->bind('<Home>',  sub { shift->parent->xview('moveto' =>  0) });
		$self->{'frame'}->bind('<End>',   sub { shift->parent->xview('moveto' =>  1) });
		$self->{'frame'}->bind('<Prior>', sub { shift->parent->yview('moveto' => -1) });
		$self->{'frame'}->bind('<Next>',  sub { shift->parent->yview('moveto' =>  1) });
		$self->{'frame'}->bind('<Return>' => [ $self => 'Callback', '-command', $self, 'active' ])
				if (defined $self->cget('-command'));

		#BIND ALL THE bindImages SEQUENCES TO THE FRAME ITSELF (AREAS OUTSIDE THE IMAGE SUBWIDGET - NEEDED MOSTLY FOR MOUSE BINDINGS):
		foreach my $bindkey (keys %{$binds}) {
			if ($binds->{$bindkey} =~ /ARRAY/o) {   #[\&callback, args...]
				my @binds = @{$binds->{$bindkey}};
				my $me = shift @binds;
				unshift @binds, $self;   #MUST PUSH OURSELF BETWEEN CALLBACK AND OTHER ARGS!
				unshift @binds, $me;
				$self->{'frame'}->bind($bindkey => [@binds]);
			} else {                                #sub { &callback(args...) }
				$self->{'frame'}->bind($bindkey => [$binds->{$bindkey}]);
			}
		}
		$self->activate(0);  #ACTIVATE THE FIRST IMAGE TO START.
	}
	$self->update;

} # end render

sub bindRows {   #SYNONYM FOR bindImages(), NAMED FOR COMPAT. W/Tk::HMListbox IN jfm5 (HAS NOTHING TO DO WITH "ROWS")!
	my ($w, $sequence, $callback) = @_;

	my $subwidget = $w;
	return (keys %{$w->{'_binds'}})  unless (defined $sequence);

	if ($callback eq '') {
		delete $w->{'_binds'}->{$sequence};
		return '';
	}
	$w->{'_binds'}->{$sequence} = $callback;
	return '';
}

sub bindImages {  #APPLY BINDINGS TO THE IMAGES (NEEDED SINCE FRAME DOESN'T PASS BINDINGS TO THE IMAGE WIDGETS)
	return shift->bindRows(@_);
}

sub clear {

	my $self = shift;

	$self->free_photos;		# delete previous images

	if (defined $self->{'descendants'}) {
		foreach my $c ( @{$self->{'descendants'}} ) {
			$c->gridForget;
			$c->destroy;
		}
	}
	%{$self->{'selected'}} = ();
	@{$self->{'data'}} = ();

	$self->update;

} # end clear

sub free_photos {

	# Free all our subsampled Photo images.

	my $self = shift;

	if (defined $self->{photos}) {
		foreach my $photo ( @{$self->{photos}} ) {
			$photo->delete;
		}
	}
	delete $self->{photos};
} # end free_photos

sub activate
{
	my ($self, $indx, %args) = @_;

	$indx = $#{$self->{'descendants'}}  if ($indx =~ /^end$/io);
	$indx = $self->{'active'}  if ($indx =~ /^active$/io);
	return undef  if ($indx < 0 || $indx > $#{$self->{'descendants'}});

	unless ($indx < 0 || $indx > $#{$self->{'descendants'}} || $self->{'active'} == $indx) {
		${$self->{'descendants'}}[$self->{'active'}]->configure(-relief => 'flat');
		$self->Tk::Pane::see(${$self->{'descendants'}}[$indx])  unless ($args{'-nosee'});
		$self->{'active'} = $indx;
		$self->update;
		${$self->{'descendants'}}[$self->{'active'}]->configure(-relief => 'ridge')
				if ($self->{'active'} >= 0);
		###FOCUS ACTIVATES, AVOID RECURSION!: ${$self->{'descendants'}}[$indx]->focus()  if ($self->{'isfocused'});
	}
}

sub isFocused
{
	return shift->{'isfocused'};
}

sub focus
{
	my $w = shift;

	$w->see($w->index('active'));
	$w->{'isfocused'} = 1; 	
}

sub curselection
{
	my $self = shift;

	my @selected = ();
	my $imgindx = 0;
	foreach my $img (@{$self->cget( '-images' )}) {
		push (@selected, $imgindx)  if (${$self->{'selected'}}{$img});
		++$imgindx;
	}

	return wantarray ? () : undef  unless ($imgindx);
	return wantarray ? @selected : \@selected;
}

sub index
{
	my ($self, $mousexy) = @_;

	return -1  unless ($mousexy);
	return $self->{'active'}  if ($mousexy =~ /^active$/io);
	return $#{$self->{'descendants'}}  if ($mousexy =~ /^end$/io);

	$mousexy = '@'.$self->pointerx.','.$self->pointery  if ($mousexy =~ /^mouse$/io);
	$mousexy =~ s/^\@//o;
	my ($mousex, $mousey) = split(/\,/o, $mousexy);
	my $btnwidget = $self->toplevel->containing($mousex, $mousey);
	return $self->getButtonIndex($btnwidget)  if (defined $btnwidget);
	return -1;
}

sub get
{
	my ($self, $indx) = @_;

	$indx = $#{$self->{'descendants'}}  if ($indx =~ /^end$/io);
	$indx = $self->{'active'}  if ($indx =~ /^active$/io);
	return undef  if ($indx < 0 || $indx > $#{$self->{'descendants'}});
	return ${$self->cget('-images')}[$indx];
}

sub getRow   #CONVENIENCE METHOD NAMED FOR COMPAT. W/Tk::HMListbox IN jfm5 (HAS NOTHING TO DO WITH "ROWS")!
{
	my ($self, $indx) = @_;

	$indx = $#{$self->{'descendants'}}  if ($indx =~ /^end$/io);
	$indx = $self->{'active'}  if ($indx =~ /^active$/io);
	return undef  if ($indx < 0 || $indx > $#{$self->{'descendants'}});

	my $fn = ${$self->cget('-images')}[$indx];
	return wantarray ? (${$self->{'data'}}[$indx], $fn, ((-d $fn) ? 'd' : '-')) : $fn;
}

sub getButtonIndex
{
	my ($self, $btn) = @_;

	my @images = @{$self->cget( '-images' )};
	for (my $i=0;$i<= $#{$self->{'descendants'}};$i++) {
		return $i  if (${$self->{'descendants'}}[$i] eq $btn);
	}
	return -1;
}

sub indexOf
{
	my ($self, $fn) = @_;

	my @images = @{$self->cget( '-images' )};
	for (my $i=0;$i<= $#images;$i++) {
		return $i  if ($images[$i] eq $fn);
	}
	return -1;
}

sub selectionSet
{
	my $self = shift;
	my @args = @_;

	for (my $i=0;$i<=$#args;$i++) {
		$args[$i] = $#{$self->{'descendants'}}  if ($args[$i] =~ /end/io);
		$args[$i] = $self->{'active'}  if ($args[$i] =~ /^active$/io);
		$args[$i] = $self->index($args[$i])  if ($args[$i] =~ /\D/o);
	}
	my @indexRange = (@args);
	@indexRange = ($args[1] < $args[0]) ? reverse($args[1]..$args[0]) : ($args[0]..$args[1])  if (defined($args[1]) && !defined($args[2]));

	foreach my $indx (@indexRange) {
		my $fn = $self->get($indx);
		${$self->{'selected'}}{$fn} = 1;
		${$self->{'descendants'}}[$indx]->configure(-background => $self->{'btnselbg'});
	}
}

sub isSelected
{
	my ($self, $indx) = @_;

	return undef  if ($indx < 0 || $indx > $#{$self->{'descendants'}});
	return ${$self->{'selected'}}{$self->get($indx)} ? 1 : 0;
}

sub selectionToggle
{
	my ($self, $indx) = @_;

	$indx = $#{$self->{'descendants'}}  if ($indx =~ /^end$/io);
	$indx = $self->{'active'}  if ($indx =~ /^active$/io);
	return undef  if ($indx < 0 || $indx > $#{$self->{'descendants'}});

	my $fn = $self->get($indx);
	${$self->{'selected'}}{$fn} = ${$self->{'selected'}}{$fn} ? 0 : 1;
	${$self->{'descendants'}}[$indx]->configure(-background => (${$self->{'selected'}}{$fn} ? $self->{'btnselbg'} : $self->{'btnnormalbg'}));

	return ${$self->{'selected'}}{$fn};
}

sub selectionClear
{
	my ($self, $indx, $indx2) = @_;

	$indx = $#{$self->{'descendants'}}  if ($indx =~ /^end$/io);
	$indx = $self->{'active'}  if ($indx =~ /^active$/io);
	$indx2 = $indx  unless (defined $indx2);
	$indx2 = $#{$self->{'descendants'}}  if (defined($indx2) && $indx2 =~ /^end$/io);
	return undef  if ($indx < 0 || $indx2 < 0 || $indx > $#{$self->{'descendants'}}
			|| $indx2 < $indx || $indx2 > $#{$self->{'descendants'}});

	my $fn;
	for (my $i=$indx; $i<=$indx2; $i++) {
		$fn = $self->get($i);
		${$self->{'selected'}}{$fn} = 0;
		${$self->{'descendants'}}[$i]->configure(-background => $self->{'btnnormalbg'});
	}
}

sub see
{
	my ($self, $indx) = @_;

	$indx = $#{$self->{'descendants'}}  if ($indx =~ /end/io);
	$self->Tk::Pane::see(${$self->{'descendants'}}[$indx])  unless ($indx < 0 || $indx > $#{$self->{'descendants'}});
}

sub Motion
{
	my $w = shift;
	my $el = shift;
	my $Ev = $w->XEvent;
	return  unless (defined $el);

	my $over = $w->index('mouse');
	if ($over >= 0 && $over != $w->{'prev'}) {
		$w->{'deselecting'} ? $w->selectionClear($w->{'prev'})
				: $w->selectionSet($w->{'prev'});
		$w->{'prev'} = $over;
	}
}

1

__END__

=head1 NAME

Tk::JThumbnail - Present a list of files in a directory as a grid of icons with or without text.

=head1 AUTHOR

Jim Turner

(c) 2019, Jim Turner under the same license that Perl 5 itself is.  All rights reserved.

=head1 ACKNOWLEDGEMENTS

Derived from L<Tk::Thumbnail>, by Stephen O. Lidie (Copyright (C) 2001 - 2005, Steve Lidie. All rights reserved.)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2019 Jim Turner.

Tk::JThumbnail is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this program; if not, write to the Free
Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301  USA

=head1 SYNOPSIS

	my $thumb = $parent->JThumbnail(-option => value, ... );

=head1 EXAMPLE

	#!/usr/bin/perl -w

	use strict;
	use Tk;
	use Tk::JThumbnail;

	my $mw = MainWindow->new;
	my @list = directory($ARGV[0] || '.');  #Directory to fetch files from.

	my $thumb = $mw->Scrolled('JThumbnail',
			-images => \@list,
			-width => 500,
			-scrollbars => 'osoe',
			-highlightthickness => 1,
			-focus => 2,
			-nodirs => 1,
	)->pack(-side => 'top', -expand => 1, -fill => 'both');

	$thumb->Subwidget('yscrollbar')->configure(-takefocus => 0);
	$thumb->Subwidget('xscrollbar')->configure(-takefocus => 0);
	$thumb->Subwidget('corner')->Button(
			-bitmap => $Tk::JThumbnail::CORNER,
			-borderwidth => 1,
			-takefocus => 0,
			-command => [\&cornerjump, $thumb],
	)->pack;

	my $b2 = $mw->Button(
			-text=>'E~xit',
			-command => sub{
					print "ok, bye.\n";
					exit(0)
			}
	)->pack(qw/-side top/);

	#EXAMPLE CALLBACK BINDING (RIGHT MOUSE-BUTTON):
	$thumb->bindImages('<ButtonRelease-3>' => [\&RighClickFunction]);

	$thumb->focus();

	MainLoop;

	exit(0);

	sub RighClickFunction  #CALLBACK BOUND TO RIGHT MOUSE-BUTTON:
	{
		my $self = pop;

		my $indx = $self->index('mouse');
		my $fn = $self->get($indx);
		print "---You right-clicked on file ($fn) at position: $indx!\n";
	}

	sub cornerjump   #CALLBACK WHEN "CORNER" BUTTON PRESSED:
	{
		my $self = shift;

		$self->activate($self->index('active') ? 0 : 'end');
	}

	sub directory   #FETCH LIST OF IMAGE FILES TO BE DISPLAYED:
	{
		my ($dir) = @_;
		chdir($dir);
		$dir .= '/'  unless ($dir =~ m#\/#);
		my $pwd = `pwd`; chomp $pwd;
		$mw->title ("Directory: $pwd");
		opendir (DIR, ".") or die "Cannot open '.': $!\n";
		my @files = ();
		foreach my $name (readdir(DIR)) {	
			my $st = stat($name);
			next  unless ($st);
			push @files, $name;
		}
		return sort @files;
	}

=head1 DESCRIPTION

Tk::JThumbnail is derived from the old Tk::Thumbnail widget.
The reason for this fork is to: 

1)  Fix some issues including an FTBFS to run in modern Perl 5.

2)  Add some features needed to use in my JFM5 Filemanager to provide 
it with a "graphical" option of displaying files in a directory with 
thumbnail images (including icons based on file extension), along with 
the other ("text") option uses my L<Tk::HMListbox> widget, similarly 
derived from the older Tk::MListbox.  (JFM5 is derived from my 
JFM4 filemanager, but adds an icon-view using THIS module)!

The main new features are:

1)  Ability to display an alternate icon for non-image files, based 
on their file-extension.

2)  Ability to "select" images (files) for further processing (as is 
done in a file-manager).

3)  Ability to bind both mouse and keyboard operatons to the individual 
images allowing for right-clicking, shift-clicking, dragging to 
select / unselect images, keyboard-traversal via arrow-keys, etc.

4)  Added method compatability with Tk::HMListbox methods needed by 
a filemanager (JFM5 in particular) to allow for both to be swapped 
in and out with very similar code, while minimizing changes needed for 
giving the file-manager user the ability to display files 
either in line-detail mode (Tk::HMListbox) or icon-mode (Tk::JThumbnail) 
and interact on them in a similar fashon.

5)  A "default" (fail-through) image added for display when a non-image 
file is encountered or an image file that can not be properly rendered.  
This file is in images/ and is called "failimg.png", and can be replaced 
with whatever default image you wish to use (must be named "failimg.png").

6)  Perl can CRASH (segfault) if a .xpm image containing the C comment 
string "/*" is processed - OUCH!  We work around this now by reading 
in .xpm images and converting this string to something harmless.

The original relevant Tk::Thumbnail documentation, including our additions 
follows below:

Create a table of thumbnail images, having a default size of 32 x 32
pixels.  Once we have a B<Photo> of an image, shrink it by copying a
subsample of the original to a blank B<Photo>. Images smaller than the
thumbnail dimensions are enlarged by zooiming.

Clicking on an image displays it full-size in a separate window with a
"Get Info" button.  The info window shows the image's width, height,
path name, size and frame count.

For multi-frame GIFs the image is shown with an extra button to play / 
stop the animation.

=over 4

=item B<-blank>

For animated GIFs, a boolean specifying whether to blank the animation 
photo between movie frames.  Default is now I<0> (I<FALSE>).  This flag 
is passed to B<Tk::Animation>'s I<set_disposal_method>().

=item B<-columns>

Number of Photos per row. The column count is computed if not specified.  
Default:  computed to mostly form a square (columns == rows).

=item B<-command>

A Legacy callback that's executed on a <Button-1> event over a thumbnail
image.  It's passed 2 arguments:  the thumbnail widget itself, and the index 
of the image clicked on (or the active image if <Return> key pressed.  
In L<Tk::Thumbnail> It was passed six arguments: the Label widget 
reference containing the thumbnail B<Photo> image, the file name of the
B<Photo>, a boolean indicating whether or not the the B<Photo> is
valid, the B<Photo>'s pixel width and height, and a boolean indicating
whether the image is a single frame (Tk::Photo) or has multiple frames
(Tk::Animation); but now this information can be fetched form the hash 
referenced by $self->{'data'}[$index] where $self and $index represent 
the two arguments passed in.

A default callback is provided that simply displays
the original image in a new Toplevel widget, along with a Get Info
Button that opens another Toplevel containing information about the
image.  For multi-frame GIFs the image is shown with an extra button 
to play / stop the animation.

To override this default <Button-1> callback, use the I<bindImages>() 
function to set your own, or set B<-command> => undef to have 
no <Button-1> callback.

Example:  I<$thumb>->B<bindImages>('<Button-1>' => [\&I<mycallbackfn> [, args] ]);

=item B<-extimages>

B<JThumbnail-added feature>:  Optional reference to a hash of icon images 
to be displayed for non-image files.  The hash keys are file extensions 
and the values image files for the icons.  Default:  {} (I<none>).

Example:  {'txt' => '/usr/local/pixmaps/texticon.png', 'pdf' => '/usr/local/pixmaps/adobe.jpg' [, ...]}

Special keys are:  '' for files with no or unrecognized extension, and 'dir' 
for directories.

=item B<-focus>

B<JThumbnail-added feature>:  Specify the focusing model.  Valid values are:

0:  Never take keyboard focus (and skip in the main window's 
tab-focusing order).

1:  Take focus when tabbed to from the main window (normal "-takefocus => 1" 
action for Tk widgets).

2:  Also take keyboard focus whenever an icon in the widget or the 
widget itself is clicked on.

Default:  I<1>.

=item B<-font>

The default font is B<fixed>.

=item B<-highlightthickness>

Set the frame border around the images, becomes visible when widget has 
keyboard focus.  Default I<0> (I<none>).  Recommended:  I<1> (pixel wide).

=item B<-ilabels>

A boolean, set to I<TRUE> if you want file names displayed under the
thumbnail images.  Default I<TRUE>.

=item B<-images>

A list (reference) of file names and/or B<Photo> widgets.  B<JThumbnail> 
creates temporarty B<Photo> images from all the files, and destroys them 
when the B<JThumbnail> is destroyed or when a new list of images is
specified in a subsequent B<configure> call.  Already existing
B<Photo>s are left untouched.

=item B<-iheight>

Pixel height of the thumbnails.  Default is I<32>. The special value -1 
means don't shrink images in the Y direction.

=item B<-iwidth>

Pixel width of the thumbnails.  Default is I<32>. The special value -1 
means don't shrink images in the X direction.

=item B<-nodirs>

B<JThumbnail-added feature>:  Do not include directories in the list.  
Default I<0> (I<FALSE>) - include them.

=item B<-noexpand>

B<JThumbnail-added feature>:  If set to I<TRUE>, Do not zoom tiny images 
(smaller than I<-iwidth> x I<-iheight>) to fill those dimensions, but keep 
their original size.  Default is I<0> (I<FALSE>) - zoom (expand) them 
until one dimension fills that space (aspect maintained), 
as B<Tk::Thumbnail> does.

=item B<-selectbackground>

B<JThumbnail-added feature>:  Set a different background color for images 
that are "selected".  Default:  the palette's "I<readonlyBackground>" or 
"I<highlightBackground>", or, if those are the same as the current 
background, a different shade of gray will be used.

=item B<-selected>

B<JThumbnail-added feature>:  Optional reference to a list of boolean 
values corresponding to the indicies of images to be marked as currently 
"selected".  Default:  [] (I<none>).

Example:  To select the first and fifth images:  -selected => [1,0,0,0,1]

All images beyond the fifth will not be selected.

=item B<-takefocus>

NOTE:  DO NOT USE (it doesn't work properly)!  Instead use the B<-focus> 
option, see above:

=back

=head1 METHODS

=over 4

=item $thumb->B<activate>(I<index>);

B<JThumbnail-added feature>:  Sets the active element to the one indicated 
by I<index>.  If I<index> is outside the range of elements in the list 
then I<undef> is returned.  The active element is drawn with a ridge 
around it, and its index may be retrieved with the index B<'active'>.

=item $thumb->B<bindImages>(I<sequence>, I<callback>);

B<JThumbnail-added feature>:  Adds the binding to all images in the widget.  
This is needed because normal events to the main widget itself are NOT 
passed down to the image subwidgets themselves.

=item $thumb->B<bindRows>(I<sequence>, I<callback>);

B<JThumbnail-added feature>:  Synonym for B<bindImages> for compatability 
in file-managers, etc. that use both this and B<Tk::HMListbox> 
interchangability for displaying directory contents.  Other that that, 
it really has nothing to do with "rows".

=item $thumb->B<clear>();

Destroys all Frames and Labels, and deletes all the temporary B<Photo> 
images, in preparation for re-populating the JThumbnail with new data.

=item $thumb->B<curselection>();

B<JThumbnail-added feature>:  Returns a list containing the numerical 
indices of all of the elements in the HListbox that are currently 
selected.  If there are no elements selected in the listbox then an empty
list is returned.

=item $thumb->B<get>(I<index>);

B<JThumbnail-added feature>:  Returns the file-name of the image 
specified by I<index>.  I<index> can be either a number, 'active', or 'end'.

=item $thumb->B<getRow>(I<index>)

B<JThumbnail-added feature>:  In scalar context, returns the file-name 
of the image specified by I<index>.  In list context, returns an array 
with the following elements:

=over 4

[0]:  Hash-reference to the detailed data-elements saved for each image.

[1]:  The file-name of the image.

[2]:  Directory indicator:  either 'd' if image file is a directory, or '-' 
if not.  This is from the first character of an "ls -l" list and is this 
way for compatability with Tk::HMListbox, as used by the JFM5 
file-manager for determining whether an entry is a directory or not.

=back

This method is provided for convenience for creating file-managers, such 
as B<JFM5>.

The keys of the hash-reference (first argument) are:

    -index:  Index number of the image file returned.

    -label:  Widget containing the image.

    -filename:  File-name of the image.

    -bad:  True if not an image file or the image could not be rendered.

    -width:  The pixel width of the image file.

    -height:  The pixel height of the image file.

    -animated:  True if the image is an animation (animated GIF).

    -blankit:  The value of the boolean I<-blank> option.

    -row:  Row index# where the image is displayed in the widget.

    -col:  Column index# where the image is displayed in the widget.

    -photo:  The photo object of the image file.

=item $thumb->B<index>(I<index-expression>);

B<JThumbnail-added feature>:  Returns a valid index number based in the 
I<index-expression>, or -1 if invalid or out of range.  I<index-expression> 
can be any of the following:  I<number>, I<'active'>, I<'end'>, I<'mouse'>, 
or I<'@x,y'> (where x & y are the pointer[x|y] pixel coordinates of 
the mouse cursor in the widget).  I<'mouse'> can be used to get the 
index of the widget under the mouse pointer (or just clicked on).
NOTE:  $thumb->index('end') returns the index of the last image in 
the list, so adding 1 to this gets the total count of images in the 
list!

=item $thumb->B<indexOf>(I<image-filename>);

B<JThumbnail-added feature>:  Returns the index# of the image file-name, 
or -1 if not a valid file-name in the list.

=item $thumb->B<isFocused>();

B<JThumbnail-added feature>:  Returns I<TRUE> if $thumb has the keyboard 
focus, I<FALSE> otherwise.

=item $thumb->B<isSelected>(I<index>);

B<JThumbnail-added feature>:  Returns I<TRUE> if the image is currently 
selected or I<FALSE> otherwise.  Returns I<undef> if I<index> is invalid 
or out of range.  NOTE:  I<index> must be a valid I<number>, 
use $thumb->B<index>() to get a valid I<index> number.

=item $thumb->B<selectionSet>(I<index> [ , I<index> ...]);

B<JThumbnail-added feature>:  If a single I<index> is given, that image 
is "selected".  If two indices are given, all images between the two, 
inclusive are selected.  If three or more are given, each image in the 
list is selected.  I<index> can be either a I<number> or I<end>.

=item $thumb->B<selectionToggle>(I<index>);

B<JThumbnail-added feature>:  Toggles the selection state of the image 
given by I<index>, then returns the selection state of the image AFTER 
the toggle.

=item $thumb->B<selectionClear>(I<index> [ , I<index> ...]);

If a single I<index> is given, that image is "selected".
If two indices are given, all images between the two, inclusive are 
de-selected, if selected.  If three or more are given, each image in 
the list is de-selected.  I<index> can be either a I<number> or I<end>.

=back

=head1 NOTES

1)  There are no insert, delete, or sort methods.  One must "reconfigure" 
the widget with a new list of images in order to change the list, example:

$thumb->B<configure>(I<-images> => \@filelist);

which will replace all the images with the new list.

2)  B<-takefocus> does not work, use B<-focus> instead.

3)  The default for scrollbars seems to be "osow" even though I've 
specified "osoe" in this code.  Not sure why, but to set "osoe" 
(SouthEast / Lower and Right), you should specify "-scrollbars => 'osoe'!
"osoe" is best, if you are using the "corner button" option (see the 
Example in this documentation).

4)  I've replaced B<Tk::Thumbnail>'s "multimedia" buttons for animated gifs 
in the default callback which displays the image you clicked on full-sized 
in it's own window since the L<Tk::MultiMediaControls> produces floods of 
errors about "Tk::MasterMenu" being missing, but no such widget seems to 
exist anymore?!  Instead, now there's a simple Play / Stop button to play 
the animation.

5)  The default callback to display full-sized images and info. in a 
separate popup window is invoked whenever one clicks on an image OR now, 
when one presses the B<Return> key, the active image is displayed as such.  
To NOT do this, specify:

B<-command> => I<undef>.

OR specify your own callback function for B<-command>, OR override both 
I<<lt>ButtonRelease-1<gt>> and I<<lt>Return<gt>> key using the 
B<bindImages>() function.  

6)  There are now TWO built-in icon images included with this package:
failimg.png and info3.png in the images/ subdirectory.  You can replace 
them with whatever you wish.  I<failimg.png> is displayed for any 
non-image file or image file that could not be converted properly, or for 
which no B<-extimg> image exists for it's extension.  I<info3.png> is 
displayed for the "info" button in the popup window image by the 
default B<-command> callback.

7)  B<Tk::Animation> is now an optional module (not required).  Needed 
only if you wish to be able to "play" animated GIF images.  
NOTE:  They are not playable from the image display screen, but only via 
a bound callback function, such as the default I<-command> callback.

=head1 KEYWORDS

jthumbnail, thumbnail, icons

=head1 DEPENDS

L<Tk> L<Tk::LabEntry> L<Tk::JPEG> L<Tk::PNG> L<File::Basename>

Optional:  L<Tk::Animation> (for GIF animation)

=head1 SEE ALSO

L<Tk::Thumbnail> L<Tk::Photo>

=cut

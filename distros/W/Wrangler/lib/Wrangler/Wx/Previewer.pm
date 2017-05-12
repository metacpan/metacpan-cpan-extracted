package Wrangler::Wx::Previewer;

use strict;
use warnings;

use base 'Wx::Panel';
use Wx ':everything';
use Wx::Event qw(EVT_PAINT EVT_SIZE EVT_MENU EVT_LEFT_DCLICK EVT_ENTER_WINDOW EVT_LEAVE_WINDOW EVT_LEFT_DOWN EVT_LEFT_UP EVT_RIGHT_UP EVT_TIMER EVT_MOUSEWHEEL);
use IO::Scalar;
use Image::MetaData::JPEG ();

# todo: As a hackish temp solution, video thumbnailing and metadata extraction
# ended up here for the 2.x branch. This probably has to be moved away again, into
# the metadata abstraction once the "on-demand value"-facility fully arrives.

sub new {
	my $class  = shift;
	my $parent = shift;
	my $self = $class->SUPER::new( $parent, -1, wxDefaultPosition, wxDefaultSize, wxSUNKEN_BORDER);

	bless $self, $class;

	# hook-up access to $wrangler
	$self->{wrangler} = $parent->{wrangler};
	$self->{config} = $self->{wrangler}->config();

	## tell central $wishlist what we need
	$Wrangler::wishlist->{'Filesystem::Path'} = 1;
	$Wrangler::wishlist->{'MIME::mediaType'} = 1;
	$Wrangler::wishlist->{'MIME::subType'} = 1;

	## wrangler events
	Wrangler::PubSub::subscribe('selection.changed', sub {
		# Wrangler::debug("Previewer: event selection.changed: @_");

		$self->{timer}->Stop() if $self->{timer}->IsRunning();

		if($_[0] && $_[0] > 1){
		#	Wrangler::debug("Previewer: $_[0] files selected: event ignored.");
			return;
		}

		if($_[1]){
			$self->Populate(${ $_[1] }[0]); # richlist_item
		}else{
			$self->LoadDefault();
		}
	},__PACKAGE__);

	## Wx events
	EVT_PAINT($self, \&OnPaint );
	EVT_SIZE($self,	\&OnSize );
	EVT_LEFT_DCLICK($self,	sub {
		Wrangler::debug('Wrangler::Wx::Previewer: DoubleClick on Thumbnail');

		# emit appropriate event
		Wrangler::PubSub::publish('file.activated', $self->{path}, $self->{richlist_item}) if $self->{path};
	});

	$self->SetBackgroundColour(Wx::Colour->new(50, 50, 50));

	# init scale and center_offset for initial draw event
	$self->{scale} = 1;
	$self->{center_offset} = [0,0];

	$self->{timer} = Wx::Timer->new();

	EVT_ENTER_WINDOW($self, \&OnMouseOver);
	EVT_LEAVE_WINDOW($self, \&OnMouseLeave);
	EVT_LEFT_DOWN($self, \&OnMouseDown);
	EVT_LEFT_UP($self, \&OnMouseUp);
	EVT_RIGHT_UP($self,sub { \&OnRightClick(@_); });
	EVT_TIMER($self->{timer}, $self->{timer}, sub {
		Wrangler::debug("Wrangler::Wx::Previewer: Timer: (load best_quality)");

		$self->Populate(undef,'best_quality');
	});
	EVT_MOUSEWHEEL($self, sub {
		my $multiplier = $_[1]->GetWheelRotation() > 1 ? 1 : -1;
		my @mouse_pos = ($_[1]->GetX(),$_[1]->GetY());
		my @center = ( int($self->{win_w}/2), int($self->{win_h}/2) );
		# $self->{center_offset} = [$mouse_pos[0] - $center[0], $mouse_pos[1] - $center[1]];
		$self->{center_offset} = [ ($center[0] - $mouse_pos[0]) * -1, ($center[1] - $mouse_pos[1]) * -1];
		$self->{scale} += 0.1 * $multiplier; $self->{scale} = 1 if $self->{scale} < 0.1;
		Wrangler::debug("Wrangler::Wx::Previewer: Mousewheel: at:@mouse_pos, center:@center, center-offset:@{$self->{center_offset}}, multiplier:$multiplier, scale:$self->{scale}");

		$self->_recalc();

		$self->Refresh();
	});

	return $self;
}

sub OnMouseOver {
	my ($previewer, $event) = @_;

	## do nothing if we don't display an image
	return if !$previewer->{BmpScaled};

	$previewer->SetBackgroundColour(Wx::Colour->new(55, 55, 55));

	return if !$previewer->{displayed_media_type} || $previewer->{displayed_media_type} ne 'video';

	$previewer->VideoMetadata($previewer->{path}) unless $previewer->{current_meta};

	$previewer->{show_nav} = 1;
}
sub OnMouseLeave {
	my ($self, $event) = @_;

	## do nothing if we don't display an image
	return if !$self->{BmpScaled};

	$self->SetBackgroundColour(Wx::Colour->new(50, 50, 50));

	$self->{show_nav} = 0;
}
sub OnMouseDown {
	my ($self, $event) = @_;

	if($self->{show_nav}){
		my $sleft = $self->{slider_pos} - 2;
		my $sright= $self->{slider_pos} + 2;

		# if( $event->GetPosition->y within top and bottom of slider){
		# if( $event->GetPosition->x within left and right side of slider){
			## commented out, as having to hit the slider on mouse-down is a bit uncomfortable
			#	my $xpos = $event->GetPosition->x;
			#	if($xpos >= $sleft && $xpos <= $sright){
					$self->{slider_hit} = 1;
			#	}
		# }
	}
}
sub OnMouseUp {
	my ($self, $event) = @_;

	if($self->{show_nav}){
		if($self->{slider_hit}){
			if($event->GetPosition->x < 20){
				$self->{slider_pos} = 20+1;
			}elsif($event->GetPosition->x > $self->{win_w} - 20){
				$self->{slider_pos} = $self->{win_w} - 20-1;
			}else{
				$self->{slider_pos} = $event->GetPosition->x - 20;
				my $video_pos_percent = $self->{slider_pos} / $self->{slider_1percent};
				$self->{slider_pos_sec} = int( ($self->{runtime_seconds} / 100) * $video_pos_percent );
				Wrangler::debug("Previewer::OnMouseUp: ".int($video_pos_percent)."% (pos:$self->{slider_pos}) = $self->{slider_pos_sec}");

				$self->LoadRef( $self->VideoThumbnail( $self->{path}, $self->{slider_pos_sec} ) );
				$self->{slider_hit} = undef;
			}
		}
	}
	$self->Refresh();
}

# OnPaint Events happen often!! (be sure to filter when we *need* a Refresh()!)
sub OnPaint {
	my ($self, $event) = @_;

	if($self->{BmpScaled}){
		# Wrangler::debug("Previewer::OnPaint: we display an image");

		## assumes a correctly scaled bmp
		my $dc = Wx::PaintDC->new($self);
		$dc->SetUserScale($self->{scale},$self->{scale}) if $self->{scale} && $self->{scale} != 1;
		$dc->DrawBitmap($self->{BmpScaled}, @{ $self->{Position} }, 1);

		if($self->{show_nav}){
			## draw slider background
			# as long as we can't get the background to render semi-transparent - commented out 
			# $dc->SetBrush( Wx::Brush->new( Wx::Colour->new(0,0,0,128), wxSOLID ) );
			# $dc->SetPen( Wx::Pen->new( Wx::Colour->new(0,0,0), 1, wxSOLID ) );
			# $dc->DrawRectangle( 10, $self->{win_h} - 50, $self->{win_w}-20, $self->{win_h} - 50 );

			## draw slider border
			my $start_y = ($self->{win_h} - 20 - 20);	# top-left start point is 40px above bottom
			my $start_x = 20;				# nav start 20px right of left border
			my $width = ($self->{win_w} - 20 - 20);		# end nav 20px from right minus left margin
			$dc->SetBrush( Wx::Brush->new( Wx::Colour->new(0,0,0,128), wxTRANSPARENT ) );
			$dc->SetPen( Wx::Pen->new( Wx::Colour->new(100,100,100), 1, wxSOLID ) );
			$dc->DrawRectangle( $start_x, $start_y, $width, 20 );

			my $slider_length = $width;
			$self->{slider_1percent} = $slider_length / 100;

			## draw slider indicator
			# todo: this pixels to seconds algo is *not working!*
			if(!$self->{slider_pos}){
				my $pos_percent = 20; # default start percentage
				$self->{slider_pos} = $self->{slider_1percent} * $pos_percent;
			}
			$dc->SetPen( Wx::Pen->new( Wx::Colour->new(130,130,130), 2, wxSOLID ) );
			$dc->DrawLine( int($self->{slider_pos}+20), $start_y +1, int($self->{slider_pos}+20), $start_y + 18 );

			## prepare dc for some timcode numbers
			$dc->SetFont( Wx::Font->new(8, wxFONTFAMILY_MAX, wxFONTSTYLE_NORMAL, wxFONTWEIGHT_NORMAL));
			$dc->SetTextForeground( Wx::Colour->new(130,130,130) );

			## draw video duration (right)
			if( $self->{current_meta} ){
				my $runtime_timecode = $self->{current_meta}->{runtime_timecode};
				$self->{runtime_seconds} = $self->{current_meta}->{runtime_seconds}; # store for later

				my ($text_width,$text_height) = $dc->GetTextExtent($runtime_timecode);
				$dc->DrawText($runtime_timecode, $self->{win_w} - $text_width - 20, $self->{win_h} - $text_height - 3);
			}

			## draw slider's timecode position (left)
			if($self->{slider_pos_sec}){
				my $hrs = int($self->{slider_pos_sec} / (60*60));
				my $rest= $self->{slider_pos_sec} % (60*60);
				my $min = int($rest / 60);
				$rest = $rest % 60;
				my $sec = $rest;
				my ($text_width,$text_height) = $dc->GetTextExtent('00:'.sprintf("%02d", $min).':'.sprintf("%02d", $sec));
				$dc->DrawText(sprintf("%02d", $hrs).':'.sprintf("%02d", $min).':'.sprintf("%02d", $sec), 20, $self->{win_h} - $text_height - 3);
			}
		}
	}
}

sub OnSize {
	my ($self, $event) = @_;

	if($self->{BmpScaled}){
		# Wrangler::debug("Previewer::OnSize: we display an image");

		## onSize events most probably result from a resize, so do transform BmpScaled
		$self->_recalc();  

		## everything calculated. force an OnPaint event by calling Refresh()
		$self->Refresh();
	}
}

sub _recalc {
	my ($self,$update)=@_;

	# update values of $self->{Position}, $self->{BmpScaled},  based on $self->{ImgCurrent} and Window Size

	# Check the Panel dimensions and recalc if they changed, rescaling when needed
	my $win_w = $self->GetClientSize()->GetWidth();
	my $win_h = $self->GetClientSize()->GetHeight();

	$self->{win_w} = $win_w;
	$self->{win_h} = $win_h;

	# Calculate new scaling factor
	my($src_w, $src_h) = ($self->{ImgCurrent}->GetWidth(), $self->{ImgCurrent}->GetHeight());
	my($scl_w, $scl_h) = ($self->{BmpScaled}->GetWidth(), $self->{BmpScaled}->GetHeight());
	my $scale_x = $win_w / $src_w if $win_w && $src_w;
	my $scale_y = $win_h / $src_h if $win_h && $src_h;
	Wrangler::debug("Previewer: _recalc: crash prevented! (division by zero) :$src_w :$src_h") if !$src_w || !$src_h;
	my $scale = $scale_x && $scale_x < $scale_y ? $scale_x : $scale_y ? $scale_y : 0;

	# Calculate new picture dimensions
	my $new_w = int($src_w * $scale);
	my $new_h = int($src_h * $scale);

	# Wrangler::debug("Wrangler::Previewer::_recalc: scale:$scale: $src_w x $src_h => $new_w x $new_h, to fit Window $win_w x $win_h");

	# If picture dimensions must change, rescale the bitmap
	if($update || $new_w != $scl_w || $new_h != $scl_h){
		$self->{BmpScaled} = Wx::Bitmap->new( $self->{ImgCurrent}->Scale($new_w,$new_h) );
	}

	# Center the picture within the window
	$self->{Position} = [0,0];
	if($new_w < $win_w){
		$self->{Position}->[0] = int(($win_w - $new_w) / 2) + round($self->{center_offset}->[0] * $self->{scale});
	}
        if($new_h < $win_h){
		$self->{Position}->[1] = int(($win_h - $new_h) / 2) + round($self->{center_offset}->[1] * $self->{scale});
	}
}

sub round {
	return $_[0] == 0 ? 0 : int($_[0] + $_[0]/abs($_[0]*2));
}

my $regex_jpeg = qr/jpg|jpeg/i;
my $regex_supported = qr/bmp|png|jpg|jpeg|gif|pcx|portable-|tiff|tga|targa|xpixmap|xpm|icon/i;
sub Populate {
	my ($previewer, $richlist_item, $best_quality) = @_;

	$previewer->{richlist_item} = $richlist_item ? $richlist_item : $previewer->{richlist_item};
	$previewer->{path} = $richlist_item ? $richlist_item->{'Filesystem::Path'} : $previewer->{path};	# if supplied, set, else, use stored $path in panel's obj;
	 $richlist_item = $previewer->{richlist_item} unless $richlist_item;
	$previewer->{displayed_media_type} = undef;	# reset stuff
	$previewer->{displaying_ref} = undef;	# reset stuff
	$previewer->{slider_pos} = undef;
	$previewer->{current_meta} = undef;
	$previewer->{scale} = 1;
	$previewer->{center_offset} = [0,0];

	## load from appropriate source
	if($richlist_item->{'MIME::mediaType'}){
	 if($richlist_item->{'MIME::mediaType'} eq 'image' && $richlist_item->{'MIME::subType'} =~ $regex_supported){
		Wrangler::debug("Previewer::Populate: an image");
		if($best_quality){
			Wrangler::debug(" ->Load() (actual file)");
			$previewer->Load($previewer->{path});
			return;
		}

		$previewer->{timer}->Start($previewer->{config}->{'ui.previewer.image.load_original_timeout'} || 800, wxTIMER_ONE_SHOT); # schedule $best_quality load

		# 1st: try to extract an embedded thumbnail-preview, regardless of size
		if($richlist_item->{'MIME::subType'} =~ $regex_jpeg){
			my $file = Image::MetaData::JPEG->new($previewer->{path} , 'APP1', 'FASTREADONLY');
			my $ref = eval { $file->get_Exif_data('THUMBNAIL') }; # above new may have die'd

			## change preview area thumbnail, Load() is smart enough to show default on empty; ref might just be '' (empty)
			if(ref($ref) && UNIVERSAL::isa($ref, 'SCALAR') && $$ref ne ''){
				Wrangler::debug(" ->LoadRef()");
				$previewer->LoadRef($ref);
				return;
			}
		}

		# 2nd: load the actual full image, in case its size is small enough
		my $max_size = $previewer->{config}->{'ui.previewer.image.original_as_preview_max_size'} ? ($previewer->{config}->{'ui.previewer.image.original_as_preview_max_size'} * 1000) : 300000;
		if($richlist_item->{'Filesystem::Size'} < $max_size){
			$previewer->{timer}->Stop();
			Wrangler::debug(" ->Load() (actual file, as its size < max_size cap)");
			$previewer->Load($previewer->{path});
			return;
		}
	 }elsif($richlist_item->{'MIME::mediaType'} eq 'video'){
		Wrangler::debug("Previewer::Populate: a video");

		my $ref = $previewer->VideoThumbnail($previewer->{path}, $previewer->{config}->{'ui.previewer.video.default_thumbnail_position'});
		if($ref){
			$previewer->LoadRef( $ref );
			$previewer->{displayed_media_type} = 'video';
			return;
		}
	 }
	}

	Wrangler::debug("Previewer::Populate: (no preview)");
	$previewer->LoadDefault(); # =load nothing, show "no preview"
}

sub probe_helper {
	my $previewer = shift;

	unless( defined($previewer->{helper_probed}) ){
		my $test = `$Wrangler::Config::env{HelperFfmpeg}`;
		if($test && $test =~ /usage/){
			Wrangler::debug('Previewer: helper found');
			$previewer->{helper_probed} = 1;
		}else{
			Wrangler::debug('Previewer: helper not found');
			$previewer->{helper_probed} = 0;
		}
	}

	return $previewer->{helper_probed};
}

sub VideoThumbnail {
	my $previewer = shift;
	my $path = quotemeta(shift);
	my $thumbpos = shift || 2;

	return undef unless $previewer->probe_helper();

	my $out;
	eval {
		$out = `$Wrangler::Config::env{HelperFfmpeg} -y -ss $thumbpos -i $path -vframes 1 -an -f image2 - 1>&1 2>/dev/null`; # 1>&1 catches out, 2>&1 catches error, ..
	};

	return \$out unless $@;

	Wrangler::debug("Previewer::VideoThumbnail: error:". $@);
	return undef;
}

sub VideoMetadata {
	my $previewer = shift;
	my $path = quotemeta(shift);
	my $thumbpos = shift || 2;

	return undef unless $previewer->probe_helper();

	my $err;
	eval {
		$err = `$Wrangler::Config::env{HelperFfmpeg} -i $path 2>&1`; # catch stderr, where ffmpeg/avconv outputs stuff
	};

	# Wrangler::debug("Previewer::VideoMetadata: $Wrangler::Config::env{HelperFfmpeg} said: ". $err);
	# Duration: 00:00:30.7, start: 0.000000, bitrate: 191 kb/s
	if($err =~ /\QDuration: \E([^,]+)\Q,\E/){
		my $ff;
		$ff->{runtime_timecode} = $1;
		( $ff->{runtime_hrs}, $ff->{runtime_min}, $ff->{runtime_sec} ) = split(/:|\./,$ff->{runtime_timecode});
		$ff->{runtime_seconds} = $ff->{runtime_sec} + ($ff->{runtime_min} * 60) + ($ff->{runtime_hrs} *60*60);
		$previewer->{current_meta}->{runtime_timecode} = $ff->{runtime_timecode};
		$previewer->{current_meta}->{runtime_seconds} = $ff->{runtime_seconds};
		return;
	}

	Wrangler::debug("Previewer::VideoMetadata: error:". $@);
	return undef;
}


sub LoadRef {
	my($previewer,$ref) = @_;

	Wrangler::debug("Previewer::LoadRef: @_");

	## load requested image or default, then init BmpScaled
	$previewer->{ImgCurrent} = Wx::Image->new( IO::Scalar->new($ref), 'image/jpeg');
	$previewer->{BmpScaled} = Wx::Bitmap->new( $previewer->{ImgCurrent} );

	## recalc: transform $self->{BmpScaled}
	$previewer->_recalc(1); 

	## trigger a Paint event
	$previewer->Refresh();

	$previewer->{displaying_ref} = 1; # for SaveThumbnail
}

sub Load {
	my ($self,$path) = @_;

	Wrangler::debug("Previewer::Load: $path");

	## load requested image or default, then init BmpScaled
	$self->{ImgCurrent} = Wx::Image->new($path, wxBITMAP_TYPE_ANY);
	$self->{BmpScaled} = Wx::Bitmap->new( $self->{ImgCurrent} );

	## recalc: transform $self->{BmpScaled}
	$self->_recalc(1); 

	## trigger a Paint event
	$self->Refresh();
}

sub LoadDefault {
	my $self = shift;

	# Wrangler::debug("Previewer::LoadDefault: @_");

	## generate a 'no_preview' bitmap, then init BmpScaled
	unless($self->{no_thumb}){
		Wrangler::debug("Previewer::LoadDefault: generate and cache no_thumb");
		my $dc = Wx::MemoryDC->new();
		$self->{no_thumb} = Wx::Bitmap->new(400, 300, -1);
		$dc->SelectObject($self->{no_thumb});
		$dc->SetBrush( Wx::Brush->new( Wx::Colour->new(0,0,0), wxSOLID ) );
		$dc->DrawRectangle(0, 0, 400, 300); # make sure nothing shines through
		$dc->GradientFillLinear(
			Wx::Rect->new(0,30,399,160),
			Wx::Colour->new(0,0,0),
			Wx::Colour->new(100,100,100),
			wxSOUTH
		);
		$dc->GradientFillLinear(
			Wx::Rect->new(0,190,399,80),
			Wx::Colour->new(100,100,100),
			Wx::Colour->new(0,0,0),
			wxSOUTH
		);
		$dc->SetTextForeground( Wx::Colour->new(220,220,220) );
		$dc->SetFont( Wx::Font->new( 13, wxFONTFAMILY_SWISS , wxNORMAL, wxNORMAL ) );
		my ($text_width) = $dc->GetTextExtent('no preview');
		$dc->DrawText('no preview', int((400 / 2) - ($text_width / 2)), 200 );
		$self->{no_thumb} = $self->{no_thumb}->ConvertToImage;
	}
	$self->{ImgCurrent} = $self->{no_thumb};
	$self->{BmpScaled} = Wx::Bitmap->new( $self->{no_thumb} );

	## recalc: transform $self->{BmpScaled}
	$self->_recalc(1); 

	## trigger a Paint event
	$self->Refresh();
}

sub SaveThumbnail {
	my $previewer = shift;

	# Wrangler::debug("Previewer: $previewer->{richlist_item}->{'Filesystem::Directory'} ");
	my $default_directory = $previewer->{richlist_item}->{'Filesystem::Directory'} ? $previewer->{richlist_item}->{'Filesystem::Directory'} : '';
	my $default_filename = 'thumbnail.jpg';
	if($previewer->{richlist_item} && $previewer->{richlist_item}->{'Filesystem::Basename'}){
		$default_filename = $previewer->{richlist_item}->{'Filesystem::Basename'} .'_thumb';
		$default_filename .= '_'. $previewer->{slider_pos} if $previewer->{slider_pos} && $previewer->{slider_pos_sec};
	#	$default_filename .= '.'.$previewer->{richlist_item}->{'Filesystem::Suffix'} if $previewer->{richlist_item}->{'Filesystem::Suffix'};
		$default_filename .= '.jpg';
	}

	my $dialog = Wx::FileDialog->new($previewer, "Choose a filename and directory", $default_directory, $default_filename, "*.*",  wxFD_SAVE|wxFD_OVERWRITE_PROMPT );

	return unless $dialog->ShowModal() == wxID_OK;

	# currently, LoadRef does not keep the original ref
	# open(my $out, '>', $dialog->GetPath() ) or Wrangler::debug("SaveThumbnail: can't write thumbnail to file: $!");
	# binmode($out);
	# print $out ${ $self->{the_ref_if_we_had_it} };
	# close($out);

	# so we use the built-in Wx solution
	$previewer->{ImgCurrent}->SaveFile($dialog->GetPath(), 'image/jpeg') or Wrangler::debug("SaveThumbnail: can't write thumbnail to file: $!");
}

sub OnDeselected {
	my($self,$path) = @_;

	$self->{BmpScaled} = undef;

	## trigger a Paint event
	$self->Refresh(1);
}

sub OnRightClick {
	my $previewer = shift;
	my $event = shift;

        my $menu = Wx::Menu->new();

		my $itemSave = Wx::MenuItem->new($menu, -1, "Save preview...", 'Save currently displayed thumbnail as a JPEG file');
	$menu->Append($itemSave);
	if( $previewer->{displaying_ref} ){
		$menu->Enable($itemSave->GetId(),1);
		EVT_MENU( $previewer, $itemSave, sub { $previewer->SaveThumbnail(); });
	}else{
		$menu->Enable($itemSave->GetId(),0);
	}
	$menu->AppendSeparator();
	EVT_MENU( $previewer, $menu->Append(-1, "Settings", 'Settings'), sub { Wrangler::PubSub::publish('show.settings', 2, 0); } );

	$previewer->PopupMenu( $menu, wxDefaultPosition );
}

sub Destroy {
	my $self = shift;

	Wrangler::PubSub::unsubscribe_owner(__PACKAGE__);

	$self->SUPER::Destroy();
}

1;

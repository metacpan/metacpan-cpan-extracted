package Wrangler::Wx::Navbar;

use strict;
use warnings;

use base qw(Wx::Panel);
use Wx qw(wxDefaultPosition wxDefaultSize wxHORIZONTAL wxTOP wxLEFT wxRIGHT wxALL wxBU_EXACTFIT wxNO_BORDER);
use Wx::Event qw(EVT_BUTTON EVT_RIGHT_UP EVT_MENU);

our @buffer;
our $history_pointer;

sub new {
	my $class  = shift;
	my $parent = shift;
	my $self = $class->SUPER::new( $parent, -1, wxDefaultPosition, wxDefaultSize );

	# hook-up access to $wrangler
	$self->{wrangler} = $parent->{wrangler};

	$self->SetForegroundColour(Wx::Colour->new(@{ $self->{wrangler}->config()->{'ui.foreground_colour'} })) if $self->{wrangler}->config()->{'ui.foreground_colour'};
	$self->SetBackgroundColour( Wx::Colour->new(229,227,226) ); # $parent->GetBackgroundColour()

	## two sizers
	$self->{sizer} = Wx::BoxSizer->new(wxHORIZONTAL);
	my $sizer = Wx::BoxSizer->new(wxHORIZONTAL);
	$self->{button_prev} = Wx::Button->new($self, -1, '<', wxDefaultPosition, [40,-1], wxBU_EXACTFIT);
	$self->{button_next} = Wx::Button->new($self, -1, '>', wxDefaultPosition, [40,-1], wxBU_EXACTFIT);
	$self->{button_prev}->Disable();
	$self->{button_next}->Disable();
	$sizer->Add($self->{button_prev}, 0, wxLEFT|wxTOP, 7 );
	$sizer->Add($self->{button_next}, 0, wxRIGHT|wxTOP, 7 );
	$sizer->Add($self->{sizer}, 0, wxLEFT|wxTOP, 7);

	$self->SetSizer($sizer);

	## prepare bitmap
	$self->{arrow} = Wx::Bitmap->newFromXPM( $Wrangler::Images::image{'arrow'} );

	## events
	Wrangler::PubSub::subscribe('dir.activated', sub { Wrangler::debug("Navbar::OnDirActivated: @_"); $self->UpdateBreadcrumbs($_[0]) }, __PACKAGE__);
	EVT_BUTTON($self, $self->{button_prev}, sub {
		$history_pointer = $history_pointer ? ($history_pointer - 1) : scalar(@buffer) - 2; # -1 = current, -2 = one-before
		my $path = $buffer[$history_pointer];
		Wrangler::PubSub::publish('dir.activated', $path);
	});
	EVT_BUTTON($self, $self->{button_next}, sub {
		$history_pointer++;
		$history_pointer = undef if $history_pointer == scalar(@buffer) - 1;
		my $path = $buffer[$history_pointer];
		Wrangler::PubSub::publish('dir.activated', $path);
	});
	EVT_RIGHT_UP($self,sub { \&OnRightClick(@_); });

	return $self;
}

sub UpdateBreadcrumbs {
	my $navbar = shift;
	my $path = shift;

	push(@buffer, $path) unless defined($history_pointer);
	if(defined($history_pointer) && $path ne $buffer[$history_pointer] && $path ne $buffer[$history_pointer]){
		$#buffer = $history_pointer ; # truncate array
		$history_pointer = undef;
	}
	shift(@buffer) if @buffer > 9;
	# require Data::Dumper;
	# Wrangler::debug("pointer: $history_pointer -> $buffer[$history_pointer] \n".Data::Dumper::Dumper(\@buffer));

	$navbar->{button_prev}->Enable() if @buffer > 1;
	$navbar->{button_next}->Enable() if defined($history_pointer);
	$navbar->{button_next}->Disable if !defined($history_pointer);
	$navbar->{button_prev}->Disable if defined($history_pointer) && $history_pointer == 0;

	## clear current breadcrumbs
	$navbar->{sizer}->Clear('and delete child windows');
	$navbar->{paths} = {};

	# parse path
	my @fragments = split(/\//,$path);
	@fragments = ('/') unless @fragments;
	my @crumbs;
	for(0 .. $#fragments){
		my $label = $_ == 0 ? 'Filesystem' : $fragments[$_];
		$label =~ s/&/&&/g;
		my $path;
		for my $pindex (0 .. $_){
			$path = $navbar->{wrangler}->{fs}->catfile($path, $fragments[$pindex]);
		}
		$crumbs[$_] = { label => $label, path => $path };
	}

	## first
	my $button = Wx::Button->new($navbar, -1, $crumbs[0]->{label}, wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT | wxNO_BORDER );
	$navbar->{sizer}->Add( $button, 0, wxRIGHT, 5);
	$navbar->{paths}->{ $button->GetId() } = $crumbs[0]->{path};
	EVT_BUTTON($navbar, $button, sub {
		Wrangler::debug("Navbar: path-button: ". $_[1]->GetId .': '. $navbar->{paths}->{ $_[1]->GetId });
		Wrangler::PubSub::publish('dir.activated', $navbar->{paths}->{ $_[1]->GetId });
	});

	## all other
	for(1 .. $#crumbs){
		my $arrow = Wx::StaticBitmap->new($navbar, -1, $navbar->{arrow});
		$navbar->{sizer}->Add( $arrow, 0, wxTOP|wxLEFT, 5 );

		my $button = Wx::Button->new($navbar, -1, $crumbs[$_]->{label}, wxDefaultPosition, wxDefaultSize, wxBU_EXACTFIT | wxNO_BORDER );
		$navbar->{sizer}->Add( $button, 0, wxLEFT|wxRIGHT, 5);
		$navbar->{paths}->{ $button->GetId() } = $crumbs[$_]->{path};
		EVT_BUTTON($navbar, $button, sub {
			Wrangler::debug("Navbar: path-button: ". $_[1]->GetId .': '. $navbar->{paths}->{ $_[1]->GetId });
			Wrangler::PubSub::publish('dir.activated', $navbar->{paths}->{ $_[1]->GetId });
		});
	}

	$navbar->{sizer}->Layout();
}

sub OnRightClick {
	my $navbar = shift;
	my $event = shift;

        my $menu = Wx::Menu->new();

	my $item = Wx::MenuItem->new($menu, -1, "History:");
	$menu->Append($item);
	$menu->Enable($item->GetId(),0);

	my %path_lookup;
	my $cnt = @buffer;
	for(reverse @buffer){
		my $item = Wx::MenuItem->new($menu, -1, $cnt .'. '. shorten($_) );
		$path_lookup{ $item->GetId() } = $_;
		$menu->Append($item);

		EVT_MENU( $navbar, $item, sub {
			Wrangler::PubSub::publish('dir.activated', $path_lookup{ $_[1]->GetId() } );
		});
		$cnt--;
	}

	$menu->AppendSeparator();
	EVT_MENU( $navbar, $menu->Append(-1, "Settings", 'Settings'), sub { Wrangler::PubSub::publish('show.settings', 0, 0); } );

	$navbar->PopupMenu( $menu, wxDefaultPosition );
}

sub shorten {
	my $string = substr($_[0], -25);
	$string = '...'.$string if length($_[0]) > 25;
	return $string;
}

sub Destroy {
	my $self = shift;

	Wrangler::PubSub::unsubscribe_owner(__PACKAGE__);

	$self->SUPER::Destroy();
}

1;

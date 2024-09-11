package Tk::AppWindow::Ext::Panels;

=head1 NAME

Tk::AppWindow::Ext::Panels - manage the layout of your application

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.12";
use Tk;
require Tk::Adjuster;
require Tk::Pane;

use base qw( Tk::AppWindow::BaseClasses::Extension );

=head1 SYNOPSIS

 my $app = new Tk::AppWindow(@options,
    -extensions => ['Panels'],
 );
 $app->MainLoop;


=head1 DESCRIPTION

Adds a layout of B<Frame> objects to the main window.
You can specify which frames should have a slider.
Each Frame can be in a shown or hidden state.
	
=head1 CONFIG VARIABLES

=over 4

=item B<-panellayout>

Specify the structure of your layout. 

The keys used below are all home to the pack geometry manager. Plus a
few more. These are:

=over 4

=item B<-canhide>

Specify if a panel is capable of hiding and showing. By default 0.

=item B<-adjuster>

If specified the panel is adjustable. The value is transferred to the
B<-side> option of the adjuster.

=back

Default value:

 [
    CENTER => {
       -in => 'MAIN',
       -side => 'top',
       -fill => 'both',
       -expand => 1,
    },
    WORK => {
       -in => 'CENTER',
       -side => 'left',
       -fill => 'both',
       -expand => 1,
    },
    TOP => {
       -in => 'MAIN',
       -side => 'top',
       -before => 'CENTER',
       -fill => 'x',
       -canhide => 1,
    },
    BOTTOM => {
       -in => 'MAIN',
       -after => 'CENTER',
       -side => 'top',
       -fill => 'x',
       -canhide => 1,
    },
    LEFT => {
       -in => 'CENTER',
       -before => 'WORK',
       -side => 'left',
       -fill => 'y',
       -canhide => 1,
       -adjuster => 'left',
    },
    RIGHT => {
       -in => 'CENTER',
       -after => 'WORK',
       -side => 'left',
       -fill => 'y',
       -canhide => 1,
       -adjuster => 'right',
    },
 ]

=item B<-workspace>

Specifies the central workspace of your application.
Default value is WORK.

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	$self->addPreConfig(
		-showadjusteratcreate => ['PASSIVE', undef, undef, 1],
	);

	$self->{PACKINFO} = {};
	$self->{ADJUSTACTIVE} = {};
	$self->{ADJUSTERS} = {};
	$self->{ADJUSTINFO} = {};
	$self->{LAYOUT} = undef;
	$self->{PANELS} = {};
	$self->{VISIBLE} = {};

	$self->configInit(
		-panellayout => ['PanelLayOut', $self, [
			CENTER => {
				-in => 'MAIN',
				-side => 'top',
				-fill => 'both',
				-expand => 1,
			},
			WORK => {
				-in => 'CENTER',
				-side => 'left',
				-fill => 'both',
				-expand => 1,
			},
			TOP => {
				-in => 'MAIN',
				-side => 'top',
				-before => 'CENTER',
				-fill => 'x',
				-canhide => 1,
			},
			BOTTOM => {
				-in => 'MAIN',
				-after => 'CENTER',
				-side => 'top',
				-fill => 'x',
				-canhide => 1,
			},
			LEFT => {
				-in => 'CENTER',
				-before => 'WORK',
				-side => 'left',
				-fill => 'y',
				-canhide => 1,
				-paneloptions => [-width => 150],
				-adjuster => 'left',
			},
			RIGHT => {
				-in => 'CENTER',
				-after => 'WORK',
				-side => 'left',
				-fill => 'y',
				-canhide => 1,
				-paneloptions => [-width => 150],
				-adjuster => 'right',
			},
		
		]],
		-workspace => ['WorkSpace', $self->GetAppWindow, 'WORK'],
	);


	return $self;
}

=head1 METHODS

=over 4


=cut

sub adjusterActive {
	my $self = shift;
	my $panel = shift;
	$self->{ADJUSTACTIVE}->{$panel} = shift if @_;
	my $active = $self->{ADJUSTACTIVE}->{$panel};
	return 1 unless defined $active;
	return $active; 
}

sub adjusterAssign {
	my ($self , $name, $panel, $adjuster) = @_;
	$self->{ADJUSTINFO}->{$name} = {
		-widget => $panel,
		-side => $adjuster,
	};
}

sub adjusterClear {
	my ($self, $panel) = @_;
	my $adj = $self->{ADJUSTERS}->{$panel};
	if (defined $adj) {
		$adj->destroy;
		delete $self->{ADJUSTERS}->{$panel};
	}
}

sub adjusterDefine {
	my $self = shift;
	my $panel = shift;
	$self->{ADJUSTINFO}->{$panel} = { @_}
}

sub adjusterSet {
	my ($self , $panel) = @_;
	my $packinfo = $self->{PACKINFO}->{$panel};
	my $adjustinfo = $self->{ADJUSTINFO}->{$panel};
	if (defined $adjustinfo) {
		unless (exists $self->{ADJUSTERS}->{$panel}) {
			my $parent = $self->Subwidget($panel)->parent;
			my $adj = $parent->Adjuster(%$adjustinfo)->pack(%$packinfo);
			$self->{ADJUSTERS}->{$panel} = $adj;
		}
	}
}

sub adjusterStatus {
	my ($self, $panel) = @_;
	return exists $self->{ADJUSTERS}->{$panel}
}

sub adjusterWidget {
	my ($self , $panel, $widget) = @_;
	my $adjustinfo = $self->{ADJUSTINFO}->{$panel};
	$adjustinfo->{'-widget'} = $widget if defined $widget;
	return $adjustinfo->{'-widget'};
}

sub layout { return $_[0]->{LAYOUT}}

sub MenuItems {
	my $self = shift;
	my @items = (
#			 type        menupath   label						cmd						icon					keyb			config variable
 		[	'menu', 				undef,      "~View"], 
	);
	my @list = $self->panelList;
	for (@list) {
		push @items, [	'menu_check',	'View::', "Show ~$_",	undef,	$self->panelOptName($_), undef, 	0,   1], 
	}
	return @items
}

sub menuRefresh {
	my $self = shift;
	my $mnu = $self->extGet('MenuBar');
	$mnu->ReConfigure if (defined $mnu) and (not $self->configMode);
}

=item panelAssignI<($name, ?$panel?)>

Returns the panel assigned to I<$name>.

If I<$panel> is specified assigns I<$name> to <$panel>
and creates a menu entry for I<$name>> in the View menu.

=cut

sub panelAssign {
	my ($self, $name, $panel) = @_;
	my $p = $self->{PANELS};
	if (defined $panel) {
		$p->{$name} = $panel;
		$self->{VISIBLE}->{$name} = 1;
		my $opt = $self->panelOptName($name);
		$self->configInit($opt => ['panelVisible', $self, $panel, 1]);
		$self->menuRefresh;
	}
	return $p->{$name};
}

=item B<panelDelete>I<($name)>

Deletes I<$name> from the list of assigned panels and
removes its menu entry in the View menu.

=cut

sub panelDelete {
	my ($self, $name) = @_;
	delete $self->{PANELS}->{$name};
	delete $self->{VISIBLE}->{$name};
	my $opt = $self->panelOptName($name);
	$self->configRemove($opt);
	$self->menuRefresh;
}


=item B<panelGet>I<($name)>

Returns the name of the assigned panel to $name

=cut

sub panelGet {
	my ($self, $name) = @_;
	return $self->{PANELS}->{$name};
}

=item B<panelHide>I<($panel)>

panelHide $panel and its adjuster if any.

=cut

sub panelHide {
	my ($self, $panel) = @_;
	unless ($self->panelIsHidden($panel)) {
		$self->Subwidget($panel)->packForget;
		$self->adjusterClear($panel);
	}
}

=item B<panelIsHidden>I<($panel)>

Returns the state of $panel. 1 if hidden, 0 if not.

=cut

sub panelIsHidden {
	my ($self, $panel) = @_;
	my $mapped = $self->Subwidget($panel)->ismapped;
	return not $mapped ;
}

sub PanelLayOut {
	my ($self, $layout) = @_;
	return unless defined $layout;
	$self->{LAYOUT} = $layout;
	my @l = @$layout;
	while (@l) {
		my $name = shift @l;
		my $options = shift @l;

		my $in = delete $options->{'-in'};
		die "Error in '$name'. Option -in must be specified" unless defined $in;
		
		my $canhide = delete $options->{'-canhide'};
		$canhide = 0 unless defined $canhide;

		my $parent;
		if ($in eq 'MAIN') {
			$parent = $self->GetAppWindow;
		} else {
			$parent = $self->Subwidget($in)
		}
		die "Error in '$name'. Panel $in does not exist" unless defined $parent;

		my $before = delete $options->{'-before'};
		if (defined $before) {
			my $neighbor = $self->Subwidget($before);
			die "Error in '$name'. Panel $neighbor does not exist" unless defined $neighbor;
			$options->{'-before'} = $neighbor;
		}

		my $after = delete $options->{'-after'};
		if (defined $after) {
			my $neighbor = $self->Subwidget($after);
			die "Error in '$name'. Panel $neighbor does not exist" unless defined $neighbor;
			$options->{'-after'} = $neighbor;
		}

		my $paneloptions = delete $options->{'-paneloptions'};
		$paneloptions = [] unless defined $paneloptions;

		my $adjuster = delete $options->{'-adjuster'};

		my $panel = $parent->Frame(@$paneloptions);
		
		$self->Advertise($name, $panel);
		
		$self->adjusterAssign($name, $panel, $adjuster) if defined $adjuster;
		
		if ($canhide) {
			$self->{PACKINFO}->{$name} = $options;
		} else {
			$panel->pack(%$options);
		}
	}
}

=item B<panelList>

Returns a list of assigned panels

=cut

sub panelList {
	my $self = shift;
	my $p = $self->{PANELS};
	return sort keys %$p
}

sub panelOptName {
	my ($self, $name) = @_;
	return "-$name" . 'visible';
}

=item B<panelShow>I<($panel)>

Show $panel and its adjuster if any.

=cut

sub panelShow {
	my ($self, $name) = @_;
	if ($self->panelIsHidden($name)) {
		my $panel = $self->Subwidget($name);
		my $packinfo = $self->{PACKINFO}->{$name};
		$panel->pack(%$packinfo);
		$self->adjusterSet($name) if $self->adjusterActive($name);
	}
}

sub panelVisible {
	my $self = shift;
	my $panel = shift;
	if (@_) {
		my $status = shift;
		if ($self->configMode) {
		} elsif ($status eq 1) {
			$self->panelShow($panel);
		} elsif ($status eq 0) {
			$self->panelHide($panel);
		}
		$self->{VISIBLE}->{$panel} = $status;
	}
	return $self->{VISIBLE}->{$panel}
}

=back

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::AppWindow>

=item L<Tk::AppWindow::BaseClasses::Extension>

=back

=cut

1;





package Tk::AppWindow::Ext::SideBars;

=head1 NAME

Tk::AppWindow::Ext::SideBars - Basic functionality for side bars.

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.11";
use Tk;
require Tk::YANoteBook;

use base qw( Tk::AppWindow::BaseClasses::Extension );

=head1 SYNOPSIS

 my $app = new Tk::AppWindow(@options,
    -extensions => ['SideBars'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

Provides a primer for panels that contain a resizable YANoteBook for
selecting various tools.

It inherits L<Tk::AppWindow::BaseClasses::Extension>

=head1 CONFIG VARIABLES

=over 4

=item Switch: B<-sidebariconsize>

Default value 32.

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	$self->Require('Panels');
	$self->{ICONSIZE} = 32;
	$self->{INITIALSIZES} = {};
	$self->{LASTSIZE} = {};
	$self->{TABSIDES} = {};
	$self->{PANELS} = {};

	$self->configInit(
		'-sidebariconsize' => ['IconSize', $self, 32]
	);
	return $self;
}

=head1 METHODS

=over 4

=cut

=item B<IconSize>I<(?$size?)>

Set and return the iconsize in the tabs of the notebooks

=cut

sub IconSize {
	my $self = shift;
	$self->{ICONSIZE} = shift if @_;
	return $self->{ICONSIZE};
}

=item B<nbAdd>I<($name, $panel, $tabside)>

Creates a new notebook widget and assigns it to I<$panel>.
If you do not specify I<$tabside> it is set to 'top'.

=cut

sub nbAdd {
	my ($self, $name, $panel, $tabside) = @_;
	$tabside = 'top' unless defined $tabside;
	my $nb = $self->Subwidget($panel)->YANoteBook(
		-onlyselect => 0,
		-rigid => 0,
		-selecttabcall => ['TabSelect', $self, $name],
		-tabside => $tabside,
		-unselecttabcall => ['TabUnselect', $self, $name],
	)->pack(-expand => 1, -fill=> 'both', -padx => 2, -pady => 2);
	$self->geoAddCall($panel, 'OnResize', $self, $name);
	$self->{TABSIDES}->{$name} = $tabside;
	$self->Advertise($name . 'NB', $nb);
	my $pn = $self->extGet('Panels');
	$pn->adjusterWidget($panel, $nb);
	$pn->adjusterActive($panel, 0);
	$pn->panelAssign($name, $panel);
}

=item B<nbDelete>I<($name)>

Destroys notebook I<$name>.

=cut

sub nbDelete {
	my ($self, $name) = @_;
	$name = $name . 'NB';
	$self->Subwidget($name)->destroy;
}

=item B<nbGet>I($name)>

Returns a reference to notebook widget I<$name>.

=cut

sub nbGet {
	my ($self, $name) = @_;
	$name = $name . 'NB';
	return $self->Subwidget($name);
}

=item B<nbMaximize>I<($name, $tab)>

Maximizes notebook I<$name> at the requested size of I<$tab>

=cut

sub nbMaximize {
	my ($self, $notebook, $tab) = @_;
	my $nb = $self->nbGet($notebook);
	my $pf = $nb->Subwidget('PageFrame');
	my $tf = $nb->Subwidget('TabFrame');
	my $panel = $self->extGet('Panels')->panelAssign($notebook);
	$panel = $self->Subwidget($panel);
	my $offset = $self->nbOffset($notebook);
	my $height = $panel->height;;
	my $width = $panel->width;
	my $ls = $self->{LASTSIZE}->{$tab};
	$ls = $self->{INITIALSIZES}->{$tab} unless defined $ls;
	my $ts = $self->{TABSIDES}->{$notebook};
	if (defined $ls) {
		my ($w, $h) = @$ls;
		if (($ts eq 'top') or ($ts eq 'bottom')) {
			$height = $h
		} else {
			$width = $w
		}
	} else {
		if (($ts eq 'top') or ($ts eq 'bottom')) {
			$height = 150;
		} else {
			$width = 300;
		}
	}
	$nb->GeometryRequest($width, $height);
}

=item B<nbMinimize>I<($name, $tab)>

Minimizes notebook I<$name> and saves the size of I<$tab>.

=cut

sub nbMinimize {
	my ($self, $notebook, $tab) = @_;
	my $nb = $self->nbGet($notebook);
	my $tf = $nb->Subwidget('TabFrame');
	$self->{LASTSIZE}->{$tab} = [$nb->width, $nb->height];
	my $ts = $self->{TABSIDES}->{$notebook};
	my $offset = $self->nbOffset($notebook);
	my @size = ();
	if (($ts eq 'top') or ($ts eq 'bottom')) {
		@size = ($nb->width + $offset, $tf->height + $offset);
	} else {
		@size = ($tf->width + $offset, $nb->height + $offset);
	}
	$nb->GeometryRequest(@size);
}

sub nbOffset {
	my ($self, $notebook) = @_;
	my $nb = $self->nbGet($notebook);
	my $tf = $nb->Subwidget('TabFrame');
	return (($tf->cget('-borderwidth') + $nb->cget('-borderwidth')) * 2) +1
}

sub OnResize {
	my ($self, $notebook) = @_;
	my $nb = $self->nbGet($notebook);
	my $pn = $self->extGet('Panels');
	my $p = $pn->panelAssign($notebook);
	my $panel = $self->Subwidget($p);

	my $owidth = $nb->width;
	my $oheight = $nb->height;
	my $offset = $self->panelOffset($notebook);
	my $width = $panel->width - $offset;
	my $height = $panel->height - $offset;
	
	$nb->GeometryRequest($width, $height) if ($width ne $owidth) or ($height ne $oheight);
}

=item B<pageAdd>I<($notebook, $name, $image, $text, $statustext, $initialsize)>

Adds a page to a notebook.

=cut

sub pageAdd {
	my ($self, $notebook, $name, $image, $text, $statustext, $initialsize) = @_;
	$text = $name, unless defined $text;

	$initialsize = 200 unless defined $initialsize;
	$self->{INITIALSIZES}->{$name} = [$initialsize, $initialsize];
	
	my $nb = $self->nbGet($notebook);

	my @opt = ();
	my $art = $self->extGet('Art');
	my $icon;
	if (defined $art) {
		$icon = $art->getIcon($image, $self->IconSize);
		
	}
	@opt = (-titleimg => $icon) if defined $icon;
	@opt = (-title => $text) unless defined $icon;
	my $page = $nb->addPage($name, @opt);

	my $l = $nb->getTab($name)->Subwidget('Label');
	$self->StatusAttach($l, $statustext) if defined $statustext;
	$self->BalloonAttach($l, $text);
	$self->after(500, sub { $nb->UpdateTabs });

	return $page;
}

=item B<pageDelete>I<($notebook, $name)>

Deletes a page from a notebook.

=cut

sub pageDelete {
	my ($self, $notebook, $name) = @_;
	$self->nbGet($notebook)->deletePage($name);
	delete $self->{INITIALSIZES}->{$name};
	delete $self->{LASTSIZE}->{$name}
}

sub panelOffset {
	my ($self, $notebook) = @_;
	my $nb = $self->nbGet($notebook);
	my $border = $nb->cget('-borderwidth');
	my $pad = 0;
	my %pi = $nb->packInfo;
	$pad = $pi{'-padx'} if exists $pi{'-padx'};
	$pad = $pi{'-pady'} if exists $pi{'-pady'};
	return ($border + $pad) * 2;
}

sub TabSelect {
	my ($self, $notebook, $tab) = @_;
	return if $self->configMode;
	$self->geoBlock(1);
	my $pn = $self->extGet('Panels');
	$self->after(1, sub {
		$self->nbMaximize($notebook, $tab);
		my $p = $pn->panelAssign($notebook);
		$pn->adjusterSet($p);
		$pn->adjusterActive($p, 1);
	});
	$self->after(200, ['geoBlock', $self, 0]);
}

sub TabUnselect {
	my ($self, $notebook, $tab) = @_;
	return if $self->configMode;
	my $pn = $self->extGet('Panels');
	my $p = $pn->panelAssign($notebook);
	$pn->adjusterClear($p);
	$pn->adjusterActive($p, 0);
	$self->geoBlock(1);
	$self->nbMinimize($notebook, $tab);
	$self->after(400, ['geoBlock', $self, 0]);
}

=back

=head1 AUTHOR

Hans Jeuken (hanje at cpan dot org)

=head1 BUGS

Unknown. If you find any, please contact the author.

=head1 SEE ALSO

=over 4

=item L<Tk::AppWindow::BaseClasses::Extension>

=item L<Tk::AppWindow::BaseClasses::PanelExtension>

=item L<Tk::AppWindow>


=back

=cut

1;
__END__








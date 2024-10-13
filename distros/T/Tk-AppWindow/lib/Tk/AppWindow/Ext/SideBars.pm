package Tk::AppWindow::Ext::SideBars;

=head1 NAME

Tk::AppWindow::Ext::SideBars - Basic functionality for side bars.

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION = "0.15";
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
	$self->{PAGES} = {};
	$self->{PANELS} = {};
	$self->{SELECTCALLS} = {};
	$self->{UNSELECTCALLS} = {};
	$self->{TABSIDES} = {};
	$self->{TEXTSIDES} = {};

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
	$self->{TABSIDES}->{$name} = $tabside;
	$self->Advertise($name . 'NB', $nb);
	my $pn = $self->extGet('Panels');
	$pn->adjusterWidget($panel, $nb);
	$pn->adjusterActive($panel, 0);
	$pn->panelAssign($name, $panel);
	$pn->panelShow($panel);
}

=item B<nbDelete>I<($name)>

Destroys notebook I<$name>.

=cut

sub nbDelete {
	my ($self, $name) = @_;
	my $pn = $self->extGet('Panels');
	my $panel = $pn->panelGet($name);
	$self->geoDeleteCall($panel);
	$pn->panelDelete($name);
	delete $self->textsides->{$name};
	$name = $name . 'NB';
	$self->Subwidget($name)->destroy;
}

sub nbExists {
	my ($self, $name) = @_;
	$name = $name . 'NB';
	my $book = $self->Subwidget($name);
	return Exists $book if defined $book;
	return undef
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
	$nb->configure(-width => $width);
	$nb->configure(-height => $height);
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
	my ($width, $height);
	if (($ts eq 'top') or ($ts eq 'bottom')) {
		$width = $nb->width + $offset;
		$height = $tf->height + $offset;
	} else {
		$width = $tf->width + $offset;
		$height = $nb->height + $offset;
	}
	$nb->configure(-width => $width);
	$nb->configure(-height => $height);
}

sub nbOffset {
	my ($self, $notebook) = @_;
	my $nb = $self->nbGet($notebook);
	my $tf = $nb->Subwidget('TabFrame');
	return (($tf->cget('-borderwidth') + $nb->cget('-borderwidth')) * 2) +1
}

=item B<nbTextSide>I($name, ?$side?)>

=cut

sub nbTextSide {
	my ($self, $name, $side) = @_;
	$self->textsides->{$name} = $side if defined $side;
	return $self->textsides->{$name}
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
	my $icon = $self->pageImage($notebook, $image, $text);
	@opt = (-title => $text) unless defined $icon;
	@opt = (-titleimg => $icon) if defined $icon;
	my $page = $nb->addPage($name, @opt);
	$self->pages->{$name} = [$notebook, $image, $text];

	my $l = $nb->getTab($name)->Subwidget('Label');
	$self->StatusAttach($l, $statustext) if defined $statustext;
	$self->BalloonAttach($l, $text);
	$self->after(500, sub { $nb->UpdateTabs });

	return $page;
}

=item B<pageCount>I<($notebook)>

Returns the number of pages in $notebook.

=cut

sub pageCount {
	my ($self, $notebook) = @_;
	my $book = $self->nbGet($notebook);
	return $book->pageCount
}

=item B<pageDelete>I<($notebook, $name)>

Deletes a page from a notebook.

=cut

sub pageDelete {
	my ($self, $notebook, $name) = @_;
	$self->nbGet($notebook)->deletePage($name);
	delete $self->{INITIALSIZES}->{$name};
	delete $self->{LASTSIZE}->{$name};
	delete $self->{SELECTCALLS}->{$name};
	delete $self->{UNSELECTCALLS}->{$name};
	delete $self->pages->{$name}
}

=item B<pageExists>I<($notebook, $name)>

Returns true if I<$name> exists in I<$notebook>.

=cut

sub pageExists {
	my ($self, $notebook, $name) = @_;
	my $book = $self->nbGet($notebook);
	return $book->pageExists($name);
}

sub pageImage {
	my ($self, $nb, $icon, $text) = @_;
	my $art = $self->extGet('Art');
	return undef unless defined $icon;
	my $img;
	if (defined $art) {
		my $image = $art->getIcon($icon, $self->IconSize);
		return undef unless defined $image;
		my $side = $self->textsides->{$nb};
		if (defined $side) {
			$img = $art->createCompound(
				-textside => $side,
				-image => $image,
				-text => $text,
			);
		} else {
			$img = $art->getIcon($icon, $self->IconSize);
		}
	}
	return $img;
}

sub pages { return $_[0]->{PAGES} }

=item B<pageSelectCall>I<($page, @callback)>

Creates a callback called when $page is selected.

=cut

sub pageSelectCall {
	my $self = shift;
	my $page = shift;
	$self->{SELECTCALLS}->{$page} = $self->CreateCallback(@_);
}

=item B<pageUnselectCall>I<($page, @callback)>

Creates a callback called when $page is unselected.

=cut

sub pageUnselectCall {
	my $self = shift;
	my $page = shift;
	$self->{UNSELECTCALLS}->{$page} = $self->CreateCallback(@_);
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

sub ReConfigure {
	my $self = shift;
	my $pgs = $self->pages;
	for (keys %$pgs) {
		my $page = $_;
		my $val = $pgs->{$page};
		my ($nb, $img, $text) = @$val;
		my $book = $self->nbGet($nb);
		my $tab = $book->getTab($page);

		my $icon = $self->pageImage($nb, $img, $text);
		$tab->configure(-titleimg => $icon) if defined $icon
	}
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
		my $call = $self->{SELECTCALLS}->{$tab};
		$call->execute if defined $call;
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
	my $call = $self->{UNSELECTCALLS}->{$tab};
	$call->execute if defined $call;
	$self->after(400, ['geoBlock', $self, 0]);
}

sub textsides { return $_[0]->{TEXTSIDES} }

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








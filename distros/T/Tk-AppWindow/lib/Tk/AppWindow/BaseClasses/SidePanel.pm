package Tk::AppWindow::BaseClasses::SidePanel;

=head1 NAME

Tk::AppWindow::Baseclasses::SidePanel - Basic functionality for extensions associated with a side panel, like NavigatorPanel and ToolPanel.

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.02";
use Tk;
require Tk::YANoteBook;

use base qw( Tk::AppWindow::BaseClasses::PanelExtension );

=head1 SYNOPSIS

 #This is useless
 my $ext = Tk::AppWindow::BaseClasses::SidePanel->new($mainwindow);

 #This is what you should do
 package Tk::AppWindow::Ext::MySidePanel
 use base(Tk::AppWindow::BaseClasses::SidePanel);
 sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_); #$mainwindow should be the first in @_
    ...
    return $self
 }

=head1 DESCRIPTION

Provides a primer for panels that contain a resizable YANoteBook for
selecting various tools.

It inherits L<Tk::AppWindow::BaseClasses::PanelExtension>

=head1 CONFIG VARIABLES

None.

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	$self->{TABSIDE} = 'top';
	$self->{LASTSIZE} = {};
	$self->{ICONSIZE} = 32;
	$self->addPostConfig('CreateNoteBook', $self);
	return $self;
}



=head1 METHODS

=over 4

=item B<addPage>I<($name, $image, $text, $statustext)>

Adds a page to the notebook.

=cut

sub addPage {
	my ($self, $name, $image, $text, $statustext) = @_;
	$text = $name, unless defined $text;
#	my $orient = 'Horizontal';
#	$orient = 'Vertical' if ($self->Tabside eq 'left') or ($self->Tabside eq 'right');
	
	my $nb = $self->nbGet;

	my @opt = ();
	my $art = $self->extGet('Art');
	my $icon;
	if (defined $art) {
		$icon = $art->GetIcon($image, $self->IconSize);
#		my @copt = (-orient => $orient);
#		if ($orient eq 'Vertical') {
#			push @copt, -textside => 'bottom'
#		} else {
#			push @copt, -textside => 'right'
#		}
#		$icon = $art->CreateCompound(@copt, -text => $text, -image => $img);
		
	}
	@opt = (-titleimg => $icon) if defined $icon;
	@opt = (-title => $text) unless defined $icon;
	my $page = $nb->addPage($name, @opt);

	my $balloon = $self->extGet('Balloon');
	my $l = $nb->getTab($name)->Subwidget('Label');
	if (defined $balloon) {
		$balloon->Attach($l, -statusmsg => $statustext) if defined $statustext;
		$balloon->Attach($l, -balloonmsg => $text) if defined $text;
	}
	$self->after(500, sub { $nb->UpdateTabs });

	return $page;
}

sub CreateNoteBook {
	my $self = shift;
	my $nb = $self->Subwidget($self->Panel)->YANoteBook(
		-onlyselect => 0,
		-rigid => 0,
		-selecttabcall => ['TabSelect', $self],
		-tabside => $self->Tabside,
		-unselecttabcall => ['TabUnselect', $self],
	)->pack(-expand => 1, -fill=> 'both', -padx => 2, -pady => 2);
	$self->geoAddCall($self->Panel, 'OnResize', $self);
	$self->Advertise($self->Name . 'NB', $nb);
	my $pn = $self->extGet('Panels');
	$pn->adjusterWidget($self->Panel, $nb);
	$pn->adjusterActive($self->Panel, 0);
}

=item B<deletePage>I<($name)>

Deletes a page from the notebook.

=cut

sub deletePage {
	my ($self, $name) = @_;
	$self->nbGet->deletePage($name);
}

=item B<IconSize>I<(?$size?)>

Set and return the iconsize in the tabs of the notebook

=cut

sub IconSize {
	my $self = shift;
	$self->{ICONSIZE} = shift if @_;
	return $self->{ICONSIZE};
}

=item B<nbGet>

Returns a reference to the notebook widget.

=cut

sub nbGet {
	my $self = shift;
	return $self->Subwidget($self->Name . 'NB');
}

=item B<nbMaximize>

Maximizes the notebook widget

=cut

sub nbMaximize {
	my ($self, $tab) = @_;
	my $nb = $self->nbGet;
	my $pf = $nb->Subwidget('PageFrame');
	my $tf = $nb->Subwidget('TabFrame');
	my $panel = $self->Subwidget($self->Panel);
	my $offset = $self->nbOffset;
	my $height = $panel->height;;
	my $width = $panel->width;
	my $ls = $self->{LASTSIZE}->{$tab};
	my $ts = $self->Tabside;
	if (defined $ls) {
		my ($w, $h) = @$ls;
		if (($ts eq 'top') or ($ts eq 'bottom')) {
			$height = $h
		} else {
			$width = $w
		}
# 		print "saved size $width, $height\n";
	} else {
		if (($ts eq 'top') or ($ts eq 'bottom')) {
			$height = $nb->height + $offset + $pf->reqheight;
		} else {
			$width = $nb->width + $offset + $pf->reqwidth;
		}
# 		print "orignal size $width, $height\n";
	}
	$nb->GeometryRequest($width, $height);
}

=item B<nbMinimize>

Minimizes the notebook widget

=cut

sub nbMinimize {
	my ($self, $tab) = @_;
	my $nb = $self->nbGet;
	my $tf = $nb->Subwidget('TabFrame');
	$self->{LASTSIZE}->{$tab} = [$nb->width, $nb->height];
	my $ts = $self->Tabside;
	my $offset = $self->nbOffset;
	my @size = ();
	if (($ts eq 'top') or ($ts eq 'bottom')) {
		@size = ($nb->width + $offset, $tf->height + $offset);
	} else {
		@size = ($tf->width + $offset, $nb->height + $offset);
	}
	$nb->GeometryRequest(@size);
}

sub nbOffset {
	my $self = shift;
	my $nb = $self->nbGet;
	my $tf = $nb->Subwidget('TabFrame');
	return (($tf->cget('-borderwidth') + $nb->cget('-borderwidth')) * 2) +1
}

sub OnResize {
	my $self = shift;
	my $nb = $self->nbGet;
	my $panel = $self->Subwidget($self->Panel);

	my $owidth = $nb->width;
	my $oheight = $nb->height;
	my $offset = $self->panelOffset;
	my $width = $panel->width - $offset;
	my $height = $panel->height - $offset;
	
	$nb->GeometryRequest($width, $height) if ($width ne $owidth) or ($height ne $oheight);
}

sub panelOffset {
	my $self = shift;
	my $nb = $self->nbGet;
	my $border = $nb->cget('-borderwidth');
	my $pad = 0;
	my %pi = $nb->packInfo;
	$pad = $pi{'-padx'} if exists $pi{'-padx'};
	$pad = $pi{'-pady'} if exists $pi{'-pady'};
	return ($border + $pad) * 2;
}

=item B<TabSelect>I<($tab)>

Maximizes $tab and adds an adjuster

=cut

sub TabSelect {
	my ($self, $tab) = @_;
# 	print "Tab $tab\n";
	return if $self->configMode;
	$self->geoBlock(1);
	my $pn = $self->extGet('Panels');
	$self->after(1, sub {
		$self->nbMaximize($tab);
		$pn->adjusterSet($self->Panel);
		$pn->adjusterActive($self->Panel, 1);
	});
	$self->after(200, ['geoBlock', $self, 0]);
}

=item B<Tabside>I<(?$side?)>

Set and return the tabside in the notebook.

=cut

sub Tabside {
	my $self = shift;
	$self->{TABSIDE} = shift if @_;
	return $self->{TABSIDE};
}

=item B<TabUnselect>I<($tab)>

Minimizes $tab and removes the adjuster.

=cut

sub TabUnselect {
	my ($self, $tab) = @_;
	return if $self->configMode;
	my $pn = $self->extGet('Panels');
	$pn->adjusterClear($self->Panel);
	$pn->adjusterActive($self->Panel, 0);
	$self->geoBlock(1);
	$self->nbMinimize($tab);
	$self->after(400, ['geoBlock', $self, 0]);
# 	$self->Subwidget($self->Panel)->GeometryRequest(@size);
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







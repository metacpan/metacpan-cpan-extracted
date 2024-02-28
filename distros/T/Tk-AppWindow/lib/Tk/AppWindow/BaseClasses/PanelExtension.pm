package Tk::AppWindow::BaseClasses::PanelExtension;

=head1 NAME

Tk::AppWindow::Baseclasses::PanelExtension - Basic functionality for extensions associated with a panel, like StatusBar and ToolBar

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.02";
use Tk;

use base qw( Tk::AppWindow::BaseClasses::Extension );

=head1 SYNOPSIS

 #This is useless
 my $ext = Tk::AppWindow::BaseClasses::PanelExtension->new($mainwindow);

 #This is what you should do
 package Tk::AppWindow::Ext::MyExtension
 use base(Tk::AppWindow::BaseClasses::PanelExtension);
 sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_); #$mainwindow should be the first in @_
    ...
    return $self
 }

=head1 DESCRIPTION

This package provides a primer for panel related extensions, like B<ToolBar>, B<StatusBar> and alse
base class B<SidePanel>.

=head1 CONFIG VARIABLES

none.

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->Require('Panels');
	$self->{VISIBLE} = 1;

	$self->addPostConfig('PostConfig', $self);
	return $self;
}

=head1 METHODS

=over 4

=item B<Panel>I<(?$name?)>

Sets or returns the name of a panel in extension B<Panels>

=cut

sub Panel {
	my $self = shift;
	if (@_) { $self->{PANEL} = shift; }
	return $self->{PANEL};
}

=item B<PanelVisible>I<(?$flag?)>

Sets and returns the visibility of the panel in B<Panel>
and changes it according to the boolean in $flag.

=cut

sub PanelVisible {
	my $self = shift;
	my $panels = $self->extGet('Panels');
	if (@_) {
		my $status = shift;
		my $panel = $self->Panel;
		if ($self->configMode) {
		} elsif ($status eq 1) {
			$panels->panelShow($panel);
		} elsif ($status eq 0) {
			$panels->panelHide($panel);
		}
		$self->{VISIBLE} = $status;
	}
	return $self->{VISIBLE}
}

=item B<PostConfig>

This is called after MainLoop has activated. Sets the initial
visibility for the panel in B<Panel>.
Override it if you must, but always call a SUPER.

=cut

sub PostConfig {
	my $self = shift;
	my $delay = $self->configGet('-initpaneldelay');
	$self->after($delay, sub { $self->PanelVisible($self->{VISIBLE}) });
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

=item L<Tk::AppWindow::Ext::Panels>

=back

=cut

1;
__END__




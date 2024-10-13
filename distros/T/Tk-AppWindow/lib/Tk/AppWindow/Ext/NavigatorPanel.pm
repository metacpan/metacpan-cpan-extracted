package Tk::AppWindow::Ext::NavigatorPanel;

=head1 NAME

Tk::AppWindow::Ext::Navigator - Navigate opened documents and files

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.15";

use base qw( Tk::AppWindow::BaseClasses::Extension );

=head1 SYNOPSIS

 my $app = new Tk::AppWindow(@options,
    -extensions => ['ToolPanel'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

B<Obsolete> use L<Tk::AppWindow::Ext::SideBars> instead.
Will be removed in the next version of I<Tk::AppWindow>.

Adds a navigator panel to your application. By default
it sits on the left side of your application. You
can add items to it's notebook.

Inherits L<Tk::AppWindow::BaseClasses::Extension>.

=head1 CONFIG VARIABLES

=over 4

=item B<-navigatorpanel>

Default value 'LEFT'. Sets the name of the panel home to B<NavigatorPanel>.

Only available at create time.

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);
	$self->Require('SideBars');

	my $args = $self->GetArgsRef;
	my $panel = delete $args->{'-navigatorpanel'};
	$panel = 'LEFT' unless defined $panel;
	my $sb = $self->extGet('SideBars');

	$sb->nbAdd('navigator panel', $panel, 'left');
	$self->addPostConfig('DoPostConfig', $self);
	return $self;
}

=head1 METHODS

=over 4

=item B<addPage>

Deprecated. Use B<pageAdd>.

=cut

sub addPage {
	my $self = shift;
	return $self->pageAdd(@_)
}

=item B<deletePage>I<($name)>

Deprecated. Use B<pageDelete>.

=cut

sub deletePage {
	my $self = shift;
	return $self->pageDelete(@_)
}

=item B<pageAdd>I<($name, $image, $text, $statustext, $initialsize)>

Adds a page to the navigator panel.

=cut

sub pageAdd {
	my $self = shift;
	my $sb = $self->extGet('SideBars');
	return $sb->pageAdd('navigator panel', @_);
}

=item B<pageDelete>I<($name)>

Deletes a page from the navigator panel.

=cut

sub pageDelete {
	my $self = shift;
	my $sb = $self->extGet('SideBars');
	return $sb->pageDelete('navigator panel', @_);
}

sub DoPostConfig {
	my $self = shift;
	#show the navigator panel if it should be visible
	if ($self->configGet('-navigator panelvisible')) {
		my $pn = $self->extGet('Panels');
		my $panel = $pn->panelAssign('navigator panel');
		$pn->panelShow($panel);
	}
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

=item L<Tk::AppWindow::BaseClasses::SidePanel>

=item L<Tk::AppWindow::Ext::Panels>

=back

=cut

1;







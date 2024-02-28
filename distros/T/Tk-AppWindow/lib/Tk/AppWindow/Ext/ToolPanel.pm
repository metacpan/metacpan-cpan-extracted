package Tk::AppWindow::Ext::ToolPanel;

=head1 NAME

Tk::AppWindow::Ext::Navigator - Navigate opened documents and files

=cut

use strict;
use warnings;
use vars qw($VERSION);
$VERSION="0.02";

use base qw( Tk::AppWindow::BaseClasses::SidePanel );

require Tk::YANoteBook;

=head1 SYNOPSIS

 my $app = new Tk::AppWindow(@options,
    -extensions => ['ToolPanel'],
 );
 $app->MainLoop;

=head1 DESCRIPTION

Adds a tool panel to your application. By default
it sits on the right side of your application. You
can add items to it's notebook.

Inherits L<Tk::AppWindow::BaseClasses::SidePanel>.

=head1 CONFIG VARIABLES

=over 4

=item B<-toolpanel>

Default value 'RIGHT'. Sets the name of the panel home to B<Navigator>.

=item B<-toolpaneliconsize>

Default value 32.

=item B<-toolpaneltabside>

Default value 'right'. At which side of the notebook do you place your tabs.

=item B<-toolpanelvisible>

Default value 1. Show or hide tool panel.

=back

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_);

	$self->configInit(
		-toolpaneliconsize => ['IconSize', $self, 32],
		-toolpanel => ['Panel', $self, 'RIGHT'],
		-toolpaneltabside	=> ['Tabside', $self, 'right'],
		-toolpanelvisible	=> ['PanelVisible', $self, 1],
	);
	return $self;
}

sub MenuItems {
	my $self = shift;
	return (
#This table is best viewed with tabsize 3.
#			 type					menupath			label			Icon		config variable	off on
		[	'menu_check',		'View::',		"Show ~tool panel",	undef,	'-toolpanelvisible', undef, 	0,   1], 
	)
}

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




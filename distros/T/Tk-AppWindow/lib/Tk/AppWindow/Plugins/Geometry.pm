package Tk::AppWindow::Plugins::Geometry;

use strict;
use warnings;

use base qw( Tk::AppWindow::BaseClasses::Plugin );

=head1 DESCRIPTION

Save the position and size of your application on exit.

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_, 'ConfigFolder');
	return undef unless defined $self;
	
	$self->after(50, ['LoadGeometry', $self]);
	return $self;
}

sub LoadGeometry {
	my $self = shift;
	my $cff = $self->extGet('ConfigFolder');
	my ($g) = $cff->loadList('geometry', 'aw geometry');
	$self->geometry($g) if defined $g;
}

sub Quit {
	my $self = shift;
	my $cff = $self->extGet('ConfigFolder');
	my $geometry = $self->geometry;
	$cff->saveList('geometry', "aw geometry", $geometry);
}


1;





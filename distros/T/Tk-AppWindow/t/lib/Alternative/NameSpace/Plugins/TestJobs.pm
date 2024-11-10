package Alternative::NameSpace::Plugins::TestJobs;

use strict;
use warnings;

use base qw( Tk::AppWindow::BaseClasses::PluginJobs );

=head1 DESCRIPTION

This is for testing only. Yes, you read me, for TESTING. Didn't you hear me say? TESTING! TESTING! TESTING!

=cut

sub new {
	my $class = shift;
	my $self = $class->SUPER::new(@_, 'SideBars');
	return unless defined $self;
	my $sb = $self->extGet('SideBars');
	$sb->nbAdd('tool panel', 'RIGHT', 'right') unless $sb->nbExists('tool panel');
	my $page = $sb->pageAdd('tool panel', 'Seasons', 'view-list-details', undef, 'Select a season');
	$page->Label(-text => 'Seasons')->pack(-expand => 1, -fill => 'both');
	$self->jobStart('jobtest', 'JobTest', $self);
	return $self;
}

sub JobTest {
 print "JobTest\n"
}

sub Unload {
	my $self = shift;
	my $sb = $self->extGet('SideBars');
	$sb->pageDelete('tool panel', 'Seasons');
	return $self->SUPER::Unload
}
1;

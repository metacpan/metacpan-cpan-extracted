package XUL::Node::Application::PeriodicTable::ProgressMeters;

use strict;
use warnings;
use Carp;
use XUL::Node;

use base 'XUL::Node::Application::PeriodicTable::Base';

sub get_demo_box {
	my $self = shift;
	my $meter;
	HBox(
		GroupBox(
			Caption(label => 'determined'),
			$meter = ProgressMeter(mode => 'determined', value => 10),
			Button(label => 'Hit me to advance', Click => sub {
				$meter->value($meter->value + 10) if $meter->value < 100;
			}),
		),
		GroupBox(
			Caption(label => 'undetermined'),
			ProgressMeter(mode => 'undetermined'),
		),
	);
}

1;

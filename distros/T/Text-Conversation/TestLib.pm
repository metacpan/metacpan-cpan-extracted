package TestLib;

use warnings;
use strict;

use Exporter;
use base qw(Exporter);

use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(try);

use Text::Conversation;

sub try {
	my @input = @_;

	my $tc = Text::Conversation->new();

	my @actual_output;
	foreach my $i (@input) {
		my ($new_id, $ref_id) = $tc->observe(@$i);
		push @actual_output, [ $new_id, $ref_id ];
	}

	return \@actual_output;
}

1;

# $Id: Tools.pm,v 1.1 1999/11/17 15:58:32 joern Exp $

package NewSpirit::Tools;

use strict;
use Carp;

use NewSpirit;

sub new {
	my $type = shift;

	my $self = {
	};

	return bless $self, $type;
}

1;

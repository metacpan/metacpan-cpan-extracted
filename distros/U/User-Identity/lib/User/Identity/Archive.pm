# This code is part of Perl distribution User-Identity version 4.00.
# The POD got stripped from this file by OODoc version 3.05.
# For contributors see file ChangeLog.

# This software is copyright (c) 2003-2025 by Mark Overmeer.

# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later


package User::Identity::Archive;{
our $VERSION = '4.00';
}

use parent 'User::Identity::Item';

use strict;
use warnings;

use Log::Report     'user-identity';

#--------------------

sub type { "archive" }


sub init($)
{	my ($self, $args) = @_;
	$self->SUPER::init($args);

	if(my $from = delete $args->{from})
	{	$self->from($from) or return;
	}

	$self;
}

#--------------------

1;


package Session;

use strict;
use warnings;

use generics params => qw(
	SESSION_TIMEOUT
	SESSION_ID_LENGTH
	);

sub new {
	return bless {} => ref($_[0]) || $_[0];
}

sub getTimeoutLength {
	return SESSION_TIMEOUT;
}

sub getSessionId {
	my @chars = ('a' .. 'z', 'A' .. 'Z', 0 .. 9);
	return join "" => map { 
				$chars[((rand() * 100) % scalar @chars)] 
				} (1 .. SESSION_ID_LENGTH);
}

1;

__DATA__
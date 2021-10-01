package TestUtils;

use strict;
use warnings;

use Exporter 5.57 'import';
our @EXPORT = qw/error_for/;

sub error_for {
	my ($head, $errno) = @_;
	my $errno_message = do {
		local $! = $errno;
		"$!";
	};
	my $message = qr/Could not $head: \Q$errno_message/;
	my $file = (caller(0))[1];
	return qr/^$message at \Q$file\E line \d+.$/;
}

1;

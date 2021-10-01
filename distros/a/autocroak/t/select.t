#! perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Socket;
use File::Temp;
use Errno 'EBADF';

use FindBin;
use lib "$FindBin::Bin/lib";
use TestUtils;

subtest ebadf => sub {
	use autocroak;

	socket my $s, Socket::AF_INET, Socket::SOCK_STREAM, 0;
	my $fd = fileno $s;

	vec( my $rin, $fd, 1) = 1;

	close $s;

	my $err = exception { select $rin, undef, undef, 0 };
	like($err, error_for('select', EBADF), 'void context' );

	#----------------------------------------------------------------------

	$err = exception { () = select $rin, undef, undef, 0 };
	like($err, error_for('select', EBADF), 'list context');
};

subtest success => sub {
	use autocroak;

	my $fh = File::Temp::tempfile();
	my $fd = fileno $fh;

	is(exception { 
		vec( my $rin, $fd, 1) = 1;
		my $got = select $rin, undef, undef, 0;
		is $got, 1, 'scalar context return 1';
	}, undef, 'scalar context lives');

	is(exception {
		vec( my $rin, $fd, 1) = 1;
		my ($got) = select $rin, undef, undef, 0;
		is $got, 1, 'list context returns 1';
	}, undef, 'list context lives');
};

done_testing;

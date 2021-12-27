#! perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;

use Socket;
use File::Temp;
use Errno 'EBADF';
use IO::Socket::INET;

use FindBin;
use lib "$FindBin::Bin/lib";
use TestUtils;

sub socket_pair {
	my $listen = IO::Socket::INET->new(Listen => 10) or die $!;
	my $connecting = IO::Socket::INET->new(PeerAddr => $listen->sockhost, PeerPort => $listen->sockport) or die $!;
	return ($connecting, $listen->accept);
}

subtest ebadf => sub {
	use autocroak;

	plan skip_all => 'Windows is special' if $^O eq 'MSWin32'; # XXX we need a better test here

	my ($s, $r) = socket_pair;
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

	my ($read, $write) = socket_pair;
	syswrite $write, "0";
	my $fd = fileno $read;

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

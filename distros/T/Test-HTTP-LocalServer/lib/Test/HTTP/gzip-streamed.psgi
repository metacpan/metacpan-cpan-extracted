#!perl
# Created by Hauke Daempfling 2018
use strict;
use warnings;
use IO::Compress::Gzip qw/$GzipError Z_PARTIAL_FLUSH/;

our $VERSION = '0.67';

my $app = sub {
	my $env = shift;
	die "This app needs a server that supports psgi.streaming"
		unless $env->{'psgi.streaming'};
	die "The client did not send the 'Accept-Encoding: gzip' header"
		unless defined $env->{HTTP_ACCEPT_ENCODING}
			&& $env->{HTTP_ACCEPT_ENCODING} =~ /\bgzip\b/;
	# Note some browsers don't correctly support gzip correctly,
	# see e.g. https://metacpan.org/pod/Plack::Middleware::Deflater
	# but we're not checking that here (and we don't set the Vary header)
	return sub {
		my $respond = shift;
		my $zipped;
		my $z = IO::Compress::Gzip->new(\$zipped)
			or die "IO::Compress::Gzip: $GzipError";
		my $w = $respond->([ 200, [
				'Content-Type' => 'text/plain; charset=ascii',
				'Content-Encoding' => 'gzip',
			] ]);
		for (1..10) {
			$z->print("Hello, it is ".gmtime." GMT\n");
			$z->flush(Z_PARTIAL_FLUSH);
			$w->write($zipped) if defined $zipped;
			$zipped = undef;
			sleep 1;
		}
		$z->print("Goodbye!\n");
		$z->close;
		$w->write($zipped) if defined $zipped;
		$w->close;
	};
};

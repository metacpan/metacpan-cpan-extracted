use strict;
use warnings;
use uSAC::MIME;
use Benchmark qw<cmpthese>;

use Plack::MIME;
use MIME::Detect;

use feature ":all";

my $db=uSAC::MIME->new->index;

my $detect=MIME::Detect->new;
my $count=$ARGV[0]//10_000_000;


cmpthese($count, {
		usac=>sub { $db->{txt}},
		plack=>sub {Plack::MIME->mime_type("txt")},
		#detect=>sub {$detect->mime_type_from_name(".txt")}
	}
);



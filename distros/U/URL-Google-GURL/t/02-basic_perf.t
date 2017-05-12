use strict;
use warnings;

use Test::More tests => 1;
use Time::HiRes qw(gettimeofday tv_interval);

use_ok('URL::Google::GURL');

my $iterations = 100000;
my $start = [gettimeofday];
my $url = "http://foo.bar.com?baz=1";
foreach (0..($iterations-1)) {
    my $u = URL::Google::GURL->new($url);
    my $spec = $u->spec();
}
my $elapsed = tv_interval($start);
my $time_per_spec = $elapsed / $iterations;
note("spec computation for $iterations urls took $elapsed seconds ($time_per_spec per url).");


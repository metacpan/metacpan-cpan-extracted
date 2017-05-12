use Test::More tests => 1;
BEGIN { use_ok('URL::Grab') };
use Data::Dumper;

my $urlgrabber = new URL::Grab;
my $content = $urlgrabber->grab('http://linux-kernel.at');
print Dumper($content);

my @files = (qw(
  lib/Test/WWW/Simple.pm
  examples/simple_scan
  examples/simple_scan2
));
use Test::Pod tests => 3;
for my $file (@files) {
  pod_file_ok( $file, "Valid POD file" );
}

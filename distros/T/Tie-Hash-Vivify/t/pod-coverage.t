use strict;
$^W=1;

eval "use Test::Pod::Coverage 1.00";
if($@) {
  print "1..0 # SKIP Test::Pod::Coverage 1.00 required for testing POD coverage";
} else {
  eval "use Pod::Coverage 0.21";
  if($@) {
    print "1..0 # SKIP Pod::Coverage 0.21 required for testing POD coverage";
  } else {
    all_pod_coverage_ok();
  }
}

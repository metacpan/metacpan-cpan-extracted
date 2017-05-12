#!perl -T
use Test::More;

eval "use Test::Pod::Coverage 1.04";
if ($@) {
    plan skip_all =>
      "Test::Pod::Coverage 1.04 required for testing POD coverage";
}

all_pod_coverage_ok({
    also_private => [
        'x509_subject_hash',
        'x509_issuer_hash',
        'errorTrap',
        'PreloadModperl'
       ]
   });

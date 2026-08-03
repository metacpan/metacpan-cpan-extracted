use Test2::V1
  -pragmas,
  -target => { CLASS => 'Version::Semantic' },
  qw( plan );
use Test::API import => [ qw( public_ok ) ];

plan 1;

public_ok CLASS,
  qw( new parse prefix major minor patch pre_release build version_core has_prefix has_pre_release has_build increment compare_to to_string semver_re )

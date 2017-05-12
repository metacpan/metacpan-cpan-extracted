# -*- perl -*-
use strict;
use Test::More;

plan skip_all => 'No RELEASE_TESTING'
  unless -d '.git' || $ENV{RELEASE_TESTING};

eval "use Test::Spelling;";
plan skip_all => "Test::Spelling required"
  if $@;

add_stopwords(<DATA>);
all_pod_files_spelling_ok();

__DATA__
Callouts
EOD
Hyperscan
lhs
NYI
Reini

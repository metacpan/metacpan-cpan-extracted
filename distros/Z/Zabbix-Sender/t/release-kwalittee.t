
BEGIN {
  unless ($ENV{RELEASE_TESTING}) {
    print "1..0 # SKIP these tests are for release candidate testing\n";
    exit
  }
}

use Test::More;

eval {
        require Test::Kwalitee; Test::Kwalitee->import(
                tests => [ qw( -has_meta_yml ) ]
        );
};

plan( skip_all => 'Test::Kwalitee not installed; skipping' ) if $@;

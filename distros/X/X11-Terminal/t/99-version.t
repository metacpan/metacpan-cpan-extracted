use Test::More;

eval "use Test::ConsistentVersion";
plan skip_all => "Test::ConsistentVersion required for checking versions" if $@;
Test::ConsistentVersion::check_consistent_versions(no_readme => 1, no_pod =>1);


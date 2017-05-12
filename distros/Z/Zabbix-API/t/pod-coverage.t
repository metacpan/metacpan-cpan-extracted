use Test::More;

plan skip_all => 'Author test. Set $ENV{AUTHOR_TESTS} to a true value to run.' unless $ENV{AUTHOR_TESTS};

eval "use Test::Pod::Coverage 1.00";

plan skip_all => 'Test::Pod::Coverage 1.00+ required for testing pod coverage' if $@;

all_pod_coverage_ok({ coverage_class => 'Pod::Coverage::CountParents' });

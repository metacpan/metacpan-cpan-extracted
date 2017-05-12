use Test::More;

plan skip_all => 'Author test. Set $ENV{AUTHOR_TESTS} to a true value to run.' unless $ENV{AUTHOR_TESTS};

eval "use Test::Pod 1.00";

plan skip_all => 'Test::Pod 1.00+ required for testing pod coverage' if $@;

all_pod_files_ok();

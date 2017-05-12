use Test::More;

eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;

plan tests => 1;

pod_file_ok('Writer.pm');

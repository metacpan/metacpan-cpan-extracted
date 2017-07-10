use Test::More;
eval 'use Test::Pod 1.00 tests => 1';
plan skip_all => 'Test::Pod 1.00 required for testing POD' if $@;
#my @pdrs = qw(. blib);
#all_pod_files_ok(all_pod_files(@pdrs));
pod_file_ok('lib/XML/Tidy.pm','Valid POD file');

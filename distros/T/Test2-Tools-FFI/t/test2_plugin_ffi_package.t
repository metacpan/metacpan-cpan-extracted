use Test2::V0 -no_srand => 1;
use Test2::Plugin::FFI::Package;

# the tool itself requires this plugin,
# so should be sufficient to ensure
# things are worky.
eval { require Test2::Tools::FFI };
is $@, '';

done_testing;

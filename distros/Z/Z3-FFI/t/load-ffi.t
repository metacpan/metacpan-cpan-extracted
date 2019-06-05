use Test::More;

use strict;
use warnings;

use_ok("Z3::FFI");

my $config = Z3::FFI::mk_config();
ok(ref($config) eq 'Z3::FFI::Types::Z3_config', "Config comes back as correct type");
my $context = Z3::FFI::mk_context($config);
ok(ref($context) eq 'Z3::FFI::Types::Z3_context', "Context comes back as correct type");

done_testing;

1;

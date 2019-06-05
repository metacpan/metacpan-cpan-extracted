use Test::More;

use strict;
use warnings;

use_ok("Z3::FFI");

my $config = Z3::FFI::mk_config();
ok(ref($config) eq 'Z3::FFI::Types::Z3_config', "Config comes back as correct type");
my $context = Z3::FFI::mk_context($config);
ok(ref($context) eq 'Z3::FFI::Types::Z3_context', "Context comes back as correct type");

my ($major, $minor, $build, $rev);

Z3::FFI::get_version(\$major, \$minor, \$build, \$rev);

is($major, "4", "Major version matches");
is($minor, "8", "Minor version matches");
is($build, "4", "Build version matches");
is($rev,   "0", "Revision version matches");

done_testing;

1;

use strict;
use warnings;

# Regression test for https://github.com/Test-More/Test2-Plugin-UUID/issues/3
# If UUID is loaded before Test2::Util::UUID is compiled, UUID::uuid7 must
# still be called correctly.
BEGIN {
    unless (eval { require UUID; UUID->VERSION('0.35'); 1 }) {
        print "1..0 # SKIP UUID 0.35+ is not installed\n";
        exit 0;
    }
}

use Test2::V0;
use Test2::Util::UUID qw/looks_like_uuid/;

Test2::Util::UUID->clear_cache;
my $subs = Test2::Util::UUID->get_gen_uuid(backends => ['UUID'], warn => 0);

is($subs->{GEN_UUID_BACKEND}->(), 'UUID', "Using the UUID backend");
ok(looks_like_uuid($subs->{gen_uuid}->()), "Generated a valid UUID with UUID preloaded");

done_testing;

use strict;
use warnings;
use Test::More;
use XS::Install;

chdir 't/testmod' or die $!;

my $args;

# Panda::Install is added to CONFIGURE_REQUIRES
$args = XS::Install::makemaker_args(NAME => 'TestMod');
ok(exists $args->{CONFIGURE_REQUIRES}{'XS::Install'});

done_testing();
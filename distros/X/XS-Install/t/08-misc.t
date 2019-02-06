use strict;
use warnings;
use Test::More;
use Test::Deep;
use XS::Install;

chdir 't/testmod' or die $!;

my %args;

# MIN_PERL_VERSION default to 5.10.0
%args = XS::Install::makemaker_args(NAME => 'TestMod');
is($args{MIN_PERL_VERSION}, '5.10.0');

done_testing();
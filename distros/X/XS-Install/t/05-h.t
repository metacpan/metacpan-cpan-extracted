use strict;
use warnings;
use Test::More;
use Test::Deep;
use XS::Install;

chdir 't/testmod' or die $!;

my $args;

# defaults (without SRC dir) are all h files in root folder
$args = XS::Install::makemaker_args(NAME => 'TestMod', H_DEPS => 0);
cmp_bag($args->{H}, [qw/file1.h file2.hh prog1.hxx prog2.hpp/]);

# no h files
$args = XS::Install::makemaker_args(NAME => 'TestMod', H => [], H_DEPS => 0);
cmp_bag($args->{H}, []);

# custom h files
$args = XS::Install::makemaker_args(NAME => 'TestMod', H => 'src/*.h file2.hh', H_DEPS => 0);
cmp_bag($args->{H}, [qw{src/sfile1.h src/sfile2.h file2.hh}]);

done_testing();
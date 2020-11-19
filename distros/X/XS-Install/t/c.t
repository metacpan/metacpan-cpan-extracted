use strict;
use warnings;
use Test::More;
use Test::Deep;
use XS::Install;

chdir 't/testmod' or die $!;

my $args;

# defaults (without SRC dir) are all c files in root folder
$args = XS::Install::makemaker_args(NAME => 'TestMod');
cmp_bag($args->{C}, [qw/file1.c file2.cc prog1.cxx prog2.cpp/, values %{$args->{XS}}]);

# no c files, however XS c files remain
$args = XS::Install::makemaker_args(NAME => 'TestMod', C => []);
cmp_bag($args->{C}, [values %{$args->{XS}}]);

# custom c files, XS c files still remain
$args = XS::Install::makemaker_args(NAME => 'TestMod', C => 'src/*.cc file2.cc');
cmp_bag($args->{C}, [qw{src/sfile1.cc src/sfile2.cc file2.cc}, values %{$args->{XS}}]);

done_testing();
use strict;
use warnings;
use Test::More;
use Test::Deep;
use XS::Install;

chdir 't/testmod' or die $!;

my $args;

# add folder's content
$args = XS::Install::makemaker_args(NAME => 'TestMod', SRC => 'src2');
cmp_bag($args->{C}, [qw{file1.c file2.cc prog1.cxx prog2.cpp src2/s2.cc src2/s2_xsgen.c misc_xsgen.c my_xsgen.c test_xsgen.c}]);
cmp_deeply($args->{XS}, {'my.xs' => 'my_xsgen.c', 'misc.xs' => 'misc_xsgen.c', 'test.xs' => 'test_xsgen.c', 'src2/s2.xs' => 'src2/s2_xsgen.c'});

$args = XS::Install::makemaker_args(NAME => 'TestMod', SRC => ['src', 'src2']);
cmp_bag($args->{C}, [qw{file1.c file2.cc prog1.cxx prog2.cpp src2/s2.cc src2/s2_xsgen.c misc_xsgen.c my_xsgen.c test_xsgen.c src/sfile1.cc src/sfile2.cc}]);
cmp_deeply($args->{XS}, {'my.xs' => 'my_xsgen.c', 'misc.xs' => 'misc_xsgen.c', 'test.xs' => 'test_xsgen.c', 'src2/s2.xs' => 'src2/s2_xsgen.c'});

# only folder's content (remove all defaults)
$args = XS::Install::makemaker_args(NAME => 'TestMod', H => [], XS => {}, C => [], SRC => ['src', 'src2']);
cmp_bag($args->{C}, [qw{src2/s2.cc src2/s2_xsgen.c src/sfile1.cc src/sfile2.cc}]);
cmp_deeply($args->{XS}, {'src2/s2.xs' => 'src2/s2_xsgen.c'});

done_testing();
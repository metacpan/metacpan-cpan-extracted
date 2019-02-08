use strict;
use warnings;
use Test::More;
use Test::Deep;
use XS::Install;

chdir 't/testmod' or die $!;

my %args;
delete $ENV{COMPILER};

# CPLUS changes compiler to C++
%args = XS::Install::makemaker_args(NAME => 'TestMod', CPLUS => 1);
is($args{CC}, 'c++');
is($args{LD}, '$(CC)');
like $args{XSOPT}, qr/-C\+\+/;
like $args{XSOPT}, qr/-csuffix \.cc/;
like $args{XSOPT}, qr/-hiertype/;
like($args{CCFLAGS}, qr/-std=c\+\+11/);

# CPLUS doesn't change custom values
%args = XS::Install::makemaker_args(NAME => 'TestMod', CPLUS => 1, CC => 'mycc', XSOPT => 'jopanah');
is($args{CC}, 'mycc');
is($args{LD}, '$(CC)');
like $args{XSOPT}, qr/-C\+\+/;
like $args{XSOPT}, qr/-csuffix \.cc/;
like $args{XSOPT}, qr/-hiertype/;
like $args{XSOPT}, qr/jopanah/;

# CPLUS version set
%args = XS::Install::makemaker_args(NAME => 'TestMod', CPLUS => 11);
like($args{CCFLAGS}, qr/-std=c\+\+11/);

done_testing();

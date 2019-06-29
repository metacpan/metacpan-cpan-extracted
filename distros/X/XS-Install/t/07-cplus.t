use strict;
use warnings;
use Test::More;
use Test::Deep;
use XS::Install;

plan skip_all => 'set TEST_FULL=1 to enable this test' unless $ENV{TEST_FULL};

chdir 't/testmod' or die $!;

my $args;
delete $ENV{COMPILER};

# CPLUS changes compiler to C++
$args = XS::Install::makemaker_args(NAME => 'TestMod', CPLUS => 1, XSOPT => 'jopanah');
is($args->{CC}, 'c++');
is($args->{LD}, '$(CC)');
like $args->{XSOPT}, qr/-C\+\+/;
like $args->{XSOPT}, qr/-csuffix \.cc/;
like $args->{XSOPT}, qr/-hiertype/;
like $args->{XSOPT}, qr/jopanah/;
like($args->{CCFLAGS}, qr/-std=c\+\+11/);

# CPLUS version set
$args = XS::Install::makemaker_args(NAME => 'TestMod', CPLUS => 11);
like($args->{CCFLAGS}, qr/-std=c\+\+11/);

$args = XS::Install::makemaker_args(NAME => 'TestMod', CPLUS => 14);
like($args->{CCFLAGS}, qr/-std=c\+\+14/);

done_testing();

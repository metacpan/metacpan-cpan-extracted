use strict;
use warnings;
use Test::More tests => 1;
use XS::Log qw(:all);

cmp_ok($XS::Log::VERSION, ">","1.00","Version $XS::Log::VERSION");
printText("\n-------------------原文输出，测试开始--------------\n");
printInf("This is info\n");
printWarn("This is warning\n");
printErr("This is error\n");

my $user = "Alice";
my $val  = 42;

printInf("Hello %s, value=%d\n", $user, $val);
printErr("File not found: %s\n", "/tmp/test.txt");
printText("-------------------原文输出，测试结束--------------\n");

__END__

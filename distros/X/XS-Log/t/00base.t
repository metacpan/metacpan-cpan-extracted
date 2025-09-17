use strict;
use warnings;
use Test::More tests => 1;
use XS::Log

cmp_ok($XS::Log::VERSION, ">","1.00","Version $XS::Log::VERSION");
XS::Log::printText("\n-------------------原文输出，测试开始--------------\n");
XS::Log::printInf("This is info\n");
XS::Log::printWarn("This is warning\n");
XS::Log::printErr("This is error\n");

my $user = "Alice";
my $val  = 42;

XS::Log::printInf("Hello %s, value=%d\n", $user, $val);
XS::Log::printErr("File not found: %s\n", "/tmp/test.txt");
XS::Log::printText("-------------------原文输出，测试结束--------------\n");

__END__

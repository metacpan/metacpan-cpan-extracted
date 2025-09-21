use strict;
#Build  MD5 : 88HK2ldjhzqvHxCFCbIThA
#Build Time : 2025-09-20 19:12:36
use warnings;
use XS::Log qw(:all);

my %opt = (
 level             => LOG_LEVEL_DEBUG,
 mode              => LOG_MODE_DAILY,
 targets           => LOG_TARGET_CONSOLE,
 use_color         => 1,
 show_timestamp    => 1,
 show_log_level    => 1,
 show_file_info    => 0,
 max_file_size     => 1024*1024*10,		#10M
 max_files         => 5,
 flush_immediately => 1,
);

openLog("test.log", \%opt);

printInf("%s\n","This is info1");
printInf("This is info2:%s\n","tt");
printInf("This is info3:%s\n","tt");
printInf("This is info4\n");
printNote("This is trace1");
printNote("This is trace2");
printNote("This is trace3");
printBug("This is debug1\n");
printBug("This is debug2\n");
printWarn("This is warning1\n");
printWarn("This is warning2\n");
printErr("This is error1\n");
printErr("This is error2\n");

setLogOptions("use_color",0);			#等效setLogColor(0);
setLogOptions("show_file_info",1);
#setLogOptions("level",10);

my $user = "Alice";
my $val  = 42;

printInf("name = %s, value=%d\n", $user, $val);
printBug("name = %s, value=%d\n", $user, $val);
printBug("name = %s, value=%d\n", $user, $val);
printBug("name = %s, value=%d\n", $user, $val);
printErr("File not found: %s\n", "/tmp/test.txt");

closeLog();

package XS::Log;
#Build  MD5 : 9OIX4TrV94RQ4xS0t862yg
#Build Time : 2025-09-23 11:57:16
our $VERSION = 1.11;
our $BUILDDATE = "2025-09-23";  #Build Time: 11:57:16
use strict;
use warnings;
use constant { 
    #颜色设置
    LOG_LEVEL_OFF		=> 0,		# 关闭日志
	LOG_LEVEL_FATAL		=> 1,    	# 严重错误
	LOG_LEVEL_ERROR		=> 2,    	# 错误信息
	LOG_LEVEL_WARN		=> 3,    	# 警告信息
	LOG_LEVEL_INFO		=> 4,    	# 一般信息
    LOG_LEVEL_TRACE		=> 5,    	# 最详细的日志信息
    LOG_LEVEL_DEBUG		=> 6,    	# 调试信息
	LOG_LEVEL_TEXT		=> 7,    	# 原文输出
    LOG_MODE_CYCLE		=> 0,
	LOG_MODE_DAILY		=> 1,
	LOG_MODE_HOURLY		=> 2,
    LOG_TARGET_CONSOLE	=> 0x01,
	LOG_TARGET_FILE		=> 0x02,
	LOG_TARGET_SYSLOG	=> 0x04
};
use XSLoader;
require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(
    openLog closeLog flushLog setLogOptions setLogColor setLogMode setLogTargets setLogLevel
    printNote printBug printInf printWarn printErr printFail printLog printRep
	LOG_LEVEL_OFF LOG_LEVEL_FATAL LOG_LEVEL_ERROR LOG_LEVEL_WARN LOG_LEVEL_INFO LOG_LEVEL_TRACE LOG_LEVEL_DEBUG LOG_LEVEL_TEXT
	LOG_MODE_CYCLE LOG_MODE_DAILY LOG_MODE_HOURLY 
	LOG_TARGET_CONSOLE LOG_TARGET_FILE LOG_TARGET_SYSLOG
);
# 定义导出标签 :all
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
XSLoader::load('XS::Log', $VERSION);

sub printNote {
	my ($fmt, @args) = @_;
	my $msg = sprintf($fmt, @args);
	my ($pkg,$file,$line);
	$file = ""; $line = 0;
	#判断是否调用caller会提速？
	if(get_show_file_info())
	{
		($pkg, $file, $line) = caller;
	}
	xs_log_write(LOG_LEVEL_TRACE,$file,$line,$msg);
}
sub printBug {
	my ($fmt, @args) = @_;
	my $msg = sprintf($fmt, @args);
	my ($pkg,$file,$line);
	$file = ""; $line = 0;
	#判断是否调用caller会提速？
	if(get_show_file_info())
	{
		($pkg, $file, $line) = caller;
	}
	xs_log_write(LOG_LEVEL_DEBUG,$file,$line,$msg);
}
sub printInf {
	my ($fmt, @args) = @_;
	my $msg = sprintf($fmt, @args);
	my ($pkg,$file,$line);
	$file = ""; $line = 0;
	#判断是否调用caller会提速？
	if(get_show_file_info())
	{
		($pkg, $file, $line) = caller;
	}
	xs_log_write(LOG_LEVEL_INFO,$file,$line,$msg);
}
sub printWarn {
	my ($fmt, @args) = @_;
	my $msg = sprintf($fmt, @args);
	my ($pkg,$file,$line);
	$file = ""; $line = 0;
	#判断是否调用caller会提速？
	if(get_show_file_info())
	{
		($pkg, $file, $line) = caller;
	}
	xs_log_write(LOG_LEVEL_WARN,$file,$line,$msg);
}
sub printErr {
	my ($fmt, @args) = @_;
	my $msg = sprintf($fmt, @args);
	my ($pkg,$file,$line);
	$file = ""; $line = 0;
	#判断是否调用caller会提速？
	if(get_show_file_info())
	{
		($pkg, $file, $line) = caller;
	}
	xs_log_write(LOG_LEVEL_ERROR,$file,$line,$msg);
}
sub printFail {
	my ($fmt, @args) = @_;
	my $msg = sprintf($fmt, @args);
	my ($pkg,$file,$line);
	$file = ""; $line = 0;
	#判断是否调用caller会提速？
	if(get_show_file_info())
	{
		($pkg, $file, $line) = caller;
	}
	xs_log_write(LOG_LEVEL_FATAL,$file,$line,$msg);
}
sub printLog {
	my ($fmt, @args) = @_;
	my $msg = sprintf($fmt, @args);
	xs_log_write(LOG_LEVEL_TEXT,"",0,$msg);
}
sub printRep {
	my ($fmt, @args) = @_;
	my $msg = sprintf($fmt, @args);
	xs_rep_write($msg);
}
1;

__END__

=pod

=encoding utf8

=head1 NAME

XS::Log - C/XS 实现的高效的日志模块

=head1 DESCRIPTION

B<XS::Log>是高效快速的日志模块，纯c语言开发，快速高效的IO读写，同时支持多线程。
也可以不通过openLog()和closeLog()，直接屏幕输出

由王海清(161263@qq.com)开发完成

=head1 SYNOPSI

 use XS::Log qw(:all);
 
 my %opt = (
     level             => LOG_LEVEL_DEBUG,
     mode              => LOG_MODE_DAILY,
     targets           => LOG_TARGET_CONSOLE | LOG_TARGET_FILE,
	 with_rep          => 0,        #参考：关于with_rep参数
     use_color         => 1,
     show_timestamp    => 1,
     show_log_level    => 1,
     show_file_info    => 1,
     max_file_size     => 1024*1024*10,		#10M
     max_files         => 5,
     flush_immediately => 1,
 );
 
 openLog("test.log", \%opt);
 
 printLog($msg);                    #原文输出
 printInf("This is info");
 printWarn("This is warning");
 printErr("This is error");
 #printFail("This is fatal");		#注意：谨慎使用 ，程序会关闭文件并exit
 
 setLogColor(0);
 setLogOptions("show_file_info",1);
 setLogMode(LOG_LEVEL_DEBUG);		#最高级别，显示所有日志
 
 my $user = "Alice";
 my $val  = 42;

 printInf("Hello %s, value=%d", $user, $val);
 printErr("File not found: %s", "/tmp/test.txt");
 
 closeLog();

=head1 常量

=head2 日志级别

 LOG_LEVEL_OFF     -1       #关闭日志
 LOG_LEVEL_FATAL    0       #致命错误
 LOG_LEVEL_ERROR    1       #错误日志
 LOG_LEVEL_WARN     2       #警告日志
 LOG_LEVEL_INFO     3       #普通日志（默认）
 LOG_LEVEL_TRACE    4       #Trace/Note日志
 LOG_LEVEL_DEBUG    5       #测试日志
 LOG_LEVEL_TEXT     6       #无格式日志

=head2 日志模式

 LOG_MODE_CYCLE     0       #循环日志模式（默认）
                            #设置日志：/temp/log/my.log
                            #循环日志：/temp/log/my.1.log
                            #        /temp/log/my.2.log
                            #        /temp/log/my.3.log
                            #        ......

 LOG_MODE_DAILY     1       #按天日志模式
                            #设置日志：/temp/log/my.log
                            #循环日志：/temp/log/20250101/my.log
                            #        /temp/log/20250102/my.log
                            #        /temp/log/20250103/my.log
                            #        ......

 LOG_MODE_HOURLY    2       #按小时日志模式
                            #设置日志：/temp/log/my.log
                            #循环日志：/temp/log/20250101/my.00.log
                            #        /temp/log/20250101/my.01.log
                            #        /temp/log/20250101/my.02.log
                            #        ......

=head2 日志输出目标选项

 LOG_TARGET_CONSOLE 1       #输出到控制台（默认）
 LOG_TARGET_FILE    2       #输出到文件
 LOG_TARGET_SYSLOG  4       #输出到系统日志(暂未实现)

=head1 关于with_rep参数

B<说明>： 很多时候，在一个程序需要写详细日志.log和概要日志.rep，所以有了with_rep参数

  0      默认：0 不写rep日志
  1      写概要日志

当with_rep=1时，详细日志.log会在默认目录下增加LOG/，概要日志.log会放到日志默认目录

B<特别注意的是>：详细日志.rep，只支持函数printRep($msg)，而且不带格式的原文输出

=head2 带概要日志的例子

  openLog("$HOME/log/my.log",$options);

B<循环日志>： 当mode=LOG_MODE_CYCLE时

REP日志目录和文件：

  $HOME/log/my.rep
  $HOME/log/my.1.rep
  $HOME/log/my.2.rep
  ......
  
LOG日志目录和文件：

  $HOME/log/LOG/my.log
  $HOME/log/LOG/my.1.log
  $HOME/log/LOG/my.2.log
  ......

B<按天日志模式>： 当mode=LOG_MODE_DAILY

REP日志目录和文件：

  $HOME/log/20250101/my.rep
  $HOME/log/20250102/my.rep
  $HOME/log/20250103/my.rep
  ......
  
LOG日志目录和文件：

  $HOME/log/20250101/LOG/my.log
  $HOME/log/20250102/LOG/my.1.log
  $HOME/log/20250103/LOG/my.2.log
  ......

B<按小时日志模式>： 当mode=LOG_MODE_HOURLY

REP日志目录和文件：

  $HOME/log/20250101/my.00.rep
  $HOME/log/20250101/my.01.rep
  $HOME/log/20250101/my.02.rep
  ......
  
LOG日志目录和文件：

  $HOME/log/20250101/LOG/my.00.log
  $HOME/log/20250101/LOG/my.01.log
  $HOME/log/20250101/LOG/my.02.log
  ......

=head1 函数说明

=head2 openLog

 openLog($log_filepath,\%options);
 
=head3 options参数

  level                  #日志级别，默认： LOG_LEVEL_INFO
  mode                   #日志模式，默认： LOG_MODE_CYCLE
  targets                #输出目标组合(位掩码)，默认： LOG_TARGET_CONSOLE
  use_color;             #是否使用彩色输出(控制台)，默认：1
  show_timestamp;        #是否显示时间戳，默认：1
  show_log_level;        #是否显示日志级别，默认：1
  show_file_info;        #是否显示文件信息，默认：0
  max_file_size;         #最大文件大小(KB)，0表示不限制，注意：mode=LOG_MODE_CYCLE有效
  max_files;             #最大文件数量，0表示不限制，默认100M，注意：mode=LOG_MODE_CYCLE有效
  flush_immediately;     #每次记录后立即刷新，默认：0

=head2 closeLog

  closeLog();                                  #关闭日志文件
  
=head2 flushLog

  flushLog();                                  #flush日志缓存

=head2 setLogOptions 

  setLogOptions($opt_key,$opt_val);	           #设置options参数，注意：$opt_val的类型

=head2 setLogUseColor 

  setLogUseColor($bool);                       #设置日志颜色，0-无颜色 1-有颜色
							                  
=head2 setLogTargets
							                  
  setLogTargets($target);                      #设置日志输出日志模式，LOG_TARGET_CONSOLE/LOG_TARGET_FILE
							                  
=head2 setLogMode                             
							                  
  setLogMode($mode);                           #设置日志文件循环模式

=head2 setLogLevel
 
  setLogLevel($level);                         #设置日志级别

=head2 日志输出命令

  printInf($msg);
  printWarn($msg);
  printErr($msg);
  printFail($msg);                             #注意：谨慎使用，会直接exit退出程序
  printNote($msg);
  printLog("[%s] %s",$datetime,$msg);          #自己设置输出格式，系统不大时间、级别等内容

  printInf("%s\n",$msg);                       #支持：%的方式格式化输出

=head2 printRep
 
  printRep($msg);                              #with_rep=1有效
  printRep("[%s] %s",$datetime,$msg);          #自己设置输出格式，系统不大时间、级别等内容

=head1 使用例子

=head2 例子1:/home/user/temp1.pl

直接使用，不输出文件：

  use strict;
  use warnings;
  use XS::Log qw(:all);
  
  printInf("This is info1\n");
  printInf("This is info2\n");
  printInf("This is info3\n");
  printInf("This is info4\n");
  printInf("This is info5\n");
  printWarn("This is warning1\n");
  printWarn("This is warning2\n");
  printErr("This is error1\n");
  printErr("This is error2\n");
  
  setLogOptions("use_color",0);                      #等效setLogColor(0);
  setLogOptions("show_file_info",0);
  setLogOptions("level",LOG_LEVEL_DEBUG);            #等效setLogLevel(LOG_LEVEL_DEBUG);
  
  my $user = "Alice";
  my $val  = 42;
  
  printInf("Hello %s, value=%d\n", $user, $val);
  printBug("Hello %s, value=%d\n", $user, $val);
  printBug("Hello %s, value=%d\n", $user, $val);
  printBug("Hello %s, value=%d\n", $user, $val);
  printErr("File not found: %s\n", "/tmp/test.txt");

屏幕输出结果：

  [2025-09-18 18:44:38.983][INF] This is info1
  [2025-09-18 18:44:38.983][INF] This is info2
  [2025-09-18 18:44:38.983][INF] This is info4
  [2025-09-18 18:44:38.983][INF] This is info5
  [2025-09-18 18:44:38.983][WRN] This is warning1
  [2025-09-18 18:44:38.983][WRN] This is warning2
  [2025-09-18 18:44:38.983][ERR] This is error1
  [2025-09-18 18:44:38.983][ERR] This is error2
  [2025-09-18 18:44:38.983][INF] (/home/user/temp1.pl:38) Hello Alice, value=42
  [2025-09-18 18:44:38.983][DEB] (/home/user/temp1.pl:39) Hello Alice, value=42
  [2025-09-18 18:44:38.983][DEB] (/home/user/temp1.pl:40) Hello Alice, value=42
  [2025-09-18 18:44:38.983][DEB] (/home/user/temp1.pl:41) Hello Alice, value=42
  [2025-09-18 18:44:38.983][ERR] (/home/user/temp1.pl:42) File not found: /tmp/test.txt

=head2 例子2:/home/user/temp2.pl

同时输出到文件和屏幕：

  use strict;
  use warnings;
  use XS::Log qw(:all);

  my %opt = (
   level             => LOG_LEVEL_INFO,
   mode              => LOG_MODE_CYCLE,
   targets           => LOG_TARGET_CONSOLE|LOG_TARGET_FILE,        #同时输出到文件和屏幕
   use_color         => 1,
   show_timestamp    => 1,
   show_log_level    => 1,
   show_file_info    => 0,
   max_file_size     => 1024*1024*10,                              #LOG_MODE_CYCLE 有效
   max_files         => 5,                                         #LOG_MODE_CYCLE 有效
   flush_immediately => 1,
  );

  openLog("/home/user/log/test.log", \%opt);
  
  printInf("This is info1\n");
  printInf("This is info2\n");
  printInf("This is info3\n");
  printInf("This is info4\n");
  printInf("This is info5\n");
  printWarn("This is warning1\n");
  printWarn("This is warning2\n");
  printErr("This is error1\n");
  printErr("This is error2\n");
  
  setLogOptions("use_color",0);                      #等效setLogColor(0);
  setLogOptions("show_file_info",0);
  setLogOptions("level",LOG_LEVEL_DEBUG);            #等效setLogLevel(LOG_LEVEL_DEBUG);
  setLogOptions("targets",LOG_TARGET_FILE);          #等效setLogTargets(LOG_TARGET_FILE); 只输出到文件，不显示到屏幕
  
  my $user = "Alice";
  my $val  = 42;
  
  printInf("Hello %s, value=%d\n", $user, $val);
  printBug("Hello %s, value=%d\n", $user, $val);
  printBug("Hello %s, value=%d\n", $user, $val);
  printBug("Hello %s, value=%d\n", $user, $val);
  printErr("File not found: %s\n", "/tmp/test.txt");
  
  closeLog();

屏幕输出结果：

  [2025-09-18 18:46:32.013][INF] This is info1
  [2025-09-18 18:46:32.013][INF] This is info2
  [2025-09-18 18:46:32.013][INF] This is info4
  [2025-09-18 18:46:32.013][INF] This is info5
  [2025-09-18 18:46:32.013][WRN] This is warning1
  [2025-09-18 18:46:32.013][WRN] This is warning2
  [2025-09-18 18:46:32.013][ERR] This is error1
  [2025-09-18 18:46:32.013][ERR] This is error2

=cut


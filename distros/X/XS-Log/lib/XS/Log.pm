package XS::Log;
#Build  MD5 : drVn1p6ygZRWEQSVolq0tg
#Build Time : 2025-09-18 13:23:17
our $VERSION = 1.04;
our $BUILDDATE = "2025-09-18";  #Build Time: 13:23:17
use strict;
use warnings;
use XSLoader;
require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(
    openLog closeLog flushLog setLogOptions setLogColor setLogMode setLogTargets setLogLevel
    printNote printBug printInf printWarn printErr printFail printText
    LOG_LEVEL_OFF LOG_LEVEL_FATAL LOG_LEVEL_ERROR LOG_LEVEL_WARN LOG_LEVEL_INFO
    LOG_LEVEL_TRACE LOG_LEVEL_DEBUG LOG_LEVEL_TEXT
    LOG_MODE_CYCLE LOG_MODE_DAILY LOG_MODE_HOURLY
    LOG_TARGET_CONSOLE LOG_TARGET_FILE LOG_TARGET_SYSLOG
);
# 定义导出标签 :all
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
XSLoader::load('XS::Log', $VERSION);
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
     use_color         => 1,
     show_timestamp    => 1,
     show_log_level    => 1,
     show_file_info    => 1,
     max_file_size     => 1024*1024*10,		#10M
     max_files         => 5,
     flush_immediately => 1,
 );
 
 openLog("test.log", \%opt);
 
 printInf("This is info");
 printWarn("This is warning");
 printErr("This is error");
 #printFail("This is fatal");
 
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
 LOG_MODE_DAILY     1       #按天日志模式
 LOG_MODE_HOURLY    2       #按小时日志模式

=head2 日志输出目标选项

 LOG_TARGET_CONSOLE 1       #输出到控制台（默认）
 LOG_TARGET_FILE    2       #输出到文件
 LOG_TARGET_SYSLOG  4       #输出到系统日志(暂未实现)

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
  max_file_size;         #最大文件大小(KB)，0表示不限制
  max_files;             #最大文件数量，0表示不限制，默认100M
  flush_immediately;     #每次记录后立即刷新，默认：0

=head2 closeLog

  closeLog();            #关闭日志文件
  
=head2 flushLog

  flushLog();           #flush日志缓存

=head2 setLogConf 

  setLogOptions($opt_key,$opt_val);	#设置options参数

=head2 setLogUseColor 

  setLogUseColor($bool);        #设置日志颜色，0-无颜色 1-有颜色

=head2 setLogTargets

  setLogTargets($target);       #设置日志输出日志模式，LOG_TARGET_CONSOLE/LOG_TARGET_FILE
 
=head2 setLogMode
 
  setLogMode($mode);            #设置日志文件循环模式

=head2 setLogLevel
 
  setLogLevel($level);          #设置日志级别

=head2 日志输出命令

  printInf($msg);
  printWarn($msg);
  printErr($msg);
  printFail($msg);      #注意：谨慎使用，会直接exit退出程序
  printNote($msg);
  printText($msg);      #原文输出

支持：%的方式格式化输出:

  printInf("%s\n",$msg);

=cut


package XS::Log;
#Build  MD5 : zd+uj+XHGbw+rKd1XJmC2Q
#Build Time : 2025-09-17 16:02:35
our $VERSION = 1.02;
our $BUILDDATE = "2025-09-17";  #Build Time: 16:02:35
use strict;
use warnings;
use XSLoader;
require Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(
    openLog closeLog flushLog
    printNote printBug printInf printWarn printErr printFail printText
    LOG_LEVEL_OFF LOG_LEVEL_FATAL LOG_LEVEL_ERROR LOG_LEVEL_WARN LOG_LEVEL_INFO
    LOG_LEVEL_TRACE LOG_LEVEL_DEBUG LOG_LEVEL_TEXT
    LOG_MODE_CYCLE LOG_MODE_DAILY LOG_MODE_HOURLY
    LOG_TARGET_CONSOLE LOG_TARGET_FILE LOG_TARGET_SYSLOG
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
     level             => Log::LOG_LEVEL_DEBUG,
     mode              => Log::LOG_MODE_DAILY,
     targets           => Log::LOG_TARGET_CONSOLE | Log::LOG_TARGET_FILE,
     use_color         => 1,
     show_timestamp    => 1,
     show_log_level    => 1,
     show_file_info    => 1,
     max_file_size     => 1024*1024*10,		#10M
     max_files         => 5,
     flush_immediately => 1,
 );
 
 Log::openLog("test.log", \%opt);
 
 Log::printInf("This is info");
 Log::printWarn("This is warning");
 Log::printErr("This is error");
 Log::printFail("This is fatal");
 
 my $user = "Alice";
 my $val  = 42;

 Log::printInf("Hello %s, value=%d", $user, $val);
 Log::printErr("File not found: %s", "/tmp/test.txt");
 
 Log::closeLog();

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
  mode 				     #日志模式，默认： LOG_MODE_CYCLE
  targets                #输出目标组合(位掩码)，默认： LOG_TARGET_CONSOLE
  use_color;             #是否使用彩色输出(控制台)，默认：1
  show_timestamp;        #是否显示时间戳，默认：1
  show_log_level;        #是否显示日志级别，默认：1
  show_file_info;        #是否显示文件信息，默认：0
  max_file_size;         #最大文件大小(KB)，0表示不限制
  max_files;             #最大文件数量，0表示不限制，默认100M
  flush_immediately;     #每次记录后立即刷新，默认：0

=head2 closeLog

=head2 flushLog

=head2 printInf

=head2 printWarn

=head2 printErr

=head2 printFail

=head2 printNote

=head2 printText

=cut



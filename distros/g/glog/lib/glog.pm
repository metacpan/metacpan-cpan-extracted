package glog;
use strict;
use warnings;
use Exporter qw(import);
use POSIX qw(strftime);
use Test::More;
use glog::logger;

our $VERSION = '1.0.5';
our @EXPORT = qw(Logger LogLevel Log LogFormat LogF LogFile LogDie LogWarn LogInfo LogDebug LogErr);

our $GLOG = glog::logger->new;

sub Logger    { glog::logger->new }
sub LogLevel  { $GLOG->LogLevel(@_); }
sub Log       { $GLOG->Log(@_); }
sub LogFormat { $GLOG->LogFormat(@_); }
sub LogF      { $GLOG->LogFormat(@_); }
sub LogFile   { $GLOG->LogFile(@_); }
sub LogDie    { $GLOG->LogDie(@_); }
sub LogWarn   { $GLOG->LogWarn(@_); }
sub LogInfo   { $GLOG->LogInfo(@_); }
sub LogDebug  { $GLOG->LogDebug(@_); }
sub LogErr    { $GLOG->LogErr(@_); }

1;
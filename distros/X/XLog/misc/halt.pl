use 5.012;
use XLog;

XLog::set_logger(sub { say $_[0] });
XLog::set_formatter(XLog::Formatter::Pattern->new("[%3t] %p %P %c[%L]: %m%C"));
XLog::set_level(XLog::CRITICAL);

XLog::halt("the beginning of the end");

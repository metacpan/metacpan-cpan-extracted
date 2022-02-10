package MyTestLogger;
use 5.012;
use XLog;

XLog::set_format("%2.3t %c[%L/%1M]%C: %m (%f:%l)");
XLog::set_logger(XLog::Console->new);
XLog::set_level(XLog::WARNING);

XLog::set_level(XLog::DEBUG, "UniEvent::WebSocket");
XLog::set_level(XLog::DEBUG, "UniEvent::HTTP");
XLog::set_level(XLog::INFO, "UniEvent");

1;
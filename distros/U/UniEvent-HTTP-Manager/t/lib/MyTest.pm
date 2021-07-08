package MyTest;
use 5.012;
use warnings;
use UniEvent::HTTP::Manager;

XS::Loader::load();

if ($ENV{LOGGER}) {
    require XLog;
    XLog::set_logger(sub { say $_[0] });
    XLog::set_level(XLog::INFO(), "UniEvent::HTTP::Manager");
}

1;

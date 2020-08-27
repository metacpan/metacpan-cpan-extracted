use 5.012;
use XLog;
use Benchmark 'timethis';

say $$;

sub concur {
    my ($nthr, $cnt) = @ARGV;
    $cnt = int($cnt/$nthr);

    XLog::test($nthr, $cnt);
}

XLog::set_format("%m");
XLog::set_logger(sub { });

XLog::set_level(XLog::DEBUG);

bench0();

sub bench0 {
    timethis(-1, sub {
        XLog::debug("");
    });
}

sub bench1 {
    {
        package Epta;
        our $xlog_module = XLog::Module->new("Epta");
        sub func { XLog::error("log message") }
    }
    
    timethis(-1, \&Epta::func);
}

sub bench2 {
    XLog::debug("") while 1;
}

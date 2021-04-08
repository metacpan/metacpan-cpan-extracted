use 5.012;
use warnings;
use lib 't/lib'; use MyTest;
use Test::More;
use XLog::Console;

XLog::set_logger(XLog::Console->new);
XLog::set_level(XLog::DEBUG);
XLog::set_formatter("%f:%l: %m");

my $str;
open(my $fh, ">", \$str) or die $!;
my $old = select $fh;

XLog::debug("epta");

select $old;

is $str, "console.t:15: epta\n";

done_testing();

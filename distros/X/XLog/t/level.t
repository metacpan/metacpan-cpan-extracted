use 5.012;
use warnings;
use lib 't/lib'; use MyTest;
use Test::More;

my @levels = @MyTest::levels;

subtest 'set level' => sub {
    my $ctx = Context->new;
    
    XLog::set_level(XLog::WARNING);
    for my $level (@levels) {
        XLog::log($level, "hi");
        if ($level >= XLog::WARNING) {
            $ctx->check;
        } else {
            is $ctx->cnt, 0;
        }
    }
    
    XLog::set_level(XLog::DEBUG);
    for my $level (@levels) {
        XLog::log($level, "hi");
        $ctx->check;
    }
};

done_testing();

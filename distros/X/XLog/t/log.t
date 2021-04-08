use 5.012;
use warnings;
use lib 't/lib'; use MyTest;
use Test::More;

subtest 'log' => sub {
    my $ctx = Context->new;
    XLog::set_level(XLog::DEBUG);
    
    for my $l (@MyTest::levels) {
        XLog::log($l, "l=$l");
        $ctx->check(
            level => $l,
            msg   => "l=$l",
        );
    }
};

subtest 'logXXXX' => sub {
    my $ctx = Context->new;
    XLog::set_level(XLog::DEBUG);
    
    XLog::debug("a");
    $ctx->check(level => XLog::DEBUG, msg => 'a');
    
    XLog::info("b");
    $ctx->check(level => XLog::INFO, msg => 'b');

    XLog::notice("c");
    $ctx->check(level => XLog::NOTICE, msg => 'c');

    XLog::warning("d");
    $ctx->check(level => XLog::WARNING, msg => 'd');

    XLog::warn("e");
    $ctx->check(level => XLog::WARNING, msg => 'e');

    XLog::error("f");
    $ctx->check(level => XLog::ERROR, msg => 'f');

    XLog::critical("g");
    $ctx->check(level => XLog::CRITICAL, msg => 'g');

    XLog::alert("h");
    $ctx->check(level => XLog::ALERT, msg => 'h');

    XLog::emergency("i");
    $ctx->check(level => XLog::EMERGENCY, msg => 'i');
};

subtest 'formatted logging' => sub {
    my $ctx = Context->new;
    
    subtest 'no args is empty message' => sub {
        XLog::log(XLog::WARNING);
        $ctx->check(msg => "==> MARK <==");
        XLog::error();
        $ctx->check(msg => "==> MARK <==");
    };
    
    subtest 'one arg left as is' => sub {
        XLog::log(XLog::WARNING, "num=%d");
        $ctx->check(msg => "num=%d");
        XLog::error("num=%d");
        $ctx->check(msg => "num=%d");
    };
    
    subtest 'several args are processed as printf' => sub {
        XLog::log(XLog::WARNING, "num=%d", 13);
        $ctx->check(msg => "num=13");
        XLog::log(XLog::ERROR, "num=%d str=%s", 666, "epta");
        $ctx->check(msg => "num=666 str=epta");
        
        XLog::error("num=%d", 10);
        $ctx->check(msg => "num=10");
        XLog::error("num=%d str=%s", 11, "qwerty");
        $ctx->check(msg => "num=11 str=qwerty");
    };
};

{
    package BBB;
    use overload '""' => sub { 'custom-stringification' };
}

subtest "custom obj logging (no overload)" => sub {
    my $ctx = Context->new;

    XLog::log(XLog::WARNING, bless {} => 'AAA');
    $ctx->check(msg => qr/AAA/);

    XLog::log(XLog::WARNING, bless {} => 'BBB');
    $ctx->check(msg => qr/custom-stringification/);
};

subtest 'callback logging' => sub {
    my $ctx = Context->new;
    
    XLog::log(XLog::WARNING, sub { "abcdef" });
    $ctx->check(msg => "abcdef");
    
    XLog::error(sub { 123 });
    $ctx->check(msg => "123");

    XLog::error(sub { bless {} => 'AAA' });
    $ctx->check(msg => qr/AAA/);

    XLog::error(sub { bless {} => 'BBB' });
    $ctx->check(msg => qr/custom-stringification/);
};

subtest 'from eval block' => sub {
    my $ctx = Context->new;

    eval {
        XLog::log(XLog::WARNING, sub { "abcdef" });
    };
    ok "passed";
};

done_testing();

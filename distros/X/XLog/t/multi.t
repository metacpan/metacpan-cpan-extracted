use 5.012;
use warnings;
use lib 't/lib'; use MyTest;
use Test::More;

subtest 'logging to multi channels' => sub {
    my $ctx = Context->new;
    my ($m1, $m2, $m3, $m4, $m5, $m6, $m7);
    XLog::set_formatter("f1:%m");
    XLog::set_logger(XLog::Multi->new([
        {logger => sub { $m1 = shift }, min_level => XLog::DEBUG},
        {logger => sub { $m2 = shift }, min_level => XLog::NOTICE, formatter => XLog::Formatter::Pattern->new("f2:%m")},
        {logger => sub { $m3 = shift }, min_level => XLog::NOTICE, formatter => "f3:%m"},
        {logger => sub { $m4 = shift }, min_level => XLog::ERROR},
        {logger => XLog::Multi->new([
                {logger => sub { $m5 = shift }, min_level => XLog::DEBUG},
                {logger => sub { $m6 = shift }, min_level => XLog::WARNING, formatter => "m2:%m",},
                {logger => sub { $m7 = shift }, min_level => XLog::ERROR},
            ]),
            min_level => XLog::DEBUG,
            formatter => "m:%m",
        },
    ]));
    XLog::warning("hi");
    is $m1, "f1:hi";
    is $m2, "f2:hi";
    is $m3, "f3:hi";
    is $m4, undef;
    is $m5, "m:hi";
    is $m6, "m2:hi";
    is $m7, undef;
};

done_testing();

use 5.012;
use warnings;
use lib 't/lib'; use MyTest;
use Test::More;

subtest 'logging to multi channels' => sub {
    my $ctx = Context->new;
    my ($m1, $m2, $m3, $m4);
    XLog::set_format("f1:%m");
    XLog::set_logger(XLog::Multi->new([
        {logger => sub { $m1 = shift }, min_level => XLog::DEBUG},
        {logger => sub { $m2 = shift }, min_level => XLog::NOTICE, formatter => XLog::Formatter::Pattern->new("f2:%m")},
        {logger => sub { $m3 = shift }, min_level => XLog::NOTICE, format    => "f3:%m"},
        {logger => sub { $m4 = shift }, min_level => XLog::ERROR},
    ]));
    XLog::warning("hi");
    is $m1, "f1:hi";
    is $m2, "f2:hi";
    is $m3, "f3:hi";
    is $m4, undef;
};

done_testing();

#! perl -w
use strict;

BEGIN {
    *CORE::GLOBAL::localtime = sub { CORE::localtime(@_) };
}

use Test::More;
use Test::Fatal 'lives_ok';
use Test::NoWarnings ();

use POSIX 'strftime';
{ # Test the $Test::Smoke::LogMixin::USE_TIMESTAMP switch.
    local $Test::Smoke::LogMixin::USE_TIMESTAMP = 0;
    my $logger = Test::Smoke::Logger->new(v => 2);
    isa_ok($logger, 'Test::Smoke::Logger');
    open my $lh, '>', \my $logfile;
    my $stdout = select $lh;
    $logger->log_warn("do_log_warn()");
    $logger->log_info("do_log_info()");
    $logger->log_debug("do_log_debug()");
    select $stdout;
    is($logfile, <<'    EOL', "logfile (v=2); no timestamp");
do_log_warn()
do_log_info()
do_log_debug()
    EOL
}

{
    local $Test::Smoke::LogMixin::USE_TIMESTAMP = 0;
    my $t0 = LogTest->new(v => 0);
    isa_ok($t0, 'LogTest');
    open my $fh0, '>', \my $o0;
    {
        my $stdout = select $fh0; $|++;
        $t0->log_warn_test();
        $t0->log_info_test();
        $t0->log_debug_test();
        select $stdout;
    }
    my $l0 = <<'    EOL';
->log_warn()
    EOL
    is($o0, $l0, "v==0 => log_warn");

    my $t1 = LogTest->new(v => 1);
    isa_ok($t1, 'LogTest');
    open my $fh1, '>', \my $o1;
    {
        my $stdout = select $fh1; $|++;
        $t1->log_warn_test();
        $t1->log_info_test();
        $t1->log_debug_test();
        select $stdout;
    }
    my $l1 = <<'    EOL';
->log_warn()
->log_info()
    EOL
    is($o1, $l1, "v==1 => log_warn, log_info");

    my $t2 = LogTest->new(v => 2);
    isa_ok($t2, 'LogTest');
    open my $fh2, '>', \my $o2;
    {
        my $stdout = select $fh2; $|++;
        $t2->log_warn_test();
        $t2->log_info_test();
        $t2->log_debug_test();
        select $stdout;
    }
    my $l2 = <<'    EOL';
->log_warn()
->log_info()
->log_debug()
    EOL
    is($o2, $l2, "v==2 => log_warn, log_info, log_debug");

    my $t4 = LogTest->new(verbose => 1);
    isa_ok($t4, 'LogTest');
    open my $fh4, '>', \my $o4;
    {
        my $stdout = select $fh4; $|++;
        $t4->log_warn_test();
        $t4->log_info_test();
        $t4->log_debug_test();
        select $stdout;
    }
    my $l4 = <<'    EOL';
->log_warn()
->log_info()
    EOL
    is($o4, $l4, "verbose==1 => log_warn, log_info");

}

{
    no warnings 'redefine';
    local *CORE::GLOBAL::localtime = sub {
        return (2, 11, 14, 15, 3, 115, 3, 104, 1);
    };
    my $prefix = $^O eq 'MSWin32'
        ? strftime "[%Y-%m-%d %H:%M:%SZ] ", gmtime
        : strftime "[%Y-%m-%d %H:%M:%S%z] ", localtime;

    my $logger = Test::Smoke::Logger->new(v => 0);
    isa_ok($logger, 'Test::Smoke::Logger');
    open my $lh, '>', \my $logfile;
    my $stdout = select $lh;
    $logger->log_warn("do_log_warn()");
    $logger->log_info("do_log_info()");
    $logger->log_debug("do_log_debug()");
    select $stdout;
    my $log = <<"    EOL";
${prefix}do_log_warn()
    EOL
    is($logfile, $log, "logfile (v=0)");
}

{
    note("no sprintf() without arguments");

    local $Test::Smoke::LogMixin::USE_TIMESTAMP = 0;
    my $logger = Test::Smoke::Logger->new(v => 1);

    open my $lh, '>', \my $logfile;
    my $stdout = select($lh); $|++;

    lives_ok(
        sub {
            use warnings FATAL => 'all';
            $logger->log_info("100% error free");
        },
        "No problems with '%' in bare log-message"
    );
    lives_ok(
        sub {
            use warnings FATAL => 'all';
            $logger->log_info("100%% error free %u", 42);
        },
        "No problems with '%%' in log-message with arguments"
    );

    is($logfile, <<'    EOL', "compare logfile");
100% error free
100% error free 42
    EOL
}

Test::NoWarnings::had_no_warnings();
$Test::NoWarnings::do_end_test = 0;
done_testing();

package LogTest;
use base 'Test::Smoke::ObjectBase';
use Test::Smoke::LogMixin;

sub new {
    my $class = shift;
    my %raw = @_;
    my $fields;
    for my $fld (keys %raw) { $fields->{"_$fld"} = $raw{$fld} }
    return bless $fields, $class;
}

sub log_warn_test {
    my $self = shift;
    $self->log_warn("->log_warn()");
}

sub log_info_test {
    my $self = shift;
    $self->log_info("->log_info()");
}

sub log_debug_test {
    my $self = shift;
    $self->log_debug("->log_debug()");
}

1;

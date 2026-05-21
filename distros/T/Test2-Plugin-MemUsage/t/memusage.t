use strict;
use warnings;
use Test2::API qw/intercept context/;

use Test2::Tools::Defer qw/def do_def/;

use vars qw/@CALLBACKS/;

BEGIN {
    no warnings 'redefine';
    local *Test2::API::test2_add_callback_exit = sub { push @CALLBACKS => @_ };

    require Test2::Plugin::MemUsage;
    def ok => (!scalar(@CALLBACKS), "requiring the module does not add a callback");

    Test2::Plugin::MemUsage->import();

    def ok => (scalar(@CALLBACKS), "importing the module does add a callback");

    Test2::Plugin::MemUsage->import();

    def ok => (scalar(@CALLBACKS) == 1, "second import is a no-op (callback registered once)");
}

use Test2::Tools::Basic;
use Test2::Tools::Compare qw/like is hash field etc/;

do_def;

is(Test2::Plugin::MemUsage->proc_file(), "/proc/$$/status", "Correct procfile");

my $events = intercept {
    sub {
        no warnings 'redefine';
        # Force the linux procfile collector regardless of host OS so the
        # mocked t/procfile drives the assertions below.
        local *Test2::Plugin::MemUsage::_collector_for_os
            = sub { \&Test2::Plugin::MemUsage::_collect_proc };
        local *Test2::Plugin::MemUsage::_maxrss_kb = sub { undef };
        local *Test2::Plugin::MemUsage::proc_file  = sub { 't/procfile' };
        my $ctx = context();
        $CALLBACKS[0]->($ctx);
        $ctx->release;
    }->();
};

chomp(my $summary = <<EOT);
rss:  16604kB
size: 25176kB
peak: 25176kB
EOT

is(
    $events->[0],
    hash {
        field info   => [{details => $summary, tag => 'MEMORY'}];
        field about  => {details => $summary, package => 'Test2::Plugin::MemUsage'};
        field memory => {
            details => $summary,
            size    => ['25176', 'kB'],
            peak    => ['25176', 'kB'],
            rss     => ['16604', 'kB'],
        };
        field harness_job_fields => [
            {name => 'mem_rss',  details => '16604kB', data => {value => 16604, units => 'kB'}},
            {name => 'mem_size', details => '25176kB', data => {value => 25176, units => 'kB'}},
            {name => 'mem_peak', details => '25176kB', data => {value => 25176, units => 'kB'}},
        ];
        etc;
    },
    "Got desired event"
);

done_testing();

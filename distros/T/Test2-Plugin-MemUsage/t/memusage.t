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
}

use Test2::Tools::Basic;
use Test2::Tools::Compare qw/like is hash field etc/;

do_def;

is(Test2::Plugin::MemUsage->proc_file(), "/proc/$$/status", "Correct procfile");

my $events = intercept {
    sub {
        no warnings 'redefine';
        local *Test2::Plugin::MemUsage::proc_file = sub { 't/procfile' };
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
        etc;
    },
    "Got desired event"
);

done_testing();

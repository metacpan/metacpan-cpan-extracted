use strict;
use warnings;
use utf8;

use Test::More;
use Test::Fluent::Logger qw/get_fluent_logs clear_fluent_logs is_active activate deactivate/;

subtest 'check export_ok' => sub {
    clear_fluent_logs;

    my $logger = Fluent::Logger->new(
        host => '127.0.0.1',
        port => 24224,
    );

    is is_active, 1;

    deactivate;
    is is_active, 0;

    $logger->post("tag1", {foo => 'bar'}); # use original _post
    my @fluent_logs = get_fluent_logs;
    is scalar @fluent_logs, 0;

    activate;
    is is_active, 1;

    $logger->post("tag1", {foo => 'bar'}); # use original _post
    @fluent_logs = get_fluent_logs;
    is scalar @fluent_logs, 1;
};

done_testing;


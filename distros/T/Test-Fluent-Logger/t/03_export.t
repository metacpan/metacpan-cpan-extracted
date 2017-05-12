use strict;
use warnings;
use utf8;

use Test::More;
use Test::Fluent::Logger;

subtest 'check export' => sub {
    clear_fluent_logs;

    my $logger = Fluent::Logger->new(
        host       => '127.0.0.1',
        port       => 24224,
        tag_prefix => 'prefix',
    );
    $logger->post("tag1", {foo => 'bar'});
    $logger->post("tag2", {buz => 'qux'});
    $logger->post_with_time("tag3", {hoge => 'fuga'}, 1234567);

    my @fluent_logs = get_fluent_logs;
    is scalar @fluent_logs, 3;

    is_deeply $fluent_logs[0]->{message}, {foo => 'bar'};
    is $fluent_logs[0]->{tag_prefix}, 'prefix';
    ok $fluent_logs[0]->{time};

    is_deeply $fluent_logs[1]->{message}, {buz => 'qux'};
    is $fluent_logs[1]->{tag_prefix}, 'prefix';
    ok $fluent_logs[1]->{time};

    is_deeply $fluent_logs[2]->{message}, {hoge => 'fuga'};
    is $fluent_logs[2]->{tag_prefix}, 'prefix';
    is $fluent_logs[2]->{time}, 1234567;
};

done_testing;


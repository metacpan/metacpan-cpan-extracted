package Test::Unit::Time::Progress::Stored;
use Test::More;
use Test::Deep;
use autobox::Core;

use Time::Progress::Stored;

subtest test__happy_path => sub {
    my $max = 42;

    my $progress = Time::Progress::Stored->new({
        max => $max,
    });

    is($progress->current, 0, "Initial current correct");
    ok( my $id = $progress->progress_id, "Got an id");
    is( $progress->storage->id__report->keys->size, 1, "One report" );

    my $storage = $progress->storage;

    {
        my $key__value = $storage->retrieve($id);
        eq_deeply(
            $key__value,
            {
                id                => $id,
                max               => $max,
                current           => 0,
                elapsed_seconds   => 0,
                elapsed_time      => "  0:00",
                finish_time       => re(qr/^[\w :]+$/),
                percent_string    => "  0.0%",
                percent           => 0,
                remaining_seconds => 0,
                remaining_time    => "  0:00",
                is_done           => 0,
                activity          => "",
            },
            "Initial report looks alright",
        );

    }

    sleep(1);
    $progress->advance();

    {
        my $key__value = $storage->retrieve($id);
        eq_deeply(
            $key__value,
            {
                id                => $id,
                max               => $max,
                current           => 1,
                elapsed_seconds   => 1,
                elapsed_time      => "  0:01",
                finish_time       => re(qr/^[\w :]+$/),
                percent_string    => "  2.4%",
                percent           => 2.4,
                remaining_seconds => re(qr/\d+/),
                remaining_time    => re(qr/^  0:\d\d$/),
                is_done           => 0,
                activity          => "",
            },
            "Next report looks alright",
        );
    }

    for (1 .. 41) {
        $progress->advance();
    }
    sleep(1);

    {
        my $key__value = $storage->retrieve($id);
        eq_deeply(
            $key__value,
            {
                id                => $id,
                max               => $max,
                current           => $max,
                elapsed_seconds   => 2,
                elapsed_time      => "  0:01",
                finish_time       => re(qr/^[\w :]+$/),
                percent_string    => "100.0%",
                percent           => 0,
                remaining_seconds => 0,
                remaining_time    => "  0:00",
                is_done           => 0,
                activity          => "",
            },
            "All items report looks alright",
        );
    }

    $progress->done();

    {
        my $key__value = $storage->retrieve($id);
        eq_deeply(
            $key__value,
            {
                id                => $id,
                max               => $max,
                current           => $max,
                elapsed_seconds   => 2,
                elapsed_time      => "  0:02",
                finish_time       => re(qr/^[\w :]+$/),
                percent_string    => "100.0%",
                percent           => 100,
                remaining_seconds => 0,
                remaining_time    => "  0:00",
                is_done           => 1,
                activity          => "",
            },
            "Done report looks alright",
        );
    }
};

done_testing();

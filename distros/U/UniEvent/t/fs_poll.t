use 5.012;
use warnings;
use lib 't/lib'; use MyTest;
use UniEvent::Error;
use UniEvent::Fs;

BEGIN { *Fs:: = *UniEvent::Fs:: }

my $call_cnt;
my $l = UniEvent::Loop->default_loop;

sub slp ($) { select undef, undef, undef, $_[0]; }

subtest 'non-existant file' => sub {
    my $h = new UniEvent::FsPoll;
    $h->start(var 'file', 0.01);
    $h->poll_callback(check_err(UE::SystemError::ENOENT, "watch non-existant file"));
    is($h->path, var 'file', "path getter works");
    $l->run;
    $l->run_nowait; # must be called only once
    check_call_cnt(1);
};

=x
subtest 'file appears' => sub {
    my $h = new UniEvent::FsPoll;
    $h->start(var 'file', 0.01);
    $h->poll_callback(check_err(UE::SystemError::ENOENT, "watch non-existant file"));
    $l->run;
    check_call_cnt(1);
    $h->poll_callback(check_appears("file appears"));
    Fs::touch(var 'file');
    $l->run;
    check_call_cnt(1);
    Fs::unlink(var 'file');
};

subtest 'mtime' => sub {
    Fs::touch(var 'file');
    my $h = new UniEvent::FsPoll;
    $h->start(var 'file', 0.01);
    $h->poll_callback(check_changes(STAT_MTIME, "file mtime"));
    $h->start_callback(sub { slp 0.01; Fs::touch(var 'file') });
    $l->run;
    check_call_cnt(1);
    Fs::unlink(var 'file');
};

subtest 'file contents' => sub {
    my $fd = Fs::open(var 'file', OPEN_RDWR | OPEN_CREAT);
    my $h = new UniEvent::FsPoll;
    $h->start(var 'file', 0.01);
    $h->poll_callback(check_changes([STAT_MTIME, STAT_SIZE], "file content"));
    $h->start_callback(sub { slp 0.01; Fs::write($fd, "epta") });
    $l->run;
    check_call_cnt(1);
    Fs::close($fd);
    Fs::unlink(var 'file');
};

subtest 'stop' => sub {
    my $h = new UniEvent::FsPoll;
    $h->start(var 'file', 0.01);
    $h->stop;
    $h->poll_callback(sub { $call_cnt++ });
    $l->run for 1..10;
    check_call_cnt(0);

    Fs::touch(var 'file');
    $h->start(var 'file', 0.1);
    my $t = UE::Timer->once(0.001, sub { $h->stop });
    $l->run for 1..10;
    check_call_cnt(0);

    Fs::unlink(var 'file');
};

subtest 'reset' => sub {
    Fs::touch(var 'file');
    my $h = new UniEvent::FsPoll;
    $h->start(var 'file', 0.01);
    $h->poll_callback(check_changes(STAT_MTIME, "mtime"));
    $h->start_callback(sub { slp 0.01; Fs::touch(var 'file') });
    $l->run;
    check_call_cnt(1);

    $h->reset;
    Fs::touch(var 'file');
    $l->run;
    check_call_cnt(0);

    Fs::unlink(var 'file');
};

subtest 'file remove' => sub {
    Fs::touch(var 'file');
    my $h = new UniEvent::FsPoll;
    $h->start(var 'file', 0.005);
    $h->start_callback(sub {
        my ($h, $stat, $err) = @_;
        die $err if $err;
        $l->stop;
    });
    $l->run;
    $h->poll_callback(check_err(UE::SystemError::ENOENT, "file remove"));
    Fs::unlink(var 'file');
    $l->run;
    check_call_cnt(1);
};

subtest 'event listener' => sub {
    no warnings 'once';
    my $cnt;
    *MyLst::on_fs_poll = sub { $cnt += 10 };
    *MyLst::on_fs_start = sub { $cnt += 1000 };
    my $h = new UE::FsPoll;
    $h->event_listener(bless {}, 'MyLst');
    $h->poll_callback(sub { $cnt++; $l->stop });
    $h->start_callback(sub { $cnt += 100 });
    $h->start(var 'file', 0.01);
    $l->run;
    is $cnt, 1111, "listener&event called";
};
=cut

done_testing();

sub check_err {
    my ($err_code, $name) = @_;
    return sub {
        my ($h, $prev, $curr, $err) = @_;
        return unless $err;
        is($err, $err_code, "fspoll callback error code correct ($name)");
        $call_cnt++;
        $l->stop;
    };
}

sub check_appears {
    my $name = shift;
    return sub {
        my ($h, $prev, $curr, $err) = @_;
        ok(!$err, "fspoll callback without error ($name)");
        $prev->[STAT_TYPE] = $curr->[STAT_TYPE] = 0;
        my $prev_sum = 0;
        $prev_sum += $_ for @$prev;
        my $curr_sum = 0;
        $curr_sum += $_ for @$curr;
        is($prev_sum, 0, "fspoll callback prev is empty ($name)");
        cmp_ok($curr_sum, '>', 0, "fspoll callback curr is not empty ($name)");
        $call_cnt++;
        $l->stop;
    };
}

sub check_changes {
    my ($fields, $name) = @_;
    $fields = [$fields] unless ref $fields;
    my %left = map {$_ => 1} @$fields;
    return sub {
        my ($h, $prev, $curr, $err) = @_;
        ok(!$err, "fspoll callback without error ($name)");
        foreach my $field (@$fields) {
            next if $prev->[$field] == $curr->[$field];
            delete $left{$field};
        }
        unless (%left) {
            pass("required fields changed");
            $call_cnt++;
            $l->stop;
        }
    };
}

sub check_call_cnt {
    my $cnt = shift;
    is $call_cnt, $cnt, "call cnt";
    $call_cnt = 0;
}

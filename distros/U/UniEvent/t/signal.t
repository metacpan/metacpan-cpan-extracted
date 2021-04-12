use 5.012;
use warnings;
use lib 't/lib'; use MyTest;
use UniEvent::Signal;

*signame = \&UniEvent::Signal::signame;

subtest 'constants' => sub {
    my @constants = qw/SIGINT SIGILL SIGABRT SIGFPE SIGSEGV SIGTERM/;
	push @constants, qw/SIGHUP SIGALRM SIGBUS SIGCHLD SIGCONT SIGKILL SIGPIPE SIGPROF SIGQUIT
						SIGSTOP SIGSYS SIGTRAP SIGTSTP SIGTTIN SIGTTOU SIGURG SIGUSR1 SIGUSR2
						SIGVTALRM SIGWINCH SIGXCPU SIGXFSZ/
		unless win32();
    
    for my $cname (sort @constants) {
        my $f = UniEvent::Signal->can($cname);
		say $cname;
        my $val = $f->();
        ok $val, "$cname -> $val";
        is signame($val), $cname, "$val -> $cname";
    }
};

my $l = UniEvent::Loop->default_loop;

subtest 'signum/signame' => \&many, sub {
    my $signum = shift;
    my $s = new UniEvent::Signal;
    is $s->type, UniEvent::Signal::TYPE, "type ok";
    $s->start($signum);
    is($s->signum, $signum, "signum: $signum");
    is($s->signame, signame($signum), 'signame: '.$s->signame);
};

subtest 'start/stop/reset' => \&many, sub {
    my $signum = shift;
    my $s = new UniEvent::Signal;
    my ($lastsignum, $i);

    $s->event->add(sub {
        $lastsignum = $_[1];
        ++$i;
        $l->stop;
    });
    
    $s->start($signum);
    
    ok $l->run_nowait, 'holds loop';
    
    trigger($l, $signum);
    ok $l->run;
    is $i, 1, "signal handler called";
    is $lastsignum, $signum, "correct signal";
    
    $s->stop;
    block($signum);
    trigger($l, $signum);
    ok !$l->run_nowait, 'stopped';
    is $i, 1, "doesn't get called";
    
    undef $lastsignum;
    $s->start($signum);
    trigger($l, $signum);
    ok $l->run;
    is $i, 2, "started again";
    is $lastsignum, $signum, "correct signal";
    
    $s->reset;
    block($signum);
    trigger($l, $signum);
    ok !$l->run, 'reset';
    is $i, 2, "doesn't get called";  
};

subtest 'once' => \&many, sub {
    my $signum = shift;
    my $s = new UniEvent::Signal;
    my ($lastsignum, $i);

    $s->once($signum, sub {
        $lastsignum = $_[1];
        ++$i;
        $l->stop;
    });
    ok $l->run_nowait, 'holds loop';
    
    trigger($l, $signum);
    ok !$l->run;
    is $i, 1, "called";
    is $lastsignum, $signum, "correct signal";
    
    block($signum);
    ok !$l->run, "won't run again";
    is $i, 1, "doesn't get called";
};

subtest 'call_now' => sub {
    my $h = new UniEvent::Signal;
    my $i = 0;
    my $sig;
    $h->event->add(sub { $i++, $sig = $_[1] });
    $h->call_now(SIGINT) for 1..5;
    is $i, 5;
    is $sig, SIGINT;
};

subtest 'static ctor' => sub {
    my $l = UE::Loop->new;
    my $signum = SIGINT;
    my $rcv;
    
    my $h = UniEvent::Signal->create($signum, sub {
        $rcv = $_[1];
        $l->stop;
    }, $l);
    trigger($l, $signum);
    $l->run;
    is $rcv, $signum;
    
    $h = UniEvent::signal $signum, sub {
        $rcv = $_[1];
        $l->stop;
    }, $l;
    trigger($l, $signum);
    $l->run;
    is $rcv, $signum;
    
    $h = UniEvent::Signal->create_once($signum, sub {
        $rcv = $_[1];
        $l->stop;
    }, $l);
    trigger($l, $signum);
    $l->run;
    is $rcv, $signum;
    
    $h = UniEvent::signal_once $signum, sub {
        $rcv = $_[1];
        $l->stop;
    }, $l;
    trigger($l, $signum);
    $l->run;
    is $rcv, $signum;
};

subtest 'event listener' => sub {
    no warnings 'once';
    my ($cnt, $rcv);
    *MyLst::on_signal = sub { $cnt += 10; $rcv = $_[2] };
    my $h = new UE::Signal;
    $h->event_listener(bless {}, 'MyLst');
    $h->callback(sub { $cnt++ });
    
    $h->call_now(SIGINT);
    is $cnt, 11, "listener&event called";
    is $rcv, SIGINT, "signal passed";
};

sub many {
    my $sub = shift;
	my @signals = (SIGINT);
	push @signals, SIGUSR1(), SIGUSR2(), SIGPIPE(), SIGALRM(), SIGTERM(), SIGCHLD() unless win32();
    foreach my $signum (SIGINT) {
        subtest signame($signum) => $sub, $signum;
    }
    %SIG = ();
}

sub trigger {
    my ($loop, $signum) = @_;
    $loop->delay(sub { kill $signum => $$ });
}

sub block {
    my $num = shift;
    my $name = signame($num);
    $name =~ s/^SIG//;
    $SIG{$name} = 'IGNORE';
}

done_testing();

use 5.012;
use lib 't/lib';
use MyTest;
use UniEvent::Error;

#use Panda::Lib::Logger;
#set_log_level(LOG_VERBOSE_DEBUG);
#set_native_logger(sub {
#    my ($level, $cp, $msg) = @_;
#    warn "$cp $msg";
#});

catch_run('[resolver]');

my $l = UniEvent::Loop->default_loop();

subtest 'not cached' => \&test_resolve, 0;
subtest 'cached'     => \&test_resolve, 1;

subtest 'cancel' => sub {
    my $resolver = new UniEvent::Resolver();
    my $i;
    my $req = $resolver->resolve({
        node       => 'ya.ru',
        on_resolve => sub {
            my ($addr, $err, $req) = @_;
            is $err, UE::SystemError::operation_canceled;
            $i++;
        },
    });
    
    $req->cancel;
    is $i, 1;
    
    $l->run;
};

sub test_resolve {
    my $cached = shift;
    my $resolver = new UniEvent::Resolver();
    my $host = "ya.ru";
    
    my $i = 0;
    
    # resolve external address reseveral times because sometimes it may fail
    $resolver->resolve({
        node       => $host,
        use_cache  => $cached,
        on_resolve => sub {
            my ($addr, $err, $req) = @_;
            return if $err or $i & 1;
            ok $addr, "@$addr";
            ok $req;
            $i++;
        },
    }) for 1..3;
    
    $resolver->resolve({
        node       => 'localhost',
        use_cache  => $cached,
        hints      => {family => UniEvent::AF_INET},
        on_resolve => sub {
            my ($addr, $err, $req) = @_;
            ok !$err;
            ok $addr, "@$addr";
            ok $req;
            is $addr->[0]->ip, "127.0.0.1";
            $i += 2;
        },
    });
    
    $l->run;
    
    is $i, 3, "both resolved";

    $resolver->resolve({
        node       => 'localhost',
        port       => 80,
        use_cache  => $cached,
        on_resolve => sub {
            my ($addr, $err, $req) = @_;
            ok !$err;
            is $addr->[0]->port, 80;
            $i += 4;
        },
    });

    $l->run;

    is $i, 7;
    
    if ($cached) {
        $resolver->resolve({
            node       => $host,
            on_resolve => sub {
                my ($addr, $err, $req) = @_;
                ok !$err;
                $i += 10;
            },
        });
        $l->run_nowait;
        is $i, 17;
    }
}

done_testing();

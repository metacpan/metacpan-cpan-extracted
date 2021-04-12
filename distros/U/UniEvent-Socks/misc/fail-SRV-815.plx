#!/usr/bin/env perl
use 5.012;
use UniEvent;
use UniEvent::Socks;

$SIG{PIPE} = 'IGNORE';

my @foo;
my ($ok, $fail);

my $zt = UE::Timer->new; $zt->start(0.3); $zt->callback(sub {
    $_->reset for (@foo);
    printf "RESET cnt=%d ok=%d fail=%d\n", scalar(@foo), $ok, $fail;
});

my $t = UE::Timer->new; $t->start(0.01); $t->callback(sub {
    my $sock = UE::Tcp->new;
    UniEvent::Socks::use_socks($sock, 'socks.crazypanda.ru', 1080);
    $sock->connect("ya.ru", 80);
    $sock->connect_callback(sub {
        $ok++ unless $_[1];
        $fail++ if $_[1];
    });

    push @foo, $sock;
});


UE::Loop->default_loop->run;

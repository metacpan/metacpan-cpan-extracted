use 5.020;
use strict;
use warnings;
use UniEvent;

$SIG{PIPE} = 'IGNORE';

my @foo;

my $zt = UE::Timer->new; $zt->start(0.2); $zt->callback(sub {
    con($_) for (@foo);
});

my $t = UE::Timer->new; $t->start(0.05); $t->callback(sub {

sub con {
    $_[0]->reset;
    $_[0]->connect("127.0.0.1", 6669);
    $_[0]->write("shit");
    $_[0]->shutdown;

    #$_[0]->connect_callback(\&dis);
    #$_[0]->connect_callback(sub {warn 6});
}

sub dis { shift->reset }

my $sock = UE::Tcp->new;
$sock->use_ssl;
#$sock->connect_callback(\&con);
$sock->read_start;
#$sock->eof_callback(\&con);
#$sock->use_ssl;
$sock->connect("127.0.0.1", 6669);
$sock->write("123", sub { 
    $_[0]->reset;
    $_[0]->write("666");
    $_[0]->connect("127.0.0.1", 6669);

    $_[0]->connect("127.0.0.1", 6667, 0.005, sub {shift->connect("127.0.0.1", 6669)});


    $_[0]->connect("127.0.0.1", 6669, 0.005);


    $_[0]->write("666");
});

push @foo, $sock;

});


UE::Loop->default_loop->run;

use 5.012;
use warnings;
use UniEvent;

my $tcp = UniEvent::Tcp->new;
$tcp->connect('yandex.ru', 80, sub {
    my ($tcp, $error_code) = @_;
    # will be thrown out of loop run
    die("cannot connect: $error_code\n") if $error_code;
    $tcp->loop->stop;
});
$tcp->loop->run;
say "connected";

$tcp->read_callback(sub {
    my ($tcp, $data, $error_code) = @_;
    die("reading data error: $error_code\n") if $error_code;
    say "[<<] ", $data;
    $tcp->loop->stop;
});

$tcp->eof_callback(sub {
    say "[eof]";
    $tcp->loop->stop;
});

my $req =<<END;
GET / HTTP/1.1\r
host: ya.ru\r
\r
END
$tcp->write($req, sub {
    my ($client, $error_code) = @_;
    die("writing data error: $error_code\n") if $error_code;
    say "[>>] (simple get)";
});
$tcp->loop->run;

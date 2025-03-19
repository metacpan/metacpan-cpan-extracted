use 5.012;
use UniEvent;
use Data::Dumper 'Dumper';
XLog::set_level(XLog::DEBUG, "UniEvent::Resolver");
XLog::set_level(XLog::DEBUG);
XLog::set_logger(XLog::Console->new);

say "HI";

my $resolver = new UniEvent::Resolver();
my $req = $resolver->resolve({
    node       => 'localhost',
    use_cache  => 0,
    hints      => UniEvent::Resolver::hints(AF_INET6, SOCK_STREAM, PF_INET6),
    on_resolve => sub {
        my ($addr, $err, $req) = @_;
        say "ERR=$err";
        say "ADDRS:";
        say Dumper($addr);
        die $err if $err;
        say "resolved as ", $addr->[0]->ip, ":", $addr->[0]->port;
    },
});

UniEvent::Loop->default->run;

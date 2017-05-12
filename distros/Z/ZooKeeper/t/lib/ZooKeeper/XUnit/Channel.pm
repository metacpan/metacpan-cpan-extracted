package ZooKeeper::XUnit::Channel;
use ZooKeeper::Channel;
use Test::LeakTrace;
use Test::Class::Moose;

has data => (
    is      => 'ro',
    builder => '_build_data',
);
sub _build_data {
    return {
        'undef'      => undef,
        'regex'      => qr/.*/,
        'glob'       => *STDIN,
        'glob-ref'   => \*STDIN,
        'int'        => 9,
        'int-ref'    => \42,
        'string'     => "a string",
        'string-ref' => \"a ref to a string",
        'array-ref'  => [],
        'hash-ref'   => {},
        'code-ref'   => sub {},
        'object'     => ZooKeeper::Channel->new,
    };
}

sub test_leak_single_send {
    my ($self) = @_;

    my $channel = ZooKeeper::Channel->new;

    my %data = %{$self->data};
    while (my ($type, $datum) = each %data) {
        is($channel->recv, undef, "received undef on empty channel");

        $channel->send($datum);
        is($channel->recv, $datum, "sent and received single $type");
        is($channel->recv, undef, "received undef on empty channel after sending single $type");
        no_leaks_ok {
            $channel->send($datum);
            $channel->recv;
        } "no leaks sending and receiving single $type";
    }
}

sub test_multi_send {
    my ($self) = @_;

    my $channel = ZooKeeper::Channel->new;

    my %data = %{$self->data};
    while (my ($type, $datum) = each %data) {
        my $repeat = int(rand(5)) + 1;
        $channel->send(($datum) x $repeat);
        my $match = grep {($channel->recv||'') eq ($datum||'')} 1 .. $repeat;
        is($match, $repeat, "sent and received multiple ${type}s");
        is($channel->recv, undef, "received undef on empty channel after sending multiple ${type}s");
        no_leaks_ok {
            $channel->send(($datum) x $repeat);
            $channel->recv for 1 .. $repeat;
        } "no leaks sending and receiving multiple ${type}s";
    }
}

1;

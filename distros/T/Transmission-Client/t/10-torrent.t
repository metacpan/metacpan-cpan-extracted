# ex:ts=4:sw=4:sts=4:et
use warnings;
use strict;
use Test::More;
use Transmission::Torrent;
use Transmission::Client;
use JSON::MaybeXS;

$SIG{'__DIE__'} = \&Carp::confess;

my $client = Transmission::Client->new;

my (%rpc_return, %rpc_callbacks);

{
    no warnings 'redefine';
    *Transmission::Client::rpc = sub {
        my $self = shift;
        my $method = shift;
        my $test = shift @{$rpc_callbacks{$method}};

        $test->($self, $method, {@_}) if $test;

        return shift @{$rpc_return{$method}};
    };
}

my $torrent = new_ok 'Transmission::Torrent' => [
    id => 1,
    client => $client,
    upload_ratio => 0.10,
    eta => 3.14,
];

is $torrent->upload_ratio, 0.10, "expected upload ratio (0.10)";
is $torrent->eta, 3, "expected upload ratio (3) (truncated double)";

# FIXME: ugly. :-(
sub test_torrent_set {
    my %args = (@_);

    my $attr = $client->_camel2Normal($args{attribute});

    push @{$rpc_return{'torrent-set'}}, {};
    push @{$rpc_callbacks{'torrent-set'}}, $args{set_test};
    push @{$rpc_return{'torrent-get'}}, {
        torrents => [ {
            $args{torrent}->id => {
                $args{attribute} => $args{value}
            }
        }, ]
    };

    my $get_val = defined $args{coerced_val} ? $args{coerced_val} :
                                               $args{value};
    is $torrent->$attr($args{value}), $get_val,
       'get return should be the same as value supplied to set';
}

test_torrent_set(
    torrent => $torrent,
    attribute => 'uploadLimit',
    value => '123',
    set_test => sub {
        my $self = shift;
        my ($method, $args) = @_;
        is_deeply $args->{ids}, [1], 'set should pass ids=[1]';
        is $args->{uploadLimit}, 123, 'set should pass uploadLimit=123';

        is encode_json([$args->{uploadLimit}]), encode_json([123]),
            'JSON value for uploadLimit should be numeric';
    },
    post_test => sub {
        is shift, 123, 'get return should be same as arg to get'
    },
);

done_testing();

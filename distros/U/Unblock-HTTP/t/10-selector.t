use strict;
use warnings;
use Test::More;

BEGIN {
    # Isolated selector test. Real engines have their own wire-level tests.
    for my $version (1 .. 3) {
        for my $side (qw(Client Server)) {
            my $package = 'Unblock::HTTP' . $version . '::' . $side;
            (my $path = $package) =~ s{::}{/}g;
            $INC{"$path.pm"} = __FILE__;
            no strict 'refs';
            *{$package . '::new'} = sub {
                my ($class, %opt) = @_;
                return bless { options => \%opt, events => [] }, $class;
            };
            *{$package . '::input'} = sub { push @{ $_[0]{events} }, ['input', $_[1]]; return length $_[1] };
            *{$package . '::input_eof'} = sub { push @{ $_[0]{events} }, ['eof']; return 1 };
            *{$package . '::transport_error'} = sub { push @{ $_[0]{events} }, ['error', $_[1]]; return 1 };
            *{$package . '::resume_output'} = sub { push @{ $_[0]{events} }, ['resume']; return 1 };
            *{$package . '::close'} = sub { push @{ $_[0]{events} }, ['close']; return 1 };
            *{$package . '::want_read'} = sub { return 1 };
            *{$package . '::want_write'} = sub { return 0 };
            *{$package . '::output'} = sub { return 'wire' };
            *{$package . '::start'} = sub { $_[0]{started} = 1; return $_[0] };
            *{$package . '::started'} = sub { return $_[0]{started} ? 1 : 0 };
            *{$package . '::request'} = sub { my ($self, @arg) = @_; $self->{request_args} = \@arg; return 'transaction' };
        }
    }
}

use Unblock::HTTP::_Session;

my $host = bless {}, 'TestTransport';
my $quic = bless {}, 'TestQuic';

my $client = Unblock::HTTP::_Session->_new('Client', protocol => 'h2', transport => $host);
isa_ok($client->backend, 'Unblock::HTTP2::Client');
is($client->backend->request(method => 'GET', target => '/'), 'transaction', 'low-level request result passed through');
is_deeply($client->backend->{request_args}, [method => 'GET', target => '/'], 'request args unchanged');

for my $case (
    [ { alpn => 'spdy/3', transport => $host }, qr/unsupported HTTP protocol/ ],
    [ { alpn => 'h2', protocol => 'h3', quic => $quic }, qr/either protocol or alpn/ ],
    [ { protocol => 'h3', transport => $host }, qr/HTTP\/3 requires quic/ ],
    [ { protocol => 'h2', quic => $quic }, qr/requires a byte transport/ ],
    [ { transport => $host, quic => $quic }, qr/both quic and transport/ ],
) {
    my ($options, $error) = @$case;
    my $success = eval { Unblock::HTTP::_Session->_new('Client', %$options); 1 };
    ok(!$success, 'bad protocol/transport combination rejected');
    like($@, $error, 'specific error');
}

done_testing;

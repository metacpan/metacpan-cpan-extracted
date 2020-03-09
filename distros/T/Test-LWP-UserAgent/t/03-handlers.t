use strict;
use warnings;

use Test::More 0.88;
use if $ENV{AUTHOR_TESTING}, 'Test::Warnings';
use Test::Deep;
use Test::LWP::UserAgent;


# all phases as defined in the LWP::UserAgent documentation
my @request_phases = qw(request_preprepare request_prepare request_send);
# TODO: I'm not sure how to get response_header and response_data to be called...
my @response_phases = qw(response_done response_redirect);

{
    my $useragent = Test::LWP::UserAgent->new;
    $useragent->map_response(
        qr/localhost/,
        HTTP::Response->new('200', 'OK', ['Content-Type' => 'text/plain'], 'all good!'),
    );

    my %phase_called;

    foreach my $phase (@request_phases)
    {
        $useragent->add_handler($phase => sub {
                my ($request, $ua, $h, $data) = @_;
                isa_ok($request, 'HTTP::Request');
                isa_ok($ua, 'LWP::UserAgent');
                $phase_called{$phase} = 1;
                return;
            }, m_host => 'localhost');
    }

    foreach my $phase (@response_phases)
    {
        $useragent->add_handler($phase => sub {
                my ($response, $ua, $h, $data) = @_;
                isa_ok($response, 'HTTP::Response');
                isa_ok($ua, 'LWP::UserAgent');
                $phase_called{$phase} = 1;
                return;
            }, m_host => 'localhost');
    }

    my $response = $useragent->get('http://localhost');

    cmp_deeply(
        \%phase_called,
        { map +($_ => 1), @request_phases, @response_phases },
        'all handlers called',
    );
}

done_testing;

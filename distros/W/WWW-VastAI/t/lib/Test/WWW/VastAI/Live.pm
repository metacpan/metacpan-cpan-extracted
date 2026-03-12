package Test::WWW::VastAI::Live;

use strict;
use warnings;

use Exporter 'import';
use LWP::UserAgent;
use Test::More ();
use Time::HiRes qw(sleep);
use WWW::VastAI;

our @EXPORT_OK = qw(
    live_client
    require_live_env
    require_cost_env
    unique_label
    pick_cheapest_offer
    public_port_for_instance
    wait_for_http
    wait_for_instance
);

sub live_client {
    return WWW::VastAI->new(
        api_key => $ENV{VAST_API_KEY},
    );
}

sub require_live_env {
    Test::More::plan(skip_all => 'Set VAST_LIVE_TEST=1 to run Vast.ai live tests')
        unless $ENV{VAST_LIVE_TEST};

    Test::More::plan(skip_all => 'Set VAST_API_KEY for Vast.ai live tests')
        unless $ENV{VAST_API_KEY};
}

sub require_cost_env {
    Test::More::plan(skip_all => 'Set VAST_LIVE_TEST=1 to enable Vast.ai live tests')
        unless $ENV{VAST_LIVE_TEST};

    Test::More::plan(skip_all => 'Set VAST_LIVE_ALLOW_COST=1 to run cost-incurring Vast.ai live tests')
        unless $ENV{VAST_LIVE_ALLOW_COST};

    Test::More::plan(skip_all => 'Set VAST_API_KEY for Vast.ai cost live tests')
        unless $ENV{VAST_API_KEY};

    Test::More::plan(skip_all => 'Set VAST_LIVE_IMAGE or VAST_LIVE_TEMPLATE_HASH_ID for the cost test')
        unless (
            (defined $ENV{VAST_LIVE_IMAGE} && length $ENV{VAST_LIVE_IMAGE})
            || (defined $ENV{VAST_LIVE_TEMPLATE_HASH_ID} && length $ENV{VAST_LIVE_TEMPLATE_HASH_ID})
        );
}

sub unique_label {
    my $prefix = shift || 'perl-live-vast';
    return join '-', $prefix, time, $$;
}

sub pick_cheapest_offer {
    my ($client, %filters) = @_;

    my $offers = $client->offers->search(
        limit    => 25,
        order    => [['dph_total', 'asc']],
        verified => { eq => \1 },
        rentable => { eq => \1 },
        rented   => { eq => \0 },
        type     => 'on-demand',
        %filters,
    );

    my ($offer) = sort {
        ($a->dph_total // 9**9**9) <=> ($b->dph_total // 9**9**9)
    } @{$offers};

    die 'No rentable Vast.ai offers matched the live-test filters' unless $offer;
    return $offer;
}

sub public_port_for_instance {
    my ($instance, $internal_port) = @_;
    my $ports = $instance->raw->{ports} || [];

    for my $port (@{$ports}) {
        next unless ref $port eq 'HASH';

        my $private = $port->{private_port} // $port->{PrivatePort} // $port->{container_port};
        my $public  = $port->{public_port}  // $port->{PublicPort}  // $port->{host_port} // $port->{HostPort} // $port->{port};
        next if defined $internal_port && defined $private && $private != $internal_port;
        return $public if defined $public;
    }

    return;
}

sub wait_for_http {
    my ($url, %opts) = @_;

    my $timeout  = $opts{timeout}  || 120;
    my $interval = $opts{interval} || 5;
    my $matcher  = $opts{match};
    my $start = time;
    my $ua = LWP::UserAgent->new(
        agent   => 'WWW-VastAI live test',
        timeout => 15,
    );

    while ((time - $start) < $timeout) {
        my $response = $ua->get($url);
        if ($response->is_success) {
            my $body = $response->decoded_content;
            return $body if !$matcher || $body =~ $matcher;
        }
        sleep($interval);
    }

    die "Timed out waiting for HTTP success from $url";
}

sub wait_for_instance {
    my ($client, $instance_id, $wanted, %opts) = @_;

    my $timeout  = $opts{timeout}  || 180;
    my $interval = $opts{interval} || 5;
    my $start = time;

    while ((time - $start) < $timeout) {
        my $instance = $client->instances->get($instance_id);
        return $instance if ($instance->actual_status || '') eq $wanted;
        sleep($interval);
    }

    die "Timed out waiting for instance $instance_id to reach status '$wanted'";
}

1;

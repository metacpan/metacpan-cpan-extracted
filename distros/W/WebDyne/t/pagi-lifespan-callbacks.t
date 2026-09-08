use strict;
use warnings;
use Test::More;

BEGIN {
    unshift(@INC, 't');
    require pagi_compat_helper;
    my $skip=pagi_compat_helper::pagi_skip_reason(qw(PAGI::Request PAGI::Response PAGI::SSE PAGI::WebSocket Future::AsyncAwait));
    plan(skip_all => "Skipping lifespan callbacks: $skip") if $skip;
    $ENV{'WEBDYNE_CONF'}='.';
}

use Future;
use WebDyne::PAGI;

foreach my $phase (qw(startup shutdown)) {
    foreach my $invalid_ref ('My::App::callback', 0, {}, []) {
        my $ok=eval { WebDyne::PAGI->new(root => '.', $phase => $invalid_ref); 1 };
        ok(!$ok, "$phase rejects a non-coderef");
        like($@, qr/callback must be a coderef/, 'constructor explains invalid callback');
    }
}

my $plain_hr=lifecycle(startup => undef, shutdown => undef);
deliver($plain_hr, 'startup');
is_deeply($plain_hr->{'events'}, [{type => 'lifespan.startup.complete'}], 'absent callbacks preserve startup');
ok(!$plain_hr->{'future'}->is_ready(), 'lifespan stays pending after startup');
deliver($plain_hr, 'shutdown');
is($plain_hr->{'events'}[1]{'type'}, 'lifespan.shutdown.complete', 'absent callbacks preserve shutdown');
ok($plain_hr->{'future'}->is_done(), 'shutdown completes lifespan');

my @call;
my $sync_hr=lifecycle(
    startup => sub {
        my ($app_or, $scope_hr)=@_;
        push(@call, ['startup', $app_or, $scope_hr]);
        return 0;
    },
    shutdown => sub { push(@call, ['shutdown', @_]); return; },
);
deliver($sync_hr, 'startup');
is($sync_hr->{'events'}[0]{'type'}, 'lifespan.startup.complete', 'false normal return is success');
is($call[0][1], $sync_hr->{'app'}, 'callback receives application object');
is($call[0][2], $sync_hr->{'scope'}, 'callback receives original lifespan scope');
deliver($sync_hr, 'shutdown');
is_deeply([map { $_->[0] } @call], ['startup', 'shutdown'], 'callbacks run in event order');
ok($sync_hr->{'future'}->is_done(), 'synchronous callbacks complete');

my $startup_or=Future->new();
my $shutdown_or=Future->new();
my $async_hr=lifecycle(startup => sub { return $startup_or }, shutdown => sub { return $shutdown_or });
deliver($async_hr, 'startup');
is(scalar(@{$async_hr->{'events'}}), 0, 'startup waits for callback Future');
$startup_or->done();
is($async_hr->{'events'}[0]{'type'}, 'lifespan.startup.complete', 'startup acknowledges completed Future');
deliver($async_hr, 'shutdown');
is(scalar(@{$async_hr->{'events'}}), 1, 'shutdown waits for callback Future');
$shutdown_or->done();
is($async_hr->{'events'}[1]{'type'}, 'lifespan.shutdown.complete', 'shutdown acknowledges completed Future');
ok($async_hr->{'future'}->is_done(), 'asynchronous shutdown completes lifespan');

foreach my $phase (qw(startup shutdown)) {
    foreach my $mode (qw(exception future)) {
        my $pending_or=Future->new();
        my $failed_hr=lifecycle($phase => sub {
            die "$phase fixture error\n" if $mode eq 'exception';
            return $pending_or;
        });
        deliver($failed_hr, 'startup') if $phase eq 'shutdown';
        deliver($failed_hr, $phase);
        $pending_or->fail("$phase fixture error") if $mode eq 'future';
        my $event_hr=$failed_hr->{'events'}[-1];
        is($event_hr->{'type'}, "lifespan.$phase.failed", "$phase $mode produces failure event");
        like($event_hr->{'message'}, qr/\Q$phase fixture error\E/, 'failure retains diagnostic');
        ok($failed_hr->{'future'}->is_done(), 'reported callback failure ends lifecycle');
    }
}

my $send_hr=lifecycle(send_failure => 1);
deliver($send_hr, 'startup');
ok($send_hr->{'future'}->is_failed(), 'transport send failure propagates');
like(scalar($send_hr->{'future'}->failure()), qr/send fixture error/, 'original send error is retained');
is(scalar(@{$send_hr->{'events'}}), 1, 'failed send is not retried as callback failure');
done_testing();

sub lifecycle {
    my %opt=@_;
    my $send_failure=delete($opt{'send_failure'});
    my $app_or=WebDyne::PAGI->new(root => '.', static => 0, %opt);
    my $scope_hr={type => 'lifespan'};
    my (@event, @receive);
    my $future_or=$app_or->to_app()->($scope_hr,
        sub { my $receive_or=Future->new(); push(@receive, $receive_or); return $receive_or },
        sub {
            push(@event, $_[0]);
            return $send_failure ? Future->fail('send fixture error') : Future->done();
        },
    );
    return {app => $app_or, scope => $scope_hr, events => \@event, receive => \@receive, future => $future_or};
}

sub deliver {
    my ($session_hr, $phase)=@_;
    my $receive_or=shift(@{$session_hr->{'receive'}}) or die 'no pending receive';
    $receive_or->done({type => "lifespan.$phase"});
    return;
}

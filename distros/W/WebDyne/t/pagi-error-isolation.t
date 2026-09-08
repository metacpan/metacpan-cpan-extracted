use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

BEGIN {
    unshift @INC, 't';
    require pagi_compat_helper;
    my $skip=pagi_compat_helper::pagi_skip_reason(qw(PAGI::Request PAGI::Response PAGI::SSE PAGI::WebSocket Future::AsyncAwait));
    plan skip_all => "Skipping PAGI error isolation test: $skip" if $skip;
    $ENV{'WEBDYNE_CONF'}='.';
    $ENV{'WEBDYNE_ERROR_TEXT'}=1;
}

use WebDyne::PAGI;
use Future;

my $root_dn=tempdir(CLEANUP => 1);
foreach my $page_ar (
    ['clean.psp', '<start_html><p>clean request</p>'],
    ['failed.psp', '<perl>die "current request failure"</perl>'],
    ['caught.psp', <<'PAGE'],
<api handler="caught" pattern="/" canonical>
__PERL__
sub caught {
    eval { die "handled application error\n" };
    return {recovered => 1};
}
PAGE
    ['sse.psp', <<'PAGE'],
<start_html sse>
__PERL__
use Future::AsyncAwait;
async sub sse {
    my ($self, $param_hr)=@_;
    my $sse_or=$self->r()->sse();
    await $sse_or->start();
    await $sse_or->send_event(data => 'clean stream');
    await $sse_or->close();
}
PAGE
    ['ws.psp', <<'PAGE'],
<start_html ws>
__PERL__
use Future::AsyncAwait;
async sub ws {
    my ($self, $param_hr)=@_;
    my $send_cr=$self->r()->{'send'};
    await $send_cr->({type => 'websocket.accept'});
    await $send_cr->({type => 'websocket.close'});
}
PAGE
) {
    open(my $page_fh, '>', "$root_dn/$page_ar->[0]") || die $!;
    print {$page_fh} $page_ar->[1];
    close($page_fh) || die $!;
}
my $app_cr=WebDyne::PAGI->new(root => $root_dn, static => 0)->to_app();

foreach (1..3) {
    recovered_request();
    my (undef, $event_ar)=request('http', '/clean.psp');
    is($event_ar->[0]->{'status'}, 200, 'next HTTP request succeeds');
    like($event_ar->[1]->{'body'}, qr/clean request/, 'next request renders its own body');
}
my (undef, $failed_ar)=request('http', '/failed.psp');
is($failed_ar->[0]->{'status'}, 500, 'current request failure remains an error');
like($failed_ar->[1]->{'body'}, qr/current request failure/i, 'current diagnostic remains visible');
my (undef, $clean_ar)=request('http', '/clean.psp');
is($clean_ar->[0]->{'status'}, 200, 'request recovers after uncaught error');

#  A second request records an error while the first awaits its form body.
#  Clearing at application entry alone cannot protect the resumed render.
#
foreach my $type (qw(http sse)) {
    my $receive_or=Future->new();
    my ($application_or, $event_ar)=request($type,
        $type eq 'http' ? '/clean.psp' : '/sse.psp', $receive_or);
    ok(!$application_or->is_ready(), "$type waits for body");
    recovered_request();
    $receive_or->done({type => "$type.request", body => 'one=two', more => 0});
    $application_or->get();
    if ($type eq 'http') {
        is($event_ar->[0]->{'status'}, 200, 'resumed HTTP request succeeds');
        like($event_ar->[1]->{'body'}, qr/clean request/, 'resumed HTTP body is clean');
    }
    else {
        is_deeply([map { $_->{'type'} } @{$event_ar}],
            [qw(sse.start sse.send sse.close)], 'resumed SSE request starts and closes');
        is($event_ar->[1]->{'data'}, 'clean stream', 'resumed SSE sends its own data');
    }
}
recovered_request();
my (undef, $ws_ar)=request('websocket', '/ws.psp');
is_deeply([map { $_->{'type'} } @{$ws_ar}],
    [qw(websocket.accept websocket.close)], 'WebSocket setup ignores previous request error');
done_testing();


sub recovered_request {
    my (undef, $event_ar)=request('http', '/caught');
    is($event_ar->[0]->{'status'}, 200, 'caught API exception returns success');
    like($event_ar->[1]->{'body'}, qr/"recovered"\s*:\s*1/, 'API returns recovered result');
}


sub request {
    my ($type, $path, $receive_or)=@_;
    my @event;
    my $application_or=$app_cr->(
        {type => $type, path => $path, method => $receive_or ? 'POST' : 'GET',
            query_string => '', headers => $receive_or ? [['content-type', 'application/x-www-form-urlencoded']] : []},
        sub { return $receive_or || Future->done({type => "$type.request", body => '', more => 0}) },
        sub { push @event, shift(); return Future->done() },
    );
    $application_or->get() unless $receive_or;
    return ($application_or, \@event);
}

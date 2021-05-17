#!/usr/bin/env perl
use 5.012;
use warnings;
use UniEvent::HTTP;

# it is limited to 4kb
my $req = UniEvent::HTTP::Request->new({
    uri => 'http://ptsv2.com/t/3pd0w-1603192842/post',
    form => [
        'key'           => 'value',
        'simple_file'   => ['filename.pdf' => '[pdf-content]', 'application/pdf'],
        'streamed_file' => ['script.pl' => UE::Streamer::FileInput->new(__FILE__), 'text/plain'],
    ],
});

my ($res, $err);
$req->response_event->add(sub {
    shift;
    ($res, $err) = @_;
    UE::Loop->default_loop->stop;
});

my $ua = UniEvent::HTTP::UserAgent->new;
$ua->request($req);

say "starting processing";
UE::Loop->default_loop->run;
say "processing has been completed";

if ($err) { say "error: ", $err; }
else {
    say "code = ", $res->code;
    say "body = ", $res->body;
}

say "exiting..."

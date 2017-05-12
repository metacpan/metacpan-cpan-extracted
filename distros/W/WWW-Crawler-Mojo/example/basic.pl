use strict;
use warnings;
use utf8;
use WWW::Crawler::Mojo;
use 5.10.0;

@ARGV || die 'Starting URL must given';
my @start = map {Mojo::URL->new($_)} @ARGV;

my $bot = WWW::Crawler::Mojo->new;

$bot->on(start => sub {
    shift->say_start;
});

$bot->on(res => sub {
    my ($bot, $scrape, $job, $res) = @_;
    say sprintf('fetching %s resulted status %s', $job->url, $res->code);
    $bot->enqueue($_) for $scrape->();
});

$bot->on(error => sub {
    my ($msg, $job) = @_;
    say $msg;
    say "Re-scheduled";
    $bot->requeue($job);
});

$bot->enqueue(@start);
$bot->crawl;

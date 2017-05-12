#
# Collect URLs.
#
# perl ./example/pages.pl http://example.com/
#

use strict;
use warnings;
use utf8;
use WWW::Crawler::Mojo;
use 5.10.0;
use Mojo::URL;

@ARGV || die 'Starting URL must given';
my @start = map {Mojo::URL->new($_)} @ARGV;
my @hosts = map {$_->host} @start;

my $bot = WWW::Crawler::Mojo->new;

$bot->on(start => sub {
    shift->say_start;
});

$bot->on(error => sub {
    my ($bot, $msg, $job) = @_;
    $bot->requeue($job);
});

$bot->on(res => sub {
    $| = 1;
    
    my ($bot, $scrape, $job, $res) = @_;
    
    return if ($res->code !~ qr{[2]..});
    return unless grep {$_ eq $job->url->host} @hosts;
    
    for my $job2 ($scrape->()) {
        state $found = {};
        next unless (ref $job2->context eq 'Mojo::DOM' && $job2->context->tag eq 'a');
        say $job2->url and $found->{$job2->url}++ unless ($found->{$job2->url} ||= 0) == 1;
        next unless grep {$_ eq $job2->url->host} @hosts;
        $bot->enqueue($job2);
    }
});

$bot->enqueue(@start);
$bot->crawl;

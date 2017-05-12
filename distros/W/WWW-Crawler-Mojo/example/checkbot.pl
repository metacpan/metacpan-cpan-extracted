#
# Validate every links within html pages and csses.
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
my %count;

$bot->on(start => sub {
    shift->say_start;
});

$bot->on(error => sub {
    my ($bot, $msg, $job) = @_;
    
    $count{'N/A'}++;
    
    chomp($msg);
    
    report_stdout($msg, $job->url, $job->referrer->url);
});

$bot->on(res => sub {
    $| = 1;
    
    my ($bot, $scrape, $job, $res) = @_;
    
    $count{$res->code}++;
    
    if ($res->code =~ qr{[245]..}) {
        my $msg = $res->code. ' occured!';
        report_stdout(
                $msg, $job->url, $job->referrer ? $job->referrer->url : '-');
    }
    
    $count{QUEUE} = $bot->queue->length;
    my @props = map { join(':', $_, $count{$_}) } (sort keys %count);
    print join(' / ', @props), ' ' x 30, "\r";
    
    return unless grep {$_ eq $job->url->host} @hosts;
    
    for my $job2 ($scrape->()) {
        if (security_warning($job2, $job2->context)) {
            $count{'WARNING'}++;
            my $msg = 'WARNING : Cross-scheme resource found';
            report_stdout($msg, $job2->url, $job->url);
        }
        $bot->enqueue($job2);
    }
});

$bot->shuffle(5);
$bot->max_conn_per_host(2);
$bot->max_conn(5);
$bot->enqueue(@start);
$bot->crawl;

sub report_stdout {
    my ($msg, $url, $url_referrer) = @_;
    state $index = 1;
    say sprintf(
        '%s: %s at %s <= %s',
        $index++,
        $msg,
        $url,
        $url_referrer,
    );
}

sub security_warning {
    my ($job, $context) = @_;
    
    my $scheme1 = $job->referrer->url->protocol;
    my $scheme2 = $job->url->protocol;
    
    if ($scheme1 eq 'https' && $scheme2 ne 'https') {
        return 1 if (!ref $context || ref $context ne 'Mojo::DOM');
        return 0 if ($context->tag eq 'a');
        return 1;
    }
    
    return 0;
}

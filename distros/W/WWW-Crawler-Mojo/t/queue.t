use strict;
use warnings;
use utf8;
use File::Basename 'dirname';
use File::Spec::Functions qw{catdir splitdir rel2abs canonpath};
use lib catdir(dirname(__FILE__), '../lib');
use lib catdir(dirname(__FILE__), 'lib');
use Test::More;
use WWW::Crawler::Mojo;
use WWW::Crawler::Mojo::Queue::Memory;
use WWW::Crawler::Mojo::Job;

use Test::More tests => 23;

my $bot  = WWW::Crawler::Mojo->new;
my @jobs = $bot->enqueue('http://example.com/');
is ref $jobs[0], 'WWW::Crawler::Mojo::Job';
is scalar @jobs, 1;
is ref $bot->queue->next, 'WWW::Crawler::Mojo::Job';
is $bot->queue->next->url, 'http://example.com/';
is $bot->queue->length, 1, 'right number';
$bot->enqueue(Mojo::URL->new('http://example.com/2'));
is ref $bot->queue->next(1), 'WWW::Crawler::Mojo::Job';
is $bot->queue->next(1)->url, 'http://example.com/2';
is $bot->queue->length, 2, 'right number';

my $job = $bot->queue->dequeue;
$bot->enqueue($job);
is $bot->queue->length, 1, 'right number';
$bot->requeue($job);
is $bot->queue->length, 2, 'right number';

# redundancy
$bot = WWW::Crawler::Mojo->new;
$bot->queue->cap(1);
$bot->enqueue('http://example.com/1');
is $bot->queue->length, 1, 'right length';
is $bot->queue->jobs->[0]->url, 'http://example.com/1', 'right job';
my $job1 = $bot->queue->next;
is $bot->queue->redundancy_storage->{$job1->digest}, 1;
$bot->enqueue('http://example.com/2');
is $bot->queue->length, 2, 'right length';
is $bot->queue->jobs->[0]->url, 'http://example.com/1', 'right job';
is $bot->queue->jobs->[1]->url, 'http://example.com/2', 'right job';
my $job2 = $bot->queue->next(1);
is $bot->queue->redundancy_storage->{$job2->digest}, 1;
$bot->enqueue('http://example.com/3');
is $bot->queue->length, 2, 'right length';
is $bot->queue->jobs->[0]->url, 'http://example.com/1', 'right job';
is $bot->queue->jobs->[1]->url, 'http://example.com/2', 'right job';
my $job3 = $bot->queue->next(1);
is $bot->queue->redundancy_storage->{$job1->digest}, 1;
is $bot->queue->redundancy_storage->{$job2->digest}, 1;
is keys(%{$bot->queue->redundancy_storage}), 2;

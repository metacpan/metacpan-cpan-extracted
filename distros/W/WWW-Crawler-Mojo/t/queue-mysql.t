use strict;
use warnings;
use utf8;
use File::Basename 'dirname';
use File::Spec::Functions qw{catdir splitdir rel2abs canonpath};
use lib catdir(dirname(__FILE__), '../lib');
use lib catdir(dirname(__FILE__), 'lib');
use Test::More;

plan skip_all => 'set TEST_ONLINE to enable this test'
  unless $ENV{TEST_ONLINE};

use WWW::Crawler::Mojo;
use WWW::Crawler::Mojo::Job;

require WWW::Crawler::Mojo::Queue::MySQL;
import WWW::Crawler::Mojo::Queue::MySQL;

my $queue = WWW::Crawler::Mojo::Queue::MySQL->new($ENV{TEST_ONLINE},
  table_name => "testing_jobs");
$queue->empty;

my $job1 = WWW::Crawler::Mojo::Job->new;
$job1->url(Mojo::URL->new('http://example.com/'));
$queue->enqueue($job1);

is ref $queue->next, 'WWW::Crawler::Mojo::Job';
is $queue->next->url, 'http://example.com/';
is $queue->length, 1, 'right number 1';

my $job2 = WWW::Crawler::Mojo::Job->new;
$job2->url(Mojo::URL->new('http://example.com/2'));
$queue->enqueue($job2);

is ref $queue->next(1), 'WWW::Crawler::Mojo::Job';
is $queue->next(1)->url, 'http://example.com/2';
is $queue->length, 2, 'right number 2';

$job1 = $queue->dequeue;

is $job1->url, 'http://example.com/', "1st job being processed";
is $queue->length, 1, 'queue length is 1';

$queue->enqueue($job1);    ## enquing back job 1
is $queue->length, 1, ' job length should be 1';

$queue->requeue($job1);
is $queue->length, 2, 'requeue will increment queue by 1';

$job2 = $queue->dequeue;    ## length = 1
is $job2->url, 'http://example.com/2', "1st job being processed";

is $queue->length, 1, 'queue length is back to 1';
$queue->requeue($job2);     ## cant requeue
is $queue->length, 2, 'right number 5';

$job1 = $queue->dequeue;
is $job1->url, 'http://example.com/', "1st job being processed again";
$queue->requeue($job1);
is $queue->length, 2, 'still requeue will increment queue by 1';

done_testing;

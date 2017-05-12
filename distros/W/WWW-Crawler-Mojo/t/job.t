use strict;
use warnings;
use utf8;
use File::Basename 'dirname';
use File::Spec::Functions qw{catdir splitdir rel2abs canonpath};
use lib catdir(dirname(__FILE__), '../lib');
use lib catdir(dirname(__FILE__), 'lib');
use Test::More;
use WWW::Crawler::Mojo::Job;

use Test::More tests => 15;
{
  my $job = WWW::Crawler::Mojo::Job->new(url => 'foo');
  is $job->depth, 0;
  my $job2 = $job->clone;
  is $job2->url, 'foo', 'right result';
  is $job2->depth, 0;
  my $job3 = $job->child;
  is $job3->depth, 1;
  my $job4 = $job->child;
  is $job4->depth, 1;
  my $job5 = $job4->child;
  is $job5->depth, 2;
  my $job6 = $job5->child;
  is $job6->depth,    3;
  ok $job6->referrer, 'referrer exists';
  ok $job6->referrer->referrer, 'referrer exists';
  ok $job6->referrer->referrer->referrer, 'referrer exists';
  $job6->close;
  is $job6->closed,   1,     'closed';
  is $job6->referrer, undef, 'closed';
}

{
  my $job = WWW::Crawler::Mojo::Job->new();
  $job->redirect('http://a.com/', 'http://b.com/', 'http://c.com/');
  is $job->url, 'http://a.com/';
  is_deeply $job->redirect_history, ['http://b.com/', 'http://c.com/'];
  is $job->original_url, 'http://c.com/';
}

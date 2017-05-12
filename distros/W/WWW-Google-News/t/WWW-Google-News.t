#!perl
use strict;
use Test::More tests => 6;

BEGIN { use_ok('WWW::Google::News',qw(get_news_for_topic get_news get_news_greg_style)); }

my $results;


my $news = WWW::Google::News->new();
$news->topic("Frank Zappa");
$news->max(2);
$results = $news->search();

ok(defined($results),'OO: At least we got something');

$results = get_news_greg_style();

#use Data::Dumper;
#print STDERR "\n",Dumper($results);

ok(defined($results),'GNGS: At least we got something');

#ok(exists($results->{'Top Stories'}),'GNGS: Top Stories Exists');
#ok(keys(%{$results->{'Top Stories'}}),'GNGS: Top Stories Is Not Empty');
#ok(exists($results->{'Top Stories'}->{1}),'GNGS: Top Stories Story 1 Exists');
#ok(exists($results->{'Top Stories'}->{1}->{url}),'GNGS: Top Stories Story 1 URL Exists');
#ok(exists($results->{'Top Stories'}->{1}->{headline}),'GNGS: Top Stories Story 1 Headline Exists');

$results = get_news();

#use Data::Dumper;
#print STDERR "\n",Dumper($results);

ok(defined($results),'GN: At least we got something');

#ok(exists($results->{'Top Stories'}),'GN: Top Stories Exists');
#ok(keys(%{$results->{'Top Stories'}}),'GN: Top Stories Is Not Empty');
#ok(exists(${$results->{'Top Stories'}}[0]),'GN: Top Stories Story 1 Exists');
#ok(exists(${$results->{'Top Stories'}}[0]->{url}),'GN: Top Stories Story 1 URL Exists');
#ok(exists(${$results->{'Top Stories'}}[0]->{headline}),'GN: Top Stories Story 1 Headline Exists');

$results = get_news_for_topic( 'san francisco' );

#use Data::Dumper;
#print STDERR "\n",Dumper($results);

ok(defined($results),'GNBT: At least we got something');
ok(defined($$results[0]->{url}),'GNBT: First result URL exists');


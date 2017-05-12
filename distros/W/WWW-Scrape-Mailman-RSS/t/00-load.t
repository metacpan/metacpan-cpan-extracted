#!perl -T
use strict;
use warnings;
use Test::More tests => 11;

use lib qw( lib );
use WWW::Scrape::Mailman::RSS;

BEGIN {
    use_ok( 'WWW::Scrape::Mailman::RSS' );
}

my $feed = WWW::Scrape::Mailman::RSS->new({ 
        'debug' => 1,
  'rss_version' => '0.91',
   'rss_output' => 't/tmp/home/hesco/tns.campaignfoundations.com/newsfeeds/gpga_news_feed.rss',
   });
isa_ok($feed,'WWW::Scrape::Mailman::RSS');
isa_ok($feed->{'agent'},'WWW::Mechanize');
isa_ok($feed->{'te'},'HTML::TableExtract');
isa_ok($feed->{'twig'},'XML::Twig');
isa_ok($feed->{'rss'},'XML::RSS');

my @methods = ('new','render_feed','_parse_mm_archive_cycle');
foreach my $method (@methods){
  can_ok($feed,$method);
}

my %args = (
     'info_url' => 'http://ga.greens.org/mailman/listinfo/gpga-news',
     'base_url' => 'http://ga.greens.org/pipermail/gpga-news',
    'list_name' => 'gpga-news',
     'audience' => 'Greens',
  'description' => 'News by, about and for Greens',
       'cycles' => 2,
  'output_file' => 't/tmp/home/hesco/tns.campaignfoundations.com/newsfeeds/gpga_news_feed.html',
   'rss_output' => 't/tmp/home/hesco/tns.campaignfoundations.com/newsfeeds/gpga_news_feed.rss',
     'template' => 't/tmpl/gpga_news_feed.tmpl',
  );

my $news_feed = $feed->render_feed(\%args);
open('OUTPUT','>',"$args{'output_file'}") or die 'Unable to open: ' . $args{'output_file'} . "\n";
  print OUTPUT $news_feed;
close OUTPUT;

my $latest_month = '2011-February';
my $next_latest_month = '2011-January';

like($news_feed,qr/$latest_month/,'Feed includes latest month');
like($news_feed,qr/$next_latest_month/,'it also includes the second most recent month');

diag( "Testing WWW::Scrape::Mailman::RSS $WWW::Scrape::Mailman::RSS::VERSION, Perl $], $^X" );

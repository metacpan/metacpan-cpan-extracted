use warnings;
use strict;
use Test::More;
use WWW::Eksi;

# Redefine _download for offline testing with minimal working example.
sub WWW::Eksi::_download{
  my $html = <<END;
<html><body>
<h1 id="title" data-title="test-topic"><a href="/test-link"></a></h1>
<ul id="entry-list">
<li data-author="test-author" data-id="1111" data-author-id="2222" data-favorite-count="3333">
<div class="content">lorem ipsum dolor sit amet, consectetur adipiscing elit</div>
</li>
</ul>
<section id="hidden-channels">channel-1,channel-2</section>
<a class="entry-date permalink">01.01.2018</a>
<a class="entry-author" href="/biri/test-author">test-author</a>
</body></html>
END
  return $html;
}

my $e = WWW::Eksi->new;
isa_ok($e, 'WWW::Eksi');

my $entry    = $e->download_entry(1111);
my $expected = {
  author_id      => 2222,
  fav_count      => 3333,
  author_name    => 'test-author',
  author_url     => 'https://eksisozluk.com/biri/test-author',
  body_processed => 'lorem ipsum dolor sit amet, consectetur adipiscing elit',
  body_raw       => 'lorem ipsum dolor sit amet, consectetur adipiscing elit',
  body_text      => 'lorem ipsum dolor sit amet, consectetur adipiscing elit',
  entry_url      => 'https://eksisozluk.com/entry/1111',
  time_as_seen   => '01.01.2018',
  topic_title    => 'test-topic',
  topic_url      => 'https://eksisozluk.com/test-link',
};

foreach my $key (keys %$expected){
  $key =~ /^body/
       ? like ($entry->{$key}, qr/$expected->{$key}/, "correct $key")
       : is ($entry->{$key}, $expected->{$key}, "correct $key");
}

is($entry->{create_time}->ymd,'2018-01-01', "correct create_time");
is_deeply($entry->{topic_channels}, [qw/channel-1 channel-2/], "correct topic_channels");

done_testing;

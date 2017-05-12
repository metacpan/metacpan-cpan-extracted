package WWW::Google::News::TW;

use utf8;
use strict;
use warnings;

require Exporter;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(get_news get_news_for_topic get_news_for_category);
our $VERSION   = '0.12';

use Carp;
use LWP;
use URI::Escape;
use Encode;

sub get_news {
    # Web version: http://news.google.com.tw/news?ned=tw
    # plain text version : http://news.google.com.tw/news?ned=ttw
  my $url = 'http://news.google.com.tw/news?ned=ttw';
  my $ua = LWP::UserAgent->new;
     $ua->agent('Mozilla/5.0');
  my $response = $ua->get($url);
  my $results = {};
  return unless $response->is_success;

  my $re1 =  '<td bgcolor=#efefef width=60% nowrap>&nbsp;<font class=ks>(.*?)</font>';
  my $re2 =  '<a href="([^"]*)" id=r-\d-\d_\d+ target=_blank>([^<]*)</a><br>'.
	    '<font size=-1><font color=#6f6f6f>([^<]*)</font>'.
	    '\s?<nobr>([^<]*)</nobr></font><br>'.
	    '<font size=-1>([^<]*)<b>...</b>';

  my $content = $response->decoded_content;
  $content = $response->content if (not defined $content);  
  my @sections = split /($re1)/m,$content;
  my $current_section = '';
  foreach my $section (@sections) {
    if ($section =~ m/$re1/m) {
      $current_section = $1;
      $current_section =~ s/&nbsp;//g; # or put this &nbsp;(.*?)(?:&nbsp;)? in re1
    } else {
      my @stories = split /($re2)/mi,$section;
      foreach my $story (@stories) {
        if ($story =~ m/$re2/mi) {
          if (!(exists($results->{$current_section}))) {
            $results->{$current_section} = [];
          }
          my $story_h = {};
	  my( $url, $headline, $source, $update_time, $summary ) = ( $1, $2, $3, $4, $5 );
          $story_h->{url} = $url;
          $story_h->{headline} = $headline;
	  $story_h->{source} = $source;
	  $story_h->{source} =~ s/&nbsp;-//g;
	  $story_h->{update_time} = $update_time;
	  $story_h->{summary} = $summary;
          push(@{$results->{$current_section}},$story_h);
        }
      }
    }
  }
  return $results;
}

sub get_news_for_topic {

    my $topic = uri_escape( $_[0] );

    my @results = ();
    my $url = "http://news.google.com.tw/news?hl=zh-TW&ned=ttw&q=$topic";
    my $ua = LWP::UserAgent->new();
    $ua->agent('Mozilla/5.0');

    my $response = $ua->get($url);
    return unless $response->is_success;

    my $re1 =  '<td bgcolor=#efefef width=60% nowrap>&nbsp;(.*?)&copy;\d{4} Google';
    my $re2 =  '<a href="([^"]*)" id=r-\d_\d+ target=_blank>(.*?)</a><br>'.
	'<font size=-1><font color=#6f6f6f>([^<]*)</font>'.
	'\s?<nobr>([^<]*)</nobr></font><br>'.
	'<font size=-1>(.*?)<b>...</b>';

    my $content = $response->decoded_content;
    $content = $response->content if (not defined $content);  
    my( $section ) = ( $content =~ m/$re1/s );
    $section =~ s/\n//g;
    my @stories = split /($re2)/mi,$section;

    foreach my $story (@stories) {
	if ($story =~ m/$re2/i) {
	    my $story_h = {};
    
	    my( $url, $headline, $source, $update_time, $summary ) = ( $1, $2, $3, $4, $5 );
	    $source =~ s/&nbsp;/ /g;
	    $source =~ s/\s+/ /g;
	    $update_time =~ s/&nbsp;/ /g;
	    $update_time =~ s/\s+/ /g;
	    $update_time =~ s/-//g;
	    $headline =~ s#<.+?>##gi;
	    $summary =~ s#<.+?>##gi;

	    $story_h->{url} = $url;
	    $story_h->{headline} = $headline;
	    $story_h->{source} = $source;
	    $story_h->{update_time} = $update_time;
	    $story_h->{summary} = $summary;

	    push(@results,$story_h);

	}
    }

    return \@results;

}

sub get_news_for_category {
    # Web version: http://news.google.com.tw/news?ned=tw
    # plain text version : http://news.google.com.tw/news?ned=ttw
  my $topic = $_[0];
  my $url = 'http://news.google.com.tw/news?ned=ttw&topic='.$topic;
  my $ua = LWP::UserAgent->new;
     $ua->agent('Mozilla/5.0');
  my $response = $ua->get($url);
  my $results = [];
  return unless $response->is_success;

  my $re1 = '<table border=0 width=75% valign=top cellpadding=2 cellspacing=7><tr><td valign=top>(.*?)</table>';
  my $re2 =  '<a href="([^"]*)" id=r-\d+ target=_blank><b>([^<]*)</b></a><br>'.
	    '<font size=-1><font color=#6f6f6f><b>([^<]*)</font>'.
	    '\s?<nobr>([^<]*)</nobr></b></font><br>'.
	    '<font size=-1>([^<]*)<b>...</b>.*?'.
	    '<a class=p href=([^>]*)><nobr><b>([^<]*)</b></nobr></a>';
  my @sections = split /($re1)/s,$response->content;
  my $current_section = '';
  foreach my $section (@sections) {
    if ($section =~ m/$re1/s) {
      $current_section = $1;
      my @stories = split /($re2)/si,$current_section;
      foreach my $story (@stories) {
        if ($story =~ m/$re2/si) {
          my $story_h = {};
	  my( $url, $headline, $source, $update_time, $summary, $related_url, $related_news) = 
	    ( $1, $2, $3, $4, $5, $6, $7 );
          $story_h->{url} = $url;
          $story_h->{headline} = $headline;
	  $story_h->{source} = $source;
	  $story_h->{source} =~ s/&nbsp;-//g;
	  $story_h->{update_time} = $update_time;
	  $story_h->{summary} = $summary;
	  $story_h->{related_url} = $related_url;
	  $story_h->{related_news} = $related_news;
          push(@{$results},$story_h);
        }
      }
    }
  }
  return $results;
}
1;

__END__

=head1 NAME

WWW::Google::News::TW - Access to Google's Taiwan News Service (Not Usenet)

=head1 SYNOPSIS

  use WWW::Google::News::TW qw(get_news);
  my $results = get_news();
  
  my $results = get_news_for_topic('金牌');

=head1 DESCRIPTION

This module provides a couple of methods to scrape results from Google Taiwan News, returning 
a data structure similar to the following (which happens to be suitable to feeding into XML::RSS).

  {
          '社會' => [
                        {
                          'update_time' => '11小時前',
                          'source' => '聯合新聞網-',
                          'summary' => '不少民眾向公平會檢舉，質疑中華電信每月帳單收取五元「屋內配線月租費」的合理性。公平會昨天決議，要求中華電信要讓樓高四樓以下的用戶，免收五元月租費，並把訊息揭露在電信帳單 ',
                          'url' => 'http://udn.com/NEWS/LIFE/LIFS2/2233728.shtml',
                          'headline' => '中華電配線費四樓以下建物免收'
                        },
                      ],
          '娛樂' => [
                        {
                          'update_time' => '2小時前',
                          'source' => '瀟湘晨報-',
                          'summary' => '本報綜合消息台灣金馬影展執委會昨日公佈本年度活動海報，兩款三幅都以彩虹為視覺主題，象徵電影的光影與夢想，強調創作者電影夢的實現，也是觀眾體驗電影夢的過程 ',
                          'url' => 'http://220.168.28.52:828/xxcb.rednet.com.cn/Articles/04/09/10/544900.HTM',
                          'headline' => '2004金馬影展海報出爐'
                        },
   }

=head1 METHODS

=over 4

=item get_news()

Scrapes L<http://news.google.com.tw/news?ned=ttw> and returns a reference
to a hash keyed on News Section, which points to an array of hashes keyed on URL and Headline.

=item get_news_for_topic( $topic )

Queries L<http://news.google.com.tw/news?ned=tw> for results on a particular topic, 
and returns a pointer to an array of hashes containing result data. 

=head1 SEE ALSO

L<WWW::Google::News>, L<http://news.google.com.tw/>

=head1 TODO

* I haven't think about it yet....

=head1 AUTHORS

Cheng-Lung Sung E<lt>clsung@tw.freebsd.orgE<gt>

=head1 KUDOS

Greg McCarroll <greg@mccarroll.demon.co.uk>, Bowen Dwelle <bowen@dwelle.org>
for the basis of this module

=head1 COPYRIGHT

Copyright 2004,2005,2006,2007 by Cheng-Lung Sung E<lt>clsung@tw.freebsd.orgE<gt>.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

See L<http://www.perl.com/perl/misc/Artistic.html>

=cut


package WWW::Google::News;

use strict;
use warnings;

require Exporter;

our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(get_news get_news_greg_style get_news_for_topic);
our $VERSION   = '0.12';

use Carp;
use LWP;
use URI::Escape;

sub new {
	my $pkg = shift;
	my $self = {};
	bless $self, $pkg;
	if (! $self->init(@_)) {
		return undef;
	}
	return $self;
}

sub init {
	my $self = shift;
	my $args = (ref($_[0]) eq "HASH") ? shift : {@_};
	$self->{'_topic'} = $args->{'topic'};
	$self->{'_start_date'} = $args->{'start_date'};
	$self->{'_end_date'} = $args->{'end_date'};
	$self->{'_sort'} = $args->{'sort'};
	$self->{'_max'} = $args->{'max'} || 20;
	
	return 1;
}

sub topic {
	my $self = shift;
	$self->{'_topic'} = shift;
	return $self->{'_topic'};
}

sub start_date {
  my $self = shift;
  $self->{'_start_date'} = shift;
	return $self->{'_start_date'};
}

sub end_date {
  my $self = shift;
  $self->{'_end_date'} = shift;
	return $self->{'_end_date'};
}

sub sort {
  my $self = shift;
  $self->{'_sort'} = shift;
	return $self->{'_sort'};
}

sub max {
  my $self = shift;
  $self->{'_max'} = shift;
	return $self->{'_max'};
}

sub search {
	my $self = shift;
	return get_news_for_topic($self->{'_topic'},$self->{'_start_date'},$self->{'_end_date'},$self->{'_sort'},$self->{'_max'});
}

sub get_news {
	my $url = 'http://news.google.com/news/gnmainlite.html';
  my $ua = LWP::UserAgent->new;
	$ua->agent('Mozilla/5.0');
  my $response = $ua->get($url);
  return unless $response->is_success;
	my $content = $response->content;
  my $results = {};

  my $re1 =  '<TD bgcolor=#efefef class=ks[^>]*>&nbsp;(.*?)&nbsp;</TD>';
	my $re2 =  '</table><a href="?([^">]+)"?[^>]*>(.+?)</a><br><font size=[^>]+><font color=[^>]+>(.*?)</font>(.*?)</font><br><font size=[^>]+>(.+?)\s*<b>...</b>\s*</font>';

  my @sections = split /($re1)/im,$content;
  my $current_section = '';
  foreach my $section (@sections) {
    if ($section =~ m/$re1/im) {
      $current_section = $1;
      #print STDERR $1,"\n";
    } else {
      my @stories = split /($re2)/mi,$section;
      foreach my $story (@stories) {
        if ($story =~ m/$re2/mi) {
          if (!(exists($results->{$current_section}))) {
            $results->{$current_section} = [];
          }
          my $story_h = {};
          my( $url, $headline, $source, $date, $summary ) = ( $1, $2, $3, $4, $5 );

          _clean_string($source);
          _clean_string($headline);
          _clean_string($date);
          _clean_string($summary);

          $story_h->{url} = $url;
          $story_h->{headline} = $headline;
          $story_h->{source} = $source;
          $story_h->{date} = $date;
          $story_h->{description} = "$source: $summary";
          $story_h->{summary} = $summary;

          push(@{$results->{$current_section}},$story_h);
        }
      }
    }
  }
  #print STDERR Dumper($results);
  return $results;
}


sub get_news_greg_style {
  my $results = get_news();
  my $greg_results = {};
  foreach my $section (keys(%$results)) {
    $greg_results->{$section} = {};
    my $cnt = 0;
    foreach my $story_h (@{$results->{$section}}) {
      $cnt++;
      $greg_results->{$section}->{$cnt} = $story_h;
    }
  }
  return $greg_results;
}

sub get_news_for_topic {

	my $topic = uri_escape( $_[0] );
	my $start_date = $_[1] || "";
	my $end_date = $_[2] || "";
	my $sort= $_[3] || "";
	my $max = $_[4] || 20;

	my $url = "http://news.google.com/news?hl=en&edition=us&q=$topic";
	my $url_start;
	my $url_end;
	if ($start_date =~ /(^|-)(\d{1,2})-(\d{1,2})$/) {
		$url_start = "&as_mind=$3&as_minm=$2";
	}
  if ($end_date =~ /(^|-)(\d{1,2})-(\d{1,2})$/) {
    $url_end = "&as_maxd=$3&as_maxm=$2";
  }
	if ($url_start && $url_end) {
		$url .= "&as_drrb=b" . $url_start . $url_end;
	}

	if (lc($sort) eq "date" || ($sort eq "" && $url_start && $url_end)) {
		$url .= "&scoring=d";
	}

	my @results = ();

	my %URL;
	$URL{"0"} = 1;
	my $flag = 1;

	my $page_size = 100;

	if ($max <= 0) {
		$page_size = 100;
	} elsif ($max <= 50) {
		$page_size = 50;
	} elsif ($max <= 20) {
		$page_size = 20;
	}

	use XML::Atom::Client;
	my $api = XML::Atom::Client->new;
	my $feed = $api->getFeed($url."&output=atom");
	my @entries = $feed->entries;
	foreach my $e (@entries) {
	  my $headline = $e->title();
		my $source = "";
		if ($headline =~ s/ - (.+)$//) {
			$source = $1;
		}
		my $date = $e->issued();
		my $summary = $e->content()->body();
		_clean_string($summary);
		$summary =~ s/^.+? \.\.\. //;
		$summary =~ s/ \.\.\..*?$//;
		my $story_h;
    $story_h->{url} = $e->link()->href();
    $story_h->{headline} = $headline;
    $story_h->{source} = $source;
    $story_h->{date} = $date;
    $story_h->{description} = "$source: $summary";
    $story_h->{summary} = $summary;   
		push(@results,$story_h);
 	}   

MAIN: while(0) {
	$flag = 0;
  foreach my $u (sort {$a<=>$b} keys %URL) {
    next unless $URL{$u};

    $flag = 1;

		my $ua = LWP::UserAgent->new();
		my $request = HTTP::Request->new(GET => $url."&start=$u");
		$request->header("Cookie","PREF=ID=3559860f31fac0d3:LD=en:NR=$page_size:TM=1109341032:LM=1113500592:GM=1:S=gRr8PQTzjZ9uhb-z; domain=.google.com; expires=Sun, Jan 17, 2038 1:14:20 PM; path=/");
		$ua->timeout(30);	
		$ua->agent('Mozilla/5.0');
		my $response = $ua->request($request);
		return unless $response->is_success;
		my $content = $response->content;

	  if (!$content) {
	    sleep 5; next;
	  }

	  $URL{$u} = 0;

		my $re1 = '<br><div[^>]*><table[^>]+>(.+)</table><p style=';
		my $re2 =  '<td valign=top><a href="?([^">]+)"?[^>]*>(.+?)</a><br><font size=[^>]+><font color=[^>]+>([^<]*?)</font>(.*?)</font><br><font size=[^>]+>(.+?)\s*<b>...</b>\s*</font>';

	  my @page_links = split /(\&start=\d+>)/mi,$content;
	  foreach my $pl (@page_links) {
	    if ($pl =~ /\&start=(\d+)>/) {
	      if (!exists($URL{$1})) {
	        $URL{$1} = 1;
	      }
	    }
	  }
		my( $section ) = ( $content =~ m/$re1/s ) or next;
		$section =~ s/\n//g;
		my @stories = split /($re2)/mi,$section;
		foreach my $story (@stories) {
			if ($story =~ m/$re2/i) {
				my $story_h = {};
				my( $url, $headline, $source, $date, $summary ) = ( $1, $2, $3, $4, $5 );

				_clean_string($source);
				_clean_string($headline);
				_clean_string($date);
				_clean_string($summary);
	
				$story_h->{url} = $url;
				$story_h->{headline} = $headline;
				$story_h->{source} = $source;
				$story_h->{date} = $date;
				$story_h->{description} = "$source: $summary";
				$story_h->{summary} = $summary;

				push(@results,$story_h);
				last MAIN if $max>0 && scalar(@results)>=$max;
			}
		}
	}
	
	last MAIN unless $flag;
}
	return \@results;

}

sub _clean_string {
	$_[0] =~ s/&nbsp;/ /ig;
	$_[0] =~ s/&quot;/"/ig;
	$_[0] =~ s/&amp;/&/ig;
	$_[0] =~ s/&#39;/'/g;
	$_[0] =~ s/<br>/ /ig;
	$_[0] =~ s/<[^>]+>//g;
	$_[0] =~ s/\s*-?\s*$//;
	$_[0] =~ s/^\s+//;
}

1;

__END__

=head1 NAME

WWW::Google::News - Access to Google's News Service (Not Usenet)

=head1 SYNOPSIS

	# OO search interface

	use WWW::Google::News;

	my $news = WWW::Google::News->new();
	$news->topic("Frank Zappa");
	my $results = $news->search();

	# original news functions

	use WWW:Google::News qw(get_news);
	my $results = get_news();
  
	my $results = get_news_for_topic('impending asteriod impact');
	
=head1 DESCRIPTION

This module provides a couple of methods to scrape results from Google News, returning 
a data structure similar to the following (which happens to be suitable to feeding into XML::RSS).

  {
    'Top Stories' =>
              [
               {
                 'url' => 'http://www.washingtonpost.com/wp-dyn/articles/A9707-2002Nov19.html',
                 'headline' => 'Amendment to Homeland Security Bill Defeated'
               },
               {
                 'url' => 'http://www.ananova.com/news/story/sm_712444.html',
                 'headline' => 'US and UN at odds as Iraq promises to meet deadline'
               }
              ],
    'Entertainment' =>
             [
              {
                'url' => 'http://abcnews.go.com/sections/entertainment/DailyNews/Coburn021119.html',
                'headline' => 'James Coburn Dies'
              },
              {
                'url' => 'http://www.cbsnews.com/stories/2002/11/15/entertainment/main529532.shtml',
                'headline' => '007s On Parade At \'Die\' Premiere'
              }
             ]
   }

=head1 METHODS

=over 4

=item search()

Perform search on Google News.  Options for search term (topic), sort, date range, and maximum results.  Scraper will maximize results per page, and will page through results until it gets enough stories.  Internally uses get_news_for_topic().

	use WWW::Google::News;

	my $news = WWW::Google::News->new();

	# these methods will get or set their values
	$news->topic("Frank Zappa"); # search term
	$news->sort("date"); # relevance or date, relevance is default
	$news->start_date("2005-04-20"); # must provide start and end date,
	$news->end_date("2005-04-20");   # changes default sort to date
	$news->max(2); # max stories, default 20.  -1 => all stories.

	my $results = $news->search();
	foreach (@{$results}) {
	  print "Source: " . $_->{source} . "\n";
	  print "Date: " . $_->{date} . "\n";
	  print "URL: " . $_->{url} . "\n";
	  print "Summary: " . $_->{summary} . "\n";
	  print "Headline: " . $_->{headline} . "\n";
	  print "\n";
	}

=item get_news()

Scrapes L<http://news.google.com/news/gnmainlite.html> and returns a reference 
to a hash keyed on News Section, which points to an array of hashes keyed on URL , Headline, etc.

  use WWW::Google::News (get_news);

  my $news = get_news();
  foreach my $topic (keys %{$news}) {
    for (@{$news->{$topic}}) {
      print "Topic: $topic\n";
      print "Headline: " . $_->{headline} . "\n";
      print "URL: " . $_->{url} . "\n";
      print "Source: " . $_->{source} . "\n";
      print "When: " . $_->{date} . "\n";
      print "Summary: " . $_->{summary} . "\n";
      print "\n";
    }
  }

=item get_news_for_topic( $topic )

Queries L<http://news.google.com/news> for results on a particular topic, 
and returns a pointer to an array of hashes containing result data, similar to get_news()

An RSS feed can be constructed from this very easily:

	use WWW::Google::News;
	use XML::RSS;

	$news = get_news_for_topic( $topic );
	# also supports the same options for search()
	# $news = get_news_for_topic( $topic, $start_date, $end_date, $sort, $max );
	my $rss = XML::RSS->new;
	$rss->channel(title => "Google News -- $topic");
	for (@{$news}) {
                $rss->add_item(
                        title => $_->{headline},
                        link  => $_->{url},
                        description  => $_->{description}, # source + summary
                );
        }
        print $rss->as_string;

=item get_news_greg_style()

It also provides a method called get_news_greg_style() which returns the same data, only
using a hash keyed on story number instead of the array described in the above.

=head1 TODO

Return info on images contained in certain articles.

Parse out sub articles from featured stories.

Consolidate scraping functions.

=head1 AUTHORS

Greg McCarroll <greg@mccarroll.demon.co.uk>, Bowen Dwelle <bowen@dwelle.org>, Scott Holdren <scott@sitening.com>

=head1 KUDOS

Darren Chamberlain for rss_alternate.pl

Leon Brocard for pulling me up on my obsessive compulsion to use
hashes.

=head1 SEE ALSO

L<http://news.google.com/>
L<http://news.google.com/news/gnmainlite.html>

=cut


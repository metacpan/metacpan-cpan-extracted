# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2011-06-02 22:46:31 +0100 (Thu, 02 Jun 2011) $
# Id:            $Id: Lite.pm 15 2011-06-02 21:46:31Z rmp $
# Source:        $Source$
# $HeadURL: svn+ssh://psyphi.net/repository/svn/www-scraper-lite/trunk/lib/WWW/Scraper/Lite.pm $
#
package WWW::Scraper::Lite;
use strict;
use warnings;
use LWP::UserAgent;
use HTML::TreeBuilder::XPath;
use Carp;

our $VERSION = do { my ($r) = q$Revision: 15 $ =~ /(\d+)/smx; $r; };

sub new {
  my ($class, $ref) = @_;
  if(!$ref) {
    $ref = {};
  }

  bless $ref, $class;

  $ref->{queue} = [];
  $ref->{seen}  = {};

  return $ref;
}

sub ua {
  my $self = shift;

  if(!$self->{ua}) {
    $self->{ua} = LWP::UserAgent->new();
  }

  return $self->{ua};
}

sub crawl {
  my ($self, $url_in, $callbacks) = @_;

  $self->enqueue($url_in);

  while(my $url = $self->dequeue()) {
    $self->{current} = {};
    my $current = $self->{current};

    if($self->{seen}->{$url}++) {
      #########
      # already fetched $url
      #
      next;
    }

    $current->{url} = $url;
    my $res = $self->ua->get($url);
    $current->{response} = $res;

    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse_content($res->content);

    while(my ($pattern, $cb) = each %{$callbacks}) {
      my $nb = $tree->findnodes($pattern);
      for my $node (@{$nb}) {
	$cb->($self, $node);
      }
    }

    #########
    # now the recommended cleanup
    #
    $tree->delete;
  }
  return 1;
}

sub enqueue {
  my ($self, @urls) = @_;
  push @{$self->{queue}}, grep { defined } @urls;
  return 1;
}

sub dequeue {
  my $self = shift;
  my $url  = shift @{$self->{queue}};
  return $url;
}

sub current {
  my $self = shift;
  return $self->{current};
}

sub url_remove_anchor {
  my ($self, $url) = @_;
  if(!$url) {
    return;
  }

  $url =~ s{[#].*}{}smx;
  return $url;
}

sub url_make_absolute {
  my ($self, $url)   = @_;

  if(!$url) {
    return q[];
  }

  my $current          = $self->current;
  my $current_url      = $current->{url};
  if(!$current_url) {
    return;
  }
  my ($current_domain) = $current_url =~ m{^([[:lower:]]+://[^/]+)}smix;
  my ($current_dir)    = $current_url =~ m{^([[:lower:]]+://.*/)}smix;

  if(!$current_dir) {
    $current_dir = q[/];
  }

  if($url =~ m{^mailto:}smix) {
    return $url;
  }

  if($url =~ m{^[[:lower:]]+://}smix) {
    #########
    # already absolute
    #
    return $url;
  }

  if($url =~ m{^/}smx) {
    #########
    # yield $domain$url
    #
    return "$current_domain$url";
  }

  return "$current_dir$url";
}

1;
__END__

=head1 NAME

WWW::Scraper::Lite

=head1 VERSION

$LastChangedRevision: 15 $

=head1 SYNOPSIS

 my $domain  = 'http://devsite.local/';
 my $scraper = WWW::Scraper::Lite->new();
 $scraper->crawl($domain,
		 {
		  '//a' => sub {                                               # handler for all 'a' tags
		    my ($scraper, $nodes) = @_;
		    $scraper->enqueue(grep { $_ =~ m{^$domain} }               # only this domain
				      map  { $scraper->url_remove_anchor($_) } # only index pages without #anchor
				      map  { $scraper->url_make_absolute($_) } # indexer needs absolute URLs
				      map  { $_->{href} }                      # pull href out of the 'a' DOM node
				      @{$nodes});
		  },
		  '/*' => sub {                                                # handler for all content
		    my ($scraper, $nodes) = @_;
		    print $scraper->{current}->{response}->content;            # do something useful with HTTP response
		  },
		 }
	        );

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 new - constructor, initialises fetch-queue and seen-URL hash

 my $oScraper = WWW::Scraper::Lite->new();

=head2 ua - new/cached LWP::UserAgent object

 my $oUA = $oScraper->ua();

=head2 crawl - start crawling a given URL with a given set of XPath callbacks

 $oScraper->crawl($sStartURL, $hrCallbacks);

=head2 enqueue - push one or more URLs onto the fetch queue

 $oScraper->enqueue(@aURLs);

=head2 dequeue - shift a URL off the fetch queue

 my $sURL = $oScraper->dequeue();

=head2 current - a hashref containing information on the current page

 my $hrCurrentData = $oScraper->current;

=head2 url_remove_anchor - strip '#anchor' text from a URL string

 my $sURLout = $oScraper->url_remove_anchor($sURLin);

=head2 url_make_absolute - add the current domain to a URL to make it absolute

 my $sURLout = $oScraper->url_remove_anchor($sURLin);

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item LWP::UserAgent

=item HTML::TreeBuilder::XPath

=item Carp

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

$Author: Roger Pettett,,,$

=head1 LICENSE AND COPYRIGHT

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut


package WWW::Search::Simple;

use strict;
use warnings;

=head1 NAME

WWW::Search::Simple - class for searching any web site

=head1 SYNOPSIS

    require WWW::Search;
    $search = new WWW::Search('Simple');

=head1 DESCRIPTION

This class is a specialization of WWW::Search for simple web based
search indices.  It extracts all links from a given page.

This class exports no public interface; all interaction should be done
through WWW::Search objects.

Note that this module will probably get a lot of false hits.

=head1 AUTHOR

C<WWW::Search::Simple> is written by Paul Lindner, <lindner@itu.int>

=head1 COPYRIGHT

Copyright (c) 1997,98 by the United Nations Administrative Committee 
on Coordination (ACC)

All rights reserved.

=cut


use base 'WWW::Search';

use Carp ();
use HTML::TreeBuilder;
use WWW::SearchResult;

my $debug = 0;

sub _native_setup_search
  {
  my ($self, $native_query, $native_opt) = @_;
  my ($native_url);
  my ($default_native_url) = "http://www.itu.int/cgi-bin/SFgate?application=itu&database=local//usr/local/wais/WWW/www-pages&listenv=table&httppath=/usr/local/www-data/&httpprefix=/&tie=and&maxhits=%n&text=%s";
  if (defined($native_opt)) 
    {
    #print "Got " . join(' ', keys(%$native_opt)) . "\n";
    # Process options..
    # Substitute query terms for %s...
    
    if ($self->{'search_url'} && $native_opt->{'search_args'}) 
      {
      $native_url = $native_opt->{'search_url'} . "?" . $native_opt->{'search_args'};
      } # if
    } # if
  $native_url = $default_native_url if (!$native_url);
  $native_url =~ s/%s/$native_query/g; # Substitute search terms...
  $self->user_agent();
  $self->{_next_to_retrieve} = 0;
  $self->{_base_url} = $self->{_next_url} = $native_url;
  } # _native_setup_search

sub _native_retrieve_some
  {
  my ($self) = @_;
  my ($hit)  = ();
  my ($hits_found) = 0;
  
  # fast exit if already done
  return undef if (!defined($self->{_next_url}));

  # get some
  print "GET " . $self->{_next_url} . "\n" if ($debug);
  my($response) = $self->http_request($self->{search_method}, 
                                      $self->{_next_url});
  
  $self->{response} = $response;
  if (!$response->is_success)
    {
    print "Some problem\n" if ($debug);
    return undef;
    }

  my $score = 800;
  my $results = $response->content();

  my($h) = new HTML::TreeBuilder;
  $h->parse($results);
  for (@{ $h->extract_links(qw(a)) })
    {
    my($link, $linkelem) = @$_;
	
    my($linkobj)       = new URI::URL $link, $self->{_next_url};
    print "Fixing $link\n" if ($debug);
    
    my($hit) = new WWW::SearchResult;
    $hit->add_url($linkobj->abs->as_string());
    $hit->title(join(' ',@{$linkelem->content}));
    $hit->score($score);
    $hit->normalized_score($score);
    if ($hit->title !~ /HASH\(0x/)
      {
      $hits_found++;
      push(@{$self->{cache}}, $hit);
      } # if
    $score = int ($score * .95);
    } # for
  $self->approximate_result_count($hits_found);
  $self->{_next_url} = undef;
  return($hits_found);
  } # _native_retrieve_some

1;


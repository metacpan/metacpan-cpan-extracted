
# $Id: Careers.pm,v 1.14 2008/01/21 02:04:11 Daddy Exp $

# AltaVistaCareers.pm
# Author: Alexander Tkatchev 
# e-mail: Alexander.Tkatchev@cern.ch
#
# WWW::Search back-end for AltaVistaCareers
# http://search.altavistacareers.com/cgi-bin/texis/jobbot/search

=head1 NAME

WWW::Search::AltaVista::Careers - class for searching www.altavistacareers.com

=head1 SYNOPSIS

 use WWW::Search;
 my $oSearch = new WWW::Search('AltaVista::Careers');
 my $sQuery = WWW::Search::escape_query("java c++)");
 $oSearch->native_query($sQuery,
 			{'state' => 'CA'});
 while (my $res = $oSearch->next_result()) {
     print $res->title . "\t" . $res->change_date
	 . "\t" . $res->location . "\t" . $res->url . "\n";
 }

=head1 DESCRIPTION

This class is a AltaVistaCareers specialization of WWW::Search.
It handles making and interpreting AltaVistaCareers searches
F<http://careers.altavista.com>.

The returned WWW::SearchResult objects contain B<url>, B<title>,
B<location> and B<change_date> fields.

=head1 OPTIONS 

The following search options can be activated by sending
a hash as the second argument to native_query().

The only available options are to select a specific location.
The default is to search all locations. To change it use

=over 2

=item   {'state' => $state} - Only jobs in state $state.

=item   {'city' => $city} - Only job in a specific $city

=back

=head1 AUTHOR

C<WWW::Search::AltaVistaCareers> is written and
maintained by Alexander Tkatchev (Alexander.Tkatchev@cern.ch).

=head1 LEGALESE

THIS SOFTWARE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

#####################################################################

package WWW::Search::AltaVista::Careers;

use strict;
use warnings;

use base 'WWW::Search::AltaVista';
use Carp ();
use HTML::TokeParser;
use WWW::Search qw( generic_option );
use WWW::SearchResult;
our
$VERSION = do { my @r = (q$Revision: 1.14 $ =~ /\d+/g); sprintf "%d."."%03d" x $#r, @r };

=head2 native_setup_search

This private method does the heavy lifting after native_query() is called.

=cut

sub native_setup_search
  {
  my($self, $native_query, $native_options_ref) = @_;
  $self->{agent_e_mail} = 'alexander.tkatchev@cern.ch';

  $self->user_agent('non-robot');

  if (!defined($self->{_options})) {
      $self->{'search_base_url'} = 'http://search.altavistacareers.com';
#      $self->{'search_base_url'} = 'http://206.132.18.101';
      $self->{_options} = {
	  'search_url' => $self->{'search_base_url'} .
	      '/cgi-bin/texis/jobbot/search',
	  'query' => $native_query,
	  'city' => '',
	  'state' => '',
	  'sort' => 'J_AsOfDate'
      };
  } # if
  my $options_ref = $self->{_options};
  if (defined($native_options_ref)) 
    {
    # Copy in new options.
    foreach (keys %$native_options_ref) 
      {
      $options_ref->{$_} = $native_options_ref->{$_};
      } # foreach
    } # if
  # Process the options.
  my($options) = '';
  foreach (sort keys %$options_ref) 
    {
    next if (generic_option($_));
    $options .= $_ . '=' . $options_ref->{$_} . '&';
    }
  # Finally figure out the url.
  $self->{_next_url} = $self->{_options}{'search_url'} .'?'. $options;;
  $self->{_debug} = $options_ref->{'search_debug'};
  } # native_setup_search


=head2 native_retrieve_some

This private method does the heavy lifting of communicating
with the server.

=cut

sub native_retrieve_some
  {
  my ($self) = @_;
  my $debug = $self->{_debug};
  print STDERR " * AltaVista::native_retrieve_some()\n" if($debug);
  
  # fast exit if already done
  return undef if (!defined($self->{_next_url}));
  
  # get some
  print STDERR " *   sending request (",$self->{_next_url},")\n" if($debug);
  my($response) = $self->http_request('GET', $self->{_next_url});
  if (!$response->is_success) {
      print STDERR $response->error_as_HTML;
      return undef;
  };
  
  $self->{'_next_url'} = undef;
  print STDERR " *   got response\n" if($debug);

  if($response->content =~ m/Nothing matched your query/) {
      print STDERR "Nothing matched your query\n";
      return 0;
  }

  my ($tag,$nexturl);
  my $p = new HTML::TokeParser(\$response->content());
  if($response->content =~ m/\[\<b\>Next \&gt\;\&gt\;\<\/b\>\]/ ) {
      while(1) {
	  $tag = $p->get_tag("a");
	  $nexturl = $self->{'search_base_url'} . $tag->[1]{href};
	  my $linktitle = $p->get_trimmed_text("/a");
	  last if($linktitle =~ m/\[Next \>\>\]/);
      }
      print STDERR "Next page url: $nexturl\n" if($debug);
      $self->{'_next_url'} = $nexturl;
  } else {
      print STDERR "No next page\n" if($debug);
  }

  my $pp = new HTML::TokeParser(\$response->content());
  while(1) {
      $tag = $pp->get_tag("td");
      my $data = $pp->get_trimmed_text("/td");
      last if($data eq 'Location' ||
              $data eq 'Date');
  }
  $tag = $pp->get_tag("tr");

  my($hits_found) = 0;
  my($hit) = ();
  while(1) {
      $tag = $pp->get_tag("a");
      my $url = $tag->[1]{href};
      $url =~ s|www|http://www|;
      $url =~ s|http://http://|http://|;
      my $title = $pp->get_trimmed_text("/a");
      $tag = $pp->get_tag("td");
      my $date = $pp->get_trimmed_text("/td");
      last unless($date =~ m|(\d+)/(\d+)/(\d+)|);
      $tag = $pp->get_tag("td");
      my $location = $pp->get_trimmed_text("/td");
      $hit = new WWW::SearchResult;
      $hit->url($url);
      $hit->change_date($date);
      $hit->title($title);
      $hit->location($location);
      push(@{$self->{cache}}, $hit);
      $hits_found++;
      last if($hits_found == 10);
  }

  return $hits_found;
} # native_retrieve_some

1;

__END__

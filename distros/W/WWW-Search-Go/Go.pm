#
# Go.pm by Alain Barbet alian@alianwebserver.com
# Copyright (C) 2000
# $Id: Go.pm,v 1.3 2002/08/10 11:40:30 alian Exp $
#

package WWW::Search::Go;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
require Exporter;

@EXPORT = qw();
@EXPORT_OK = qw();
@ISA = qw(WWW::Search Exporter);

$VERSION = ('$Revision: 1.3 $ ' =~ /(\d+\.\d+)/)[0];

use Carp ();
use WWW::Search(qw (generic_option strip_tags));
require WWW::SearchResult;

# private
sub native_setup_search	{
  my($self, $native_query, $native_options_ref) = @_;
  $self->user_agent('alian');
  $self->{_next_to_retrieve} = 0;
  #$self->{_debug} = 1;
  # options par defaut
  if (!defined($self->{_options})) {
    $self->{_options} =
      {
       'Partner' 	=> 'go_home',
       'Keywords' 	=> $native_query,
       'Go' 	      => 'Search',
       'search_url'   => 'http://www.goto.com/d/search/p/go/',
      };}

  my($options_ref) = $self->{_options};
  if (defined($native_options_ref)) 
    {
      # Copy in new options.
      foreach (keys %$native_options_ref) 
	{$options_ref->{$_} = $native_options_ref->{$_};}
    }
  # Process the options.
  # (Now in sorted order for consistency regarless of hash ordering.)
  my($options) = '';
  foreach (sort keys %$options_ref) 
    {
      # printf STDERR "option: $_ is " . $options_ref->{$_} . "\n";
      next if (generic_option($_));
      $options .= $_ . '=' . $options_ref->{$_} . '&' 
	if (defined $options_ref->{$_});
    }

  # Finally figure out the url.
  $self->{_base_url} = $self->{_next_url} 
    = $self->{_options}{'search_url'} ."?" . $options;
}

# private
sub create_hit	{
  my ($self,$url,$titre,$description)=@_;
  my $hit = new WWW::SearchResult;
  $hit->add_url($url);
  $hit->title($titre);
  $hit->description($description);
  push(@{$self->{cache}},$hit);
  return 1;
}

# private
sub native_retrieve_some	{
  my ($self) = @_;
  my($hits_found) = 0;
  my ($buf,$langue);

  #fast exit if already done
  return undef if (!defined($self->{_next_url}));    
  print STDERR "WWW::Search::Go::native_retrieve_some: fetching " .
    $self->{_next_url} . "\n" if ($self->{_debug});
  my($response) = $self->http_request('GET', $self->{_next_url});
  $self->{response} = $response;
  print STDERR "WWW::Search::Go GET  $self->{_next_url} return ",
    $response->code,"\n"  if ($self->{_debug});
  if (!$response->is_success) {return undef;};
  $self->{_next_url} = undef; 
  
  # parse the output
  my($url,$titre,$description);
  my @l = split(/<a name=\d*>/, $response->content());
  foreach my $buf (@l)
    {
      #print STDERR $buf,"\n***************************\n\n\n";		
      my @l2 = split(/\n/, $buf);
      foreach my $ligne (@l2) {
	chomp $ligne;
	# url + titre
	if ($ligne=~/<a href="(.*?)" target="_top">(.*?)<\/a>$/) {
	  ($url, $titre) = ($1, $2);
	}
	# description
	elsif ($ligne=~/^\s* <td><font \s face="verdana,sans-serif"
	       \s size=2>(.*)$/x) { $description = $1; }
      }
      # Ajout d'une entree
      if ($url && $titre && $description) {
	print " *** Find hit: \n\turl: $url\n\ttitre: $titre\n"
	  if ($self->{_debug});
	print "\t description: $description\n"
	  if ($self->{_debug});
	$hits_found+=$self->create_hit($url,$titre,$description);
      }
    }
  #
  # NEXT URL
  #
  # On a le lien dans le dernier bloc analyse precedement
  my $buf = $l[$#l];
  if ($buf=~/<BR><table \s width=100%><tr><td \s align=right>
      <a \s href="(.*)"><font \s face="verdana,sans-serif" \s size=1><b>/x)
    {
      $self->{_next_url} = "http://www.goto.com".$1;
      print " *** Next url: $self->{_next_url}\n" if ($self->{_debug});
    }
  $self->approximate_result_count($hits_found);
  return $hits_found;
}

1;

=head1 NAME

WWW::Search::Go - backend class for searching with go.com

=head1 SYNOPSIS

  use WWW::Search;

  my $oSearch = new WWW::Search('Go');
  $oSearch->maximum_to_retrieve(100);

  #$oSearch ->{_debug}=1;

  my $sQuery = WWW::Search::escape_query("cgi");
  $oSearch->gui_query($sQuery);

  while (my $oResult = $oSearch->next_result())
  {
    print $oResult->url,"\t",$oResult->title,"\n";
  }

=head1 DESCRIPTION

This class is an Go specialization of WWW::Search.
It handles making and interpreting Go searches
F<http://www.Go.com>, older Infoseek search engine.

This class exports no public interface; all interaction should be done
through WWW::Search objects.

On 03/10/2001, Go use GoTo Search Engine. This module is done for
previous versions compatibility.

=head1 BUGS

Go didn't define a total number of result.

=head1 AUTHOR

C<WWW::Search::Go> is written by Alain BARBET,
alian@alianwebserver.com

=cut

#
# RpmFind.pm
# by Alain Barbet alian@alianwebserver.com
# Copyright (C) 2001
# $Id: RpmFind.pm,v 1.2 2002/08/09 14:38:16 alian Exp $
#

package WWW::Search::RpmFind;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
@EXPORT = qw();
@EXPORT_OK = qw();
@ISA = qw(WWW::Search Exporter);
$VERSION = ('$Revision: 1.2 $ ' =~ /(\d+\.\d+)/)[0];

use Carp ();
use strict;
use WWW::Search(qw (generic_option strip_tags));
require WWW::SearchResult;

# private
sub native_setup_search	{
  my($self, $native_query, $native_options_ref) = @_;
  $self->user_agent('WWW::Search::RpmFind - alian@cpan.org');
  $self->{_next_to_retrieve} = 0;
  $self->{'search_base_url'} = 'http://www.rpmfind.net';
  if (!defined($self->{_options})) {
    $self->{_options} = 
      { 
       'query' 	=> $native_query,
       'submit'     => "Search ...",
       'search_url' => $self->{'search_base_url'}.'/linux/rpm2html/search.php'
      };}
  my($options_ref) = $self->{_options};
  if (defined($native_options_ref)) {
    # Copy in new options.
    foreach (keys %$native_options_ref) 
      {$options_ref->{$_} = $native_options_ref->{$_};}
  }
  # Process the options.
  # (Now in sorted order for consistency regarless of hash ordering.)
  my($options) = '';
  foreach (sort keys %$options_ref) {
    # printf STDERR "option: $_ is " . $options_ref->{$_} . "\n";
    next if (generic_option($_));
    $options .= $_ . '=' . $options_ref->{$_} . '&' 
      if (defined $options_ref->{$_});
  }

  # Finally figure out the url.
  $self->{_base_url} = $self->{_next_url} 
    = $self->{_options}{'search_url'} ."?" . $options;
  print STDERR $self->{_base_url} . "\n" if ($self->{_debug});	
}

# private
sub create_hit  {
    my ($self,$url,$titre,$description,$rpm)=@_;
    my $hit = new WWW::SearchResult;
    $hit->add_url($url);
    $hit->title(strip_tags($titre));
    $hit->description(strip_tags($description));
    $hit->source($rpm);
    print STDERR " *** Found item\n\tUrl: $url\n",
	"\tTitle:",$hit->title(),"\n\tDescription:",$hit->description(),"\n"	
	  if ($self->{_debug});
    push(@{$self->{cache}},$hit);
    return $hit;
  }

# private
sub native_retrieve_some
  {
    my ($self) = @_;
    my($hits_found) = 0;
    my ($buf,$langue);
    print "DEBUG MODE\n" unless $self->{_debug}==0;
    #fast exit if already done
    return undef if (!defined($self->{_next_url}));
    print STDERR "WWW::Search::RpmFind::native_retrieve_some: fetching " .
	$self->{_next_url} . "\n" if ($self->{_debug});
    my($response) = $self->http_request('GET', $self->{_next_url});
    $self->{response} = $response;
    print STDERR "WWW::Search::RpmFind GET  $self->{_next_url} return ",
	$response->code,"\n"  if ($self->{_debug});
    if (!$response->is_success) {return undef;};
    $self->{_next_url} = undef; 

    # parse the output
    my $HEADER=1;
    my $stop = -1;
    my $end = 0;
    my($raw) = '';
    my @l = $self->split_lines($response->content());
    foreach (@l) {
	$stop++;
	next if m@^$@; # short circuit for blank lines
	# HEADER PARSING: find the number of hits
	if (m!<h3 \s align='center'> \s Found \s (\d*) \s RPM \s for !x)
	  {
	    $self->approximate_result_count($1);
	    print STDERR "*** $1 result\n"  if ($self->{_debug});
	    last;
	  }
    } # Fin du parcours par ligne

     my $rest = join("\n", @l[$stop..$#l]);
     my @rest = split(/<tr /, $rest);
     undef @l; $stop = 0; 
     # walk on each part. One part = one hit
#    print "$#rest elems to parse\n";
     foreach (@rest)
	 {	
	   # url + title (Summary) + description (Distribution)
	   if (m!bgcolor='.*'><td><a \s href='(.*)'>.*</a></td>
		 <td>(.*)</td><td>(.*)</td><td><a \s href='(.*)'>.*</a>
                 </td></tr>!x) {
	     # Create hit
	     $self->create_hit($1,$2,$3,$4);
	     $hits_found++;
	   }
	   elsif (m!<table \s\s width=624 \s\s cellpadding=0 \s 
		    cellspacing=0 \s border=0>!x)
	   { $end =1; last; }
	 }
    return $hits_found;
  }

1;

=head1 NAME

WWW::Search::RpmFind - class for searching RpmFind.net

=head1 SYNOPSIS

  #!/usr/bin/perl
  use WWW::Search;
  use strict;
  my $oSearch = new WWW::Search('RpmFind');

  # Create request
  $oSearch->native_query(WWW::Search::escape_query("cgi"));

  print "I find ", $oSearch->approximate_result_count()," elem\n";
  while (my $oResult = $oSearch->next_result())
    {
      print "---------------------------------\n",
    	      "Url    :", $oResult->url,"\n",
	      "Titre  :", $oResult->title,"\n",
              "Distrib:", $oResult->description,"\n",
	          "Rpm:", $oResult->source,"\n";
    }

=head1 DESCRIPTION

This class is an RpmFind specialization of WWW::Search.
It handles making and interpreting RpmFind searches
F<http://RpmFind.net>, a database search engine on RPM packages..

This class exports no public interface; all interaction should be done
through WWW::Search objects.

=head1 SEE ALSO

  The WWW::Search man pages

=head1 AUTHOR

C<WWW::Search::RpmFind> is written by Alain BARBET,
alian@alianwebserver.com

=cut

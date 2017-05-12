package WWW::Search::RPMPbone;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);

require Exporter;
@EXPORT = qw();
@EXPORT_OK = qw();
@ISA = qw(WWW::Search Exporter);
$VERSION = ('$Revision: 1.0 $ ' =~ /(\d+\.\d+)/)[0];

use strict;
use WWW::Search(qw (generic_option strip_tags));
require WWW::SearchResult;

sub _get_next_urlparameters {
  my ($self) = @_;
  if (!defined($self->{_options})) {
    $self->{_options} =
      {
       'stat'       =>  3,
       'limit'      =>  1,
       'srodzaj'    =>  4,
       'dl'         =>  20,
       'search'     => $self->{'native_query'},
       'dist[]'     => 42,
       'search_url' => $self->{'search_base_url'}
      };
  }
  else {
     $self->{_options}{'limit'}++;
  }
  my($options_ref) = $self->{_options};
  if (defined($self->{'native_options_ref'})) {
    my $native_options_ref = $self->{'native_options_ref'};
    foreach (keys %$native_options_ref)
      {$options_ref->{$_} = $native_options_ref->{$_};}
  }
  my($options) = '';
  foreach (sort keys %$options_ref) {
    next if (generic_option($_));
    $options .= $_ . '=' . $options_ref->{$_} . '&'
      if (defined $options_ref->{$_});
  }
  return $options;
}

sub native_setup_search {
  my($self, $native_query, $native_options_ref) = @_;
  $self->{'native_query'} = $native_query;
  $self->{'native_options_ref'} = $native_options_ref if (defined $native_options_ref);
  $self->user_agent('WWW::Search::RpmPbone');
  $self->{'search_base_url'} = 'http://rpm.pbone.net/index.php3';
  my $options = $self->_get_next_urlparameters();
  $self->{_base_url} = $self->{_next_url} 
    = $self->{_options}{'search_url'} ."?" . $options;
}

sub native_retrieve_some  {
    my ($self) = @_;
    my($hits_found) = 0;
    return undef if (!defined($self->{_next_url}));
    my($response) = $self->http_request('GET', $self->{_next_url});
    $self->{response} = $response;
    if (!$response->is_success) {return undef;}
    if ($response->content =~ /FILE WASN\'T FOUND ON FTP SERVERS/sm) { print "No match\n"; return undef; }
    $self->{_next_url} = $self->{_options}{'search_url'} ."?" .$self->_get_next_urlparameters();
    if ($response->content =~ /^Display 1 - (\d+) hits of (\d+)/sm) { $self->{'totalhits'} = $2; print $2;}
    my @response_content = split("\n",$response->content);
    foreach my $content (@response_content) {
      $content =~ s/&nbsp;//g;
      if ($content =~ /<TR><TD>(.*?)<\/TD>.*<a href=\"(.*)\">(.*rpm)<\/a><\/TD><TD><\/TD><TD>(.*)<\/TD><\/TR>/) {
        $self->_new_hit($1,$2,$3,$4);
        $hits_found++;
      }
    }
    return $hits_found;
}

sub _new_hit {
  my ($self,$site,$site_url,$rpm,$distribution) = @_;
  my $hit = new WWW::SearchResult;
  $hit->add_url($site_url);
  $hit->source($rpm);
  $hit->description($distribution);
  push(@{$self->{cache}},$hit);
  return $hit;
}

=head1 NAME

WWW::Search::RPMPbone - class for searching rpm.pbone.net

=head1 SYNOPSIS

  #!/usr/bin/perl
  use WWW::Search;
  use strict;
  my $oSearch = new WWW::Search('RPMPbone');

  # Create request
  $oSearch->native_query(WWW::Search::escape_query("ccache*src.rpm"));

  print "I find ", $oSearch->approximate_result_count()," elem\n";
  while (my $oResult = $oSearch->next_result())
    {
      print "---------------------------------\n",
            "Url    :", $oResult->url,"\n",
            "Distrib:", $oResult->description,"\n",
            "Rpm:", $oResult->source,"\n";
    }

=head1 DESCRIPTION

This class is an RpmPbone (http://rpm.pbone.net/index.php3) specialization of WWW::Search.
It handles making and interpreting searches from rpm.pbone.net, a database search engine on RPM packages..

This class exports no public interface; all interaction should be done
through WWW::Search objects.

=head1 SEE ALSO

  The WWW::Search man pages

=head1 AUTHOR

C<WWW::Search::RPMPbone> is written by Alagar,
samy@cpan.org

=cut


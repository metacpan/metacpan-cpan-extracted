#!/usr/local/bin/perl

=head1 NAME

WWW::Search::Livelink  -  class for searching Open Text Livelink Intranet search engine

=head1 SYNOPSIS

    require WWW::Search;
    $search = new WWW::Search('Livelink');

=head1 DESCRIPTION

This class is an Open Text Livelink Intranet specialization of
WWW::Search.  It queries and interprets searches based on Livelink
Intranet, which is available at F<http://www.opentext.com>

This class exports no public interface; all interaction should be done
through WWW::Search objects.

=head1 OPTIONS

This search supports sytandard WWW::Search arguments

=over 8

=item search_url

The Livelink Intranet URL to search.  This usually looks like
F<http://somehost/otcgi/llscgi60.exe>

=item search_args

The arguments used for the search engine, separate them by &.

=back

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>,

=head1 AUTHOR

C<WWW::Search::Livelink> is written by Paul Lindner, <lindner@itu.int>,
Nicholas Sapirie <sapirie@unicc.org>

=head1 COPYRIGHT

Copyright (c) 1998 by the United Nations Administrative Committee on
Coordination (ACC)

All rights reserved.

=cut

package WWW::Search::Livelink;

use strict;
use warnings;

use base 'WWW::Search';

our
$VERSION = do { my @r = ( q$Revision: 1.4 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use Carp ();
require WWW::SearchResult;

my($debug) = 0;

#private
sub native_setup_search {
    my($self, $native_query, $native_opt) = @_;
    my($native_url);
    my($default_native_url) =
	"http://www.unicef.org/otcgi/llscgi60.exe?db=1&mode=%m&SearchFor=%s&From=1&Size=%n";
    
    if (defined($native_opt)) {
	#print "Got " . join(' ', keys(%$native_opt)) . "\n";
	# Process options..
	# Substitute query terms for %s...

	if ($self->{'search_url'} && $native_opt->{'search_args'}) {
	    $native_url = $native_opt->{'search_url'} . "?" . $native_opt->{'search_args'};
	}
    } 
    
    $native_url = $default_native_url if (!$native_url);

    my $how = $self->{search_how};
    if ($how) {
	#Change behaviour depending on 'search_how'
	if ($how eq 'match_all') {
	    $native_url =~ s/%m/and/;
	}  elsif ($how eq 'match_phrase') {
	    $native_url =~ s/%m/phrase/;
	} else {
	    $native_url =~ s/%m/or/;               #or is default
	}
    } else {
      $native_url =~ s/%m/or/;
    }

    #specify database to be searched
    #$native_url =~ s/%d/4/;                       #valid values are 0, 1, 4, 6 for UNICEF

    #specify number of results
    $native_url =~ s/%n/40/;

    $native_url =~ s/%s/$native_query/g;           # Substitute search terms...

    $self->user_agent(1);
    $self->{_next_to_retrieve} = 0;
    $self->{_base_url} = $self->{_next_url} = $native_url;
}


# private
sub native_retrieve_some
{
    my ($self) = @_;
    my ($hit)  = ();
    my ($hits_found) = 0;
    my $step = 0;

    # fast exit if already done
    return undef if (!defined($self->{_next_url}));

    # get some
    my $method = $self->{search_method};
    $method = 'POST' unless $method;
    print "POST" . $self->{_next_url} . "\n" if ($debug);
    my($response) = $self->http_request($method, $self->{_next_url});
 
    $self->{response} = $response;
 
    if (!$response->is_success) {
	print "Some problem\n" if ($debug);
	return (undef);
    };
 
    my $results = $response->content();
    # parse the output
 
    @{$self->{cache}} = (1);
    @{$self->{cache}} = ();
    if (!$results) {
       return(0);
    }

    my ($size, $url);
    my (@lines) = $self->split_lines($results);
    my $backup;

    my ($lititle, $lidesc, $liurl, $lisize, $lihits, $liscore) = ('', '', '', 0, 0, 0);
    while ($#lines > -1) {
      $hits_found++;
      $_ = shift(@lines);
      if ($step == 0) {
        if ($_ =~ m/documents containing:/) {
          $_ =~ s/of <B>/%/;
          $_ =~ s/^.*%//;
          $_ =~ s/<\/B> documents/%/;
          $_ =~ s/%.*//;
          chomp;
          $lihits = $_;
        }
      }
      if ($step == 0) {
        if ($_ =~ m/START/) {
          $step = 1;
        }
      } elsif ($step == 1) {
        if ($_ =~ m/<B><A HREF="/) {
          $backup = $_;
          $backup =~ s/^<B><A HREF="//;
          $backup =~ s/">http:/%%/;
          $backup =~ s/%%.*$//;
          chomp($backup);
          $liurl = $backup;                #get url
          $backup = $_;
          $backup =~ s/ \(Size: /%%/;
          $backup =~ s/^.*%%//;
          $backup =~ s/\)<BR>/%%/;
          $backup =~ s/%%.*$//;
          chomp($backup);
          $lisize = $backup;               #get size
          $backup = $_;
          $backup =~ s/<BR><I>/%%/;
          $backup =~ s/^.*%%//;
          $backup =~ s/<\/I>/%%/;
          $backup =~ s/%%.*$//;
          $lidesc = $backup;
          $backup =~ s/\. /%%/;
          $backup =~ s/%%.*$//;
          $backup =~ s/ - /%%/;
          $backup =~ s/%%.*$//;
          chomp($backup);
          $lititle = $backup;              #get title
          $backup = $_;
          $backup =~ s/Search score: /%%/;
          $backup =~ s/^.*%%//;
          $backup =~ s/\)</%%/;
          $backup =~ s/%%.*$//;
          chomp($backup);
          $liscore = $backup * 4;               #get score
          if ($liscore > 1000) {
              $liscore = 1000;
          }
          
          my($hit) = new WWW::SearchResult;

          my($linkobj) = new URI::URL $liurl, $self->{_next_url};
          $hit->add_url($linkobj->abs->as_string);
          $hit->title($lititle);
          $hit->size($lisize);
          $hit->description($lidesc);
          $hit->score($liscore);
          $hit->normalized_score($liscore);

          push(@{$self->{cache}}, $hit);
        }
      }
    }
    $self->approximate_result_count($lihits);
    $self->{_next_url} = undef;

    return($lihits);
}


1;

__END__


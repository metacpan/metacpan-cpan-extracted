#!/usr/local/bin/perl

=head1 NAME

WWW::Search::Search97  -  class for searching Verity Search97 search engine

=head1 SYNOPSIS

    require WWW::Search;
    $search = new WWW::Search('Search97');


=head1 DESCRIPTION

This class is a Verity Search97 specialization of
WWW::Search.  It queries and interprets searches based on Verity
Search97, which is available at F<http://www.verity.com>

This class exports no public interface; all interaction should be done
through WWW::Search objects.

=head1 OPTIONS

This search supports sytandard WWW::Search arguments

=over 8

=item search_url

The Search97 URL to search.  This usually looks like
F<http://somehost/Search97cgi/s97_cgi.exe>

=item search_args

The arguments used for the search engine, separate them by &.

=back

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>,

=head1 AUTHOR

C<WWW::Search::Search97> is written by Paul Lindner, <lindner@itu.int>,
Nicholas Sapirie <sapirie@unicc.org>

=head1 COPYRIGHT

Copyright (c) 1998 by the United Nations Administrative Committee on
Coordination (ACC)

All rights reserved.

=cut

package WWW::Search::Search97;

use strict;
use warnings;

use base 'WWW::Search';

our
$VERSION = do { my @r = ( q$Revision: 1.4 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use Carp ();
use WWW::SearchResult;

my($debug) = 0;

#private
sub native_setup_search {
    my($self, $native_query, $native_opt) = @_;
    my($native_url);
    my($default_native_url) =
	"http://www.imf.org/search97cgi/s97_cgi.exe?QueryZip=%s&ResultTemplate=imfrslp%2Ehts&QueryText=%s&Collection=econiss&Collection=insext&Collection=external&SortOrder=Desc&ScoreThreshold=14&ResultStart=1&ResultCount=%n&ServerKey=&AdminImagePath=&Theme=&Company=";
    
    if (defined($native_opt)) {
	#print "Got " . join(' ', keys(%$native_opt)) . "\n";
	# Process options..
	# Substitute query terms for %s...

	if ($self->{'search_url'} && $native_opt->{'search_args'}) {
	    $native_url = $native_opt->{'search_url'} . "?" . $native_opt->{'search_args'};
	}
    } 
    
    $native_url = $default_native_url if (!$native_url);

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
    $method = 'GET' unless $method;
    print "GET" . $self->{_next_url} . "\n" if ($debug);
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
      $_ = shift(@lines);
      if ($step == 0) {
        if ($_ =~ m/^matched/) {
          $_ =~ s/^matched //;
          $_ =~ s/ matches.*$//;
          chomp;
          $lihits = $_;
          $step = 1;
        }
      } elsif ($step == 1) {
        if ($_ =~ m/^<TD width=75%/) {
          $_ =~ s/HREF="/%%/;
          $_ =~ s/^.*%%//;
          $_ =~ s/">.*$//;
          chomp;
          $liurl = $_;
          $step = 2;
        }
      } elsif ($step == 2) {
        $hits_found++;
        $_ =~ s/^ *//;
        $_ =~ s/<\/A>.*$//;
        chomp;
        $lititle = $_;
        $step = 3;
      } elsif ($step == 3) {
        if ($_ =~ m/Summary/) {
          $_ =~ s/^.*Summary:<\/b> //;
          chomp;
          $lidesc = $_;
        } else {$lidesc = '';}
        $step = 4;
      } elsif ($step == 4) {
        if ($_ =~ m/width=15%>/) {
          $_ =~ s/width=15%>/%%/;
          $_ =~ s/^.*%%//;
          $_ =~ s/ Kb.*$//;
          chomp;
          $lisize = $_;
          $liscore = 1000 - (1000 / $lihits * $hits_found);
          my($hit) = new WWW::SearchResult;
          my($linkobj) = new URI::URL $liurl, $self->{next_url};
          $hit->add_url($linkobj->abs->as_string);
          $hit->title($lititle);
          $hit->size($lisize * 1024);
          $hit->description($lidesc);
          $hit->score($liscore);
          $hit->normalized_score($liscore);
          push(@{$self->{cache}}, $hit);
          
          $step = 1;
        }
      }
    }
    $self->approximate_result_count($lihits);
    $self->{_next_url} = undef;

    return($lihits);
}


1;

__END__


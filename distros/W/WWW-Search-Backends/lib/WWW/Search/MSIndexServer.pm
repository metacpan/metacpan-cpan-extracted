#!/usr/local/bin/perl

=head1 NAME

WWW::Search::MSIndexServer - class for searching MSIndexServer search engine

=head1 SYNOPSIS

    require WWW::Search;
    $search = new WWW::Search('MSIndexServer');

=head1 DESCRIPTION

This class is a MSIndexServer specialization of WWW::Search.  It queries and
interprets searches based on MSIndexServer, which is available at
F<http://www.microsoft.com/>

This class exports no public interface; all interaction should be
done through WWW::Search objects.

=head1 OPTIONS

This search supports standard WWW::Search arguments

=over 8

=item search_url

The MSIndexServer URL to search.  This usually looks like
F<http://somehost/scripts/queryhit.idq>

=item search_args

The arguments used for the search engine, separate them by &.

=item search_method

POST or GET

=item search_debug

Turn debugging on or off

=item search_how

Possible values match_any, match_all, match_phrase

=back

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>,

=head1 AUTHOR

C<WWW::Search::MSIndexServer> is written by Paul Lindner, <lindner@itu.int>,
Nicholas Sapirie <sapirie@unicc.org>

=head1 COPYRIGHT

Copyright (c) 1998 by the United Nations Administrative Committee 
on Coordination (ACC)

All rights reserved.

=cut

package WWW::Search::MSIndexServer;

use strict;
use warnings;

use base 'WWW::Search';

our
$VERSION = do { my @r = ( q$Revision: 1.5 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use Carp ();
use WWW::SearchResult;

my($debug) = 0;

#private

sub native_setup_search {
    my($self, $native_query, $native_opt) = @_;
    my($native_url);
    my($default_native_url) =
 "http://www.fao.org/scripts/samples/search/queryhit.idq?CiRestriction=%s&CiMaxRecordsPerPage=%n&CiScope=%2F&TemplateName=queryhit&CiSort=rank%5Bd%5D&HTMLQueryForm=%2Fsearch%2Fqueryhit.htm";
    
    if (defined($native_opt)) {
	#print "Got " . join(' ', keys(%$native_opt)) . "\n";
	# Process options..

	if ($self->{'search_url'} && $native_opt->{'search_args'}) {
	    $native_url = $native_opt->{'search_url'} . "?" . $native_opt->{'search_args'};
	}
	$debug = 1 if ($native_opt->{'search_debug'});
    } 

    $native_url = $default_native_url if (!$native_url);


    ## Change behaviour depending on 'search_how'
    my $how = $self->{'search_how'};
    if (defined($how)) {
	if ($how eq 'match%5Fany') {
	    $native_query =~ s/ and //g;
	} 
	elsif ($how eq 'match%5Fall') {
	    ### Add 'and'
	    $native_query =~ s/\s+and\s+//g;
	    $native_query =~ s/\s+/ and /g;
	} 
	elsif ($how eq 'match%5Fphrase') {
	    ### Add quotes around the item..
	    $native_query =~ s/[\'\"]+//g;
	    $native_query =~ s/\+/ /g;
	    $native_query = "'$native_query'";
	} 
	elsif ($how eq 'match_boolean') {
	    ## Leave asis
	    ;
	}
    }

    $native_url =~ s/%s/$native_query/g; # Substitute search terms...
    $native_url =~ s/%n/40/g; # Substitute num hits...
    $native_url .= "&MaxRecordsPerPage=40" if ($native_url !~ /MaxRecordsPerPage=/);

    $self->user_agent(1);
    $self->{_next_to_retrieve} = 0;
    $self->{_base_url} = $native_url;
    $self->{_next_url} = $native_url;
}


# private
sub native_retrieve_some
{
    my ($self) = @_;
    my ($hit)  = ();
    my ($hits_found) = 0;
    my($step) = 0;

    # fast exit if already done
    return undef if (!defined($self->{_next_url}));

    # get some
    my $method = $self->{search_method};
    if (! defined($method)) {
	$method = 'GET';
    }
    warn "$method ", $self->{_next_url}, "\n" if ($debug);

    my $response = $self->http_request($method, $self->{_next_url}); 

    $self->{response} = $response;

    if (!$response->is_success) {
	#warn $response->as_string();
	warn " --- HTTP request failed: ", $response->as_string, "\n" if ($debug);
	return (undef);
    };

    my $results = $response->content();
    # parse the output
	
    @{$self->{cache}} = (1);
    @{$self->{cache}} = ();
    if (!$results) {
	return(0);
    }
	
    my ($url);
    my (@lines) = $self->split_lines($results);

    my($mstitle, $msurl, $mssize, $mshits, $msdesc);
    ($mstitle, $msurl, $mssize, $mshits, $msdesc) = ('', '', 0, 0, undef);

    while ($#lines > -1) {
	$_ = shift(@lines);

        if ($step == 0) {
	    ($mstitle, $msurl, $mssize, $msdesc) = ('', '', 0, undef);

          if ($_ =~ m/matching the query/) {
            $_ =~ s/[^0-9]//g;
            $mshits = $_;
          }
        }
	if ($step == 0) {
	  if ($_ =~ m/<dt>/) {
	    $step = 1;
	  }
	} elsif ($step == 1) {
	  if ($_ =~ m/<b><a href=/) {
	    $_ =~ s/^.*\">//;
	    $_ =~ s/<\/a>.*$//; 
            $mstitle = $_;
            $step = 2;
          } 
	} elsif ($step == 2) {
	    if ($_ =~ m/Abstract: /) {
		$msdesc = $_;
		$msdesc =~ s/^.*Abstract: //;
		$step = 3;
	    }
	} elsif ($step == 3) {
	    # collect abstract info..
	    if ($_ =~ m/cite/) {
		$step = 4;
	    } else {
		s/\s+/ /;
		$msdesc .= $_;
	    }
	} elsif ($step == 4) {
          if ($_ =~ m/a href=/) {
	    $_ =~ s/^.*\">//;
	    $_ =~ s/<\/a.*$//;
	    $msurl = $_;                 #print url 
	    $step = 5;
	  } 
	} elsif ($step == 5) {
	  if ($_ =~ m/size.*bytes/) {
	    $_ =~ s/^.*- size //;
	    $_ =~ s/ - .*$//;
	    $_ =~ s/,//;
	    $mssize = $_;               #print document size
	    $step = 0;
	    
	    my($hit) = new WWW::SearchResult;
	    # change into an absolute URL
	    my($linkobj) = new URI::URL $msurl, $self->{_next_url};
	    $hit->add_url($linkobj->abs->as_string);
	    $hit->title($mstitle);
	    $hit->size($mssize);
	    $msdesc =~ s,<[A-Za-z/]*?>,,g; #remove tags..
	    $hit->description($msdesc);
	    $hits_found++;
	    $hit->score(800 - (20 * $hits_found));
	    $hit->normalized_score(800 - (20 * $hits_found));
	    push(@{$self->{cache}}, $hit);      
	  } 
	}
	
      }
    if ($mshits) {
      $self->approximate_result_count($mshits);
    } else {
      $self->approximate_result_count($hits_found);
    }
    $self->{_next_url} = undef;
    
    return($hits_found);
  }


1;

__END__


#!/usr/local/bin/perl

=head1 NAME

WWW::Search::ExciteForWebServers - class for searching ExciteforWeb engine

=head1 SYNOPSIS

    require WWW::Search;
    $search = new WWW::Search('ExciteForWebServers');

=head1 DESCRIPTION

This class is a specialization of WWW::Search for search indices built
using Excite for Web Servers (available from F<http://www.excite.com>).

This class exports no public interface; all interaction should be done
through WWW::Search objects.

This object interprets the WWW::Search L<search_how> attribute as follows: 

  match_any    = concept search
  match_all    = keyword (simple) search
  match_phrase = error condition
  match_boolean= error condition

=head1 AUTHOR

C<WWW::Search::ExciteForWebServers> is written by Paul Lindner,
<lindner@itu.int>

=head1 COPYRIGHT

Copyright (c) 1997,98 by the United Nations Administrative Committee 
on Coordination (ACC)

All rights reserved.

=cut

package WWW::Search::ExciteForWebServers;

use strict;
use warnings;

use base 'WWW::Search';

#use strict vars;
use Carp();
use WWW::SearchResult;

our
$VERSION = do { my @r = ( q$Revision: 1.5 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

my($debug) = 0;

sub native_setup_search {
    my($self, $native_query, $native_opt) = @_;
    my($native_url);
    my($default_native_url) = 
	"http://www.worldbank.org/cgi-bin/AT-Full_Site_Searchsearch.cgi?mode=concept&search=%s&SearchButton.x=0&SearchButton.y=0&sp=sp";

    if (defined($self->{'search_debug'}) ) {
      $debug = 1;
    }

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
    my $how = $self->{search_how};

    if (defined($how)) {
	if ($how =~ /any/) {
	    ## change mode to concept, or add it..
	    $native_url =~ s/mode=[^&]+/mode=concept/ig;
	    if ($native_url !~ /mode=/) {
		$native_url .= "&mode=concept";
	    }
	} elsif ($how =~ /all/) {
	    ## change mode to simple, or add it..
	    $native_url =~ s/mode=[^&]+/mode=simple/ig;
	    if ($native_url !~ /mode=/) {
		$native_url .= "&mode=simple";
	    }
	}
    }

    $native_url =~ s/%s/$native_query/g; # Substitute search terms...

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

    # fast exit if already done
    return undef if (!defined($self->{_next_url}));

    # exit if set to search_phrase
    my $how = $self->{search_how};

    if (defined($how) && ($how =~ /(phrase|boolean)/)) {
	my $response = new HTTP::Response(500, "This Search Engine does not support $1 searches");
	$self->{response} = $response;
	return(undef);
    }

    my $method = $self->{search_method};
    $method = 'GET' unless $method;

    # get some
    print "$method " . $self->{_next_url} . "\n" if ($debug);

    my($response) = $self->http_request($method, $self->{_next_url});
    $self->{response} = $response;

    if (!$response->is_success) {
	print "Some problem\n" if ($debug);
	return undef;
    };
    # parse the output
    use HTML::TreeBuilder;

    my($srchitem);

    foreach $_ ($self->split_lines($response->content())) {
      s/ architext\=result//g;
      print "Got $_\n" if ($debug);

	if ((m,(<BR>|</ul>)$,i) && (/<A/i) && (/ ([\d]+)\%/)) {
	    m,([\d]+)\%,;
	    my $score = $1;
	    my $normscore = $1 * 10;
	    my $summary;

	    if (m,Summary(<.*)$,) {
		$summary = $1;
		$summary =~ s,<[A-Za-z/]*?>,,g;
	    }

	    my($h) = new HTML::TreeBuilder;
	    $h->parse($_);
	    
	    for (@{ $h->extract_links(qw(a)) }) {
		my($link, $linkelem) = @$_;
		next if ($link =~ /\?/);
		my $t = "";
		my $i;
		foreach $i (@{$linkelem->content}) {
		    if (ref($i)) {
			$t .= $i->as_HTML;
			$t =~ s,</?B>,,ig;
		    }else {
			$t .= $i;
		    }
		}
		
		my($srchitem) = new WWW::SearchResult;
		my($linkobj)       = new URI::URL $link, $self->{_next_url};
		print "Fixing $link\n" if ($debug);

		$srchitem->add_url($linkobj->abs->as_string());	  
		$srchitem->title($t);#$linkelem->as_HTML;

		$srchitem->score($score);
		$srchitem->description($summary);
		$srchitem->normalized_score($normscore);
		$hits_found++;
		push(@{$self->{cache}},$srchitem);
		last;
	    }
	    $h->delete;
	}
    }
    $self->approximate_result_count($hits_found);
    $self->{_next_url} = undef;
    return($hits_found);
}

1;

__END__


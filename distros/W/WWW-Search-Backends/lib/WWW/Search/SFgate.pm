#!/usr/local/bin/perl

# contributed from Paul Lindner <lindner@itu.int>

=head1 NAME

WWW::Search::SFgate - class for searching SFgate/Wais search engine

=head1 SYNOPSIS

    require WWW::Search;
    $search = new WWW::Search('SFgate');

=head1 DESCRIPTION

This class is a SFgate specialization of WWW::Search.  It queries and
interprets searches based on SFgate, which is available at
F<http://ls6-www.informatik.uni-dortmund.de/SFgate/welcome.html>

This class exports no public interface; all interaction should be
done through WWW::Search objects.

This object rewrites URLs to use the preformatted, verbose output
format of SFgate.  This allows it to get the 'score' and 'size'
information easily.  The url portions it rewrites are 'verbose=1' 
and 'listenv=pre'.

=head1 OPTIONS

This search supports standard WWW::Search arguments

=over 8

=item search_url

The SFgate URL to search.  This usually looks like
F<http://somehost/cgi-bin/SFgate>

=item search_args

The arguments used for the search engine, separate them by &.

=back

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>,

=head1 AUTHOR

C<WWW::Search::SFgate> is written by Paul Lindner, <lindner@itu.int>

=head1 BUGS

Things not supported: $result->raw()

=head1 COPYRIGHT

Copyright (c) 1997,98 by the United Nations Administrative Committee 
on Coordination (ACC)

All rights reserved.

=cut

package WWW::Search::SFgate;

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
	"http://www.itu.int/SFgate/scripts/SFgate.cgi?application=itu&database=local/WWW/www-pages&tie=and&verbose=1&text=%s";
    
    if (defined($native_opt)) {
	#print "Got " . join(' ', keys(%$native_opt)) . "\n";
	# Process options..

	if ($self->{'search_url'} && $native_opt->{'search_args'}) {
	    $native_url = $native_opt->{'search_url'} . "?" . $native_opt->{'search_args'};
	}

	$debug = 1 if ($native_opt->{'search_debug'});
    } 

    $native_url = $default_native_url if (!$native_url);

    ## Get the system into a mode we can parse..
    $native_url =~ s/listenv=(table|dl)/listenv=pre/i;
    $native_url .= "&listenv=pre" if ($native_url !~ /listenv=pre/i);
    $native_url =~ s/verbose=0/verbose=1/i;
    $native_url .= "&verbose=1" if ($native_url !~ /verbose=1/i);

    ## Change behaviour depending on 'search_how'
    my $how = $self->{'search_how'};
    if (defined($how)) {
	if ($how =~ /any/) {
	    ## remove any tieinternal from the query string
	    $native_url =~ s/tieinternal=[^&]+(&?)/$1/ig;
	} elsif ($how =~ /all/) {
	    ## change tieinternal to and, or add it..
	    $native_url =~ s/tieinternal=[^&]+/tieinternal=and/ig;
	    if ($native_url !~ /tieinternal/) {
		$native_url .= "&tieinternal=and";
	    }
	} elsif ($how =~ /phrase/) {
	    $native_query =~ s/[\'\"]+//g;
	    $native_query =~ s/\+/ /g;
	    $native_query = "'$native_query'";
	} elsif ($how =~ /boolean/) {
	    ## Leave the same..
	}
    }
    $native_url =~ s/%s/$native_query/g; # Substitute search terms...
    $native_url =~ s/%n/40/g; # Substitute num hits...

    $native_url .= "&maxhits=40" if ($native_url !~ /maxhits=/);

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

    # fast exit if already done
    return undef if (!defined($self->{_next_url}));

    # get some
    my($method) = $self->{search_method};
    $method = 'GET' unless $method;

    print $method . $self->{_next_url} . "\n" if ($debug);

    my($response) = $self->http_request($method,
					$self->{_next_url});

    $self->{response} = $response;

    if (!$response->is_success) {
	#print $response->as_string();
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
    while ($#lines > -1) {
	$_ = shift(@lines);
	if ((m,^<B>\d+:</B>.*<A,) &&
	    (m,<A HREF=\"([^\"]+)\">(.*)</A>,i)) {
	    #print "Found $1" . $self->{_next_url} . "<BR>\n";
	    $hits_found++;
	    $url = $1;
	    my($hittitle) = $2;

	    $url =~ s,http:/cgi-bin,/cgi-bin,i;	# weird sfgate thing..
	    $url =~ s,http:/([^/]),/$1,i;	# weird sfgate thing..
	    my($linkobj) = new URI::URL $url, $self->{_next_url};

	    my($hit) = new WWW::SearchResult;
	    $hit->add_url($linkobj->abs->as_string);
	    $hit->title($hittitle);

	    my ($other) = shift(@lines);
	    $other =~ s,</?B>,,ig;
	    $other =~ s,\s+, ,g;

	    $other =~ m,Score: (\d+),i;

	    $hit->score($1);
	    $hit->normalized_score($1);

	    $other =~ m/Size: ([0-9\.]+)/;
	    $size = $1;
	    $size = $size * 1024 if ($other =~ /kbytes/);

	    $hit->size($size);

	    push(@{$self->{cache}}, $hit);
	}
    }
    $self->approximate_result_count($hits_found);
    $self->{_next_url} = undef;

    return($hits_found);
}


1;

__END__


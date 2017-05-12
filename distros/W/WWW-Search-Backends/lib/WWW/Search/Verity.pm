#!/usr/local/bin/perl

# contributed from Paul Lindner <lindner@reliefweb.int>

=head1 NAME

WWW::Search::Verity - class for searching Verity


=head1 SYNOPSIS

    require WWW::Search;
    $search = new WWW::Search('Verity');


=head1 DESCRIPTION

Not documented.

=cut

package WWW::Search::Verity;

use strict;
use warnings;

use base 'WWW::Search';

our
$VERSION = do { my @r = ( q$Revision: 1.4 $ =~ /\d+/g ); sprintf "%d." . "%03d" x $#r, @r };

use Carp ();
use WWW::SearchResult;

my($Debug) = 0;

sub native_setup_search {
    my($self, $native_query, $native_opt) = @_;
    my($native_url);
    my($default_native_url) =
	"http://www.fao.org/bin/v_search.dll?Action=Search&qparser=fullText&query=%s&srchButton=Search";
    
    if (defined($native_opt)) {
	#print "Got " . join(' ', keys(%$native_opt)) . "\n";
	# Process options..
	# Substitute query terms for %s...

	if ($self->{'search_url'} && $native_opt->{'search_args'}) {
	    $native_url = $native_opt->{'search_url'} . "?" . $native_opt->{'search_args'};
	}
    } 

    
    $native_url = $default_native_url if (!$native_url);

    $native_url =~ s/%s/$native_query/g; # Substitute search terms...

    $self->user_agent();
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

    # get some
    print "GET " . $self->{_next_url} . "\n" if ($Debug);
    my($response) = $self->http_request($self->{search_method}, 
					$self->{_next_url});

    $self->{response} = $response;
    if (!$response->is_success) {
	print "Some problem\n" if ($Debug);
	return undef;
    };
    # parse the output
    use HTML::TreeBuilder;

    my $results = $response->content();

    my($h) = new HTML::TreeBuilder;
    $h->parse($results);

    for (@{ $h->extract_links(qw(a)) }) {
	my($link, $linkelem) = @$_;
	
	if (($linkelem->parent->starttag() =~ /^<TD/) &&
	     ($linkelem->parent->endtag()   eq '</TD>')) {

	    my($linkobj)       = new URI::URL $link, $self->{_next_url};
	    $hits_found++;

	    my($hit) = new WWW::SearchResult;
	    $hit->add_url($linkobj->abs->as_string());
	    $hit->title(join(' ',@{$linkelem->content}));
	    $hit->normalized_score($score);

	    $hit->score($score);
	    # Find the score....  Ack! Uglyness..
	    my(@s) = @{$linkelem->parent->parent->content};
	    $s = join(' ', @{$s[0]->content}) . "\n";
	    $hit->score($s);

	    $hit->normalized_score($s * 1000.0);


	    push(@{$self->{cache}}, $hit);
		
	}
    }
    $self->approximate_result_count($hits_found);
    $self->{_next_url} = undef;
    return($hits_found);
}

1;

__END__


#!/usr/local/bin/perl

=head1 NAME

WWW::Search:: FolioViews  -  class for searching Folio Views

=head1 SYNOPSIS

    require WWW::Search;
    $search = new WWW::Search('FolioViews');

=head1 DESCRIPTION

This class is an Folio Views specialization of
WWW::Search.  It queries and interprets searches based on Folio
Views, which is available at F<http://www.openmarket.com>

This class exports no public interface; all interaction should be done
through WWW::Search objects.

=head1 OPTIONS

This search supports sytandard WWW::Search arguments

=over 8

=item search_url

The Folio Views URL to search.  This usually looks like
F<http://somehost/.../cgi-bin/search2.pl>

=item search_args

The arguments used for the search engine, separate them by &.

=back

=head1 SEE ALSO

To make new back-ends, see L<WWW::Search>,

=head1 AUTHOR

C<WWW::Search::FolioViews> is written by Paul Lindner, <lindner@itu.int>,
Nicholas Sapirie <sapirie@unicc.org>

=head1 COPYRIGHT

Copyright (c) 1998 by the United Nations Administrative Committee on
Coordination (ACC)

All rights reserved.

=cut

package WWW::Search::FolioViews;

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
	"http://www.unhcr.ch/refworld/cgi-bin/search2.pl?keywords=%s&index=/www/data/WWW/unhcr/refworld/index/all.swish&maxhits=%n";
    
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

    my ($fvtitle, $fvurl, $fvsize, $fvscore) = ('', '', 0, 0, 0);
    while ($#lines > -1) {
      $hits_found++;
      $_ = shift(@lines);
      $backup = $_;
      if ($step == 0) {
        if ($_ =~ m/^<TR><TD valign=top/) {
          $_ =~ s/<font size=2>/%%/;
          $_ =~ s/^.*%%//;
          $_ =~ s/<\/font>/%%/;
          $_ =~ s/%%.*$//;
          chomp;
          $fvscore = $_;
          $_ = $backup;
          $_ =~ s/HREF="/%%/;
          $_ =~ s/^.*%%//;
          $_ =~ s/">/%%/;
          $_ =~ s/%%.*$//;
          chomp;
          $fvurl = $_;
          $_ = $backup;
          $_ =~ s/">/%%/;
          $_ =~ s/^.*%%//;
          $_ =~ s/<\/A>//;
          chomp;
          $fvtitle = $_;
          $step = 1;
        }
      }
      if ($step == 1) {
        if ($_ =~ m/^<\/font>/) {
          $_ =~ s/align=right>/%%/;
          $_ =~ s/^.*%%//;
          $_ =~ s/<\/font>/%%/;
          $_ =~ s/%%.*$//;
          chomp;
          $fvsize = $_;
          $step = 0;
  
          my($hit) = new WWW::SearchResult;

          # Change to absolute url..
          my($linkobj) = new URI::URL $fvurl, $self->{_next_url};
          $hit->add_url($linkobj->abs->as_string);
          $hit->title($fvtitle);
          $hit->size($fvsize);
          $hit->score($fvscore);
          $hit->normalized_score($fvscore);

          push(@{$self->{cache}}, $hit);
        }
      }
    }
    $self->approximate_result_count($hits_found);
    $self->{_next_url} = undef;

    return($hits_found);
}


1;

__END__


package WWW::Search::AOL;

use warnings;
use strict;

use 5.008;

require WWW::Search;

use WWW::SearchResult;
use Encode;

use Scalar::Util ();

=head1 NAME

WWW::Search::AOL - backend for searching search.aol.com

=head1 NOTE

This module currently does not work. I'll fix it if there's interest to
fix it.

=head1 VERSION

Version 0.0107

=cut

our $VERSION = '0.0107';

use vars qw(@ISA);

@ISA=(qw(WWW::Search));

=head1 SYNOPSIS

This module provides a backend of L<WWW::Search> to search using
L<http://search.aol.com/>.

    use WWW::Search;

    my $oSearch = WWW::Search->new("AOL");

=head1 FUNCTIONS

All of these functions are internal to the module and are of no concern
of the user.

=head2 native_setup_search()

This function sets up the search.

=cut

sub native_setup_search
{
    my ($self, $native_query, $opts) = @_;

    $self->{'_hits_per_page'} = 10;

    $self->user_agent('non-robot');

    $self->{'_next_to_retrieve'} = 1;

    $self->{'search_base_url'} ||= 'http://search.aol.com';
    $self->{'search_base_path'} ||= '/aolcom/search';

    if (!defined($self->{'_options'}))
    {
        $self->{'_options'} = +{
            'query' => $native_query,
            'invocationType' => 'topsearchbox.webhome',
        };
    }
    my $self_options = $self->{'_options'};

    if (defined($opts))
    {
        foreach my $k (keys %$opts)
        {
            if (WWW::Search::generic_option($k))
            {
                if (defined($opts->{$k}))
                {
                    $self->{$k} = $opts->{$k};
                }
            }
            else
            {
                if (defined($opts->{$k}))
                {
                    $self_options->{$k} = $opts->{$k};
                }
            }
        }
    }

    $self->{'_next_url'} = $self->{'search_base_url'} . $self->{'search_base_path'} . '?' . $self->hash_to_cgi_string($self_options);
    $self->{'_AOL_first_retrieve_call'} = 1;
}

=head2 parse_tree()

This function parses the tree and fetches the results.

=cut

sub _no_hits
{
    my $self = shift;

    $self->approximate_result_count(0);
    $self->{'_AOL_no_results_found'} = 1;
    return 0;
}

sub parse_tree
{
    my ($self, $tree) = @_;

    if ($self->{'_AOL_no_results_found'})
    {
        return 0;
    }

    if ($self->{'_AOL_first_retrieve_call'})
    {
        $self->{'_AOL_first_retrieve_call'} = undef;

        my $nohit_div = $tree->look_down("_tag", "div", "class", "NH");

        if (defined($nohit_div))
        {
            if (($nohit_div->as_text() =~ /Your search for/) &&
                ($nohit_div->as_text() =~ /returned no results\./)
               )
            {
                return $self->_no_hits();
            }
        }

        my $wr_div = $tree->look_down("_tag", "div", "class", "BB");

        if (!defined($wr_div))
        {
            return $self->_no_hits();
        }

        # A word separator that includes whitespace and &nbsp; (\x{a0}.
        my $word_sep = qr/[\s\x{a0}]+/;

        if (my ($n) =
            (
                $wr_div->as_text() =~
                m/of${word_sep}about${word_sep}([\d,]+)/
            )
        )
        {
            $n =~ tr/,//d;
            $self->approximate_result_count($n);
        }
    }

=begin Removed

    my @h1_divs = $tree->look_down("_tag", "div", "class", "h1");
    my $requested_div;
    foreach my $div (@h1_divs)
    {
        my $h1 = $div->look_down("_tag", "h1");
        if ($h1->as_text() eq "web results")
        {
            $requested_div = $div;
            last;
        }
    }
    if (!defined($requested_div))
    {
        die "Could not find div. Please report the error to the author of the module.";
    }

    my $r_head_div = $requested_div->parent();
    my $r_web_div = $r_head_div->parent();

=end Removed

=cut

    my $r_web_div = $tree->look_down("_tag", "ul", "content", "MSL");
    my @results_divs = $r_web_div->look_down("_tag", "li", "about", qr{^r\d+$});
    my $hits_found = 0;
    foreach my $result (@results_divs)
    {
        if ($result->attr('about') !~ m/^r(\d+)$/)
        {
            die "Broken Parsing. Please contact the author to fix it.";
        }
        my $id_num = $1;
        my $desc_tag = $result->look_down("_tag", "p", "property", "f:desc");
        my $a_tag = $result->look_down("_tag", "a", "class", "find");
        my $hit = WWW::SearchResult->new();
        $hit->add_url($a_tag->attr("href"));
        $hit->description($desc_tag->as_text());
        $hit->title($a_tag->as_text());
        push @{$self->{'cache'}}, $hit;
        $hits_found++;
    }

    # Get the next URL
    {
        my $span_next_page = $tree->look_down("_tag", "span", "class", "gspPageNext");
        my @a_tags = $span_next_page->look_down("_tag", "a");
        # The reverse() is there because it seems the "next" link is at
        # the end.
        foreach my $a_tag (reverse(@a_tags))
        {
            if ($a_tag->as_text() =~ "Next")
            {
                $self->{'_next_url'} =
                    $self->absurl(
                        $self->{'_prev_url'},
                        $a_tag->attr('href')
                    );
                last;
            }
        }
    }
    return $hits_found;
}


=begin Removed

=head2 preprocess_results_page()

The purpose of this function was to decode the HTML text as returned by
search.aol.com as UTF-8. But it seems recent versions of WWW::Search already
have a similar mechanism.

sub preprocess_results_page
{
    my $self = shift;
    my $contents = shift;

    return decode('UTF-8', $contents);
}

=end Removed

=cut

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

Funded by L<http://www.deviatemedia.com/> and
L<http://www.redtreesystems.com/>.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-www-search-aol@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Search-AOL>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

Funded by L<http://www.deviatemedia.com/> and
L<http://www.redtreesystems.com/>.

=head1 DEVELOPMENT

Source code is version-controlled in a Subversion repository in Berlios:

L<http://svn.berlios.de/svnroot/repos/web-cpan/WWW-Search/trunk/>

One can find the most up-to-date version there.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Shlomi Fish, all rights reserved.

This program is released under the following license: MIT X11 (a BSD-style
license).

=cut

1; # End of WWW::Search::AOL

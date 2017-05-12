package WWW::Search::MSN;

use warnings;
use strict;

use 5.008;

require WWW::Search;

use WWW::SearchResult;
use Encode;

use Scalar::Util ();

=head1 NAME

WWW::Search::MSN - backend for searching search.msn.com

=head1 VERSION

Version 0.0202

=cut

our $VERSION = '0.0202';

use vars qw(@ISA);

@ISA=(qw(WWW::Search));

=head1 WARNING! THIS MODULE IS DEPRECATED

You should be using L<Bing::Search> instead which uses the API.

=head1 SYNOPSIS

This module provides a backend of L<WWW::Search> to search using
L<http://search.msn.com/>.

    use WWW::Search;

    my $oSearch = WWW::Search->new("MSN");

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

    $self->user_agent()->default_header('Accept-Language' => "en");

    $self->{'_next_to_retrieve'} = 1;

    $self->{'search_base_url'} ||= 'http://search.msn.com';
    $self->{'search_base_path'} ||= '/results.aspx';

    if (!defined($self->{'_options'}))
    {
        $self->{'_options'} = +{
            'q' => $native_query,
            'FORM' => "PORE",
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
    $self->{'_MSN_first_retrieve_call'} = 1;
}

=head2 parse_tree()

This function parses the tree and fetches the results.

=cut

sub parse_tree
{
    my ($self, $tree) = @_;

    if ($self->{'_MSN_first_retrieve_call'})
    {
        $self->{'_MSN_first_retrieve_call'} = undef;

        my $header_div = $tree->look_down("_tag", "div", "id", "results_area");

        if (!defined($header_div))
        {
            return 0;
        }
        my $h5 = $header_div->look_down("_tag", "span", "id", "count");

        if (!defined($h5))
        {
            return 0;
        }

        if ($h5->as_text() =~ m{^\d+-\d+\s+of\s+([\d,]+)\s+results})
        {
            my $n = $1;
            $n =~ tr/,//d;
            $self->approximate_result_count($n);
        }
    }

    my $results_div = $tree->look_down("_tag", "div", "id", "results");
    my $results_ul = $results_div->look_down("_tag", "ul");
    my @items;
    @items = (grep { Scalar::Util::blessed($_) && ($_->tag() eq "li") } $results_ul->content_list());

    my $hits_found = 0;
    foreach my $item (@items)
    {
        my $h3 = $item->look_down("_tag", "h3");
        my ($a_tag) = (grep { $_->tag() eq "a" } $h3->content_list());
        my ($p_tag) = (grep { $_->tag() eq "p" } $item->content_list());
        my $url = $a_tag->attr("href");

        my $hit = WWW::SearchResult->new();
        $hit->add_url($url);
        $hit->title($a_tag->as_text());
        $hit->description(defined($p_tag) ? $p_tag->as_text() : "");
        push @{$self->{'cache'}}, $hit;
        $hits_found++;
    }

    # Get the next URL
    {
        my $pagination_div =
            $tree->look_down("_tag", "div", "class", "sb_pag");
        if ($pagination_div)
        {
            my ($a_tag) = $pagination_div->look_down(
                "_tag", "a", "class", "sb_pagN"
            );

            if ($a_tag)
            {
                $self->{'_next_url'} =
                    $self->absurl(
                            $self->{'_prev_url'},
                            $a_tag->attr('href')
                        );
            }
        }
    }
    return $hits_found;
}

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/> .

Funded by L<http://www.deviatemedia.com/> and
L<http://www.redtreesystems.com/>.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-www-search-msn@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Search-MSN>.
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

1; # End of WWW::Search::MSN

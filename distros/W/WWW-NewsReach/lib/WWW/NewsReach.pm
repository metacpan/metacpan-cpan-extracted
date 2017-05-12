# ABSTRACT: Perl wrapper for the NewsReach API

package WWW::NewsReach;

our $VERSION = '0.06';

use Moose;

use LWP::UserAgent;
use XML::LibXML;
use Data::Dump qw( pp );

use WWW::NewsReach::NewsItem;
use WWW::NewsReach::Client;

my $API_BASE = 'http://api.newsreach.co.uk/';

has api_key => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has ua => (
    is         => 'ro',
    isa        => 'WWW::NewsReach::Client',
    lazy_build => 1,
);

has api_url => (
    is         => 'ro',
    isa        => 'Str',
    lazy_build => 1,
);

has news_url => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

has comments_url => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

has categories_url => (
    is       => 'rw',
    isa      => 'Str',
    required => 0,
);

# Construct some of the API URLs based on the root API response
# This is definitely slow but it's what they recommend in the docs:
#
# "It doesn't intend to imply how the API should be accessed.
# Your code should only have knowledge about the Base URL and API Key.
# Do not hard code resource URL logic into your software. Rather it should
# be discovered from the Root of the API."
#
# http://support.newsreach.co.uk/index.php?title=Reference

sub BUILD {
    my $self     = shift;
    my ( $args ) = @_;

    my $resp = $self->ua->request( $self->api_url );
    my $xp   = XML::LibXML->new->parse_string( $resp );
    # Use XPath to find the element attributes from the XML response
    my $news_url       = $xp->findnodes('//news/@href')->[0]->textContent;
    my $comments_url   = $xp->findnodes('//comments/@href')->[0]->textContent;
    my $categories_url = $xp->findnodes(
        '//categoryDefinitions/@href'
    )->[0]->textContent;

    $self->news_url( $news_url );
    $self->comments_url( $comments_url );
    $self->categories_url( $categories_url );

}

sub _build_ua {
    my $self = shift;

    return WWW::NewsReach::Client->new;
}

sub _build_api_url {
    my $self = shift;

    return $API_BASE . $self->api_key;
}



sub get_news {
    my $self = shift;

    my $resp = $self->ua->request( $self->news_url );

    my $news;
    my $xp = XML::LibXML->new->parse_string( $resp );
    foreach ($xp->findnodes('//newsListItem')) {
        my $id  = $_->find('id')->[0]->textContent;
        my $xml = $self->_get_news_item_xml( $id );
        push @$news, WWW::NewsReach::NewsItem->new_from_xml( $xml );
    }

    return wantarray ? @$news : $news;
}

sub _get_news_item_xml {
    my $self = shift;
    my ( $id ) = @_;

    my $news_item_url = $self->news_url . $id;
    my $resp = $self->ua->request( $news_item_url );
    my $xml  = XML::LibXML->new->parse_string( $resp );

    return $xml;
}


1;

__END__
=pod

=head1 NAME

WWW::NewsReach - Perl wrapper for the NewsReach API

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    my $nr = WWW::NewsReach->new({ api_key => $api_key })

    my $news = $nr->get_news;

    foreach ( @{$news} ) {
        my $comments   = $news->comments;
        my $categories = $news->categories;
        my $photos     = $news->photos;
    }

=head1 DESCRIPTION

WWW::NewsReach is a simple Perl wrapper for the NewsReach API. It provides access
to individual news articles via the get_news() method.

Each news article [may] have associated comments, categories, and photos. These, if
present will be associated with the article and can be accessed.

Most of the non-optional data the API returns has been modelled by this wrapper but
no guarantees are made that ALL data is modelled.

=head1 METHODS

=head2 WWW::NewsReach->new({ api_key => $api_key })

Return a new WWW::NewsReach object.

=head2 $nr->get_news();

Get a list of NewsItems from NewsReach.

Returns a list of WWW::NewsReach::NewsItem objects in list context or a referrence
to the list in scalar context.

=head1 SEE ALSO

L<http://newsreach.co.uk/>
L<http://support.newsreach.co.uk/index.php?title=Reference>

=head1 ACKNOWLEDGEMENTS

Much of the design of this module was inspired by L<Net::Songkick>. Advice and
feedback was also provided by Kristian Flint.

=head1 AUTHOR

Adam Taylor <ajct@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Taylor.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


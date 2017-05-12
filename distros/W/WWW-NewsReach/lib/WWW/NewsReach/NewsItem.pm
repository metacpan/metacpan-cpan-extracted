# ABSTRACT: Model a news article in the NewsReach API
package WWW::NewsReach::NewsItem;

our $VERSION = '0.06';

use Moose;

use XML::LibXML;
use DateTime;
use DateTime::Format::ISO8601;

use WWW::NewsReach::Photo;
use WWW::NewsReach::Category;
use WWW::NewsReach::Comment;
use WWW::NewsReach::Client;

has $_ => (
    is  => 'ro',
    isa => 'Str',
) for qw(headline text state extract);

has $_ => (
    is  => 'ro',
    isa => 'DateTime',
) for qw(publishDate lastModifiedDate);

has id => (
    is  => 'ro',
    isa => 'Int',
);

has photos => (
    is  => 'ro',
    isa => 'ArrayRef[WWW::NewsReach::Photo]',
);

has categories => (
    is  => 'ro',
    isa => 'ArrayRef[WWW::NewsReach::Category]',
);

has comments => (
    is  => 'ro',
    isa => 'ArrayRef[WWW::NewsReach::Comment]',
);


sub new_from_xml {
    my $class = shift;
    my ( $xml ) = @_;

    my $self = {};

    foreach (qw[id headline text state extract]) {
        # extract is optional
        eval {
            $self->{$_} = $xml->findnodes("//$_")->[0]->textContent;
        };
    }

    my $iso8601 = DateTime::Format::ISO8601->new;
    foreach (qw[publishDate lastModifiedDate]) {
        my $dt_str    = $xml->findnodes("//$_")->[0]->textContent;
        my $dt        = $iso8601->parse_datetime( $dt_str );
        $self->{$_} = $dt;
    }

    my $photo_xml = $class->_get_related_xml( $xml, 'photos' );
    foreach ( $photo_xml->findnodes('//photo') ) {
        push @{$self->{photos}},
            WWW::NewsReach::Photo->new_from_xml( $_ );
    }

    my $comment_xml = $class->_get_related_xml( $xml, 'comments' );
    foreach ( $comment_xml->findnodes('//commentListItem') ) {
        push @{$self->{Comment}},
            WWW::NewsReach::Comment->new_from_xml( $_ );
    }

    my $category_xml = $class->_get_related_xml( $xml, 'categories' );
    foreach ( $category_xml->findnodes('//category') ) {
        push @{$self->{categories}},
            WWW::NewsReach::Category->new_from_xml( $_ );
    }

    return $class->new( $self );
}

sub _get_related_xml {
    my $class = shift;
    my ( $xml, $type ) = @_;

    my $url = $xml->findnodes("//$type/".'@href')->[0]->textContent;

    my $ua = WWW::NewsReach::Client->new;
    my $resp = $ua->request( $url );
    my $related_xml = XML::LibXML->new->parse_string( $resp );

    return $related_xml;
}

1;

__END__
=pod

=head1 NAME

WWW::NewsReach::NewsItem - Model a news article in the NewsReach API

=head1 VERSION

version 0.06

=head1 METHODS

=head2 WWW::NewsReach::NewsItem->new_from_xml

Creates a new WWW::NewsReach::NewsItem object from an XML::Element object that
has been created from an <newsItem> ... </newsItem> element in the XML returned
from a NewsReach API request.

=head1 AUTHOR

Adam Taylor <ajct@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Taylor.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


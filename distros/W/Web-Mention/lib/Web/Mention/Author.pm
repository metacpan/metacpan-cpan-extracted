package Web::Mention::Author;

use Moose;
use MooseX::Types::URI qw(Uri);
use MooseX::ClassAttribute;
use Try::Tiny;
use LWP::UserAgent;
use List::Util qw(first);

use Web::Microformats2::Parser;

has 'name' => (
    is => 'ro',
    isa => 'Str',
);

has 'url' => (
    is => 'ro',
    isa => Uri,
    coerce => 1,
);

has 'photo' => (
    is => 'ro',
    isa => Uri,
    coerce => 1,
);

class_has 'parser' => (
    is => 'ro',
    isa => 'Web::Microformats2::Parser',
    default => sub { Web::Microformats2::Parser->new },
);

sub new_from_mf2_document {
    my $class = shift;
    my ($doc) = @_;

    # This method implements the Indieweb Authorship Algorithm.
    # https://indieweb.org/authorship#How_to_determine
    # The quoted comments below are direct quotes from that page
    # (as of spring 2018).

    # "Start with a particular h-entry to determine authorship for,
    # and no author."

    my $author;
    my $author_page;

    my $h_entry = $doc->get_first( 'h-entry' );

    # "If no h-entry, then there's no post to find authorship for, abort."
    unless ( $h_entry ) {
        return;
    }

    # "If the h-entry has an author property, use that."
    $author = $h_entry->get_property( 'author' );

    # "Otherwise if the h-entry has a parent h-feed with author property,
    # use that."
    if (
        not ( $author )
        && $h_entry->parent
        && ( $h_entry->parent->has_type ('h-feed') )
    ) {
        $author = $h_entry->parent->get_property( 'author' );
    }

    # "If an author property was found:"

    #   "If it has an h-card, use it, exit."
    if (
        defined $author
        && blessed( $author )
        && ( $author->has_type( 'h-card' ) )
    ) {
        return $class->_new_with_h_card( $author );
    }

    #   "Otherwise if author property is an http(s) URL,
    #   let the author-page have that URL."
    if ( defined $author ) {
        try {
            $author_page = URI->new( $author );
            unless ( $author_page->schema =~ /^http/ ) {
                undef $author_page;
            }
        };
    }

    #   "Otherwise use the author property as the author name, exit."
    if ( $author and !$author_page ) {
        return $class->new( name => $author );
    }

    # "If there is an author-page URL:"

    #   "Get the author-page from that URL and parse it for Microformats-2."
    my $ua = LWP::UserAgent->new;
    my $response = $ua->get( $author_page );
    my $author_doc = $class->parser->parse( $response );

    #   "If author-page has 1+ h-card with url == uid == author-page's URL,
    #   then use first such h-card, exit."
    my @h_cards = grep{ $_->has_type( 'h-card' ) } $doc->all_items;
    for my $h_card ( @h_cards ) {
        my $urls_ref = $h_card->get_properties( 'url' );
        my $uids_ref = $h_card->get_properties( 'uid' );
        if (
            first { $_ eq $author_page->as_string } @$urls_ref
            && first { $_ eq $author_page->as_string } @$uids_ref
        ) {
            return $class->_new_with_h_card( $h_card );
        }
    }

    # XXX Skipping the "rel-me"-based test.

    #   "if the h-entry's page has 1+ h-card with url == author-page URL,
    #   use first such h-card, exit."
    for my $h_card ( @h_cards ) {
        my $urls_ref = $h_card->get_properties( 'url' );
        if (
            first { $_ eq $author_page->as_string } @$urls_ref
        ) {
            return $class->_new_with_h_card( $h_card );
        }
    }

    return;

}

sub new_from_html {
    my $class = shift;
    my ($html) = @_;

    my $doc = $class->parser->parse( $html );

    return $class->new_from_mf2_document( $doc );

}

sub _new_with_h_card {
    my ( $class, $h_card ) = @_;

    my %constructor_args;

    foreach ( qw (name url photo ) ) {
    	my $value = $h_card->get_properties( $_ );
    	if ( defined $value && defined $value->[0] ) {
	        $constructor_args{ $_ } = $value->[0];
    	}
    }

    return $class->new( %constructor_args );
}

1;

=pod

=head1 NAME

Web::Mention::Author - The author of a webmention's source document

=head1 DESCRIPTION

An object of this class represents the author of a webmention -- or,
more specifically, the author of the document that a given webmention
points to as its source.

It implements the IndieWeb I<authorship protocol>, as defined here:
L<https://indieweb.org/authorship#How_to_determine>

It is not expected that you'll build objects of this class yourself.
Rather, you'll receive and query them by way of the C<author()> method
of Web::Mention objects.

=head1 METHODS

=head2 Object Methods

=head3 name

 $name = $author->name;

Returns the author's name.

=head3 url

 $author_url = $author->url;

Returns the author's URL as a L<URI> object, or undef.

=head3 photo

 $photo_url = $author->photo;

Returns the author's photo (avatar) as a L<URI> object, or undef.

=head1 NOTES AND BUGS

This software is B<alpha>; its author is still determining how it wants
to work, and its interface might change dramatically.

(Honestly, the Web::Mention namespace might not even be the best place
for it!)

Its implementation of the authorship algorithm is I<very> incomplete.
The author only got as far as being able to parse typical output from
L<http://brid.gy> and then stopped. Tsk tsk.

=head1 AUTHOR

Jason McIntosh (jmac@jmac.org)

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018 by Jason McIntosh.

This is free software, licensed under:

  The MIT (X11) License

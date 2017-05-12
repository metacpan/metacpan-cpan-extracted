package XML::Atom::Ext::Media;
our $VERSION = '0.092840';


# ABSTRACT: An XML::Atom extenstion for the yahoo Media RSS extension

use strict;
use warnings;

use base qw( XML::Atom::Base );

use XML::Atom::Feed;

use XML::Atom::Ext::Media::Group;
use XML::Atom::Ext::Media::Content;
use XML::Atom::Ext::Media::Thumbnail;



BEGIN {
    XML::Atom::Entry->mk_object_list_accessor(
        group => 'XML::Atom::Ext::Media::Group',
        'media_groups',
    );
# XXX: This conflicts with <entry><content>, how to restrict to NS?
#    XML::Atom::Entry->mk_object_list_accessor(
#        content => 'XML::Atom::Ext::Media::Content'
#    );
}


sub element_ns {
     return XML::Atom::Namespace->new(
        "media" => q{http://search.yahoo.com/mrss/} 
    );
}

1;




=pod

=head1 NAME

XML::Atom::Ext::Media - An XML::Atom extenstion for the yahoo Media RSS extension

=head1 VERSION

version 0.092840

=head1 DESCRIPTION

A for the moment rather crude and simple module for handeling MRSS elements

=head1 SYNOPSIS

    use XML::Atom::Feed;
    use XML::Atom::Ext::Media;

    my $feed = XML::Atom::Feed->new(
        URI->new('http://gdata.youtube.com/feeds/api/users/andreasmarienborg/uploads')
    );

    my ($entry) = $feed->entries;
    my ($media) = $entry->media_groups;
    my $content = $media->default_content;
    my $thumb_url = $media->thumbnail->url;

=head1 IMPLEMENTATION

The L<ATTRIBUTES> we describe here end up on L<XML::Atom::Entry>-objects, except
for L<element_ns>.

=head1 ACKNOWLEDGEMENTS

Thank you to L<XML::Atom::Ext::OpenSearch> for being invaluable aid in figuring out
how to write extension for L<XML::Atom>. Thank you to MIYAGAWA for L<XML::Atom>.

=head1 ATTRIBUTES

=head2 media

Will look for any elements of the type <media:group> (as long as 
xmlns:media='http://search.yahoo.com/mrss/').

In SCALAR context it will return the first sich element, in list context
it will return all such elements as a list.

=head2 media_groups

Like L<media>, but will return a array ref in SCALAR context, and the list
in list context.



=head2 element_ns

Returns the L<XML::Atom::Namespace> object representing our
xmlns:media="http://search.yahoo.com/mrss/">.



=head1 AUTHOR

  Andreas Marienborg <andremar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Andreas Marienborg.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut 



__END__


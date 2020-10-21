package WebService::Blogger::Blog::Entry;
our $VERSION = '0.23';
use warnings;
use strict;

use Moose;
use XML::Simple ();

with 'WebService::Blogger::AtomReading';

# Properties that can be updated in existing entries.
has title           => ( is => 'rw', isa => 'Maybe[Str]' );
has content         => ( is => 'rw', isa => 'Maybe[Str]' );
has categories      => ( is => 'rw', isa => 'ArrayRef[Str]', auto_deref => 1 );

# Read-only properties.
has id              => ( is => 'ro', isa => 'Str' );
has author          => ( is => 'ro', isa => 'Str' );
has published       => ( is => 'ro', isa => 'Str' );
has updated         => ( is => 'ro', isa => 'Str' );
has edit_url        => ( is => 'ro', isa => 'Str' );
has id_url          => ( is => 'ro', isa => 'Str' );
has public_url      => ( is => 'ro', isa => 'Str' );

# Service properties.
has source_xml_tree => ( is => 'ro', isa => 'HashRef', default => sub { {} }, required => 1 );
has blog            => ( is => 'ro', isa => 'WebService::Blogger::Blog', required => 1 );

# Speed Moose up.
__PACKAGE__->meta->make_immutable;


sub BUILDARGS {
    ## Populates object attributes from parsed XML source.
    my $class = shift;
    my %params = @_;

    # Use shorter name for clarity.
    my $tree = $params{source_xml_tree};

    # Extract attributes from the XML tree and return the to be set as
    # attributes.

    return {
        id         => $tree->{id}[0],
        author     => $tree->{author}[0]{name}[0],
        published  => $tree->{published}[0],
        updated    => $tree->{updated}[0],
        title      => $tree->{title}[0]{content},
        content    => $tree->{content}{content},
        public_url => $class->get_link_href_by_rel($tree, 'alternate'),
        id_url     => $class->get_link_href_by_rel($tree, 'self'),
        edit_url   => $class->get_link_href_by_rel($tree, 'edit'),
        categories => [ map $_->{term}, @{ $tree->{category} || [] } ],
        %params,
    };
}


sub xml_for_creation {
    ## Class method. Returns XML for creation of a new entry with given properties.
    my $class = shift;
    my %props = @_;

    # Build data structure to generate XML from.
    my %xml_tree = (
        title => [ {
            content => $props{title},
            type    => 'text',
        } ],
        content => [ {
            content => $props{content},
            type    => 'html',
        } ],
        category => [
            map {
                    scheme => 'http://www.blogger.com/atom/ns#',
                    term   => $_,
                },
                @{ $props{categories} || [] }
        ],
    );
    $class->add_xml_ns(\%xml_tree);

    # Convert data tree to XML.
    return XML::Simple::XMLout(\%xml_tree, RootName => 'entry');
}


sub add_xml_ns {
    ## Adds XML namespace attributes to the given XML hash tree.
    my $class = shift;
    my ($dest) = @_;

    my %xml_ns = (
        ''     => 'http://www.w3.org/2005/Atom',
        ':thr' => 'http://purl.org/rss/1.0/modules/threading/',
        ':gd'  => 'http://schemas.google.com/g/2005',
    );
    while (my ($postfix, $url) = each %xml_ns) {
        $dest->{"xmlns$postfix"} = $url;
    }
}


sub as_xml {
    ## Returns XML string representing the entry.
    my $self = shift;

    # Place attribute values into original data tree. Don't generate an Atom entry anew as
    # Blogger wants us to preserve all original data when updating posts.
    $self->source_xml_tree->{title}[0] = {
        content => $self->title,
        type    => 'text',
    };
    $self->source_xml_tree->{content} = {
        content => $self->content,
        type    => 'html',
    };
    $self->source_xml_tree->{category} = [
        map {
                scheme => 'http://www.blogger.com/atom/ns#',
                term   => $_,
            },
            $self->categories
    ];
    $self->add_xml_ns($self->source_xml_tree);

    # Convert data tree to XML.
    return XML::Simple::XMLout($self->source_xml_tree, RootName => 'entry');
}


sub save {
    ## Saves the entry to blogger.
    my $self = shift;

    my $response = $self->blog->blogger->http_put($self->edit_url => $self->as_xml);
    die 'Unable to save entry: ' . $response->status_line unless $response->is_success;
    return $response;
}


sub delete {
    ## Deletes the entry from server.
    my $self = shift;

    $self->blog->delete_entry($self);
}


1;

__END__

=head1 NAME

WebService::Blogger::Entry - represents blog entry in WebService::Blogger package.

=head1 SYNOPSIS

Please see L<WebService::Blogger>.

=head1 ATTRIBUTES

=head3 C<id>

=over

Unique numeric ID of the entry.

=back

=head3 C<title>

=over

Title of the entry.

=back


=head3 C<content>

=over

Content of the entry. Currently entries are always submitted with
content type set to "html".

=back


=head3 C<author>

=over

Author of the entry, as name only. Editing of this field is currently
not supported by Blogger API.

=back

=head3 C<published>

=over

Time when entry was published, in ISO format.

=back

=head3 C<updated>

=over

Time when entry was last updated, in ISO format.

=back

=head3 C<public_url>

=over

The human-readable, SEO-friendly URL of the entry.

=back

=head3 C<id_url>

=over

The never-changing URL of the entry, based on its numeric ID.

=back

=head3 C<categories>

=over

Categories (tags) of the entry, as array of strings.

=back

=head3 C<blog>

=over

The blog in which entry is published, as instance of WebService::Blogger::Blog

=back

=cut

=head1 METHODS

=over 1

=item new()

Creates new entry. Requires C<blog>, C<content> and C<title> attributes.

=item save()

Saves changes to the entry.

=item delete()

Deltes the entry from server and parent blog object.

=cut

=back

=head1 AUTHOR

Kedar Warriner, C<< <kedar at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-net-google-api-blogger at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WebService-Blogger>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WebService::Blogger

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WebService-Blogger>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WebService-Blogger>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WebService-Blogger>

=item * Search CPAN

L<http://search.cpan.org/dist/WebService-Blogger/>

=back

=head1 ACKNOWLEDGEMENTS

 Many thanks to:
  - Egor Shipovalov who wrote the original version of this module
  - Everyone involved with CPAN.

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Kedar Warriner.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

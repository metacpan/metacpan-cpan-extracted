package WebService::Blogger::Blog;
our $VERSION = '0.22';
use warnings;
use strict;

use Moose;
use XML::Simple ();
use URI::Escape ();
use Encode ();
use WebService::Blogger::Blog::Entry;

with 'WebService::Blogger::AtomReading';

# Blog properties, non-updatable.
has id          => ( is => 'ro', isa => 'Str', required => 1 );
has numeric_id  => ( is => 'ro', isa => 'Str', required => 1 );
has title       => ( is => 'ro', isa => 'Str', required => 1 );
has public_url  => ( is => 'ro', isa => 'Str', required => 1 );
has id_url      => ( is => 'ro', isa => 'Str', required => 1 );
has post_url    => ( is => 'ro', isa => 'Str', required => 1 );

# Service attributes.
has source_xml_tree => ( is => 'ro', isa => 'HashRef', required => 1 );
has blogger         => ( is => 'ro', isa => 'WebService::Blogger', required => 1 );

# Blog entries.
has max_results => ( is => 'rw', isa => 'Num', required => 1, default => 30, );
has entries => (
    is         => 'rw',
    isa        => 'ArrayRef[WebService::Blogger::Blog::Entry]',
    lazy_build => 1,
    auto_deref => 1,
);

# Speed Moose up.
__PACKAGE__->meta->make_immutable;


sub BUILDARGS {
    ## Parses source XML into initial attribute values.
    my $class = shift;
    my %params = @_;

    my $tree = $params{source_xml_tree};
    my $id = $tree->{id}[0];

    # Extract attributes from XML tree and return them to be set in the instance.
    return {
        id         => $id,
        numeric_id => $id =~ /(\d+)$/,
        title      => $tree->{title}[0]{content},
        id_url     => $class->get_link_href_by_rel($tree, 'self'),
        public_url => $class->get_link_href_by_rel($tree, 'alternate'),
        post_url   => $class->get_link_href_by_rel($tree, qr/#post$/),
        %params,
    };
}


sub _build_entries {
    ## Populates the entries attribute, loading all entries for the blog.
    my $self = shift;

    # Search with no parameters.
    return $self->search_entries;
}


sub search_entries {
    ## Returns entries matching search criteria.
    my $self = shift;
    my %params = @_;

    # Construct request URL, incorporating category criteria into it, if given.
    my $url = 'http://www.blogger.com/feeds/' . $self->numeric_id . '/posts/default';
    $url .= '/-/' . join '/', map URI::Escape::uri_escape($_), @{ $params{categories} }
        if $params{categories};

    # Map our parameter names to Blogger's.
    my %params_to_req_args_map = (
        max_results   => 'max-results',
        published_min => 'published-min',
        published_max => 'published-max',
        updated_min   => 'updated-min',
        updated_max   => 'updated-max',
        order_by      => 'orderby',
        offset        => 'start-index',
    );

    # Map our sort mode parameter names to Blogger's.
    my %sort_mode_map = (
        last_modified => 'lastmodified',
        start_time    => 'starttime',
        updated       => 'updated',
    );

    # Populate request arguments hash WRT above mappings.
    my %req_args = (
        alt => 'atom',
    );
    foreach my $param (keys %params_to_req_args_map) {
        my $value = $self->$param if $self->meta->has_attribute($param);
        $value = $params{$param} if exists $params{$param};
        $req_args{$params_to_req_args_map{$param}} = $value if defined $value;
    }
    if (my $sort_mode = $params{sort_by}) {
        $req_args{orderby} = $sort_mode_map{$sort_mode};
    }

    # Execute request and parse the response.
    my $uri_obj = URI->new($url);
    $uri_obj->query_form(%req_args);
    my $response = $self->blogger->http_get($uri_obj);
    my $response_tree = XML::Simple::XMLin($response->content, ForceArray => 1);

    # Return list of entry objects constructed from list of hashes in parsed data.
    my @entries
        = map WebService::Blogger::Blog::Entry->new(
                  source_xml_tree => $_,
                  blog            => $self,
              ),
              @{ $response_tree->{entry} };
    return wantarray ? @entries : \@entries;
}


sub add_entry {
    ## Adds new entry with specified properties to the blog and returns it.
    my $self = shift;
    my %params = @_;

    # Get the XML for creation of new entry and post it to appropriate URL.
    my $creation_xml = WebService::Blogger::Blog::Entry->xml_for_creation(%params);
    my $response = $self->blogger->http_post(
        $self->post_url,
        'Content-Type' => 'application/atom+xml',
        Content        => Encode::encode_utf8($creation_xml),
    );
    die 'Unable to add entry to blog: ' . $response->status_line unless $response->is_success;

    # Create new entry object from the response.
    my $xml_tree = XML::Simple::XMLin($response->content, ForceArray => 1);
    return WebService::Blogger::Blog::Entry->new(source_xml_tree => $xml_tree, blog => $self);
}


sub delete_entry {
    ## Deletes given entry from server as well as list of entries held in blog object.
    my $self = shift;
    my ($entry) = @_;

    # Execute deletion request, with a workaround for proxies blocking DELETE method.
    my $response = $self->blogger->http_post(
        $entry->edit_url,
        'X-HTTP-Method-Override' => 'DELETE',
    );
    die 'Could not delete entry from server: ' . $response->status_line unless $response->is_success;

    # Remove the entry from local list of entries.
    $self->entries([ grep $_ ne $entry, $self->entries ]);
}


sub destroy {
    ## Removes references to the blog from child entries, so they're
    ## no longer circular. Blog object as well as entries can then be
    ## garbage-collected.
    my $self = shift;

    $_->blog(undef) foreach $self->entries;
}


1;

__END__

=head1 NAME

WebService::Blogger::Blog - represents blog entity of Google Blogger service.

=head1 SYNOPSIS

Please see L<WebService::Blogger>.

=head1 DESCRIPTION

This class represents a blog in WebService::Blogger package, and is
not designed to be instantiated directly.

=head1 METHODS

=head3 C<add_entry(%properties)>

=over

Adds given entry to the blog:

 my $new_entry = $blog->add_entry(
     title      => 'New entry',
     content    => 'New content',
     categories => [ 'news', 'testing', 'perl examples' ],
 );

=back

=head3 C<search_entries(%criteria)>

=over

Returns entries matching specified criteria. The following example
contains all possible search conditions:

my @entries = $blog->search_entries(
     published_min => '2010-08-10T23:25:00+04:00'
     published_max => '2010-07-17T23:25:00+04:00',
     updated_min   => '2010-09-17T12:25:00+04:00',
     updated_max   => '2010-09-17T14:00:00+04:00',
     order_by      => 'start_time', # can also be: 'last_modified' or 'updated'
     max_results   => 20,
     offset        => 10,           # skip first 10 entries
);

=back

=head3 C<destroy()>

=over

Removes references to the blog from child entries, so they're no
longer circular. Blog object as well as entries can then be
garbage-collected.

=back

=head1 ATTRIBUTES

=head3 C<id>

=over

Unique ID of the blog, a string in Blogger-specific format as present
in the Atom entry.

=back

=head3 C<numeric_id>

=over

Numeric ID of the blog.

=back

=head3 C<title>

=over

Title of the blog.

=back

=head3 C<public_url>

=over

The human-readable, SEO-friendly URL of the blog.

=back

=head3 C<id_url>

=over

URL of the blog based on its numeric ID. Never changes.

=back

=head3 C<post_url>

=over

URL for publishing new posts.

=back

=head3 C<entries>

=over

List of blog entries, lazily populated.

=back

=head1 AUTHOR

Kedar Warriner, C<< <kedar at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-webservice-blogger at rt.cpan.org>, or through
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


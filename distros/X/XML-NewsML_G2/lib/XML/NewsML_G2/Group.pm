package XML::NewsML_G2::Group;

use Moose;
use XML::NewsML_G2::News_Item;
use namespace::autoclean;

has 'role', isa => 'Str', is => 'ro', required => 1;
has 'mode', isa => 'XML::NewsML_G2::Types::Group_Mode', is => 'rw', default => 'bag';

has 'items', isa =>
    'ArrayRef[XML::NewsML_G2::News_Item|XML::NewsML_G2::Group]',
    is => 'ro', default => sub {[]},
    traits => ['Array'], handles => {add_item => 'push'};


__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::Group - a group of news items (or other groups)

=for test_synopsis
    my ($news_item, $news_item_for_picture);

=head1 SYNOPSIS

    my $group = XML::NewsML_G2::Group->new(role => 'slide');

    $group->add_item($news_item);
    $group->add_item($news_item_for_picture);

=head1 DESCRIPTION

This module is used to group news items within a package item. A group
can contain any number of news items, as well as other groups. The
role is used to inform the receiver of the package item which kind of
content the group contains - the main content of a story, a sidebar, a
slideshow, ...

=head1 ATTRIBUTES

=over 4

=item role

The role of this group, within the package item. The attribute is
required by the NewsML-G2 specification, but currently, IPTC does not
provide a CV for it, so you will have to define a
L<XML::NewsML_G2::Scheme> for yourself and register it with the
L<XML::NewsML_G2::Scheme_Manager>.

=item items

Reference to an array of items contained in this group. Each item must
be a L<XML::NewsML_G2::News_Item> or a L<XML::NewsML_G2::Group>.

=item mode

A group can have one of the following modes: bag, sequential,
alternative. Defaulto to "bag".

=back

=head1 METHODS

=over 4

=item add_item

Takes one or more items to be added to this group.

=back

=head1 AUTHOR

Philipp Gortan  C<< <philipp.gortan@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2014, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.

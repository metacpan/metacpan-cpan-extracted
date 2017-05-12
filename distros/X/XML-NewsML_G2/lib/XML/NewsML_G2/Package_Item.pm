package XML::NewsML_G2::Package_Item;

use Moose;
use namespace::autoclean;
use XML::NewsML_G2::Group;

extends 'XML::NewsML_G2::AnyItem';

has '+nature', default => 'composite';
has 'title', isa => 'Str', is => 'ro';

has 'root_group', isa => 'XML::NewsML_G2::Group', is => 'ro', lazy => 1,
    builder => '_build_root_group';

has 'root_role', isa => 'Str', is => 'ro', default => 'main';
has 'root_id', isa => 'Str', is => 'ro', default => 'root_group';

sub _build_sent {
    return DateTime->now(time_zone => 'local');
}

sub _build_root_group {
    my $self = shift;
    return XML::NewsML_G2::Group->new(role => $self->root_role);
}

sub add_to_root_group {
    my ($self, @items) = @_;
    return $self->root_group->add_item(@items);
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::Package_Item - a package of news items

=for test_synopsis
    my ($prov_apa, $text_item, $pic_item);

=head1 SYNOPSIS

    my $pi = XML::NewsML_G2::Package_Item->new
        (language => 'de', provider => $prov_apa);
    $pi->add_to_root_group($text_item, $pic_item);


=head1 DESCRIPTION

A package item is a collection of news items, that are published
together. The structure of packages is flexible to support nested
groups of items - please see the NewsML-G2 specification for details.

Each package item is built up by one root group, which is an instance
of L<XML::NewsML_G2::Group>.

=head1 ATTRIBUTES

=over 4

=item title
Optional title of the package.

=item root_group

Upon creation of the package item, a new, empty
L<XML::NewsML_G2::Group> is created and stored in the C<root_group>
attribute.

=item root_role

The root group needs a role that specifies the type of content the
package contains. Defaults to 'main'.

=item root_id

All groups are identified by IDs. This attribute is used to name the
root group - all other groups are named automatically. Defaults to
'root_group'.

=back

=head1 METHODS

=over 4

=item add_to_root_group

Use this method to add news items and groups to the root group.

=back

=head1 AUTHOR

Philipp Gortan  C<< <philipp.gortan@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2014, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.

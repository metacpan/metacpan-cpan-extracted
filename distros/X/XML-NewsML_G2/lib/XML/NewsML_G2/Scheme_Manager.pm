package XML::NewsML_G2::Scheme_Manager;

use Moose;
use Carp;
use namespace::autoclean;

my @attrs = (qw(desk hltype role ind geo org topic crel crol drol svc
isbn ean isrol nprov ninat stat sig iso3166_1a2 genre isin medtop rnd
colsp adc group pgrmod copyright_holder));

foreach (@attrs) {
    has $_, isa => 'XML::NewsML_G2::Scheme', is => 'rw';
}

# public methods

sub get_all_schemes {
    my $self = shift;

    return grep {defined} map {$self->$_()} sort $self->meta->get_attribute_list();
}

sub build_qcode {
    my ($self, $name, $value) = @_;
    return unless $value;

    my $getter = $self->can($name) or croak "No schema named '$name'!";
    my $scheme = $getter->($self);
    return unless ($scheme and ($scheme->uri or $scheme->catalog));

    return $scheme->alias . ':' . $value;
}

sub add_qcode_or_literal {
    my ($self, $elem, $name, $value) = @_;
    $self->_add_qcode($elem, $name, $value) or $elem->setAttribute('literal', $name . '#' . $value);
    return 1;
}

sub add_qcode {
    my ($self, $elem, $name, $value) = @_;
    $self->_add_qcode($elem, $name, $value) or die "Specifying a '$name' schema with uri or catalog required\n";
    return 1;
}

sub add_role {
    my ($self, $elem, $name, $value) = @_;

    my $role = $self->build_qcode($name, $value);
    return unless $role;

    $elem->setAttribute('role', $role);
    return 1;
}

# private methods

sub _add_qcode {
    my ($self, $elem, $name, $value) = @_;

    my $qcode = $self->build_qcode($name, $value);
    return unless $qcode;

    $elem->setAttribute('qcode', $qcode);
    return 1;
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

XML::NewsML_G2::Scheme_Manager - hold all L<XML::NewsML_G2::Scheme> instances


=for test_synopsis
    my ($s1, $s2, $s3);

=head1 SYNOPSIS

    my $sm = XML::NewsML_G2::Scheme_Manager->new(desk => $s1, hltype => $s2, svc => $s3);

=head1 ATTRIBUTES

=over 4

=item crel

Scheme for company relations

=item desk

Scheme for editorial desk

=item ean

Scheme for european/international article number

=item geo

Scheme for location information

=item hltype

Scheme for type of headline

=item ind

Scheme for content indicators

=item isbn

Scheme for international standard book number

=item org

Scheme for organisations

=item role

Scheme for editorial note roles

=item svc

Scheme for editorial service

=item topic

Scheme for topics

=item isrol

Scheme for info source role

=item nprov

Scheme for news provder

=item ninat

Scheme for news item nature

=item stat

Scheme for document state

=item sig

Scheme for signals

=item iso3166_1a2

Scheme for country codes

=item genre

Scheme for genres

=item isin

Scheme for ISIN codes

=item medtop

Scheme for media topics

=item rnd

Scheme for renditions

=item colsp

Scheme for colorspaces

=item adc

Scheme for audio channels

=item group

Scheme for groups within a package

=item pgrmod

Scheme for package group mode

=item copyright_holder

Scheme for copyright holder

=back

=head1 METHODS

=over 4

=item get_all_schemes

Returns a list of all registered L<XML::NewsML_G2::Scheme> instances

=item build_qcode

Build a qcode of the given scheme

    $scheme_manager->build_qcode('ninat', 'text');

If the schema does not provide a catalog or URI, creating a qcode is
not possible, and this method will return undef.

=item add_qcode

Add a qcode attribute of the given scheme to the XML element:

    $scheme_manager->add_qcode($element, 'ninat', 'text');

If the schema does not provide a catalog or URI, creating a qcode is
not possible, and this method will die.

=item add_qcode_or_literal

Same as C<add_qcode>, but will create a C<literal> attribute if
creating a qcode is not possible.

=item add_role

If the scheme is defined, add a role attribute to the given XML
element. Else, do nothing.

    $scheme_manager->add_role($element, 'isrol', 'originfo');

=back

=head1 AUTHOR

Philipp Gortan  C<< <philipp.gortan@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013-2014, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.

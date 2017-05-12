package XML::NewsML_G2::Scheme;

use Moose;
use namespace::autoclean;


has 'alias', isa => 'Str', is => 'ro', required => 1;
has 'uri', isa => 'Str', is => 'ro';
has 'catalog', isa => 'Str', is => 'ro';

sub BUILD {
    my $self = shift;
    die "Either uri or catalog is required\n" unless ($self->uri or $self->catalog);
    return;
}

__PACKAGE__->meta->make_immutable;

1;
__END__

=head1 NAME

XML::NewsML_G2::Scheme - a Scheme (controlled vocabulary)

=head1 SYNOPSIS

    my $genre = XML::NewsML_G2::Scheme->new
        (alias => "genre",
         uri => "http://cv.iptc.org/newscodes/genre/",
         catalog => "http://www.iptc.org/std/catalog/catalog.IPTC-G2-Standards_22.xml");

=head1 ATTRIBUTES

=over 4

=item alias

The alias to be used for this scheme in the created output, required.

=item uri

String containing the URI of this scheme

=item catalog

Optional string containing the URI of the catalog containing this scheme

=back

=head1 AUTHOR

Philipp Gortan  C<< <philipp.gortan@apa.at> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2013-2014, APA-IT. All rights reserved.

See L<XML::NewsML_G2> for the license.

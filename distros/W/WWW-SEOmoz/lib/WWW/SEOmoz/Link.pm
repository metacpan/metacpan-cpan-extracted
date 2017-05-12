# ABSTRACT: Class to represent a link returned from the SEOmoz API.
package WWW::SEOmoz::Link;

use Moose;
use namespace::autoclean;

use Carp qw( croak );

our $VERSION = '0.03'; # VERSION


has 'target_url' => (
    isa         => 'Str|Undef',
    is          => 'ro',
);


has 'source_url' => (
    isa         => 'Str|Undef',
    is          => 'ro',
);


has 'link_id' => (
    isa         => 'Int|Undef',
    is          => 'ro',
);


has 'source_url_id' => (
    isa         => 'Int|Undef',
    is          => 'ro',
);


has 'target_url_id' => (
    isa         => 'Int|Undef',
    is          => 'ro',
);

__PACKAGE__->meta->make_immutable;


sub new_from_data {
    my $class = shift;
    my $data  = shift || croak 'Requires a hash ref of data returned from the API';

    return $class->new({
        target_url      => $data->{luuu},
        source_url      => $data->{uu},
        link_id         => $data->{lrid},
        source_url_id   => $data->{lsrc},
        target_url_id   => $data->{ltgt},
    });
}


1;

__END__
=pod

=head1 NAME

WWW::SEOmoz::Link - Class to represent a link returned from the SEOmoz API.

=head1 VERSION

version 0.03

=head1 DESCRIPTION

Class to represent an individual link returned from the 'links' method in the
SEOmoz API.

=head1 ATTRIBUTES

=head2 target_url

=head2 source_url

=head2 link_id

=head2 source_url_id

=head2 target_url_id

=head1 METHODS

=head2 new_from_data

    my $link = WWW::SEOmoz::Link->( $data );

Returns a new L<WWW::SEOmoz::Link> object from the data returned from the API call.

=head1 SEE ALSO

L<WWW::SEOmoz>
L<WWW::SEOmoz::Links>

=head1 AUTHOR

Adam Taylor <ajct@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Taylor.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


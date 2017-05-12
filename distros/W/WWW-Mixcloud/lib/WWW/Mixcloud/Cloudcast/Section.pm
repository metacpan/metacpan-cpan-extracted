# ABSTRACT: Represents cloudcast sections in the Mixcloud API
package WWW::Mixcloud::Cloudcast::Section;

use Moose;
use namespace::autoclean;

use Carp qw/ croak /;

our $VERSION = '0.01'; # VERSION

use WWW::Mixcloud::Track;


has track => (
    isa      => 'WWW::Mixcloud::Track',
    is       => 'ro',
    required => 1,
);


has position => (
    is       => 'ro',
    required => 1,
);


has start_time => (
    is       => 'ro',
    required => 1,
);


has section_type => (
    is       => 'ro',
    required => 1,
);

__PACKAGE__->meta->make_immutable;


sub new_list_from_data {
    my $class = shift;
    my $data  = shift || croak 'Data reference required for construction';

    my @sections;

    foreach my $section ( @{$data} ) {
        my $track = WWW::Mixcloud::Track->new_from_data( $section->{track} );

        push @sections, $class->new({
            track        => $track,
            position     => $section->{position},
            start_time   => $section->{start_time},
            section_type => $section->{section_type},
        })
    }

    return \@sections;
}
1;

__END__
=pod

=head1 NAME

WWW::Mixcloud::Cloudcast::Section - Represents cloudcast sections in the Mixcloud API

=head1 VERSION

version 0.01

=head1 ATTRIBUTES

=head2 track

A L<WWW::Mixcloud::Track> object.

=head2 position

=head2 start_time

=head2 section_type

=head1 METHODS

=head2 new_list_from_data

    my @sections = WWW::Mixcloud::Cloudcast::Section->new_from_data( $data )

=head1 AUTHOR

Adam Taylor <ajct@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Taylor.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


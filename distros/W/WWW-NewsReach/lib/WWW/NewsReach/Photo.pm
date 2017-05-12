# ABSTRACT: Models a photo in the NewsReach API.
package WWW::NewsReach::Photo;

our $VERSION = '0.06';

use Moose;

use WWW::NewsReach::Photo::Instance;

has $_ => (
    is => 'ro',
    isa => 'Str',
) for qw( caption alt orientation );

has id => (
    is => 'ro',
    isa => 'Int',
);

has instances => (
    is => 'ro',
    isa => 'ArrayRef[WWW::NewsReach::Photo::Instance]',
);


sub new_from_xml {
    my $class = shift;
    my ( $xml ) = @_;

    my $self = {};

    foreach (qw[id caption orientation]) {
        $self->{$_} = $xml->findnodes("//$_")->[0]->textContent;
    }

    $self->{alt} = $xml->findnodes('//htmlAlt')->[0]->textContent;

    foreach my $instance ( $xml->findnodes("//instance") ) {
        my $photo =
            WWW::NewsReach::Photo::Instance->new_from_xml( $instance );
        push @{$self->{instances}}, $photo;
    }
    return $class->new( $self );
}

1;

__END__
=pod

=head1 NAME

WWW::NewsReach::Photo - Models a photo in the NewsReach API.

=head1 VERSION

version 0.06

=head1 METHODS

=head2 WWW::NewsReach::Photo->new_from_xml

Creates a new WWW::NewsReach::Photo object from the <photo> ... </photo> element
returned in the XML from a NewsReach API request.

=head1 AUTHOR

Adam Taylor <ajct@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Taylor.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


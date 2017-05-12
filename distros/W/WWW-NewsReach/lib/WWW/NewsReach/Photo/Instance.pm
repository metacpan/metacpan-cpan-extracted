# ABSTRACT: Models a photo instance in the NewsReach API
package WWW::NewsReach::Photo::Instance;

our $VERSION = '0.06';

use Moose;

use URI;

has $_ => (
    is => 'ro',
    isa => 'Int',
) for qw( width height );

has type => (
    is => 'ro',
    isa => 'Str',
);

has url => (
    is => 'ro',
    isa => 'URI',
);


sub new_from_xml {
    my $class = shift;
    my ( $xml ) = @_;

    my $self = {};

    foreach (qw[ width height ]) {
        $self->{$_} = $xml->findnodes(".//$_")->[0]->textContent;
    }

    $self->{type} = $xml->findnodes(".//type")->[0]->textContent;

    $self->{url} = URI->new( $xml->findnodes(".//url")->[0]->textContent );

    return $class->new( $self );
}

1;

__END__
=pod

=head1 NAME

WWW::NewsReach::Photo::Instance - Models a photo instance in the NewsReach API

=head1 VERSION

version 0.06

=head1 METHODS

=head2 WWW::NewsReach::Photo::Instance->new_from_xml

Creates a new WWW::NewsReach::Photo::Instance object from the
<instance> ... </instance> XML element returned from a NewsReach API request.

=head1 AUTHOR

Adam Taylor <ajct@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Taylor.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


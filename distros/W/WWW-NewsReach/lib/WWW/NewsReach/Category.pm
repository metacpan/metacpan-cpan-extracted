# ABSTRACT: Models a category in the NewsReach API
package WWW::NewsReach::Category;

our $VERSION = '0.06';

use Moose;

has id => (
    is => 'ro',
    isa => 'Int',
);

has name => (
    is => 'ro',
    isa => 'Str',
);

sub new_from_xml {
    my $class = shift;
    my ( $xml ) = @_;

    my $self = {};

    foreach (qw[id name]) {
        $self->{$_} = $xml->findnodes("//$_")->[0]->textContent;
    }

    return $class->new( $self );
}

1;

__END__
=pod

=head1 NAME

WWW::NewsReach::Category - Models a category in the NewsReach API

=head1 VERSION

version 0.06

=head1 METHODS

=head2 WWW::NewsReach::Category->new_from_xml

Creates a new WWW::NewsReach::Category object from the <category> ... </category>
XML element returned from a NewsReach API request.

=head1 AUTHOR

Adam Taylor <ajct@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Adam Taylor.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


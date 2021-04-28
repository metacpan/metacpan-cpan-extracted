package MARC::Moose::Parser::MarcxmlSaxSimple;
# ABSTRACT: Parser for MARXML records using SAX::Simple parser
$MARC::Moose::Parser::MarcxmlSaxSimple::VERSION = '1.0.44';
use Moose;

extends 'MARC::Moose::Parser';

use MARC::Moose::Field::Control;
use MARC::Moose::Field::Std;
use XML::Simple;

has 'xs' => ( is => 'rw', default => sub {  XML::Simple->new() } );


override 'parse' => sub {
    my ($self, $raw) = @_;

    return unless $raw;

    my $ref = eval { $self->xs->XMLin($raw, forcearray => [ 'subfield' ] ) };
    return if $@;

    my $record = MARC::Moose::Record->new();
    $record->_leader( $ref->{leader} );
    my @fields_control = map {
        MARC::Moose::Field::Control->new( tag => $_->{tag}, value => $_->{content} );
    } @{$ref->{controlfield}};
    my @fields_std = map {
        my @sf = map { [ $_->{code}, $_->{content} ] }  @{$_->{subfield}};
        MARC::Moose::Field::Std->new(
            tag  => $_->{tag},
            ind1 => defined($_->{ind1}) ? $_->{ind1} : ' ',
            ind2 => defined($_->{ind2}) ? $_->{ind2} : ' ',
            subf => \@sf,
        ); 
    } @{$ref->{datafield}};
    $record->fields( [ @fields_control, @fields_std ] );

    return $record;
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MARC::Moose::Parser::MarcxmlSaxSimple - Parser for MARXML records using SAX::Simple parser

=head1 VERSION

version 1.0.44

=head1 SEE ALSO

=over 4

=item *

L<MARC::Moose>

=item *

L<MARC::Moose::Parser>

=item *

L<MARC::Moose::Parser::Marcxml>

=back

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Frédéric Demians.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

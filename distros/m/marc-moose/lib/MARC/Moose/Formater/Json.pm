package MARC::Moose::Formater::Json;
# ABSTRACT: Record formater into a Json representation
$MARC::Moose::Formater::Json::VERSION = '1.0.46';
use Moose;

extends 'MARC::Moose::Formater';

use MARC::Moose::Field::Control;
use MARC::Moose::Field::Std;
use JSON;

has pretty => ( is => 'rw', isa => 'Bool', default => 0 );

override 'format' => sub {
    my ($self, $record) = @_;

    my $rec = {
        leader => $record->leader,
        fields => [ map {
            $_->tag,
            ( ref($_) eq 'MARC::Moose::Field::Control'
              ? $_->value
              : {
                    ind1 => $_->ind1,
                    ind2 => $_->ind2,
                    subfields => [ map { ($_->[0], $_->[1]) } @{$_->subf} ],
                }
            );
        } @{ $record->fields } ],
    };
    return to_json($rec, { pretty => $self->pretty } ) . ",\n";
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MARC::Moose::Formater::Json - Record formater into a Json representation

=head1 VERSION

version 1.0.46

=head1 DESCRIPTION

The resulting JSON string representing a MARC::Moose::Record conforms to the
following schema:

  L<http://dilettantes.code4lib.org/files/marc-schema.json>

Further details can be found at:

  L<http://dilettantes.code4lib.org/blog/2010/09/a-proposal-to-serialize-marc-in-json/>

=head1 ATTRIBUTES

=head2 pretty

A boolean value. If true, the resulting JSON string is prettier. 

=head1 SYNOPSYS

 use MARC::Moose::Reader::File::Iso2709;
 use MARC::Moose::Formater::Json;

 my $reader   = MARC::Moose::Reader::File::Iso2709->new( file => 'marc.iso' );
 my $formater = MARC::Moose::Formater::Json->new( pretty => 1);
 while ( my $record = $reader->read() ) {
     print $formater->format($record);
 }

=head1 SEE ALSO

=over 4

=item *

L<MARC::Moose>

=item *

L<MARC::Moose::Formater>

=item *

L<MARC::Moose::Parser>

=back

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Frédéric Demians.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

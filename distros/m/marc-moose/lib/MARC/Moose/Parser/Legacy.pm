package MARC::Moose::Parser::Legacy;
# ABSTRACT: Parser for MARC::Record legacy records
$MARC::Moose::Parser::Legacy::VERSION = '1.0.45';
use Moose;

extends 'MARC::Moose::Parser';



override 'parse' => sub {
    my ($self, $legacy) = @_;

    return unless $legacy;

    my $record = MARC::Moose::Record->new();
    $record->_leader( $legacy->leader );
    my @fields;
    for my $field ( $legacy->fields() ) {
        my $tag = $field->tag;
        push @fields, $tag < '010'
            ? MARC::Moose::Field::Control->new(
                tag   => $tag,
                value => $field->data )
            : MARC::Moose::Field::Std->new(
                tag  => $tag,
                ind1 => $field->indicator(1),
                ind2 => $field->indicator(2), 
                subf => [ $field->subfields() ] )
    }
    $record->fields( \@fields );
    $record->lint($self->lint) if $self->lint;
    return $record;
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MARC::Moose::Parser::Legacy - Parser for MARC::Record legacy records

=head1 VERSION

version 1.0.45

=head1 SYNOPSYS

 # Get a MARC::Record
 my $legacy_record = GetMarcBiblio(100); 
 my $parser = MARC::Moose::Parser::Legacy->new();
 # Transform it into MARC::Moose::Record
 my $record = $parser->parse($legacy_record);

=head1 SEE ALSO
=for :list
* L<MARC::Moose>
* L<MARC::Moose::Parser>
* L<MARC::Record>

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Frédéric Demians.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

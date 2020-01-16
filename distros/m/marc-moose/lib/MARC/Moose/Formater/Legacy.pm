package MARC::Moose::Formater::Legacy;
# ABSTRACT: Record formater into the legacy MARC::Record object
$MARC::Moose::Formater::Legacy::VERSION = '1.0.41';
use Moose;

extends 'MARC::Moose::Formater';

use MARC::Moose::Field::Control;
use MARC::Moose::Field::Std;
use MARC::Record;


override 'format' => sub {
    my ($self, $record) = @_;

    my $marc = MARC::Record->new;
    $marc->leader( $record->leader );
    for my $field ( @{$record->fields} ) {
        my $nfield;
        if ( $field->tag < 10 ) {
            my $value = $field->value;
            $nfield =  MARC::Field->new( $field->tag, $field->value );
        }
        else {
            my @sf;
            for (@{$field->subf}) {
                my ($letter, $value) = @$_;
                push @sf, $letter, $value if defined $value;
            }
            $nfield = MARC::Field->new(
                $field->tag,
                $field->ind1 || ' ',
                $field->ind2 || ' ', @sf ) if @sf;
        }
        $marc->append_fields($nfield) if $nfield;
    }
    return $marc;
};

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MARC::Moose::Formater::Legacy - Record formater into the legacy MARC::Record object

=head1 VERSION

version 1.0.41

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Frédéric Demians.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

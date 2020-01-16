package MARC::Moose::Parser::Json;
# ABSTRACT: Parser for JSON records
$MARC::Moose::Parser::Json::VERSION = '1.0.41';
use Moose;
extends 'MARC::Moose::Parser';
use JSON;


override 'parse' => sub {
    my ($self, $raw) = @_;
    return unless $raw;
    my $json = from_json($raw);
    my @jfields = @{$json->{fields}};
    my @fields;
    while ( @jfields ) {
        my $tag = shift @jfields;
        my $value = shift @jfields;
        if ( ref($value) eq 'HASH' ) {
            my @subf;
            my @jsubf = @{$value->{subfields}};
            while (@jsubf) {
                my ($letter, $value) = (shift @jsubf, shift @jsubf);
                push @subf, [ $letter => $value ];
            }
            push @fields, MARC::Moose::Field::Std->new(
                tag => $tag,
                ind1 => $value->{ind1},
                ind2 => $value->{ind2},
                subf => \@subf );
        }
        else {
            push @fields, MARC::Moose::Field::Control->new(
                tag => $tag, value => $value );
        }
    }
    my $record = MARC::Moose::Record->new(
        leader => $json->{leader},
        fields => \@fields );
    $record->lint($self->lint) if $record->lint;
    return $record;
};

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MARC::Moose::Parser::Json - Parser for JSON records

=head1 VERSION

version 1.0.41

=head1 SEE ALSO
=for :list
* L<MARC::Moose>
* L<MARC::Moose::Parser>

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Frédéric Demians.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

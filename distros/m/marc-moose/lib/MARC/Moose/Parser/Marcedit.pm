package MARC::Moose::Parser::Marcedit;
# ABSTRACT: Parser for Marcedit records
$MARC::Moose::Parser::Marcedit::VERSION = '1.0.49';
use Moose;
extends 'MARC::Moose::Parser';
use JSON;


override 'parse' => sub {
    my ($self, $raw) = @_;
    return unless $raw;

    my @fields;
    my $leader;
    for my $line (split /\n/, $raw) {
        my $tag = substr($line, 1, 3);
        if ($tag eq 'LDR') {
            $leader = substr($line, 6);
            next;
        }
        if ($tag lt '010') {
            push @fields, MARC::Moose::Field::Control->new(
                tag => $tag, value => substr($line, 6));
            next;
        }
        my $ind1 = substr($line, 6, 1);
        my $ind2 = substr($line, 7, 1);
        $ind1 = ' ' if $ind1 eq "\\";
        $ind2 = ' ' if $ind2 eq "\\";
        $line = substr($line, 9);
        my @parts = split /\$/, $line;
        my @subf;
        for my $part (@parts) {
            my ($letter, $value) = (substr($part, 0, 1), substr($part, 1));
            push @subf, [ $letter => $value ];
        }
        push @fields, MARC::Moose::Field::Std->new(
            tag => $tag,
            ind1 => $ind1,
            ind2 => $ind2,
            subf => \@subf );
    }
    my $record = MARC::Moose::Record->new(
        fields => \@fields );
    $record->_leader($leader);

    $record->lint($self->lint) if $record->lint;

    return $record;
};

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MARC::Moose::Parser::Marcedit - Parser for Marcedit records

=head1 VERSION

version 1.0.49

=head1 SEE ALSO
=for :list
* L<MARC::Moose>
* L<MARC::Moose::Parser>

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Frédéric Demians.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

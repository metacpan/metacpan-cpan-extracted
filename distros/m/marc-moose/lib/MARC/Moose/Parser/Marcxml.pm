package MARC::Moose::Parser::Marcxml;
# ABSTRACT: Parser for MARXML records
$MARC::Moose::Parser::Marcxml::VERSION = '1.0.42';
use Moose;

extends 'MARC::Moose::Parser';

use MARC::Moose::Field::Control;
use MARC::Moose::Field::Std;


override 'parse' => sub {
    my ($self, $raw) = @_;

    return unless $raw =~ /<record/;

    my @parts = split />/, $raw;
    my ($tag, $code, $ind1, $ind2);
    my $record = MARC::Moose::Record->new();
    my @fields;
    while ( @parts ) {
        $_ = shift @parts;
        $_ = shift @parts if /<record/;
        if ( /<leader/ ) {
            $_ = shift @parts;
            /(.*)<\/leader/;
            $record->_leader($1);
            next;
        }
        if ( /<controlfield\s*tag="(.*)"/ ) {
            my $tag = $1;
            $_ = shift @parts;
            s/<\/controlfield//;
            push @fields, MARC::Moose::Field::Control->new( tag => $tag, value => $_ );
            next;
        }
        if ( /<datafield\s*tag="(.*?)"\s*ind1="(.*?)"\s*ind2="(.*)"/ ) {
            my ($tag, $ind1, $ind2) = ($1, $2, $3);
            my @subf;
            while ( @parts && $parts[0] =~ /<subfield.*code="(.*)"/ ) {
                my $letter = $1;
                shift @parts;
                $_ = shift @parts;
                s/<\/subfield//;
                push @subf, [ $letter => $_ ];
            }
            $ind1 = ' ' unless defined($ind1);
            $ind2 = ' ' unless defined($ind2);
            push @fields, MARC::Moose::Field::Std->new(
                tag => $tag,
                ind1 => $ind1,
                ind2 => $ind2,
                subf => \@subf );
            shift @parts;
            next;
        }
        last;
    }
    $record->fields( \@fields );

    return $record;
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MARC::Moose::Parser::Marcxml - Parser for MARXML records

=head1 VERSION

version 1.0.42

=head1 DESCRIPTION

This MARCXML parser doesn't use a SAX parser. It's pure Perl. This results in
better performances.

=head1 SEE ALSO

=over 4

=item *

L<MARC::Moose>

=item *

L<MARC::Moose::Parser>

=back

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Frédéric Demians.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

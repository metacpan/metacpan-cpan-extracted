package MARC::Moose::Parser::Iso2709;
# ABSTRACT: Parser for ISO2709 records
$MARC::Moose::Parser::Iso2709::VERSION = '1.0.35';
use Moose;
use Modern::Perl;
require bytes;

extends 'MARC::Moose::Parser';

use MARC::Moose::Record;
use MARC::Moose::Field::Control;
use MARC::Moose::Field::Std;


# FIXME Experimental. Not used yet.
#has converter => (
#    is      => 'rw',
#    isa     => 'Text::IconvPtr',
#    default => sub { Text::Iconv->new( "cp857", "utf8" ) }
#);



override 'parse' => sub {
    my ($self, $raw) = @_;

    return unless $raw;
    my $utf8_flag = utf8::is_utf8($raw) || 1;

    my $record = MARC::Moose::Record->new();

    my $leader = substr($raw, 0, 24);
    $record->_leader( $leader );

    $raw = substr($raw, 24);
    my $directory_len = substr($leader, 12, 5) - 25;
    my $directory = substr $raw, 0, $directory_len;
    my $content = substr($raw, $directory_len+1);
    my $number_of_tag = $directory_len / 12; 
    my @fields;
    for (my $i = 0; $i < $number_of_tag; $i++) {
        my $off = $i * 12;
        my $tag = substr($directory, $off, 3);
        next if $tag !~ /^[a-zA-Z0-9]*$/; # FIXME: it happens!
        my $len = substr($directory, $off+3, 4) - 1;
        my $pos = substr($directory, $off+7, 5) + 0;
        my $value = bytes::substr($content, $pos, $len);
        utf8::decode($value) if $utf8_flag;
        next unless $value;
        #$value = $self->converter->convert($value);
        if ( $value =~ /\x1F/ ) { # There are some letters
            my $i1 = substr($value, 0, 1);
            my $i2 = substr($value, 1, 1);
            $value = substr($value, 2);
            my @sf;
            for ( split /\x1F/, $value) {
                next if length($_) < 2;
                push @sf, [ substr($_, 0, 1), substr($_, 1) ];
            }
            push @fields, MARC::Moose::Field::Std->new(
                tag => $tag, ind1 => $i1, ind2 => $i2, subf => \@sf );
        }
        else {
            push @fields, MARC::Moose::Field::Control->new( tag => $tag, value => $value );
        }
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

MARC::Moose::Parser::Iso2709 - Parser for ISO2709 records

=head1 VERSION

version 1.0.35

=head1 DESCRIPTION

Override L<MARC::Moose::Parser> to parse ISO2709 MARC records.

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

This software is copyright (c) 2018 by Frédéric Demians.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

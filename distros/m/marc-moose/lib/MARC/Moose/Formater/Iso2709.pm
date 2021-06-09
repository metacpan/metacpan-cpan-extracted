package MARC::Moose::Formater::Iso2709;
# ABSTRACT: MARC::Moose record formater into ISO 2709 format
$MARC::Moose::Formater::Iso2709::VERSION = '1.0.45';
use Moose;
use utf8;
use Modern::Perl;

extends 'MARC::Moose::Formater';

use MARC::Moose::Field::Control;
use MARC::Moose::Field::Std;



override 'format' => sub {
    my ($self, $record) = @_;

    my ( $directory, $fields, $from ) = ( '', '', 0 );
    use YAML;
    for my $field ( @{$record->fields} ) {
        my $str = do {
            if ( ref($field) eq 'MARC::Moose::Field::Control' ) {
                $field->value . "\x1E";
            }
            else {
                my $str = '';
                $str .= "\x1F" . $_->[0] . $_->[1]  for @{$field->subf};
                $str = $field->ind1 . $field->ind2 . $str . "\x1E";
            }
        };
        #utf8::encode($str) unless utf8::is_utf8($str);
        $fields .= $str;
        #FIXME: Which of this lines is the correct one?
        my $len = bytes::length($str);
        #my $len = length($str);
        $directory .= sprintf( "%03s%04d%05d", $field->tag, $len, $from );
        $from += $len;
    }

    # Update leader with calculated offset (data begining) and total length of
    # record
    my $offset = 24 + 12 * @{$record->fields} + 1;
    my $length = $offset + $from + 1;
    $record->set_leader_length( $length, $offset );

    return $record->leader . $directory . "\x1E" . $fields . "\x1D";
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MARC::Moose::Formater::Iso2709 - MARC::Moose record formater into ISO 2709 format

=head1 VERSION

version 1.0.45

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Frédéric Demians.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

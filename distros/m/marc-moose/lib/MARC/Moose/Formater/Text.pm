package MARC::Moose::Formater::Text;
# ABSTRACT: Record formater into a text representation
$MARC::Moose::Formater::Text::VERSION = '1.0.49';
use Moose;

extends 'MARC::Moose::Formater';

use MARC::Moose::Field::Control;
use MARC::Moose::Field::Std;


override 'format' => sub {
    my ($self, $record) = @_;

    my $text = join "\n",
         $record->leader,
         map {
             $_->tag .
             ( ref($_) eq 'MARC::Moose::Field::Control' 
               ? ' ' . $_->value
               : ' ' . $_->ind1 . $_->ind2 . ' '  .
               join ' ', map { ('$' . $_->[0], $_->[1] ) } @{$_->subf}
             );
         } @{ $record->fields };
    return $text . "\n\n"; 
};

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MARC::Moose::Formater::Text - Record formater into a text representation

=head1 VERSION

version 1.0.49

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Frédéric Demians.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

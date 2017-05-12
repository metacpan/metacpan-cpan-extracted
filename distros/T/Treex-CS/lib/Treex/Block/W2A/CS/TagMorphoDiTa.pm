package Treex::Block::W2A::CS::TagMorphoDiTa;
$Treex::Block::W2A::CS::TagMorphoDiTa::VERSION = '2.20151102';
use strict;
use warnings;
use Moose;
use Treex::Core::Common;
extends 'Treex::Block::W2A::TagMorphoDiTa';

has '+model' => ( default => 'data/models/morphodita/cs/czech-morfflex-pdt-131112.tagger-best_accuracy' );

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Treex::Block::W2A::CS::TagMorphoDiTa

=head1 VERSION

version 2.20151102

=head1 DESCRIPTION

This is just a small modification of L<Treex::Block::W2A::TagMorphoDiTa> which adds the path to the
default model for Czech.

=head1 AUTHORS

Martin Popel <popel@ufal.mff.cuni.cz>

=head1 COPYRIGHT AND LICENSE

Copyright © 2014 by Institute of Formal and Applied Linguistics, Charles University in Prague

This module is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

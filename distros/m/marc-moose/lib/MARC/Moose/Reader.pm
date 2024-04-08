package MARC::Moose::Reader;
# ABSTRACT: Base class for a reader returning MARC::Moose records
$MARC::Moose::Reader::VERSION = '1.0.49';
use Moose::Role;
use MARC::Moose::Lint::Checker;

with 'MooseX::RW::Reader';




has parser => (
    is => 'rw', isa => 'MARC::Moose::Parser',
);



1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MARC::Moose::Reader - Base class for a reader returning MARC::Moose records

=head1 VERSION

version 1.0.49

=head1 ATTRIBUTES

=head2 parser

L<MARC::Moose::Parser> parser used to parse records that have been read.

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Frédéric Demians.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

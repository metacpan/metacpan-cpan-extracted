package MARC::Moose::Reader::File::Marcxml;
# ABSTRACT: File reader for MARCXML file
$MARC::Moose::Reader::File::Marcxml::VERSION = '1.0.45';
use Moose;

use Carp;
use MARC::Moose::Record;
use MARC::Moose::Parser::Marcxml;

with 'MARC::Moose::Reader::File';



has '+parser' => ( default => sub { MARC::Moose::Parser::MarcxmlSax->new() } );


sub read {
    my $self = shift;

    $self->count($self->count + 1);

    my $fh = $self->{fh};

    return if eof($fh);

    local $/ = "</record>"; # End of record
    my $raw = <$fh>;
    
    # Skip <collection if present
    $raw =~ s/<(\/*)collection.*>//;

    # End of file
    return unless $raw =~ /<record.*>/;

    $self->parser->parse( $raw );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MARC::Moose::Reader::File::Marcxml - File reader for MARCXML file

=head1 VERSION

version 1.0.45

=head1 DESCRIPTION

Override L<MARC::Moose::Reader::File>, and read a file containing MARCXML
records.

=head1 ATTRIBUTES

=head2 parser

By default, a L<MARC::Moose::Parser::MarcxmlSax> parser is used.

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Frédéric Demians.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

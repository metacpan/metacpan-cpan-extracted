package MARC::Moose::Reader::File::Marcedit;
# ABSTRACT: File reader for MARC::Moose record from Marcedit file (.mrk)
$MARC::Moose::Reader::File::Marcedit::VERSION = '1.0.49';
use Moose;
use Modern::Perl;
use MARC::Moose::Record;
use MARC::Moose::Parser::Marcedit;

with 'MARC::Moose::Reader::File';


has '+parser' => (
    default => sub {
        my $parser = MARC::Moose::Parser::Marcedit->new();
        return $parser;
    }
);


sub read {
    my $self = shift;

    $self->count( $self->count + 1);

    my $fh = $self->{fh};

    return if eof($fh);

    my @lines;

    # Next record
    my $found = 0;
    while (<$fh>) {
        $found = $_ =~ /^=LDR/;
        if ($found) {
            s/\n$//;
            s/\r$//;
            push @lines, $_;
            last;
        }
    }
    return unless $found;

    while (<$fh>) {
        s/\n$//;
        s/\r$//;
        last unless $_; # Ligne vide
        push @lines, $_;
    }

    $self->parser->parse(join("\n", @lines));
}


__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MARC::Moose::Reader::File::Marcedit - File reader for MARC::Moose record from Marcedit file (.mrk)

=head1 VERSION

version 1.0.49

=head1 AUTHOR

Frédéric Demians <f.demians@tamil.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Frédéric Demians.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

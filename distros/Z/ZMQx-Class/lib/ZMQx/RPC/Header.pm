package ZMQx::RPC::Header;
use strict;
use warnings;
use Moose;
use Carp qw(croak);

# TODO specify header position via trait
has 'type' => (is=>'ro',isa=>'Str'); # TODO enum? serializable_types?
has 'timeout' => (is=>'ro',isa=>'Int');

our @header_positions = qw( type timeout );

sub pack {
    my $self = shift;

    my @head;
    foreach my $fld (@header_positions) {
        if (my $v = $self->$fld) {
            push(@head, $v);
        }
        else {
            push(@head, '')
        }
    }
    return join(';',@head);
}

sub unpack {
    my ($class, $packed) = @_;
    my %new;
    my @header = split(/;/,$packed);
    while (my ($index, $val) = each (@header_positions)) {
        next unless defined $header[$index];
        $new{$val} = $header[$index];
    }
    return $class->new(%new);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ZMQx::RPC::Header

=head1 VERSION

version 0.006

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Validad AG.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

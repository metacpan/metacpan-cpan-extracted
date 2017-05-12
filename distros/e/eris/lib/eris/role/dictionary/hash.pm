package eris::role::dictionary::hash;

use Moo::Role;
use namespace::autoclean;

requires qw(hash);
with qw(eris::role::dictionary);

sub lookup {
    my ($self,$field) = @_;

    my $entry = undef;
    my $dict  = $self->hash;
    if( exists $dict->{lc $field} ) {
        $entry = {
            field => lc $field,
            description => $dict->{lc $field},
        };
    }
    return $entry;
}

sub fields {
    my ($self) = @_;

    return [ sort keys %{ $self->hash }  ];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::role::dictionary::hash

=head1 VERSION

version 0.003

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

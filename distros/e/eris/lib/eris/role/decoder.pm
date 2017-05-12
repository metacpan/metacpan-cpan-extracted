package eris::role::decoder;

use Moo::Role;
use Types::Standard qw( Str Int );
use namespace::autoclean;

########################################################################
# Attributes
requires 'decode_message';
with qw(
    eris::role::plugin
);

########################################################################
# Attributes

########################################################################
# Builders
sub _build_name {
    my ($self) = shift;
    my ($class) = ref $self;
    my @path = split /\:\:/, defined $class ? $class : '';

    die "Bad reference to eris::role::decoder $class" unless @path > 1;

    return $path[-1];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::role::decoder

=head1 VERSION

version 0.003

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

package eris::role::dictionary;

use Moo::Role;
use Types::Standard qw(Int Str);
use namespace::autoclean;

########################################################################
# Interface
requires qw(lookup fields);
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

    die "Bad reference to eris::dictionary $class" unless @path > 1;

    return $path[-1];
}


########################################################################
# Method Augmentation
around 'lookup' => sub {
    my $orig = shift;
    my $self = shift;

    my $entry = $self->$orig(@_);
    if( defined $entry && ref $entry eq 'HASH' ) {
        $entry->{from} = $self->name;
    }
    $entry; # return'd
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::role::dictionary

=head1 VERSION

version 0.003

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

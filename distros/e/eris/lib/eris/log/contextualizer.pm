package eris::log::contextualizer;

use Moo;
use Time::HiRes qw(gettimeofday tv_interval);
use Types::Standard qw( HashRef InstanceOf );

use eris::base::types qw( HashRefFromYAML );
use eris::log::contexts;
use eris::log::decoders;
use eris::dictionary;

use namespace::autoclean;

########################################################################
# Attributes
has config => (
    is       => 'ro',
    isa      => HashRef,
    coerce   => HashRefFromYAML,
    default  => sub { +{} },
);
has contexts => (
    is      => 'ro',
    isa     => InstanceOf['eris::log::contexts'],
    handles => [qw(contextualize)],
    lazy    => 1,
    builder => '_build_contexts',
);
has 'decoders' => (
    is      => 'ro',
    isa     => InstanceOf['eris::log::decoders'],
    handles => [qw(decode)],
    lazy    => 1,
    builder => '_build_decoders',
    handles => [qw(decode)],
);
has 'dictionary' => (
    is      => 'ro',
    isa     => InstanceOf['eris::dictionary'],
    lazy    => 1,
    builder => '_build_dictionary',
);

########################################################################
# Builders
sub _build_decoders {
    my $self = shift;
    return eris::log::decoders->new(
        %{ $self->config->{decoder} || {} },
    );
}
sub _build_contexts {
    my $self = shift;
    return eris::log::contexts->new(
        %{ $self->config->{context} || {} },
    );
}
sub _build_dictionary {
    my $self = shift;
    return eris::dictionary->instance(
        %{ $self->config->{dictionary} || {} },
    );
}
########################################################################
# Methods
sub parse {
    my ($self,$raw) = @_;

    # Apply the decoders
    my %t=();
    my $t0 = [gettimeofday];
    my $log = $self->decode($raw);
    my $tdiff = tv_interval($t0);
    $t{decoders} = $tdiff;


    # Add context
    my $t1 = [gettimeofday];
    $self->contextualize($log);
    my $t2 = [gettimeofday];

    # Record timings
    $t{contexts} = tv_interval( $t1, $t2 );
    $t{total}    = tv_interval( $t0, $t2 );
    $log->add_timing(%t);

    # Return the log created
    return $log;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

eris::log::contextualizer

=head1 VERSION

version 0.003

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

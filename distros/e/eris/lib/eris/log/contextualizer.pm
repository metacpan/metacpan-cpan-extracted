package eris::log::contextualizer;
# ABSTRACT: Primary interface to the eris log parsing library

use Moo;
use Time::HiRes qw(gettimeofday tv_interval);
use Types::Standard qw( HashRef InstanceOf );

use eris::log::contexts;
use eris::log::decoders;

use namespace::autoclean;

our $VERSION = '0.008'; # VERSION


has config => (
    is       => 'ro',
    isa      => HashRef,
    default  => sub { +{} },
);



has contexts => (
    is      => 'ro',
    isa     => InstanceOf['eris::log::contexts'],
    handles => [qw(contextualize)],
    lazy    => 1,
    builder => '_build_contexts',
);
sub _build_contexts {
    my $self = shift;
    return eris::log::contexts->new(
        %{ $self->config->{contexts} || {} },
    );
}


has 'decoders' => (
    is      => 'ro',
    isa     => InstanceOf['eris::log::decoders'],
    handles => [qw(decode)],
    lazy    => 1,
    builder => '_build_decoders',
    handles => [qw(decode)],
);
sub _build_decoders {
    my $self = shift;
    return eris::log::decoders->new(
        %{ $self->config->{decoders} || {} },
    );
}


sub parse {
    my ($self,$raw) = @_;

    # Apply the decoders
    my %t=();
    my $t0 = [gettimeofday];
    my $log = $self->decode($raw);
    $log->add_context( raw => { raw => $raw } );
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

eris::log::contextualizer - Primary interface to the eris log parsing library

=head1 VERSION

version 0.008

=head1 SYNOPSIS

This objects wraps the decoders and contexts to fully annotate an L<eris::log>
instance.

    use Data::Printer;
    use eris::contextualizer;

    my $ctxr = eris::contextualizer->new();

    while( <<>> ) {
        p( $ctxr->parse($_) )
    }

=head1 ATTRIBUTES

=head2 config

The configuration as a hash reference.

A YAML Representation of the root namespaces for the configuration:

    ---
    contexts: {}
    decoders: {}
    schemas: {}

=head2 contexts

An instance of an L<eris::log::contexts> object.  Passed
the configuration specified in the C<contexts> root key of
the config or an empty HashRef

=head2 decoders

An instance of an L<eris::log::decoders> object. Passed
the configuration specified in the C<decoders> root key of
the config or an empty HashRef

=head1 METHODS

=head2 parse

Takes a raw string.

Builds the list of decoders and contexts, passes the raw string to
the L<eris::log::decoders>, which returns an instance of an L<eris::log> object.

Then calls L<eris::log::contexts>, passing that L<eris::log> instance to each.

This method wraps this process w/timing data that's added with the
L<eris::log>'s C<add_timing> method.  This data is available when the
L<eris::dictionary::eris::debug> is enabled.  This can be helpful for examining
parser performance.

=head1 SEE ALSO

L<eris::log>, L<eris::log::decoders>, L<eris::log::contexts>

=head1 AUTHOR

Brad Lhotsky <brad@divisionbyzero.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by Brad Lhotsky.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

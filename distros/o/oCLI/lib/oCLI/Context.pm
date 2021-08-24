package oCLI::Context;
use Moo;
use Package::Stash;
use Module::Runtime qw( use_module );
use oCLI::Plugin;

has req => (
    is => 'rw',
);

has plugin => (
    is      => 'ro',
    lazy    => 1,
    builder => sub { oCLI::Plugin->new },
);

has stash => (
    is      => 'rw',
    default => sub { return +{} },
);

has root => (
    is => 'ro',
);

sub trace {
    my ( $self, $message ) = @_;

    my ( $package, $filename, $line ) = caller;
    if ( exists $self->req->{overrides}->{trace} ) {
        print "TRACE[$package:$line]> $message\n";
    }
}

sub model {
    my ( $self, $name ) = @_;


    if ( exists $self->{model}->{name} ) {
        $self->trace("model($name) requested and memoized object returned.");
        return $self->{model}->{name};
    }

    $self->trace("Initial request for model($name)");

    my $stash = (Package::Stash->new( $self->root )->get_symbol('%stash'));

    # Inject context into arguments if context is set.
    if ( exists $stash->{model}{$name}{context} ) {
        die "Can only inject context argument into hash style arguments."
            if ref($stash->{model}{$name}{args}) ne 'HASH';
        $stash->{model}{$name}{args}{$stash->{model}{$name}{context}} = $self;
    }

    if ( exists $stash->{model}->{$name} ) {
        return use_module( $stash->{model}->{$name}->{class} )->new( 
            ref($stash->{model}->{$name}->{args}) eq 'ARRAY'
                ? @{$stash->{model}->{$name}->{args}}
                : ref($stash->{model}->{$name}->{args}) eq 'HASH'
                    ? %{$stash->{model}->{$name}->{args}}
                    : $stash->{model}->{$name}->{args}
        );
    } else {
        die "Error: Couldn't load model $name\n";
    }

}

1;

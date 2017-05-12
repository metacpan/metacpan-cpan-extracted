package XPlanner::Object;

use strict;


=head1 NAME

XPlanner::Object - Base class for all XPlanner objects

=head1 SYNOPSIS

  # No user servicable parts inside.  Go away

=begin private

  package XPlanner::Foo;
  use base 'XPlanner::Object';


=head1 DESCRIPTION

A place to put methods common to all XPlanner objects

=head2 Methods

=head3 _map_from_soap

  my $mapped_objects = $self->_map_from_soap($key, $proxy_method, $class);

Loads the given $class we want to map these objects to and calls the
given $proxy_method on the SOAP proxy to get them.  It then translates the
list of objects into a hash keyed on $key from inside each object.

The SOAP proxy will be put into each object.

Equivalent to

    eval "require $class";
    my %mapped_objects = map { $_->{_proxy} = $self;
                               $_->{$key} => $_
                           } @{$proxy->$proxy_method($self->{id})->result};

=cut

sub _map_from_soap {
    my($self, $key, $proxy_method, $class) = @_;
    my $proxy = $self->{_proxy};

    # Everything has an id except for the project itself.
    my @proxy_args;
    @proxy_args = $self->{id} unless $self->isa('XPlanner');

    eval "require $class";
    my %mapped_objects = map { $_->{_proxy} = $self->{_proxy};
                               $_->{$key} => $_
                             } @{$proxy->$proxy_method(@proxy_args)->result};

    return \%mapped_objects;
}


sub _init {
    my($class, %args) = @_;

    bless \%args, $class->_proxy_class;
}


1;

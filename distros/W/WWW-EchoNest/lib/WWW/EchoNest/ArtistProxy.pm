
package WWW::EchoNest::ArtistProxy;

use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw( first );

use WWW::EchoNest;
BEGIN { our $VERSION = $WWW::EchoNest::VERSION; }

use WWW::EchoNest::Id qw( is_id );
use WWW::EchoNest::Functional qw( all update );
use WWW::EchoNest::Util qw( call_api );

use parent qw( WWW::EchoNest::Proxy );

sub new {
    my $class           = $_[0];
    my %args            = %{ $_[1] };
    my $object_type     = 'artist';
    my $id              = $args{id};
    my $name            = $args{name};
    my $buckets         = $args{buckets} // [];
    
    croak 'Must provide id or name' if ! (defined($id) or defined($name));
    croak "Invalid id string: $id"  if defined($id) and not is_id($id);

    # Create the new instance
    $args{object}  = $object_type;
    my $instance   = $class->SUPER::new( \%args );
    
    # Check to make sure we were provided with all the core attributes
    my @core_attrs     = qw( name );
    my %arg_map        = map { $_ => 1 } (keys %args);
    my @provided_attrs = @arg_map{ @core_attrs };
    
    # Get the profile if any of the core_attrs were left out
    if ( ! all(@provided_attrs) ) {
    	my $profile = $instance->get_attribute(
                                               {
                                                method  => 'profile',
                                                bucket  => $buckets,
                                               }
                                              );
	
    	my $artist_info_ref = $profile->{ $object_type };
        $instance->{$_} = $artist_info_ref->{$_} for (keys %$artist_info_ref);
    }
    return $instance;
}

sub get_attribute {
    my($self, $args_ref)   = @_;
    my $id                 = $self->{id};
    my $name               = $self->{name};

    croak q[you must provide one of 'id' or 'name']
        if not (defined($id) || defined($name));

    $args_ref->{id}     = $id       if defined($id);
    $args_ref->{name}   = $name     if defined($name) and not defined($id);
    return $self->SUPER::get_attribute( $args_ref );
}

sub post_attribute {
    my($self, $args_ref)    = @_;
    $args_ref->{post}     //= 1;
    croak 'You must provide a method' if not defined $args_ref->{method};
    my $result = call_api($args_ref);
    return $result->{response};
}

sub get_id {
    my $self = shift;
    my $id   = $self->{id};

    if (! defined($id)) {
        my $name = $self->{name};
        croak q[neither 'id' nor 'name' are defined] if ! defined($name);

        my $profile = $self->get_attribute( { method => 'profile' } );
        croak "Could not get Artist profile: $name" if ! defined($profile);

        $id         = $profile->{artist}{id};
        $self->{id} = $id;
    }
    return $id;
}

sub get_name {
    my $self   = shift;
    my $name   = $self->{name};

    if (! defined($name)) {
        my $id = $self->{id};
        croak q[neither 'id' nor 'name' are defined] if ! defined($id);
        
        my $profile = $self->get_attribute( { method => 'profile' } );
        croak "Could not get Artist profile: $id" if ! defined($profile);

        $name         = $profile->{artist}{name};
        $self->{name} = $name;
    }
    return $name;
}

1;

__END__

=head1 NAME

WWW::EchoNest::ArtistProxy
For internal use only!

=head1 AUTHOR

Brian Sorahan, C<< <bsorahan@gmail.com> >>

=head1 SUPPORT

Join the Google group: <http://groups.google.com/group/www-echonest>

=head1 ACKNOWLEDGEMENTS

Thanks to all the folks at The Echo Nest for providing access to their
powerful API.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Brian Sorahan.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

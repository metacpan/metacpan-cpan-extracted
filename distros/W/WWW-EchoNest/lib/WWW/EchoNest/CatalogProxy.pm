
package WWW::EchoNest::CatalogProxy;

BEGIN {
    our @EXPORT       = ();
    our @EXPORT_OK    = ();
}
use parent qw[ WWW::EchoNest::Proxy Exporter ];

use 5.010;
use strict;
use warnings;
use Carp;
use List::Util qw[ first ];

use WWW::EchoNest;
our $VERSION = $WWW::EchoNest::VERSION;

use WWW::EchoNest::Id qw( is_id );
use WWW::EchoNest::Functional qw(
                                    all
                                    update
                                    make_stupid_accessor
                               );



# FUNCTIONS ############################################################
#
my @types  = qw( artist song );
sub _types { @types }



########################################################################
#
# METHODS
#

# Acceptable catalog types are 'song' and 'artist'
sub new {
    my($class, $args_ref) = @_;
    my $object            = 'catalog';
    my $id                = $args_ref->{id};
    my $name              = $args_ref->{name};
    # pyechonest uses a 'buckets' arg for catalog creation -- not sure why
    # my $buckets           = $args_ref->{buckets}    || [];
    my $type              = $args_ref->{type}       // 'song';

    # Acceptable catalog types
    croak "unrecognized type: $type" if ! grep { $type eq $_ } @types;

    $args_ref->{object}    = $object;
    $args_ref->{type}      = $type if ! exists $args_ref->{type};
    my $instance           = $class->SUPER::new($args_ref);

    my @core_attrs = qw( name );
    my %args = map { $_ => 1 } keys %$args_ref;
    my @provided_attrs = @args{ @core_attrs };
    
    # Get the profile if any of the core_attrs were left out
    if (! all( @provided_attrs )) {
        if ( is_id($id) ) {
            my($profile, $catalog_info);
            eval {
                $profile = $instance->get_attribute( { method => 'profile' } );
                update( $args_ref, $profile->{catalog} );
            };
            croak "Catalog $id does not exist: $@" if $@;
        } else {
            my($profile, $existing_type);
            eval {
                # See if the catalog already exists
                $profile = $instance->get_attribute( { method => 'profile' } );
                $existing_type = $profile->{catalog}{type} // 'Unknown';
		
                if ($type ne $existing_type) {
                    croak "Catalog type requested ($type) does not match "
                          . "existing catalog type ($existing_type)";
                }
                update( $args_ref, $profile->{catalog} );
            };
            if ($@) {
                my $new_catalog_href =
                    $instance->post_attribute(
                                              {
                                               method     => 'create',
                                               type       => $type,
                                               params     => $args_ref,
                                              }
                                             );
                update( $args_ref, $new_catalog_href );
            }
        }
    }
    for my $k (keys %$args_ref) {
        $instance->{$k} = $args_ref->{$k};
    }
    return $instance;
}

sub get_type { $_[0]->{type} }

sub get_id {
    my($self)   = @_;
    my $id      = $self->{id};
    my $type    = $self->{type};

    croak 'No type!' if ! $type;

    if (! defined($id)) {
        my $args_ref = {};
        
        eval {
            my $profile = $self->get_attribute( { method => 'profile', } );
            my $existing_type = $profile->{catalog}{type} // 'Unknown';
		
            if ($type ne $existing_type) {
                croak "Catalog type requested ($type) does not match "
                      . "existing catalog type ($existing_type)";
            }
            update( $args_ref, $profile->{catalog} );
        };
        if ($@) {
            $args_ref->{method} = 'create';
            $args_ref->{type}   = $type;
            update( $args_ref, $self->post_attribute($args_ref) );
        }
        for my $k (keys %$args_ref) {
            $self->{$k} = $args_ref->{$k};
        }
    }

    return $self->{id};
}

make_stupid_accessor( qw[ name ] );

sub get_attribute {
    my($self, $args_ref) = @_;
    my $id     = $self->{id};
    my $name   = $self->{name};
    $args_ref->{id}   = $id      if $id;
    # We shouldn't use both name and id
    $args_ref->{name} = $name    if $name && ! $id;
    return $self->SUPER::get_attribute( $args_ref );
}

# Doesn't add the id or name fields
sub get_attribute_simple {
    my $self = shift;
    return $self->SUPER::get_attribute( @_ );
}

sub post_attribute {
    my($self, $args_ref) = @_;
    my $id     = $self->{id};
    my $name   = $self->{name};
    $args_ref->{id}   = $id      if $id;
    # We shouldn't use both name and id
    $args_ref->{name} = $name    if $name && ! $id;
    return $self->SUPER::post_attribute( $args_ref );
}

1;

__END__

=head1 NAME

WWW::EchoNest::CatalogProxy
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

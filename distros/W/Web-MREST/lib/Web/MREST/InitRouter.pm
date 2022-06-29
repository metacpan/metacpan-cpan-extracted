# ************************************************************************* 
# Copyright (c) 2014-2022, SUSE LLC
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of SUSE LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ************************************************************************* 

package Web::MREST::InitRouter;

use 5.012;
use strict;
use warnings;

use App::CELL qw( $log $meta $site );
use Data::Dumper;
use Path::Router;
use Try::Tiny;


=head1 NAME

Web::MREST::InitRouter - Routines for initializing our Path::Router instance



=head1 SYNOPSIS

L<Web::MREST> uses L<Path::Router> to match URIs to resources. All resources
are packed into a single object. The singleton is exported as C<$router> from
this module and can be initialized by calling C<init_router>, which is also
exported, with no arguments.

    use Web::MREST::InitRouter qw( $router );

    ...

    Web::MREST::InitRouter::init_router() unless defined $router and $router->can( 'match' );




=head1 PACKAGE VARIABLES

=cut

our $router;
our $resources = {};
our @non_expandable_properties = qw( parent validations documentation resource_name children );
our %no_expand_map = map { ( $_ => '' ) } @non_expandable_properties;


=head1 EXPORTS

This module provides the following exports:

=over 

=item C<$router> (Path::Router singleton)

=item C<$resources> (expanded resource definitions)

=back

=cut

use Exporter qw( import );
our @EXPORT_OK = qw( $router $resources );


=head1 FUNCTIONS

=cut


#
# read in multiple resource definitions from a hash
#
sub load_resource_defs { 
    my $defs = shift; 
    #$log->debug("Entering " . __PACKAGE__. "::_load_resource_defs with argument " . Dumper( $defs ));

    # first pass -> expand resource defs and add them to $resources
    foreach my $resource ( keys( %$defs ) ) {
        # each resource definition is a hash.
        if ( ref( $defs->{$resource} ) eq 'HASH' ) {
            _process_resource_def( $resource, $defs->{$resource} );
        } else {
            die "AAAAAAAHHHHHHH! Definition of resource $resource is not a hashref!";
        }
        _add_route( $resource );
    }
}


# processes an individual resource definition hash and adds Path::Router route
# for it
sub _process_resource_def {
    my ( $resource, $resource_def ) = @_;
    #$log->debug("Entering " . __PACKAGE__. "::_process_resource_def with:" );
    $log->info("Initializing \$resource ->$resource<-");
    #$log->debug("\$resource_def " . Dumper( $resource_def ) );

    # expand all properties except those in %no_expand_map
    foreach my $prop ( keys %$resource_def ) {
        next if exists $no_expand_map{ $prop };
        _expand_property( $resource, $resource_def, $prop );
    }

    # handle non-expandable properties
    #
    # - validations
    my $validations = $resource_def->{'validations'};
    $resources->{$resource}->{'validations'} = $validations if $resource_def->{'validations'};
    #
    # - documentation
    my $documentation = $resource_def->{'documentation'};
    $resources->{$resource}->{'documentation'} = $documentation if $resource_def->{'documentation'};
    #
    # - parent
    if ( $resource ne '/' ) {
        my $parent = $resource_def->{'parent'} || '/';
        push( @{ $resources->{$parent}->{'children'} }, $resource );
        $resources->{$resource}->{'parent'} = $parent;
    }

    return;
}


sub _add_route {
    my $resource = shift;
    my %validations;
    if ( ref( $resources->{$resource}->{'validations'} ) eq 'HASH' ) {
        %validations = %{ $resources->{$resource}->{'validations'} };
        delete $resources->{$resource}->{'validations'};
    }
    my $ARGS = {
        target => $resources->{$resource},
    };
    $ARGS->{'validations'} = \%validations if %validations;
    
    try {
        $router->add_route( $resource, %$ARGS );
    } catch {
        $log->crit( $_ );
    };
}


# takes an individual resource definition property, expands it and puts it in
# $resources package variable
sub _expand_property {
    my ( $resource, $resource_def, $prop ) = @_;
    #$log->debug("Entering " . __PACKAGE__. "::_expand_property with " .
    #            "resource \"$resource\" and property \"$prop\"" );

    # set the resource_name property
    $resources->{$resource}->{'resource_name'} = $resource;

    my @supported_methods = ( ref( $resource_def->{'handler'} ) eq 'HASH' )
        ? keys( %{ $resource_def->{'handler'} } )
        : @{ $site->MREST_SUPPORTED_HTTP_METHODS || [ qw( GET POST PUT DELETE ) ] };
    foreach my $method ( @supported_methods ) {
        #$log->debug( "Considering the \"$method\" method" );
        if ( exists $resource_def->{$prop} ) {
            my $prop_def = $resource_def->{$prop}; 
            my $refv = ref( $prop_def ) || 'SCALAR';
            #$log->debug( "The definition of this property is a $refv" );
            if ( $refv eq 'HASH' ) {
                if ( $prop_def->{$method} ) {
                    $resources->{$resource}->{$method}->{$prop} = $prop_def->{$method};
                } else {
                    $log->crit( "No $prop defined for $method method in $resource!" );
                }
            } elsif ( $refv eq 'SCALAR' ) {
                $resources->{$resource}->{$method}->{$prop} = $prop_def;
            } else {
                die "AAAAAGAAAGAAAAAA! in " . __FILE__ . ", _populate_resources";
            }
        } else {
            # resource with no def_part: suspicious
            $log->notice( "While walking resource definition tree, " . 
                "encountered resource $resource with missing $prop in its definition" ); 
        }
    }
}

1;

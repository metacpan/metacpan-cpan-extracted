package Yahoo::Marketing::VaultService;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Yahoo::Marketing::Service/;

use YAML qw/LoadFile/;

=head1 NAME

Yahoo::Marketing::VaultService - an object that provides access to Yahoo Marketing's Vault SOAP Service.

=cut

=head1 SYNOPSIS

See EWS documentation online for available SOAP methods:

L<http://searchmarketing.yahoo.com/developer/docs/V7/reference/services/VaultService.php>

Also see perldoc Yahoo::Marketing::Service for functionality common to all service modules.



=head2 new

Creates a new instance

=cut 

=head2 use_location_service

    Overrides get/set method to always return 0.  I.E. never use LocationService for VaultService calls

=cut

sub use_location_service {
    return 0;
}

=head2 parse_config

    set endpoint to vault_endpoint from config, if it exists

=cut

sub parse_config {
    my ( $self, %args ) = @_;

    $self->SUPER::parse_config( %args );

    $args{ path }    = 'yahoo-marketing.yml' unless defined $args{ path };
    $args{ section } = 'default'             unless defined $args{ section };

    my $config = LoadFile( $args{ path } );

    my $vault_endpoint = $config->{ $args{ 'section' } }->{ vault_endpoint };

    $self->endpoint( $vault_endpoint ) if defined $vault_endpoint;
}


1;

package VMware::vCloud::vApp;

# ABSTRACT: VMware vCloud Director vApp

use Data::Dumper;

use warnings;
use strict;

our $VERSION = '2.404'; # VERSION
our $AUTHORITY = 'cpan:NIGELM'; # AUTHORITY


sub new {
    my $class = shift @_;
    our $api  = shift @_;
    our $href = shift @_;

    my $self = {};
    bless( $self, $class );

    our $data = $api->vapp_get($href);

    return $self;
}


sub available_actions {
    my %actions;
    for my $action ( @{ our $data->{Link} } ) {
        next if $action->{rel} =~ /^(up|down|edit|controlAccess)$/;
        $actions{ $action->{rel} } = $action->{href};
    }
    return wantarray ? %actions : \%actions;
}


sub dumper {
    return our $data;
}


sub power_on {
    my $self    = shift @_;
    my %actions = $self->available_actions();
    return "Error: Unable to Power On the vApp at this time.\n" . Dumper( \%actions )
        unless defined $actions{'power:powerOn'};

    return our $api->post( $actions{'power:powerOn'} );
}


sub power_off {

}


sub recompose {

}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

VMware::vCloud::vApp - VMware vCloud Director vApp

=head1 VERSION

version 2.404

=head1 DESCRIPTION

This module is instanciated to represent a vApp on vCloud Director. As such, it
contains methods that interact with the specific vApp this object represents.

This is an internal module to VMware::vCloud and is not designed to be used
independantly. You obtain a vApp object by using the get_vapp() method availble
in VMware::vCloud.

=head1 METHODS

=head2 new($class, $api, $href)

Create a new C<VMware::vCloud::vApp> object and fetch the associated data from
the vCloud API.

=head2 available_actions()

This method returns a hash or hashref of available actions that can be
performed on the VM. (Eg: Powering on, deploying, etc.)

Each key represents and action and each value is the corresponding href for
said action to be executed.

=head2 dumper()

This debugging method returns the internal data structure representing all
known information on the vApp.

=head2 power_on($vappid)

If it is an available action, it creates the task to power on a vApp.

It returns an array or arraref with three items: returned message, returned
numeric code, and a hashref of the full XML data returned.

The "Power On" action will deploy the vApp if it is currently undeployed.

A text error message is returned if the app is currently not able to be powered
 on. (IE: It is already on, or is busy with another task.)

=head2 power_off

Not implemented

=head2 recompose

Not implemented

=head1 AUTHORS

=over 4

=item *

Phillip Pollard <bennie@cpan.org>

=item *

Nigel Metheringham <nigelm@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Phillip Pollard <bennie@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

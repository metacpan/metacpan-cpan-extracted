package Webservice::OVH::Hosting;

=encoding utf-8

=head1 NAME

Webservice::OVH::Hosting

=head1 SYNOPSIS

=head1 DESCRIPTION

Gives access to hostings

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.41;

use Webservice::OVH::Hosting::Web;

=head2 _new

Internal Method to create the hosting object.
This method is not ment to be called external.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object

=item * Return: L<Webservice::OVH::Order>

=item * Synopsis: Webservice::OVH::Order->_new($ovh_api_wrapper, $self);

=back

=cut

sub _new {

    my ( $class, %params ) = @_;

    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};

    my $module      = $params{module};
    my $api_wrapper = $params{wrapper};
    
    my $web = Webservice::OVH::Hosting::Web->_new( wrapper => $api_wrapper, module => $module );

    my $self = bless { _module => $module, _api_wrapper => $api_wrapper, _web => $web }, $class;

    return $self;
}

sub web {

    my ($self) = @_;

    return $self->{_web};
}

1;

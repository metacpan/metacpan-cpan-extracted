package Webservice::OVH::Email;

=encoding utf-8

=head1 NAME

Webservice::OVH::Email

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $email_domains = $ovh->email->domains->domains;
    
    foreach my $email_domain (@$email_domains) {
        
        print $email_domain->name;
    }

=head1 DESCRIPTION

Module that support limited access to email methods of the ovh api
The methods that are supported are marked as deprecated by ovh. 
But unitl now they didn't produce a alternative.
For now the MX order Methods are functional.  

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.48;

use Webservice::OVH::Email::Domain;

=head2 _new

Internal Method to create the email object.
This method is not ment to be called external.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object

=item * Return: L<Webservice::OVH::Email>

=item * Synopsis: Webservice::OVH::Email->_new($ovh_api_wrapper, $self);

=back

=cut

sub _new {

    my ( $class, %params ) = @_;

    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};
    my $module      = $params{module};
    my $api_wrapper = $params{wrapper};

    my $self = bless { module => $module, _api_wrapper => $api_wrapper }, $class;

    $self->{_domain} = Webservice::OVH::Email::Domain->_new( wrapper => $api_wrapper, module => $module );

    return $self;
}

=head2 domain

Gives Acces to the /email/domain/ methods of the ovh api

=over

=item * Return: L<Webservice::OVH::Email::Domain>

=item * Synopsis: $ovh->order->email

=back

=cut

sub domain {

    my ($self) = @_;

    return $self->{_domain};
}

1;

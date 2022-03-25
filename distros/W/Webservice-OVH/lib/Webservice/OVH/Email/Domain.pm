package Webservice::OVH::Email::Domain;

=encoding utf-8

=head1 NAME

Webservice::OVH::Email::Domain

=head1 SYNOPSIS

    use Webservice::OVH;
    
    my $ovh = Webservice::OVH->new_from_json("credentials.json");
    
    my $email_domains = $ovh->email->domain->domains;
    
    foreach $email_domain (@$email_domains) {
        
        $email_domain->name;
    }

=head1 DESCRIPTION

Provides access to email domain objects.

=head1 METHODS

=cut

use strict;
use warnings;
use Carp qw{ carp croak };

our $VERSION = 0.47;

use Webservice::OVH::Email::Domain::Domain;

=head2 _new

Internal Method to create the domain object.
This method is not ment to be called external.

=over

=item * Parameter: $api_wrapper - ovh api wrapper object, $module - root object

=item * Return: L<Webservice::OVH::Email::Domain>

=item * Synopsis: Webservice::OVH::Email::Domain->_new($ovh_api_wrapper, $zone_name, $module);

=back

=cut

sub _new {

    my ( $class, %params ) = @_;

    die "Missing module"  unless $params{module};
    die "Missing wrapper" unless $params{wrapper};

    my $module      = $params{module};
    my $api_wrapper = $params{wrapper};

    my $self = bless { _module => $module, _api_wrapper => $api_wrapper, _domains => {}, _aviable_domains => [] }, $class;

    my $api = $self->{_api_wrapper};
    my $response = $api->rawCall( method => 'get', path => "/email/domain/", noSignature => 0 );
    croak $response->error if $response->error;

    $self->{_aviable_domains} = $response->content;

    return $self;
}

=head2 domain_exists

Returns 1 if email-domain is available for the connected account, 0 if not.

=over

=item * Parameter: $domain - (required)Domain name, $no_recheck - (optional)only for internal usage 

=item * Return: VALUE

=item * Synopsis: print "mydomain.com exists" if $ovh->email->domain->domain_exists("mydomain.com");

=back

=cut

sub domain_exists {

    my ( $self, $domain, $no_recheck ) = @_;

    if ( !$no_recheck ) {

        my $api = $self->{_api_wrapper};
        my $response = $api->rawCall( method => 'get', path => "/email/domain/", noSignature => 0 );
        croak $response->error if $response->error;

        $self->{_aviable_domains} = $response->content;

        my $list = $response->content;

        return ( grep { $_ eq $domain } @$list ) ? 1 : 0;

    } else {

        my $list = $self->{_aviable_domains};

        return ( grep { $_ eq $domain } @$list ) ? 1 : 0;
    }
}

=head2 domains

Produces an array of all available email-domains that are connected to the used account.

=over

=item * Return: L<ARRAY>

=item * Synopsis: my $domains = $ovh->email->domain->domains();

=back

=cut

sub domains {

    my ($self) = @_;

    my $api = $self->{_api_wrapper};
    my $response = $api->rawCall( method => 'get', path => "/email/domain/", noSignature => 0 );
    croak $response->error if $response->error;

    my $domain_array = $response->content;
    my $domains      = [];
    $self->{_aviable_domains} = $domain_array;

    foreach my $domain (@$domain_array) {
        if ( $self->domain_exists( $domain, 1 ) ) {
            my $domain = $self->{_domains}{$domain} = $self->{_domains}{$domain} || Webservice::OVH::Email::Domain::Domain->_new( wrapper => $api, id => $domain, module => $self->{_module} );
            push @$domains, $domain;
        }
    }

    return $domains;

}

=head2 domain

Returns a single email-domains by name

=over

=item * Parameter: $domain - domain name

=item * Return: L<Webservice::OVH::Email::Domains::Domain>

=item * Synopsis: my $email_domain = $ovh->email->domain->domain("mydomain.com");

=back

=cut

sub domain {

    my ( $self, $domain ) = @_;

    if ( $self->domain_exists($domain) ) {

        my $api = $self->{_api_wrapper};
        my $domain = $self->{_domains}{$domain} = $self->{_domains}{$domain} || Webservice::OVH::Email::Domain::Domain->_new( wrapper => $api, id => $domain, module => $self->{_module} );

        return $domain;
    } else {

        carp "Domain $domain doesn't exists";
        return undef;
    }
}

1;

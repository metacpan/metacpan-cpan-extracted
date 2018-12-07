package WWW::eNom::Role::Command::Domain::Registration;

use strict;
use warnings;

use Moose::Role;
use MooseX::Params::Validate;

use WWW::eNom::Types qw( DomainRegistration );
use WWW::eNom::DomainRequest::Registration;

use Try::Tiny;
use Carp;

requires 'submit', 'purchase_domain_privacy_for_domain';

our $VERSION = 'v2.7.0'; # VERSION
# ABSTRACT: Domain Registration API Calls

sub register_domain {
    my $self = shift;
    my ( %args ) = validated_hash(
        \@_,
        request => { isa => DomainRegistration, coerce => 1 },
    );

    return try {
        my $response = $self->submit({
            method => 'Purchase',
            params => $args{request}->construct_request(),
        });

        if( $response->{ErrCount} > 0 ) {
            if( grep { $_ eq 'Domain name not available' } @{ $response->{errors} } ) {
                croak 'Domain not available for registration';
            }

            croak 'Unknown error';
        }

        if( $args{request}->is_private ) {
            $self->purchase_domain_privacy_for_domain({
                domain_name   => $args{request}->name,
                years         => $args{request}->years,
                is_auto_renew => $args{request}->is_auto_renew,
            });
        }

        # Because there can be some lag between domain creation and being able to
        # fetch the data from eNom, give it a few tries before calling it a failure
        for ( my $attempt_number = 1; $attempt_number <= 5; $attempt_number++ ) {
            my $domain;
            try {
                $domain = $self->get_domain_by_name( $args{request}->name )
            }
            catch {
                sleep $attempt_number;
            };

            $domain and return $domain;
        }

        croak 'Domain registered but unable to retrieve it';
    }
    catch {
        croak $_;
    };
}

1;

__END__

=pod

=head1 NAME

WWW::eNom::Role::Command::Domain::Registration - Domain Registration API Calls

=head1 SYNOPSIS

    use WWW::eNom;
    use WWW::eNom::Domain;
    use WWW::eNom::DomainRequest::Registration;

    my $api = WWW::eNom->new( ... );

    # Register a new domain
    my $registration_request = WWW::eNom::DomainRequest::Registration->new( ... );
    my $domain = $api->register_domain( request => $registration_request );

=head1 REQUIRES

=over 4

=item submit

=item purchase_domain_privacy_for_domain

This is needed in order to purchase domain privacy for instances of L<WWW::eNom::DomainRequest::Registration> that have is_private set to true.

=back

=head1 DESCRIPTION

Implements domain registration operations with the L<eNom|https://www.enom.com> API.

=head1 METHODS

=head2 register_domain

    my $registration_request = WWW::eNom::DomainRequest::Registration->new( ... );
    my $domain = $api->register_domain( request => $registration_request );

Abstraction of the L<Purchase|https://www.enom.com/api/API%20topics/api_Purchase.htm> eNom API Call.  Given a L<WWW::eNom::DomainRequest::Registration> or a HashRef that can be coerced into a L<WWW::eNom::DomainRequest::Registration>, attempts to register the domain with L<eNom|https://www.enom.com>.  If the domain you attempted to register is unavailable (because you don't sell that public suffix or because it's already taken) this method will croak with details about the error.

Returned is a fully formed L<WWW::eNom::Domain> object.

B<NOTE> This call is fairly slow (several seconds to complete).  This is because, in addition to requesting the domain registration, several API calls are made to fetch back out the recently created domain registration and populate a L<WWW::eNom::Domain> object.

B<FURTHER NOTE> It is possible for the domain registration to succeed but this method fail to retrieve the L<WWW::eNom::Domain>.  When that occurs this method will croak with 'Domain registered but unable to retrieve it'.  In this case you can either just move on (if you don't care about inspecting the L<WWW::eNom::Domain>) or you can request it again using L<WWW::eNom::Role::Command::Domain/get_domain_by_name>.

=cut

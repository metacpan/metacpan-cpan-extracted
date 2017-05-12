package WebService::Avalara::AvaTax::Role::Service;

# ABSTRACT: Common attributes and methods for AvaTax services

use strict;
use warnings;

our $VERSION = '0.020';    # VERSION
use utf8;

#pod =head1 SYNOPSIS
#pod
#pod     use Moo;
#pod     with 'WebService::Avalara::AvaTax::Role::Service';
#pod
#pod =head1 DESCRIPTION
#pod
#pod This role factors out the common attributes and methods used by the
#pod Avalara AvaTax (C<http://developer.avalara.com/api-docs/soap>)
#pod web service interface.
#pod
#pod =cut

use Moo::Role;
use Types::Standard qw(Bool CodeRef HashRef InstanceOf Str);
use Types::URI 'Uri';
use URI;
use XML::Compile::SOAP::WSS;
use XML::Compile::Transport::SOAPHTTP;
use XML::Compile::WSDL11;
use XML::Compile::WSS;
use namespace::clean;

#pod =attr uri
#pod
#pod The L<URI|URI> of the WSDL file used to define the web service.
#pod Consumer classes are expected to set this attribute.
#pod As a convenience this can also be set with anything that
#pod L<Types::URI|Types::URI> can coerce into a C<Uri>.
#pod
#pod =cut

has uri => ( is => 'lazy', isa => Uri, coerce => 1 );

#pod =attr port
#pod
#pod The SOAP port identifier (not to be confused with the TCP/IP port) used in the
#pod WSDL file at L</uri>.
#pod Consumer classes are expected to set this attribute.
#pod
#pod =cut

has port => ( is => 'lazy', isa => Str );

#pod =attr service
#pod
#pod The SOAP service name used in the WSDL file at L</uri>.
#pod Consumer classes are expected to set this attribute.
#pod
#pod =cut

has service => ( is => 'ro', isa => Str );

#pod =attr wsdl
#pod
#pod After construction, you can retrieve the created
#pod L<XML::Compile::WSDL11|XML::Compile::WSDL11> instance.
#pod
#pod Example:
#pod
#pod     my $wsdl = $avatax->wsdl;
#pod     my @soap_operations = map { $_->name } $wsdl->operations;
#pod
#pod =cut

has wsdl => (
    is       => 'lazy',
    isa      => InstanceOf ['XML::Compile::WSDL11'],
    init_arg => undef,
    default  => sub {
        XML::Compile::WSDL11->new(
            $_[0]->user_agent->get( $_[0]->uri )->content );
    },
);

has clients => (
    is       => 'lazy',
    isa      => HashRef [CodeRef],
    init_arg => undef,
);

sub _build_clients {
    my $self = shift;

    my ( $wss, $auth );
    if ( $self->use_wss ) { $wss = XML::Compile::SOAP::WSS->new }
    my $wsdl = $self->wsdl;
    if ( $self->use_wss ) {
        $auth = $wss->basicAuth( map { ( $_ => $self->$_ ) }
                qw(username password) );
    }

    my %soap_params = map { ( $_ => $self->$_ ) } qw(port service);
    my %client_params = (
        transporter => $self->_transport->compileClient,
        %soap_params,
    );
    return {
        map { ( $_ => $wsdl->compileClient( $_, %client_params ) ) }
        map { $_->name } $wsdl->operations(%soap_params),
    };
}

has _current_operation_name => ( is => 'rw', isa => Str, default => q{} );

has _transport =>
    ( is => 'lazy', isa => InstanceOf ['XML::Compile::Transport'] );

sub _build__transport {
    my $self = shift;

    my %soap_params  = map { ( $_ => $self->$_ ) } qw(port service);
    my $wsdl         = $self->wsdl;
    my $endpoint_uri = URI->new( $wsdl->endPoint(%soap_params) );
    my $user_agent   = $self->user_agent;

    $user_agent->add_handler(
        request_prepare => sub {
            $_[0]->header(
                SOAPAction =>
                    $wsdl->operation( $self->_current_operation_name,
                    %soap_params )->soapAction,
            );
        },
        (   m_method => 'POST',
            map { ( "m_$_" => $endpoint_uri->$_ ) } qw(scheme host_port path),
        ),
    );

    return XML::Compile::Transport::SOAPHTTP->new(
        address    => $endpoint_uri,
        user_agent => $user_agent,
    );
}

1;

__END__

=pod

=for :stopwords Mark Gardner ZipRecruiter cpan testmatrix url annocpan anno bugtracker rt
cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 NAME

WebService::Avalara::AvaTax::Role::Service - Common attributes and methods for AvaTax services

=head1 VERSION

version 0.020

=head1 SYNOPSIS

    use Moo;
    with 'WebService::Avalara::AvaTax::Role::Service';

=head1 DESCRIPTION

This role factors out the common attributes and methods used by the
Avalara AvaTax (C<http://developer.avalara.com/api-docs/soap>)
web service interface.

=head1 ATTRIBUTES

=head2 uri

The L<URI|URI> of the WSDL file used to define the web service.
Consumer classes are expected to set this attribute.
As a convenience this can also be set with anything that
L<Types::URI|Types::URI> can coerce into a C<Uri>.

=head2 port

The SOAP port identifier (not to be confused with the TCP/IP port) used in the
WSDL file at L</uri>.
Consumer classes are expected to set this attribute.

=head2 service

The SOAP service name used in the WSDL file at L</uri>.
Consumer classes are expected to set this attribute.

=head2 wsdl

After construction, you can retrieve the created
L<XML::Compile::WSDL11|XML::Compile::WSDL11> instance.

Example:

    my $wsdl = $avatax->wsdl;
    my @soap_operations = map { $_->name } $wsdl->operations;

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc WebService::Avalara::AvaTax

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/WebService-Avalara-AvaTax>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/WebService-Avalara-AvaTax>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/WebService-Avalara-AvaTax>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/WebService-Avalara-AvaTax>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/WebService-Avalara-AvaTax>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/WebService-Avalara-AvaTax>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/W/WebService-Avalara-AvaTax>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=WebService-Avalara-AvaTax>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=WebService::Avalara::AvaTax>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the web
interface at
L<https://github.com/mjgardner/WebService-Avalara-AvaTax/issues>.
You will be automatically notified of any progress on the
request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/mjgardner/WebService-Avalara-AvaTax>

  git clone git://github.com/mjgardner/WebService-Avalara-AvaTax.git

=head1 AUTHOR

Mark Gardner <mjgardner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by ZipRecruiter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

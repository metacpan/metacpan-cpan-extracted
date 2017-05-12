package WebService::Avalara::AvaTax::Service::Tax;

# ABSTRACT: Avalara AvaTax tax engine service via SOAP

use strict;
use warnings;

our $VERSION = '0.020';    # VERSION
use utf8;

#pod =head1 SYNOPSIS
#pod
#pod     use WebService::Avalara::AvaTax::Service::Tax;
#pod
#pod     my $avatax = WebService::Avalara::AvaTax::Service::Tax->new(
#pod         username => 'avalara@example.com',
#pod         password => 'sekrit',
#pod     );
#pod     my ( $answer_ref, $trace ) = $avatax->call('Ping');
#pod
#pod =head1 DESCRIPTION
#pod
#pod This class implements basic support for the
#pod Avalara AvaTax (C<http://developer.avalara.com/api-docs/soap>)
#pod tax engine service using SOAP. Most of its mechanics are in
#pod L<WebService::Avalara::AvaTax::Role::Connection|WebService::Avalara::AvaTax::Role::Connection>,
#pod with defaults for certain attributes as listed below.
#pod
#pod =cut

use File::ShareDir 1.00 'module_file';
use Moo;
use URI;
use XML::Compile::SOAP11;
use XML::Compile::SOAP12;
use XML::Compile::WSDL11;
use namespace::clean;
with qw(
    WebService::Avalara::AvaTax::Role::Connection
    WebService::Avalara::AvaTax::Role::Service
    WebService::Avalara::AvaTax::Role::Dumper
);

#pod =attr uri
#pod
#pod The L<URI|URI> of the WSDL file used to define the web service.
#pod Defaults to C</tax/taxsvc.wsdl>, with the URI base either
#pod C<https://avatax.avalara.net/> if
#pod L<is_production|WebService::Avalara::AvaTax::Role::Connection/is_production>
#pod returns true, or C<https://development.avalara.net/> if it returns false.
#pod
#pod Note that if
#pod L<use_wss|WebService::Avalara::AvaTax::Role::Connection/use_wss>
#pod is false, the alternate security WSDL file C</tax/taxsvcaltsec.wsdl>
#pod will be used instead.
#pod
#pod =cut

has '+uri' => (
    default => sub {
        my $self = shift;
        URI->new_abs( '/tax/taxsvc'
                . ( $self->use_wss ? q{} : 'altsec' )
                . '.wsdl' => 'https://'
                . ( $self->is_production ? 'avatax' : 'development' )
                . '.avalara.net/' );
    },
);

#pod =attr port
#pod
#pod The SOAP port identifier (not to be confused with the TCP/IP port) used in the
#pod WSDL file at L</uri>.
#pod Defaults to C<AddressSvcSoap>.
#pod
#pod =cut

has '+port' => ( default =>
        sub { 'TaxSvc' . ( $_[0]->use_wss ? q{} : 'AltSec' ) . 'Soap' }, );

#pod =attr service
#pod
#pod The SOAP service name used in the WSDL file at L</uri>.
#pod Defaults to C<AddressSvc>.
#pod
#pod =cut

has '+service' => ( default => 'TaxSvc' );

#pod =head1 WORKAROUNDS FOR INCORRECT AVALARA RESPONSES
#pod
#pod As of this writing the Avalara SOAP API returns responses that are
#pod inconsistent with the WSDL document provided. Specifically, the C<TaxIncluded>
#pod and C<GeocodeType> fields in the C<GetTaxResponse> are wrongly placed in their
#pod sequences of fields. This module adds an overlay to the Avalara tax service
#pod WSDL file that attempts to work around these problems so that the responses
#pod may be successfully parsed.
#pod
#pod =cut

has '+wsdl' => (
    default => sub {
        my $self = shift;
        my $wsdl = XML::Compile::WSDL11->new(
            $self->user_agent->get( $self->uri )->content );
        $wsdl->addWSDL( module_file( __PACKAGE__, 'taxsvc_patch.wsdl' ) );
        return $wsdl;
    },
);

#pod =for Pod::Coverage BUILDARGS
#pod
#pod =cut

1;

__END__

=pod

=for :stopwords Mark Gardner ZipRecruiter cpan testmatrix url annocpan anno bugtracker rt
cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 NAME

WebService::Avalara::AvaTax::Service::Tax - Avalara AvaTax tax engine service via SOAP

=head1 VERSION

version 0.020

=head1 SYNOPSIS

    use WebService::Avalara::AvaTax::Service::Tax;

    my $avatax = WebService::Avalara::AvaTax::Service::Tax->new(
        username => 'avalara@example.com',
        password => 'sekrit',
    );
    my ( $answer_ref, $trace ) = $avatax->call('Ping');

=head1 DESCRIPTION

This class implements basic support for the
Avalara AvaTax (C<http://developer.avalara.com/api-docs/soap>)
tax engine service using SOAP. Most of its mechanics are in
L<WebService::Avalara::AvaTax::Role::Connection|WebService::Avalara::AvaTax::Role::Connection>,
with defaults for certain attributes as listed below.

=head1 ATTRIBUTES

=head2 uri

The L<URI|URI> of the WSDL file used to define the web service.
Defaults to C</tax/taxsvc.wsdl>, with the URI base either
C<https://avatax.avalara.net/> if
L<is_production|WebService::Avalara::AvaTax::Role::Connection/is_production>
returns true, or C<https://development.avalara.net/> if it returns false.

Note that if
L<use_wss|WebService::Avalara::AvaTax::Role::Connection/use_wss>
is false, the alternate security WSDL file C</tax/taxsvcaltsec.wsdl>
will be used instead.

=head2 port

The SOAP port identifier (not to be confused with the TCP/IP port) used in the
WSDL file at L</uri>.
Defaults to C<AddressSvcSoap>.

=head2 service

The SOAP service name used in the WSDL file at L</uri>.
Defaults to C<AddressSvc>.

=head1 WORKAROUNDS FOR INCORRECT AVALARA RESPONSES

As of this writing the Avalara SOAP API returns responses that are
inconsistent with the WSDL document provided. Specifically, the C<TaxIncluded>
and C<GeocodeType> fields in the C<GetTaxResponse> are wrongly placed in their
sequences of fields. This module adds an overlay to the Avalara tax service
WSDL file that attempts to work around these problems so that the responses
may be successfully parsed.

=for Pod::Coverage BUILDARGS

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

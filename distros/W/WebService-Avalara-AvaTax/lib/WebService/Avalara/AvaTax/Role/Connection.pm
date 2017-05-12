package WebService::Avalara::AvaTax::Role::Connection;

# ABSTRACT: Common attributes and methods for AvaTax

use strict;
use warnings;

our $VERSION = '0.020';    # VERSION
use utf8;

#pod =head1 SYNOPSIS
#pod
#pod     use Moo;
#pod     with 'WebService::Avalara::AvaTax::Role::Connection';
#pod
#pod =head1 DESCRIPTION
#pod
#pod This role factors out the common attributes and methods used by the
#pod Avalara AvaTax (C<http://developer.avalara.com/api-docs/soap>)
#pod web service interface.
#pod
#pod =cut

use Log::Report;
use LWP::UserAgent;
use LWPx::UserAgent::Cached;
use Moo::Role;
use Mozilla::CA;
use Types::Standard qw(Bool InstanceOf Str);
use namespace::clean;

#pod =attr username
#pod
#pod The Avalara AvaTax Admin Console user name. Usually an email address. Required.
#pod
#pod =cut

has username => ( is => 'ro', isa => Str, required => 1 );

#pod =attr password
#pod
#pod The password used for Avalara authentication. Required.
#pod
#pod =cut

has password => ( is => 'ro', isa => Str, required => 1 );

#pod =attr use_wss
#pod
#pod A boolean value that indicates whether or not to use WSS security tokens in
#pod the SOAP header or to use those specified in Avalara's alternate security WSDL.
#pod Defaults to true. Normally you should leave this alone unless your application
#pod does not work correctly with WSS.
#pod
#pod =cut

has use_wss => ( is => 'rwp', isa => Bool, default => 1 );

#pod =attr is_production
#pod
#pod A boolean value that indicates whether to connect to the production AvaTax
#pod services (true) or development (false). Defaults to false.
#pod
#pod =cut

has is_production => ( is => 'ro', isa => Bool, default => 0 );

#pod =attr debug
#pod
#pod When set to true, the L<Log::Report|Log::Report> dispatcher used by
#pod L<XML::Compile|XML::Compile> and friends is set to I<DEBUG> mode.
#pod
#pod =cut

has debug => (
    is      => 'ro',
    isa     => Bool,
    default => 0,
    trigger =>
        sub { dispatcher( mode => ( $_[1] ? 'DEBUG' : 'NORMAL' ), 'ALL' ) },
);

#pod =attr user_agent
#pod
#pod An instance of an L<LWP::UserAgent|LWP::UserAgent> (sub-)class. You can
#pod use your own subclass to add features such as caching or enhanced logging.
#pod
#pod If you do not specify a C<user_agent> then we default to an instance of
#pod L<LWPx::UserAgent::Cached|LWPx::UserAgent::Cached>. Note that we also set
#pod the C<HTTPS_CA_FILE> environment variable to the result from
#pod L<Mozilla::CA::SSL_ca_file|Mozilla::CA> in order to correctly
#pod resolve certificate names.
#pod
#pod =cut

BEGIN {
    ## no critic (Subroutines::ProhibitCallsToUnexportedSubs)
    ## no critic (Variables::RequireLocalizedPunctuationVars)
    $ENV{HTTPS_CA_FILE} = Mozilla::CA::SSL_ca_file();
}
has user_agent => (
    is      => 'lazy',
    isa     => InstanceOf ['LWP::UserAgent'],
    default => sub { LWPx::UserAgent::Cached->new },
);

1;

__END__

=pod

=for :stopwords Mark Gardner ZipRecruiter cpan testmatrix url annocpan anno bugtracker rt
cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 NAME

WebService::Avalara::AvaTax::Role::Connection - Common attributes and methods for AvaTax

=head1 VERSION

version 0.020

=head1 SYNOPSIS

    use Moo;
    with 'WebService::Avalara::AvaTax::Role::Connection';

=head1 DESCRIPTION

This role factors out the common attributes and methods used by the
Avalara AvaTax (C<http://developer.avalara.com/api-docs/soap>)
web service interface.

=head1 ATTRIBUTES

=head2 username

The Avalara AvaTax Admin Console user name. Usually an email address. Required.

=head2 password

The password used for Avalara authentication. Required.

=head2 use_wss

A boolean value that indicates whether or not to use WSS security tokens in
the SOAP header or to use those specified in Avalara's alternate security WSDL.
Defaults to true. Normally you should leave this alone unless your application
does not work correctly with WSS.

=head2 is_production

A boolean value that indicates whether to connect to the production AvaTax
services (true) or development (false). Defaults to false.

=head2 debug

When set to true, the L<Log::Report|Log::Report> dispatcher used by
L<XML::Compile|XML::Compile> and friends is set to I<DEBUG> mode.

=head2 user_agent

An instance of an L<LWP::UserAgent|LWP::UserAgent> (sub-)class. You can
use your own subclass to add features such as caching or enhanced logging.

If you do not specify a C<user_agent> then we default to an instance of
L<LWPx::UserAgent::Cached|LWPx::UserAgent::Cached>. Note that we also set
the C<HTTPS_CA_FILE> environment variable to the result from
L<Mozilla::CA::SSL_ca_file|Mozilla::CA> in order to correctly
resolve certificate names.

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

package XML::CompileX::Schema::Loader;

use Modern::Perl '2010';    ## no critic (Modules::ProhibitUseQuotedVersion)

our $VERSION = '0.006';     # VERSION
use utf8;
use Moo;
use MooX::Types::MooseLike::Base qw(ArrayRef HashRef InstanceOf);
use HTTP::Exception;
use List::MoreUtils 'uniq';
use LWP::UserAgent;
use URI;
use XML::Compile::WSDL11;
use XML::Compile::Util 'SCHEMA2001';
use XML::Compile::SOAP::Util 'WSDL11';
use XML::LibXML;

has uris => (
    is       => 'rwp',
    isa      => ArrayRef [ InstanceOf ['URI'] ],
    required => 1,
    coerce   => sub {
        'ARRAY' eq ref $_[0]
            ? [ map { URI->new($_) } @{ $_[0] } ]
            : [ URI->new( $_[0] ) ];
    },
);

has user_agent => (
    is      => 'lazy',
    isa     => InstanceOf ['LWP::UserAgent'],
    default => sub { LWP::UserAgent->new },
);

has wsdl => ( is => 'lazy', isa => InstanceOf ['XML::Compile::WSDL11'] );

sub _build_wsdl {
    my $self = shift;
    my @uri  = @{ $self->uris };

    my $wsdl = XML::Compile::WSDL11->new(
        $self->_get_uri_content_ref( shift @uri ) );
    for (@uri) { $wsdl->addWSDL( $self->_get_uri_content_ref($_) ) }

    return $wsdl;
}

sub collect_imports {
    my ( $self, @uri ) = @_;
    my $wsdl = $self->wsdl;
    $self->_set_uris(
        [ @uri = uniq @uri, map { $_->as_string } @{ $self->uris } ] );
    for my $uri ( @{ $self->uris } ) {
        $wsdl->addWSDL( $self->_get_uri_content_ref($uri) );
        $wsdl = $self->_do_imports( $wsdl, $uri );
    }
    $wsdl->importDefinitions( [ values %{ $self->_imports } ] );
    return $wsdl;
}

has _imports => ( is => 'rw', isa => HashRef, default => sub { {} } );

sub _do_imports {
    my ( $self, $wsdl, @locations ) = @_;

    for my $uri ( grep { not exists $self->_imports->{ $_->as_string } }
        @locations )
    {
        my $content_ref = $self->_get_uri_content_ref($uri);
        my $doc = XML::LibXML->load_xml( string => $content_ref );
        $self->_imports(
            +{ %{ $self->_imports }, $uri->as_string => $content_ref } );

        if ( 'definitions' eq $doc->documentElement->getName ) {
            $wsdl->addWSDL($content_ref);
        }
        $wsdl->importDefinitions($content_ref);

        my @imports = (
            _collect( 'location', $uri, $doc, WSDL11, 'import' ),
            map { _collect( 'schemaLocation', $uri, $doc, SCHEMA2001, $_ ) }
                qw(import include),
        );
        if (@imports) { $wsdl = $self->_do_imports( $wsdl, @imports ) }
        undef $doc;
    }
    return $wsdl;
}

sub _collect {
    my ( $attr, $uri, $document, $ns, $element ) = @_;
    return
        map { URI->new_abs( $_->getAttribute($attr), $uri ) }
        $document->getElementsByTagNameNS( $ns => $element );
}

sub _get_uri_content_ref {
    my ( $self, $uri ) = @_;
    my $response = $self->user_agent->get($uri);
    if ( $response->is_error ) {
        HTTP::Exception->throw( $response->code,
            status_message => sprintf '"%s": %s' =>
                ( $uri->as_string, $response->message // q{} ) );
    }
    return $response->decoded_content( ref => 1, raise_error => 1 );
}

1;

# ABSTRACT: Load a web service and its dependencies for XML::Compile::WSDL11

__END__

=pod

=encoding UTF-8

=for :stopwords Mark Gardner ZipRecruiter cpan testmatrix url annocpan anno bugtracker rt
cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 NAME

XML::CompileX::Schema::Loader - Load a web service and its dependencies for XML::Compile::WSDL11

=head1 VERSION

version 0.006

=head1 SYNOPSIS

    use XML::Compile::WSDL11;
    use XML::Compile::SOAP11;
    use XML::Compile::Transport::SOAPHTTP;
    use XML::CompileX::Schema::Loader;

    my $wsdl   = XML::Compile::WSDL11->new;
    my $loader = XML::CompileX::Schema::Loader->new(
        wsdl => $wsdl,
        uris => 'http://example.com/foo.wsdl',
    );
    $loader->collect_imports;
    $wsdl->compileCalls;
    my ( $answer, $trace ) = $wsdl->call( hello => {name => 'Joe'} );

=head1 DESCRIPTION

From the
L<description of XML::Compile::WSDL11|XML::Compile::WSDL11/DESCRIPTION>:

=over

When the [WSDL] definitions are spread over multiple files you will need to
use L<addWSDL()|XML::Compile::WSDL11/"Extension"> (wsdl) or
L<importDefinitions()|XML::Compile::Schema/"Administration">
(additional schema's)
explicitly. Usually, interreferences between those files are broken.
Often they reference over networks (you should never trust). So, on
purpose you B<must explicitly load> the files you need from local disk!
(of course, it is simple to find one-liners as work-arounds, but I will
to tell you how!)

=back

This module implements that work-around, recursively parsing and compiling a
WSDL specification and any imported definitions and schemas. The wrapped WSDL
is available as a C<wsdl> attribute.

You may also provide your own L<LWP::UserAgent|LWP::UserAgent> (sub)class
instance, possibly to correct on-the-fly any broken interreferences between
files as warned above.  You can also provide a caching layer, as with
L<WWW::Mechanize::Cached|WWW::Mechanize::Cached> which is a sub-class of
L<WWW::Mechanize|WWW::Mechanize> and L<LWP::UserAgent|LWP::UserAgent>.

Please see the distribution's F<eg> directory for sample scripts that use
this module to save schemas from a URL to the filesystem and then reload them
again.

=head1 ATTRIBUTES

=head2 wsdl

An L<XML::Compile::WSDL11|XML::Compile::WSDL11> instance. If you do not set
this, a generic instance will be created with the XML from the URIs in C<uris>
added. If there are problems retrieving any files, an
L<HTTP::Exception|HTTP::Exception> is thrown with the details.

=head2 uris

Required string or L<URI|URI> object, or a reference to an array of the same,
that points to WSDL file(s) to compile.

=head2 user_agent

Optional instance of an L<LWP::UserAgent|LWP::UserAgent> that will be used to
get all WSDL and XSD content.

=head1 METHODS

=head2 collect_imports

Loops through all C<uris>, adding them as WSDL documents to C<wsdl> and then
importing all definitions, schemas, included and imported definition and schema
locations.  You should call this before calling any of the L<compilers in
XML::Compile::WSDL11|XML::Compile::WSDL11/Compilers> to ensure that any
dependencies have been imported.

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc XML::CompileX::Schema::Loader

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

MetaCPAN

A modern, open-source CPAN search engine, useful to view POD in HTML format.

L<http://metacpan.org/release/XML-CompileX-Schema-Loader>

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/XML-CompileX-Schema-Loader>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/XML-CompileX-Schema-Loader>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/XML-CompileX-Schema-Loader>

=item *

CPAN Forum

The CPAN Forum is a web forum for discussing Perl modules.

L<http://cpanforum.com/dist/XML-CompileX-Schema-Loader>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.cpanauthors.org/dist/XML-CompileX-Schema-Loader>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/X/XML-CompileX-Schema-Loader>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=XML-CompileX-Schema-Loader>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=XML::CompileX::Schema::Loader>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the web
interface at
L<https://github.com/mjgardner/xml-compilex-schema-loader/issues>.
You will be automatically notified of any progress on the
request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/mjgardner/xml-compilex-schema-loader>

  git clone git://github.com/mjgardner/xml-compilex-schema-loader.git

=head1 AUTHOR

Mark Gardner <mjgardner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by ZipRecruiter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

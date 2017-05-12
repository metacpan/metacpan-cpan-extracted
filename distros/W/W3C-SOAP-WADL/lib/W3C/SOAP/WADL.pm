package W3C::SOAP::WADL;

# Created on: 2013-04-20 13:30:57
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use version;
use Carp;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use TryCatch;
use JSON qw/decode_json/;

extends 'W3C::SOAP::Client';

our $VERSION = version->new('0.007');

has _response => (
    is  => 'rw',
    isa => 'Any',
);

sub _request {
    my ( $self, $method_name, @params ) = @_;
    my $method = $self->_get_method($method_name);

    my $uri = $self->_get_uri($method);
    my $http_request = HTTP::Request->new( $method->method, $uri );
    my $request = $method->has_request ? $method->request : '';
    if ( $request ) {

        # build the request object
        my $object = $request->new(@params);

        # split the object into its components
        # Headers
        my %headers = $object->_get_headers;
        for my $header ( keys %headers ) {
            $http_request->header( $header, $headers{$header} );
        }

        # GET or body parameters
        if ( $method->method eq 'GET' ) {
            $http_request->uri( $uri . '?' . $object->_get_query );
        }
        else {
            $http_request->content( scalar $object->_get_query );
        }
    }

    my $ua       = $self->ua;
    my $response = $method->response;

    $self->clear_response;
    my $http_response = $ua->request( $http_request );
    $self->response($http_response);

    if ( !$response->{ $http_response->code } ) {
        my $msg = "Unknown response code '" . $http_response->code . "'!\n";
        $self->log->error($msg) if $self->has_log;
        confess $msg;
    }

    if ( !$response->{ $http_response->code } ) {
        # unhandled codes
        $self->log->error( "Unknown response code '" . $http_response->code . "'!\n" ) if $self->has_log;
        confess "Unknown response code '" . $http_response->code . "'!\n";
    }

    my $res_class = $response->{ $http_response->code };
    my $object    = $res_class->new( $http_response );
    $self->_response($object);

    my $content = $http_response->content;
    if ( $object->has_representations ) {
        my $type = lc $http_response->headers->content_type;
        my $rep  = $object->_representations->{$type};

        if ( $rep ) {

            # Do any parsing of content
            if ( $rep->{parser} && ref $rep->{parser} eq 'CODE' ) {
                # custom user defined parser
                $content = $rep->{parser}->( $content );
            }
            elsif ( $type eq 'application/json' ) {
                # process JSON
                $content = decode_json($content);
            }
            elsif ( $type eq 'text/xml' || $type eq 'application/xml' ) {
                # get xml element object
                $content = XML::LibXML->load_xml( string => $content );
            }
            elsif (
                $type eq 'x-application-urlencoded'
                || $type eq 'application/x-www-form-urlencoded'
                || $type eq 'multipart/form-data'
            ) {
                # get a form element object
                $content = { map { (split /=/, $_) } split /&/, $content };
            }

            # if the content should be inflated to a particular class, do so
            if ( $rep->{class} ) {
                my $class = $rep->{class};
                $content = $class->new($content);
            }
        }
    }

    return wantarray ? ( $content, $object ) : $content;
}

sub _get_uri {
    my ($self, $method) = @_;

    my $uri = $self->location;
    $uri =~ s{/$}{};
    $uri .= '/' . $method->path;

    return $uri;
}

sub _get_method {
    my ($self, $name) = @_;

    my $method = $self->meta->get_method($name);
    return $method if $method && $method->meta->name eq 'W3C::SOAP::WADL::Meta::Method';

    for my $super ( $self->meta->superclasses ) {
        next unless $super->can('_get_method');
        $method = $super->_get_method($name);
        return $method if $method && $method->meta->name eq 'W3C::SOAP::WADL::Meta::Method';
    }

    confess "Could not find any methods called $name in $self!";
}

1;

__END__

=head1 NAME

W3C::SOAP::WADL - The base object for WADL clients.

=head1 VERSION

This documentation refers to W3C::SOAP::WADL version 0.007.

=head1 SYNOPSIS

   use W3C::SOAP::WADL::Utils;
   extends 'W3C::SOAP::WADL';

   operation name_method (...);

=head1 DESCRIPTION

The C<W3C::SOAP::WADL> class is base class of generated WADL clients.

=head1 SUBROUTINES/METHODS

Provides no public methods, see L<W3C::SOAP::Client> for more details on
client object

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut

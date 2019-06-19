## no critic (Subroutines::ProhibitExportingUndeclaredSubs)
package WebService::MinFraud::Types;

use strict;
use warnings;

our $VERSION = '1.009001';

use Sub::Quote qw( quote_sub );

use namespace::clean;

use GeoIP2::Types 2.006001 qw(
    ArrayRef
    Bool
    BoolCoercion
    HTTPStatus
    HashRef
    IPAddress
    JSONObject
    LocalesArrayRef
    MaxMindID
    MaxMindLicenseKey
    NonNegativeInt
    Num
    Str
    URIObject
    UserAgentObject
    object_isa_type
);

use Exporter qw( import );

our @EXPORT_OK = qw(
    ArrayRef
    Bool
    BoolCoercion
    HTTPStatus
    HashRef
    IPAddress
    IssuerObject
    IssuerObjectCoercion
    JSONObject
    LocalesArrayRef
    MaxMindID
    MaxMindLicenseKey
    NonNegativeInt
    NonNegativeNum
    Num
    Str
    URIObject
    UserAgentObject
    object_isa_type
);

our %EXPORT_TAGS = ( all => \@EXPORT_OK );

## no critic (NamingConventions::Capitalization, ValuesAndExpressions::ProhibitImplicitNewlines)
sub IssuerObject () {
    return quote_sub(
        q{ WebService::MinFraud::Types::object_isa_type( $_[0], 'WebService::MinFraud::Record::Issuer' ) }
    );
}

sub IssuerObjectCoercion () {
    return quote_sub(
        q{
            defined $_[0]
            && Scalar::Util::blessed($_[0])
            && $_[0]->isa('WebService::MinFraud::Record::Issuer')
            ? $_[0]
            : WebService::MinFraud::Record::Issuer->new($_[0]);
        }
    );
}

sub NonNegativeNum () {
    return quote_sub(
        q{ GeoIP2::Types::_tc_fail( $_[0], 'NonNegativeNum' )
               unless defined $_[0]
               && ! ref $_[0]
               && $_[0] =~ /^-?\d+(\.\d+)?$/
               && $_[0] >= 0; }
    );
}

1;

# ABSTRACT: Custom types for the MaxMind minFraud service

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::MinFraud::Types - Custom types for the MaxMind minFraud service

=head1 VERSION

version 1.009001

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/minfraud-api-perl/issues>.

=head1 AUTHOR

Mateu Hunter <mhunter@maxmind.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2019 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

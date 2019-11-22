package VMware::vCloudDirector2::Error;

# ABSTRACT: Throw errors with the best of them

use strict;
use warnings;

our $VERSION = '0.107'; # VERSION
our $AUTHORITY = 'cpan:NIGELM'; # AUTHORITY

use Moose;
use Method::Signatures;

extends 'Throwable::Error';

# ------------------------------------------------------------------------

has uri =>
    ( is => 'ro', isa => 'URI', documentation => 'An optional URI that was being processed' );

has response => ( is => 'ro', isa => 'Object', documentation => 'The response object' );
has object   => ( is => 'ro', isa => 'Object', documentation => 'The object that threw this' );
has request  => ( is => 'ro', isa => 'Object', documentation => 'The request object' );

# ------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

VMware::vCloudDirector2::Error - Throw errors with the best of them

=head1 VERSION

version 0.107

=head1 AUTHOR

Nigel Metheringham <nigelm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Nigel Metheringham.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

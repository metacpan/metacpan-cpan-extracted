package VMware::vCloudDirector::Error;

# ABSTRACT: Throw errors with the best of them

use strict;
use warnings;

our $VERSION = '0.007'; # VERSION
our $AUTHORITY = 'cpan:NIGELM'; # AUTHORITY

use Moose;
use Method::Signatures;

extends 'Throwable::Error';

# ------------------------------------------------------------------------

has uri =>
    ( is => 'ro', isa => 'URI', documentation => 'An optional URI that was being processed' );

has response => ( is => 'ro', isa => 'Object', documentation => 'The response object' );
has request  => ( is => 'ro', isa => 'Object', documentation => 'The request object' );

# ------------------------------------------------------------------------

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

VMware::vCloudDirector::Error - Throw errors with the best of them

=head1 VERSION

version 0.007

=head1 AUTHOR

Nigel Metheringham <nigelm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Nigel Metheringham.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

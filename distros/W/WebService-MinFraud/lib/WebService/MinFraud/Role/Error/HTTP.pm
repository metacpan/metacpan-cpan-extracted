package WebService::MinFraud::Role::Error::HTTP;

use Moo::Role;
use namespace::autoclean;

our $VERSION = '1.009001';

use WebService::MinFraud::Types qw( HTTPStatus URIObject );

has http_status => (
    is       => 'ro',
    isa      => HTTPStatus,
    required => 1,
);

has uri => (
    is       => 'ro',
    isa      => URIObject,
    required => 1,
);

1;

# ABSTRACT: An HTTP Error role

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::MinFraud::Role::Error::HTTP - An HTTP Error role

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

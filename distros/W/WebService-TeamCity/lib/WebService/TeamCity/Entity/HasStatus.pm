package WebService::TeamCity::Entity::HasStatus;

use v5.10;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.04';

use Types::Standard qw( Bool );
use WebService::TeamCity::Types qw( JSONBool );

use Moo::Role;

requires 'status';

has passed => (
    is      => 'ro',
    isa     => Bool | JSONBool,
    lazy    => 1,
    default => sub { $_[0]->status eq 'SUCCESS' },
);

has failed => (
    is      => 'ro',
    isa     => Bool | JSONBool,
    lazy    => 1,
    default => sub { $_[0]->status eq 'FAILURE' },
);

1;

# ABSTRACT: Role for any REST API object with a status

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::TeamCity::Entity::HasStatus - Role for any REST API object with a status

=head1 VERSION

version 0.04

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/WebService-TeamCity/issues>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package WebService::TeamCity::Entity::TestOccurrence;

use v5.10;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.04';

use Types::Standard qw( Bool InstanceOf Int Str );
use WebService::TeamCity::Types qw( TestStatus );
use WebService::TeamCity::Types qw( JSONBool );

use Moo;

has status => (
    is       => 'ro',
    isa      => TestStatus,
    required => 1,
);

has duration => (
    is      => 'ro',
    isa     => Int,
    default => 0,
);

has build => (
    is      => 'ro',
    isa     => InstanceOf ['WebService::TeamCity::Entity::Build'],
    lazy    => 1,
    default => sub {
        $_[0]->_inflate_one(
            $_[0]->_full_data->{build},
            'Build',
        );
    },
);

has unknown => (
    is      => 'ro',
    isa     => Bool | JSONBool,
    lazy    => 1,
    default => sub { $_[0]->status eq 'UNKNOWN' },
);

has details => (
    is      => 'ro',
    isa     => Str,
    lazy    => 1,
    default => sub { $_[0]->_full_data->{details} },
);

with(
    'WebService::TeamCity::Entity',
    'WebService::TeamCity::Entity::HasID',
    'WebService::TeamCity::Entity::HasName',
    'WebService::TeamCity::Entity::HasStatus',
);

1;

# ABSTRACT: A single TeamCity test occurrence

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::TeamCity::Entity::TestOccurrence - A single TeamCity test occurrence

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    my $build = ...;
    my $tests = $build->test_occurrences;

    while ( my $test = $tests->next ) {
        print $test->name, "\n" if $test->failed;
    }

=head1 DESCRIPTION

This class represents a single TeamCity test occurrence.

=head1 API

This class has the following methods:

=head2 $test->href

Returns the REST API URI for the test occurrence, without the scheme and host.

=head2 $test->name

Returns the test occurrence's name.

=head2 $test->description

Returns the test occurrence's description.

=head2 $test->id

Returns the test occurrence's id string.

=head2 $test->status

Returns the test occurrence's status string.

=head2 $test->passed

Returns true if the test occurrence passed.

=head2 $test->failed

Returns true if the test occurrence failed.

=head2 $test->unknown

Returns true if the test occurrence neither passed nor failed.

=head2 $test->build

Returns the L<WebService::TeamCity::Entity::Build> for the test occurrence.

=head2 $test->duration

Returns the test's duration in milliseconds.

=head2 $test->details

Returns details about the test, if any exist. The contents of this field
depend on the details of how the build ran.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/WebService-TeamCity/issues>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

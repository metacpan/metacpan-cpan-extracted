package WebService::TeamCity::Entity::BuildType;

use v5.10;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.04';

use Types::Standard qw( InstanceOf );
use WebService::TeamCity::Entity::Build;
use WebService::TeamCity::Iterator;

use Moo;

has project => (
    is      => 'ro',
    isa     => InstanceOf ['WebService::TeamCity::Entity::Project'],
    lazy    => 1,
    default => sub {
        $_[0]->_inflate_one(
            'Project',
            $_[0]->_full_data->{project},
        );
    },
);

# has template => (
#     is      => 'ro',
#     isa     => Maybe [ InstanceOf [__PACKAGE__] ],
#     lazy    => 1,
#     default => sub {
#         $_[0]->_inflate_one(
#             $_[0]->_full_data->{template},
#             'Template',
#         );
#     },
# );

has builds => (
    is      => 'ro',
    isa     => InstanceOf ['WebService::TeamCity::Iterator'],
    lazy    => 1,
    default => sub {
        $_[0]->_iterator_for(
            $_[0]->client->base_uri . $_[0]->_full_data->{builds}{href},
            'build',
            'Build',
        );
    },
);

# has vcs_root_entries

# has settings

# has parameters

# has steps

# has features

# has triggers

# has snapshot_dependencies

with(
    'WebService::TeamCity::Entity',
    'WebService::TeamCity::Entity::HasDescription',
    'WebService::TeamCity::Entity::HasID',
    'WebService::TeamCity::Entity::HasName',
    'WebService::TeamCity::Entity::HasWebURL',
);

1;

# ABSTRACT: A single TeamCity build type

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::TeamCity::Entity::BuildType - A single TeamCity build type

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    my $build_type = ...;

    my $template = $build_type->template;

=head1 DESCRIPTION

This class represents a single TeamCity build type.

=head1 API

This class has the following methods:

=head2 $build_type->href

Returns the REST API URI for the build type, without the scheme and host.

=head2 $build_type->name

Returns the build type's name.

=head2 $build_type->description

Returns the build type's description.

=head2 $build_type->id

Returns the build type's id string.

=head2 $build_type->web_url

Returns a browser-friendly URI for the build type.

=head2 $build_type->project

Returns the L<WebService::TeamCity::Entity::Project> for the project
associated with the build type.

=head2 $build_type->builds

Returns a L<WebService::TeamCity::Iterator> which returns
L<WebService::TeamCity::Entity::Build> objects.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/WebService-TeamCity/issues>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

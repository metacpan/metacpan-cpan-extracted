package WebService::TeamCity::Entity::Project;

use v5.10;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.04';

use Types::Standard qw( ArrayRef Bool InstanceOf Maybe Str );
use WebService::TeamCity::Entity::BuildType;
use WebService::TeamCity::Entity::Project;
use WebService::TeamCity::Types qw( JSONBool );

use Moo;

has archived => (
    is      => 'ro',
    isa     => Bool | JSONBool,
    default => 0,
);

has parent_project => (
    is      => 'ro',
    isa     => Maybe [ InstanceOf [__PACKAGE__] ],
    lazy    => 1,
    builder => '_build_parent_project',
);

has child_projects => (
    is      => 'ro',
    isa     => ArrayRef [ InstanceOf [__PACKAGE__] ],
    lazy    => 1,
    default => sub {
        $_[0]->_inflate_array(
            $_[0]->_full_data->{projects}{project},
            'Project',
            'parent_project',
        );
    },
);

has build_types => (
    is => 'ro',
    isa =>
        ArrayRef [ InstanceOf ['WebService::TeamCity::Entity::BuildType'] ],
    lazy    => 1,
    default => sub {
        $_[0]->_inflate_array(
            $_[0]->_full_data->{build_types}{build_type},
            'BuildType',
            'project',
        );
    },
);

# has templates => (
#     is      => 'ro',
#     isa     => ArrayRef [ InstanceOf ['WebService::TeamCity::Entity::BuildType'] ],
#     lazy    => 1,
#     default => sub {
#         $_[0]->_inflate_array(
#             $_[0]->_full_data->{templates}{build_type},
#             'BuildType',
#             'project',
#         );
#     },
# );

# has parameters => (
#     is      => 'ro',
#     isa     => ArrayRef [ InstanceOf ['WebService::TeamCity::Parameter'] ],
#     lazy    => 1,
#     default => sub {
#         $_[0]->_inflate_array(
#             'Parameter',
#             $_[0]->_full_data->{projects}{parameters},
#         );
#     },
# );

# has vcs_roots => (
#     is      => 'ro',
#     isa     => ArrayRef [ InstanceOf ['WebService::TeamCity::VCSRoot'] ],
#     lazy    => 1,
#     default => sub {
#         $_[0]->_inflate_array(
#             'VCSRoot',
#             $_[0]->_full_data->{projects}{vcs_roots},
#         );
#     },
# );

with(
    'WebService::TeamCity::Entity',
    'WebService::TeamCity::Entity::HasDescription',
    'WebService::TeamCity::Entity::HasID',
    'WebService::TeamCity::Entity::HasName',
    'WebService::TeamCity::Entity::HasWebURL',
);

sub _build_parent_project {
    my $self = shift;

    my $full_data = $self->_full_data;
    return unless $full_data->{parent_project};

    return $self->_inflate_one(
        $full_data->{parent_project},
        'Project',
    );
}

1;

# ABSTRACT: A single TeamCity project

__END__

=pod

=encoding UTF-8

=head1 NAME

WebService::TeamCity::Entity::Project - A single TeamCity project

=head1 VERSION

version 0.04

=head1 SYNOPSIS

    my $project = ...;

    my $parent = $project->parent_project;

=head1 DESCRIPTION

This class represents a single TeamCity project.

=head1 API

This class has the following methods:

=head2 $project->href

Returns the REST API URI for the project, without the scheme and host.

=head2 $project->name

Returns the project's name.

=head2 $project->description

Returns the project's description.

=head2 $project->id

Returns the project's id string.

=head2 $project->web_url

Returns a browser-friendly URI for the project.

=head2 $project->archived

Returns true if the project has been archived.

=head2 $project->parent_project

Returns the L<WebService::TeamCity::Entity::Project> for the project's parent,
if it has one.

=head2 $project->child_projects

Returns an arrayref of L<WebService::TeamCity::Entity::Project> objects. If
there are no child projects it returns an empty arrayref.

=head2 $project->build_types

Returns an arrayref of L<WebService::TeamCity::Entity::BuildType> objects for
the build types associated with this project.

=head1 SUPPORT

Bugs may be submitted through L<https://github.com/maxmind/WebService-TeamCity/issues>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by MaxMind, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

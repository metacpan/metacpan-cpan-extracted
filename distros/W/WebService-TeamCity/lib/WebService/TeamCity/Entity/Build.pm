package WebService::TeamCity::Entity::Build;

use v5.10;
use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.03';

use Archive::Zip;
use File::pushd qw( pushd );
use Path::Tiny 0.086 qw( path tempdir );
use Types::Standard qw( ArrayRef Bool Maybe InstanceOf Str );
use WebService::TeamCity::Entity::BuildType;
use WebService::TeamCity::Iterator;
use WebService::TeamCity::Entity::TestOccurrence;
use WebService::TeamCity::Types qw( BuildStatus );

use Moo;

has status => (
    is       => 'ro',
    isa      => BuildStatus,
    required => 1,
);

has build_type => (
    is      => 'ro',
    isa     => InstanceOf ['WebService::TeamCity::Entity::BuildType'],
    lazy    => 1,
    default => sub {
        $_[0]->_inflate_one(
            $_[0]->_full_data->{build_type},
            'BuildType',
        );
    },
);

has test_occurrences => (
    is      => 'ro',
    isa     => InstanceOf ['WebService::TeamCity::Iterator'],
    lazy    => 1,
    default => sub {
        $_[0]->_iterator_for(
                  $_[0]->client->base_uri
                . $_[0]->_full_data->{test_occurrences}{href},
            'test_occurrence',
            'TestOccurrence',
        );
    },
);

has branch_name => (
    is        => 'ro',
    isa       => Str,
    predicate => 'has_branch_name',
);

has default_branch => (
    is        => 'ro',
    isa       => Bool,
    predicate => 'has_default_branch',
);

has number => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has state => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has queued_date => (
    is      => 'ro',
    isa     => InstanceOf ['DateTime'],
    lazy    => 1,
    default => sub {
        $_[0]->_parse_datetime( $_[0]->_full_data->{queued_date} );
    },
);

has start_date => (
    is      => 'ro',
    isa     => Maybe [ InstanceOf ['DateTime'] ],
    lazy    => 1,
    default => sub {
        my $full = $_[0]->_full_data;
        return unless $full->{start_date};
        $_[0]->_parse_datetime( $full->{start_date} );
    },
);

has finish_date => (
    is      => 'ro',
    isa     => Maybe [ InstanceOf ['DateTime'] ],
    lazy    => 1,
    default => sub {
        my $full = $_[0]->_full_data;
        return unless $full->{finish_date};
        $_[0]->_parse_datetime( $full->{finish_date} );
    },
);

has _artifacts_dir => (
    is      => 'ro',
    isa     => ArrayRef,
    lazy    => 1,
    builder => '_build_artifacts_dir',
);

# has statistics

# has properties

# has related_issues

# has agent

# has revisions

# has changes

# has triggered

# has last_changes

# has problem_occurences

with(
    'WebService::TeamCity::Entity',
    'WebService::TeamCity::Entity::HasID',
    'WebService::TeamCity::Entity::HasStatus',
    'WebService::TeamCity::Entity::HasWebURL',
);

sub artifacts_dir { $_[0]->_artifacts_dir->[1] }

sub _build_artifacts_dir {
    my $self = shift;

    my $tempdir = tempdir( CLEANUP => 1 );

    ( my $base = $self->href ) =~ s{/$}{};

    my $zip = $tempdir->child('artifacts.zip');
    $self->client->make_request(
        uri  => $self->client->uri_for( $base . '/artifacts/archived' ),
        file => $zip->stringify,
    );

    my $dir = $tempdir->child('artifacts');
    $dir->mkpath(
        {
            verbose => 0,
            ## no critic (ValuesAndExpressions::ProhibitLeadingZeros)
            mode => 0755,
        }
    );

    # The zip file downloaded from TC may have very odd permissions for
    # directories (dirs without execute bits on). The
    # Archive::Zip::Archive->extractTree method simply blows up because of
    # this. It makes a parent dir and then cannot write the files it contains
    # into that directory.
    #
    # So we go through each member in the zip and extract it ourselves, then
    # change the permissions to something sane.
    my $az = Archive::Zip->new;
    $az->read( $zip->stringify );

    my $pushed = pushd($dir);

    for my $member ( $az->members ) {
        $az->extractMember($member);
        my $extracted = $dir->child( $member->fileName );
        ## no critic (ValuesAndExpressions::ProhibitLeadingZeros)
        $extracted->chmod( $extracted->is_dir ? 0755 : 0644 );
    }

    # We have to save the temp dir in the object or it gets cleaned up when
    # $tempdir goes out of scope.
    return [ $tempdir, $dir ];
}

1;

# ABSTRACT: A single TeamCity build

__END__

=pod

=head1 NAME

WebService::TeamCity::Entity::Build - A single TeamCity build

=head1 VERSION

version 0.03

=head1 SYNOPSIS

    my $build = ...;

    if ( $build->passed ) { ... }

=head1 DESCRIPTION

This class represents a single TeamCity build.

=head1 API

This class has the following methods:

=head2 $build->href

Returns the REST API URI for the build, without the scheme and host.

=head2 $build->id

Returns the build's id string.

=head2 $build->status

Returns the build's status string.

=head2 $build->passed

Returns true if the build passed. Note that both both C<passed> and C<failed>
can return false if the build is not yet finished.

=head2 $build->failed

Returns true if the build failed. Note that both both C<passed> and C<failed>
can return false if the build is not yet finished.

=head2 $build->web_url

Returns a browser-friendly URI for the build.

=head2 $build->build_type

Returns the L<WebService::TeamCity::Entity::BuildType> object for this build's
type.

=head2 $build->test_occurrences

Returns a L<WebService::TeamCity::Iterator> for each of the build's test
occurrences. The iterator returns
L<WebService::TeamCity::Entity::TestOccurrence> objects.

=head2 $build->branch_name

Returns the branch name for this build. Note that this might be C<undef>.

=head2 $build->has_branch_name

Returns true if there is a branch associated with the build.

=head2 $build->default_branch

Returns true or false indicating whether the build used the default branch.

=head2 $build->has_default_branch

Returns true or false indicating whether there is any information about the
default branch. Builds can exist without an associated branch, in which case
this returns false.

=head2 $build->number

Returns the build's build number (which can actually be a string).

=head2 $build->state

Returns a string describing the build's state.

=head2 $build->queued_date

Returns a L<DateTime> object indicating when the build was queued.

=head2 $build->start_date

Returns a L<DateTime> object indicating when the build was started. If the
build has not yet been started then this returns C<undef>.

=head2 $build->finish_date

Returns a L<DateTime> object indicating when the build was finished. If the
build has not yet been finished then this returns C<undef>.

=head2 $build->artifacts_dir

This method fetches all of the artifacts for the build and extracts them to a
new temporary directory. It then returns the directory containing the
artifacts as a L<Path::Tiny> object.

Note that this temporary directory will be cleaned up when the build object
goes out of scope.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by MaxMind, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

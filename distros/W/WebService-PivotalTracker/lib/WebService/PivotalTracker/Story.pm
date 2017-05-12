package WebService::PivotalTracker::Story;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.07';

use Params::ValidationCompiler qw( validation_for );
use WebService::PivotalTracker::Comment;
use WebService::PivotalTracker::Label;
use WebService::PivotalTracker::PropertyAttributes;
use WebService::PivotalTracker::Types qw(
    ArrayRef CommentObject DateTimeObject LabelObject Maybe
    NonEmptyStr Num PositiveInt Str StoryState StoryType Uri
);

use Moo;

my %props = (
    id            => PositiveInt,
    project_id    => PositiveInt,
    name          => NonEmptyStr,
    description   => Str,
    story_type    => StoryType,
    current_state => StoryState,
    estimate      => Maybe [Num],
    accepted_at   => {
        type     => DateTimeObject,
        inflator => '_inflate_iso8601_datetime',
    },
    deadline => {
        type     => DateTimeObject,
        inflator => '_inflate_iso8601_datetime',
    },
    requested_by_id => PositiveInt,
    owner_ids       => ArrayRef [PositiveInt],
    task_ids        => {
        type => ArrayRef [PositiveInt],
        default => sub { [] },
    },
    follower_ids => {
        type => ArrayRef [PositiveInt],
        default => sub { [] },
    },
    created_at => {
        type     => DateTimeObject,
        inflator => '_inflate_iso8601_datetime',
    },
    updated_at => {
        type     => DateTimeObject,
        inflator => '_inflate_iso8601_datetime',
    },
    url => {
        type     => Uri,
        inflator => '_inflate_uri',
    },
    kind => NonEmptyStr,
);

has( @{$_} ) for props_to_attributes(%props);

has comments => (
    is       => 'ro',
    isa      => ArrayRef [CommentObject],
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_comments',
    clearer  => '_clear_comments',
);

has labels => (
    is       => 'ro',
    isa      => ArrayRef [LabelObject],
    init_arg => undef,
    lazy     => 1,
    builder  => '_build_labels',
    clearer  => '_clear_labels',
);

with 'WebService::PivotalTracker::Entity';

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _properties {
    return %props;
}
## use critic

{
    my $check = validation_for(
        params => {
            current_state => { type => StoryState },
        }
    );

    sub update {
        my $self = shift;
        my %args = $check->(@_);

        my $raw = $self->_client->put( $self->_self_uri, \%args );

        return ( ref $self )->new(
            raw_content => $raw,
            pt_api      => $self->_pt_api,
        );
    }
}

{
    my $check = validation_for(
        params => {
            person_id => {
                type     => PositiveInt,
                optional => 1,
            },
            text => { type => NonEmptyStr },
        }
    );

    sub add_comment {
        my $self = shift;
        my %args = $check->(@_);

        my $comment = WebService::PivotalTracker::Comment->new(
            raw_content =>
                $self->_client->post( $self->_comments_uri, \%args ),
            pt_api => $self->_pt_api,
        );
        $self->_clear_comments;

        return $comment;
    }
}

# We could fetch each id in $self->comment_ids one at a time, but there's an
# endpoint to get all the comments at once, which is going to be more
# efficient.
sub _build_comments {
    my $self = shift;

    my $raw_comments = $self->_client->get( $self->_comments_uri );

    return [
        map {
            WebService::PivotalTracker::Comment->new(
                raw_content => $_,
                pt_api      => $self->_pt_api,
                )
        } @{$raw_comments}
    ];
}

sub _comments_uri {
    my $self = shift;

    my $path = sprintf(
        '/projects/%s/stories/%s/comments',
        $self->project_id,
        $self->id,
    );

    return $self->_client->build_uri($path);
}

before _clear_comments => sub {
    my $self = shift;
    delete $self->raw_content->{comments};
};

{
    my $check = validation_for(
        params => {
            name => { type => NonEmptyStr },
        }
    );

    sub add_label {
        my $self = shift;
        my %args = $check->(@_);

        $self->_client->post( $self->_labels_uri, \%args );
        $self->_clear_labels;

        return;
    }
}

before _clear_labels => sub {
    my $self = shift;
    delete $self->raw_content->{labels};
};

# We might already have all the label info, otherwise we can fetch all the
# labels at once rather iterating over each id, just like with comments.
sub _build_labels {
    my $self = shift;

    if ( $self->raw_content->{labels} ) {
        return [
            map {
                WebService::PivotalTracker::Label->new(
                    raw_content => $_,
                    pt_api      => $self->_pt_api,
                    )
            } @{ $self->raw_content->{labels} }
        ];
    }

    my $raw_labels = $self->_client->get( $self->_labels_uri );

    return [
        map {
            WebService::PivotalTracker::Label->new(
                raw_content => $_,
                pt_api      => $self->_pt_api,
                )
        } @{$raw_labels}
    ];
}

sub _labels_uri {
    my $self = shift;

    my $path = sprintf(
        '/projects/%s/stories/%s/labels',
        $self->project_id,
        $self->id,
    );

    return $self->_client->build_uri($path);
}

sub _self_uri {
    my $self = shift;

    return $self->_client->build_uri(
        sprintf(
            '/stories/%s',
            $self->id,
        )
    );
}

1;

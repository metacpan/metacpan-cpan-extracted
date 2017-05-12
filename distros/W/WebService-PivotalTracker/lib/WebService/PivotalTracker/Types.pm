package WebService::PivotalTracker::Types;

use strict;
use warnings;

our $VERSION = '0.07';

use Type::Library
    -base,
    -declare => qw(
    ClientObject
    CommentObject
    DateTimeObject
    DayOfWeek
    IterationScope
    LabelObject
    LWPObject
    MD5Hex
    ProjectType
    PTAPIObject
    StoryState
    StoryType
);
use Type::Utils -all;
use Types::Common::Numeric;
use Types::Common::String;
use Types::Standard -types;
use Types::URI;

BEGIN {
    extends qw(
        Types::Common::Numeric
        Types::Common::String
        Types::Standard
        Types::URI
    );
}

class_type ClientObject, { class => 'WebService::PivotalTracker::Client' };

class_type CommentObject, { class => 'WebService::PivotalTracker::Comment' };

class_type DateTimeObject, { class => 'DateTime' };

enum DayOfWeek, [
    qw(
        monday
        tuesday
        wednesday
        thursday
        friday
        saturday
        sunday
        )
];

enum IterationScope, [
    qw(
        done
        current
        backlog
        current_backlog
        done_current
        )
];

class_type LabelObject, { class => 'WebService::PivotalTracker::Label' };

class_type LWPObject, { class => 'LWP::UserAgent' };

declare MD5Hex,
    as Str,
    where {m/^[0-9a-f]{32}$/i},
    inline_as {
    $_[0]->parent->inline_check( $_[1] ) . " && $_[1] =~ m/^[0-9a-f]{32}\$/i"
    };

enum ProjectType, [
    qw(
        demo
        private
        public
        shared
        )
];

class_type PTAPIObject, { class => 'WebService::PivotalTracker' };

enum StoryState, [
    qw(
        accepted
        delivered
        finished
        started
        rejected
        planned
        unstarted
        unscheduled
        )
];

enum StoryType, [qw( feature bug chore release )];

1;

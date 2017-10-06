package UR::Object::Command::Copy;

use strict;
use warnings FATAL => 'all';

class UR::Object::Command::Copy {
    is => 'Command::V2',
    is_abstract => 1,
    has => {
        changes => {
            is => 'Text',
            is_many => 1,
            doc => 'A name/value comma-separated list of changes',
        },
    },
};

sub help_detail {
<<HELP;
    Any non-delegated, non-ID properties may be specified with an operator and a value.

    Valid operators are '=', '+=', '-=', and '.='; function is same as in Perl.
    Example:
        --changes "name.=-RT101912,foo=bar"

    A value of 'undef' may be used to pass a Perl undef as the value.  Either `foo=` [safer] or `foo=''` can be used to set the value to an empty string.
HELP
}

sub execute {
    my $self = shift;

    my $tx = UR::Context::Transaction->begin;

    my $copy = $self->source->copy();

    my $failure;
    for my $change ($self->changes) {
        my ($key, $op, $value) = $change =~ /^(.+?)(=|\+=|\-=|\.=)(.*)$/;
        $failure = "Invalid change: $change" and last
            unless $key and defined $op;
        $failure = sprintf('Invalid property %s for %s', $key, $copy->__display_name__) and last
            if !$copy->can($key);

        $value = undef if $value eq '';

        if ($op eq '=') {
            $copy->$key($value);
        }
        elsif ($op eq '+=') {
            $copy->$key($copy->$key + $value);
        }
        elsif ($op eq '-=') {
            $copy->$key($copy->$key - $value);
        }
        elsif ($op eq '.=') {
            $copy->$key($copy->$key . $value);
        }
    }

    if ($failure or !$tx->commit ) {
        $tx->rollback;
        $self->fatal_message($failure || 'Failed to commit software transaction!');
    }

    $self->status_message("NEW\t%s\t%s", $copy->class, $copy->__display_name__);
    1;
}

1;

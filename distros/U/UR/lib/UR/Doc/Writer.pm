package UR::Doc::Writer;

use strict;
use warnings;

use UR;
our $VERSION = "0.46"; # UR $VERSION;
use Carp qw/croak/;

class UR::Doc::Writer {
    is => 'UR::Object',
    is_abstract => 1,
    has => [
        title => { is => 'Text', },
        sections => {
            is => 'UR::Doc::Section',
            is_many => 1,
        },
        navigation => {
            is => 'ARRAY',
            is_optional => 1,
        },
    ],
    has_transient_optional => [
        content => {
            is => 'Text',
            default_value => '',
        },
    ]
};

sub _append {
    my ($self, $data) = @_;
    $self->content($self->content . $data);
}

sub generate_index {
    my ($self, @command_trees) = @_;
    return '';
}

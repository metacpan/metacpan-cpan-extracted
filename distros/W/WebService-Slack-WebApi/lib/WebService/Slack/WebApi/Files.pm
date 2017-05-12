package WebService::Slack::WebApi::Files;
use strict;
use warnings;
use utf8;
use feature qw/state/;

use parent 'WebService::Slack::WebApi::Base';

use WebService::Slack::WebApi::Generator (
    delete => {
        file => 'Str',
    },
    info => {
        file  => 'Str',
        count => { isa => 'Int', optional => 1 },
        page  => { isa => 'Int', optional => 1 },
    },
    list => {
        user    => { isa => 'Str', optional => 1 },
        ts_from => { isa => 'Str', optional => 1 },
        ts_to   => { isa => 'Str', optional => 1 },
        types   => { isa => 'Str', optional => 1 },
        count   => { isa => 'Int', optional => 1 },
        page    => { isa => 'Int', optional => 1 },
    },
);

sub upload {
    state $rule = Data::Validator->new(
        file            => { isa => 'Str', optional => 1 },
        content         => { isa => 'Str', optional => 1 },
        filetype        => { isa => 'Str', optional => 1 },
        filename        => { isa => 'Str', optional => 1 },
        title           => { isa => 'Str', optional => 1 },
        initial_comment => { isa => 'Str', optional => 1 },
        channels        => { isa => 'ArrayRef[Str]', optional => 1 },
    )->with('Method', 'AllowExtra');
    my ($self, $args, %extra) = $rule->validate(@_);

    $args->{file} = [$args->{file}] if exists $args->{file};
    $args->{channels} = join ',', @{$args->{channels}} if exists $args->{channels};

    return $self->request('upload', {%$args, %extra});
}

1;


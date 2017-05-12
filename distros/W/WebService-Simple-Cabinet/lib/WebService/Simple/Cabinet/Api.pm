package WebService::Simple::Cabinet::Api;

use strict;
use warnings;

use WebService::Simple;

sub new {
    my($class, %args) = @_;

    my $self = bless {
        %args,
        api => WebService::Simple->new(%{ $args{simple_opts} }),
    }, $class;

    $self->init;
    $self;
}

sub init {}

sub response { shift->{response} }

1;

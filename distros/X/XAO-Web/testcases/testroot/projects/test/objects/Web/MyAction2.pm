package XAO::DO::Web::MyAction2;
use strict;
use XAO::Utils;
use XAO::Objects;
use base XAO::Objects->load(objname => 'Web::Action');

sub display_test_one ($@) {
    my $self=shift;
    my $args=get_args(\@_);

    $args->{'arg'} || throw $self "- no 'arg'";

    $self->textout('MyAction2: test-one-ok');
}

sub check_mode ($%) {
    my $self=shift;
    my $args=get_args(\@_);
    my $mode=$args->{mode} || 'no-mode';
    if($mode eq 'foo') {
        $self->textout('MyAction2: Got FOO');
    }
    elsif($mode eq 'no-mode') {
        $self->textout('MyAction2: Got MODELESS');
    }
    else {
        $self->SUPER::check_mode($args);
    }
}

1;

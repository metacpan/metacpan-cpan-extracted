package XAO::DO::Web::MyAction;
use strict;
use warnings;
use base XAO::Objects->load(objname => 'Web::Action');
use Error qw(:try);
use XAO::Objects;
use XAO::Utils;

# display_* only

sub display_test_one ($@) {
    my $self=shift;
    my $args=get_args(\@_);

    $args->{'arg'} || throw $self "- no 'arg'";

    $self->textout('test-one-ok');
}

# data_* and display_*

sub data_test_two ($@) {
    my $self=shift;
    my $args=get_args(\@_);

    return {
        'foo'       => 'bar',
        'hashref'   => { a => 'aa', b => 'bb' },
        'arg'       => 'xx'.($args->{'arg'} || throw $self "- no 'arg'"),
    };
}

sub display_test_two ($@) {
    my $self=shift;
    my $args=get_args(\@_);

    my $data=$args->{'data'} || throw $self "- no 'data'";

    ref($data) eq 'HASH' || throw $self "- data is not a hash";

    $data->{'arg'} eq 'xx'.$args->{'arg'} ||
        throw $self "- invalid data->{arg}='$data->{'arg'}'";

    $self->textout('test-two-ok');
}

# data_* only, no display_*, array ref data

sub data_test_three ($@) {
    my $self=shift;
    my $args=get_args(\@_);

    return [
        'foo',
        'bar',
    ];
}

# data_* only, no display_*, hash ref data

sub data_test_four ($@) {
    my $self=shift;
    my $args=get_args(\@_);

    return {
        'foo'   => 'scalar',
        'bar'   => { 'hash' => 'ref' },
    };
}

# XML converter for 'test-four'

sub xml_test_four ($@) {
    my $self=shift;
    my $args=get_args(\@_);

    my $data=$args->{'data'};

    return
        '<test-four>' .
            '<foo>' . $data->{'foo'} . '</foo>' .
            '<bar><hash>' . $data->{'bar'}->{'hash'} . '</hash></bar>' .
        '</test-four>';
}

sub xml_generic ($@) {
    my $self=shift;
    my $args=get_args(\@_);

    my $data=$args->{'data'};

    return '<data-keys>' . join(',',sort keys %$data) . '</data-keys>';
}

# data_* and display_* for alternate display and data tests

sub data_test_alt ($@) {
    my $self=shift;
    my $args=get_args(\@_);
    return {
        arg => ($args->{'arg'} || ''),
    };
}

sub display_test_alt ($@) {
    my $self=shift;
    my $args=get_args(\@_);
    $self->textout('ALT:'.($args->{'data'}->{'arg'} || ''));
}

sub display_throw_error ($@) {
    my $self=shift;
    my $args=get_args(\@_);
    my $text=$args->{'text'} || 'Intentional Error';
    throw $self "- {{$text}}";
}

sub display_catch_error ($@) {
    my $self=shift;
    my $args=get_args(\@_);

    my $prefix=$args->{'prefix'} || '[Prefix]';
    my $suffix=$args->{'suffix'} || '[Suffix]';

    $self->textout($prefix);

    try {
        $self->object->expand($args);
    }
    otherwise {
        my $etext=''.shift;
        $etext=$1 if $etext=~/\{\{\s*(.*?)\s*\}\}/;
        $self->textout("[Error:$etext]");
    };

    $self->textout($suffix);
}

# Old style

sub check_mode ($%) {
    my $self=shift;
    my $args=get_args(\@_);
    my $mode=$args->{mode} || 'no-mode';

    if($mode eq 'foo') {
        $self->textout('Got FOO');
    }
    elsif($mode eq 'no-mode') {
        $self->textout('Got MODELESS');
    }
    else {
        $self->SUPER::check_mode($args);
    }
}

1;

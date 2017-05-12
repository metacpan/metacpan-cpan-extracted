use strict;
use warnings;

use Test::More tests => 1;

package MySprintf;

use base 'Text::Sprintf::Named';

sub calc_param
{
    my ($self, $args) = @_;

    my $method = $args->{name};

    return $args->{named_params}->{obj}->$method();
}

package MyObj;

sub new
{
    my $class = shift;
    my $self = {};
    bless $self, $class;
    $self->_init(@_);
    return $self
}

sub _init
{
    my $self = shift;

    $self->{hello} = "Foo Goo";
}

sub hello
{
    return "Twalidoo";
}

package main;

{
    my $formatter = MySprintf->new({fmt => "{%(hello)s}"});

    my $hello_obj = MyObj->new;

    # TEST
    is ($formatter->format({args => {obj => $hello_obj, hello => "Though I am here"}}),
        "{Twalidoo}",
        "Customizability of Text::Sprintf::Named",
    );
}

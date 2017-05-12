# Defines the behavior of the +test+ keyword.
# @api private
package Test::Mini::Unit::Sugar::Test;
use base 'Devel::Declare::Context::Simple';
use strict;
use warnings;

use Devel::Declare ();
use Sub::Name;

sub import {
    my ($class, %args) = @_;
    my $caller = $args{into} || caller;

    {
        no strict 'refs';
        *{"$caller\::test"} = sub (&) {};
    }

    Devel::Declare->setup_for(
        $caller => { test => { const => sub { $class->new()->parser(@_) } } }
    );
}

sub parser {
    my $self = shift;
    $self->init(@_);

    $self->skip_declarator;
    my $name = $self->strip_name;

    $self->inject_if_block($_) for reverse (
        $self->scope_injector_call(),
        'my $self = shift;',
    );

    $self->shadow($self->code("test_$name"));
}

sub code {
    my ($self, $name) = @_;

    my $pkg = $self->get_curstash_name;
    $name = join('::', $pkg, $name) unless ($name =~ /::/);

    return sub (&) {
        no strict 'refs';
        *{$name} = subname $name => shift;
    };
}

1;

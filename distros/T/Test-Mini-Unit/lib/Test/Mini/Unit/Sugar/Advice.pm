# Defines the behavior of the test advice keywords (+setup+ and +teardown+).
# @api private
package Test::Mini::Unit::Sugar::Advice;
use base 'Devel::Declare::Context::Simple';
use strict;
use warnings;

use B::Hooks::EndOfScope;
use Devel::Declare ();
use Sub::Name;

sub import {
    my ($class, %args) = @_;
    die 'Test::Mini::Unit::Sugar::Advice requires a name argument!' unless $args{name};

    my $caller = $args{into} || caller;
    my $ctx = $class->new(%args, advice => [ $caller->can($args{name}) || () ]);

    {
        no strict 'refs';
        no warnings;

        *{"$caller\::$args{name}"} = sub (&) {};

        on_scope_end {
            *{"$caller\::$args{name}"} = sub { $_->(@_) for @{$ctx->{advice}} };
        }
    }

    Devel::Declare->setup_for(
        $caller => { $args{name} => { const => sub { $ctx->parser(@_) } } }
    );
}

sub parser {
    my $self = shift;
    $self->init(@_);

    $self->skip_declarator;

    $self->inject_if_block($_) for reverse (
        $self->scope_injector_call(),
        'my $self = shift;',
    );

    if ($self->{order} eq 'pre') {
        $self->shadow(sub (&) { push @{$self->{advice}}, @_ });
    }
    elsif ($self->{order} eq 'post') {
        $self->shadow(sub (&) { unshift @{$self->{advice}}, @_ });
    }
}

1;

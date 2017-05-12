package Text::Xatena::Inline::Base;

use strict;
use warnings;
use List::MoreUtils qw(any);

sub import {
    my $class = shift;
    my $caller = caller(0);
    if (any { $_ eq '-Base' } @_) {
        no strict 'refs';
        push @{"$caller\::ISA"}, $class;

        for my $method (qw/match/) {
            no warnings 'redefine';
            *{"$caller\::$method"} = \&{"$class\::$method"};
        }
    }
}

sub inlines {
    my ($caller) = @_;
    $caller = ref($caller) || $caller;
    no strict 'refs';
    ${$caller.'::_inlines'} ||= do {
        my $parents = [];
        for my $isa (@{$caller.'::ISA'}) {
            my $isa = $isa->inlines;
            push @$parents, @$isa;
        }
        $parents;
    };
}

sub match ($$) { ## no critic
    my ($regexp, $block) = @_;
    my $pkg = caller(0);
    push @{ $pkg->inlines }, { regexp => $regexp, block => $block };
}

sub new {
    my ($class, %opts) = @_;
    bless {
        %opts
    }, $class;
}

sub format {
    my ($self, $text) = @_;
    $text =~ s{^\n}{}g;
    my $re = join("|", map { $_->{regexp} } @{ $self->inlines });
    $text =~ s{($re)}{$self->_format($1)}eg;
    $text;
}

sub _format {
    my ($self, $string) = @_;
    for my $inline (@{ $self->inlines }) {
        if (my @matched = ($string =~ $inline->{regexp})) {
            $string = $inline->{block}->($self, @matched);
            last;
        }
    }
    $string;
}

1;

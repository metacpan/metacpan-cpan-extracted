package Wrap::Sub::Child;
use 5.006;
use strict;
use warnings;

use Carp qw(croak);
use Scalar::Util qw(weaken);

use Data::Dumper;

our $VERSION = '0.06';

BEGIN {
    *CORE::GLOBAL::caller = sub (;$) {
        my ($height) = ($_[0] || 0);
        my $i = 1;
        my $name_cache;
        while (1) {
            my @caller = CORE::caller($i++) or return;
            $caller[3] = $name_cache if $name_cache;
            $name_cache = $caller[0] eq 'Wrap::Sub::Child' ? $caller[3] : '';
            next if $name_cache || $height-- != 0;
            return wantarray ? @_ ? @caller : @caller[0..2] : $caller[0];
        }
    };
}

sub new {
    return bless {}, shift;
}
sub _wrap {

    my $self = shift;
    my $sub = @_ ? shift : $self->{name};

    my %p = @_;
    for (keys %p){
        $self->{$_} = $p{$_};
    }

    if (ref $self ne 'Wrap::Sub::Child'){
        croak "\n_wrap() is not a public method\n";
    }

    $sub = "main::$sub" if $sub !~ /::/;

    if (! exists &$sub){
        croak "can't wrap() a non-existent sub ($sub). The sub specified " .
              "does not exist. If you're trying to wrap all subs in a " .
              "module, you have to load it with 'use' or 'require' first\n";
    }

    $self->{name} = $sub;
    $self->{orig} = \&$sub;

    {
        no warnings 'redefine';
        no strict 'refs';

        my $wrap = $self;
        weaken $wrap;

        *$sub = sub {

            local $Wrap::Sub::name = $wrap->name;

            @{ $wrap->{called_with} } = @_;
            $wrap->{called} = 1;

            my ($pre_return, $post_return) = ([], []);

            if (defined $wrap->{pre}){
                $pre_return = [ $wrap->{pre}->(@_) ];
                push @{ $wrap->{wrapper}{pre_returns} }, $pre_return;
            }

            my $sub_return = [ $wrap->{orig}->(@_) ] || [];

            if (defined $wrap->{post}){
                $post_return = [ $wrap->{post}->($pre_return, $sub_return) ];
                push @{ $wrap->{wrapper}{post_returns} }, $post_return;
            }

            $post_return = undef if ! $wrap->{post_return};

            if (! $wrap->{pre} && ! $wrap->{post}) {
                if (! wantarray){
                    return $sub_return->[0];
                }
                else {
                    return @$sub_return;
                }
            }
            else {
                if (defined $post_return->[0] && $wrap->{post_return}){
                    return wantarray ? @$post_return : $post_return->[0];
                }
                else {
                    return wantarray ? @$sub_return : $sub_return->[0];
                }
            }
        };
    }

    $self->{state} = 1;

    return $self;
}
sub rewrap {
    my $self = shift;

    if ($self->is_wrapped){
        croak "\ncan't call rewrap() on an already wrapped sub. Either call " .
              "unwrap() first, or DESTROY() the object\n";
    }
    $self->_wrap;
}
sub unwrap {
    my $self = shift;
    my $sub = $self->{name};

    {
        no strict 'refs';
        no warnings 'redefine';

        if (defined $self->{orig}) {
            *$sub = \&{ $self->{orig} };
        }
        else {
            undef *$sub if $self->{name};
        }
    }

    $self->{state} = 0;
    $self->reset;
}
sub called {
    return $_[0]->{called};
}
sub called_with {
    my $self = shift;
    if (! $self->called){
        croak "\n\ncan't call called_with() before the wrapped sub has " .
            "been called. ";
    }
    return @{ $self->{called_with} };
}
sub name {
    return shift->{name};  
}
sub reset {
    for (qw(pre post post_return post_returns called called_with)){
        delete $_[0]->{$_};
    }
}
sub pre {
    $_[0]->_check_wrap($_[1], 'pre');
    $_[0]->{pre} = $_[1];
}
sub post {
    my $self = shift;

    if (! defined $_[0]) {
        $self->{post} = undef;
        return;
    }

    my @args = @_;
    my ($cref, %p);

    if (ref $args[0] eq 'CODE'){
        $cref = shift;
        %p = @_ if @_;
    }
    elsif ($args[0] eq 'post_return' && ref $args[2] eq 'CODE'){
        $cref = pop @args;
        %p = @args;
    }
    elsif ($args[0] eq 'post_return'){
        %p = @args;
    }
    else {
        croak "invalid parameters to post()";
    }

    $self->{post} = $cref if $cref;

    $self->{post_return} = $p{post_return} if defined $p{post_return};
}
sub _check_wrap {
    if (defined $_[1] && ref $_[1] ne 'CODE') {
        croak "\n\nwrap()'s '$_[2]' parameter must be code a reference.";
    }
}
sub is_wrapped {
    return shift->{state};
}
sub DESTROY {
    $_[0]->unwrap;
}
sub _end {}; # vim fold placeholder

__END__

=head1 NAME

Wrap::Sub::Child - Provides for Wrap::Sub

=head1 METHODS

Please refer to the C<Wrap::Sub> parent module for full documentation. The
descriptions here are just a briefing.

=head2 new

This method can only be called by the parent C<Wrap::Sub> module.

=head2 called

Returns bool whether the wrapped sub has been called yet.

=head2 called_with

Returns a list of arguments the wrapped sub was called with.

=head2 wrap

This method should only be called by the parent wrap object. You shouldn't be
calling this.

=head2 rewrap

Re-wraps an unwrapped sub back to the same subroutine it was originally wrapped with.

=head2 is_wrapped

Returns bool whether the sub the object represents is currently wrapped or not.

=head2 name

Returns the name of the sub this object is wraping.

=head2 pre

Send in a code reference containing actions you want performed before the
wrapped sub is called.

=head2 post

Send in a code reference containing actions you want performed after the
wrapped sub is called.

=head2 reset

Resets all state of the object back to default (does not unwrap the sub).

=head2 unwrap

Restores original functionality of the wrapped sub, and calls C<reset()> on the object.

=cut
1;


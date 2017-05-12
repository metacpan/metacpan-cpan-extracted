#!/usr/bin/perl -w
use strict;

package submain;
our @ISA = ('main');
sub foo {
    push @main::foo, ['submain', @_ ]
}

package main;

use Test::More;

our @foo;

sub foo {
    push @foo, \@_;
}
{
    # XXX: using string eval blows up b::hooks::parser here
    my $sub = eval { sub {
                     use invoker;
                     sub {
                         my $self = shift;
                         $->foo("x", @_);
                     }
                 }} ;
    ok($sub);
    diag $@ if $@;

    my $self = bless {}, 'main';
    $sub->()->($self, 1,2);

    my $subself = bless {}, 'submain';
    $sub->()->($subself, 1,2);

    is_deeply(\@foo, [[$self, 'x', 1,2],
                      ['submain', $subself, 'x', 1, 2]]);
}

{
    @foo = ();
    my $sub = eval q{ sub {
                     use invoker;
                     sub {
                         my $self = shift;
                         $->foo;
                     }
                 } };
    ok($sub);
    diag $@ if $@;

    my $self = bless {}, 'main';
    $sub->()->($self, 1,2);

    my $subself = bless {}, 'submain';
    $sub->()->($subself, 1,2);

    is_deeply(\@foo, [[$self],
                      ['submain', $subself]]);
}

{
    @foo = ();
    my $sub = eval q{ sub {
                     use invoker;
                     sub {
                         my $self = shift;
                         $->bar('x');
                     }
                 } };

    no warnings 'once';
    *bar = sub {
        push @foo, ['bar', @_];
    };
    ok($sub);
    diag $@ if $@;

    my $self = bless {}, 'main';
    $sub->()->($self, 1,2);

    my $subself = bless {}, 'submain';
    $sub->()->($subself, 1,2);

    is_deeply(\@foo, [['bar', $self, 'x'],
                      ['bar', $subself, 'x']]);
    @foo = ();
}

{
    @foo = ();
    my $sub = eval q{ sub {
                     use invoker;
                     my $name = 'bar';
                     sub {
                         my $self = shift;
                         $->$name;
                     }
                 } };


    ok($sub);
    diag $@ if $@;

    my $self = bless {}, 'main';
    $sub->()->($self, 1,2);

    my $subself = bless {}, 'submain';
    $sub->()->($subself, 1,2);

    is_deeply(\@foo, [['bar', $self],
                      ['bar', $subself]]);
    @foo = ();
}

{
    @foo = ();
    my $sub = eval q{ sub {
                     use invoker;
                     my $name = 'bar';
                     sub {
                         $->$name;
                     }
                 } };


    ok(!$sub);
    like($@, qr'\$self not found');

}


done_testing;

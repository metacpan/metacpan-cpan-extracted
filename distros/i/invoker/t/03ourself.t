#!/usr/bin/perl -w
use strict;

package submain;
our @ISA = ('main');
sub foo {
    push @main::foo, ['submain', @_ ]
}

package main;
use vars '$self';

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
                         $self = shift;
                         $->foo("x", @_);
                     }
                 }} ;
    ok($sub);
    diag $@ if $@;

    $self = bless {}, 'main';
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
                         $self = shift;
                         $->foo;
                     }
                 } };
    ok($sub);
    diag $@ if $@;

    $self = bless {}, 'main';
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
                         $self = shift;
                         $->bar('x');
                     }
                 } };

    no warnings 'once';
    *bar = sub {
        push @foo, ['bar', @_];
    };
    ok($sub);
    diag $@ if $@;

    $self = bless {}, 'main';
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
                         $self = shift;
                         $->$name;
                     }
                 } };


    ok($sub);
    diag $@ if $@;

    $self = bless {}, 'main';
    $sub->()->($self, 1,2);

    my $subself = bless {}, 'submain';
    $sub->()->($subself, 1,2);

    is_deeply(\@foo, [['bar', $self],
                      ['bar', $subself]]);
    @foo = ();
}

{
    package Les::Autres;
    @foo = ();
    my $sub = eval q{ sub {
                     use invoker;
                     my $name = 'bar';
                     sub {
                         $->$name;
                     }
                 } };


    package main;
    ok(!$sub);
    like($@, qr'\$self not found');

}


done_testing;

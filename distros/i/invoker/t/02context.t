#!/usr/bin/perl -w
use strict;

use Test::More;

our @foo;

sub foo {
    my $c = defined wantarray ? wantarray ? 'list' : 'scalar'
                              : 'void';
    push @foo, [$c, @_];
}
{
    my $sub = eval { sub {
                     use invoker;
                     sub {
                         my $self = shift;
                         $->foo("x", @_);
                     }
                 } };
    ok($sub);
    diag $@ if $@;

    my $self = bless {}, 'main';
    $sub->()->($self, 1,2);
    scalar $sub->()->($self, 3, 4);
    map { $_ } $sub->()->($self, 5,6);

    is_deeply(\@foo, [['void', $self, 'x', 1,2],
                      ['scalar', $self, 'x', 3,4],
                      ['list', $self, 'x', 5,6],
                  ]);

}

{
    @foo = ();
    my $sub = eval q{ sub {
                     use invoker;
                     sub {
                         my $self = shift;
                         scalar($->foo("x", @_));
                     }
                 } };
    ok($sub);
    diag $@ if $@;

    my $self = bless {}, 'main';
    $sub->()->($self, 1,2);
    scalar $sub->()->($self, 3, 4);
    map { $_ } $sub->()->($self, 5,6);

    is_deeply(\@foo, [['scalar', $self, 'x', 1,2],
                      ['scalar', $self, 'x', 3,4],
                      ['scalar', $self, 'x', 5,6],
                  ]);
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
    scalar $sub->()->($self, 3, 4);
    map { $_ } $sub->()->($self, 5,6);

    is_deeply(\@foo, [['void', $self],
                      ['scalar', $self],
                      ['list', $self],
                  ]);

}

{
    @foo = ();
    my $sub = eval q{ sub {
                     use invoker;
                     my $name = "foo";
                     sub {
                         my $self = shift;
                         $->$name;
                     }
                 } };
    ok($sub);
    diag $@ if $@;

    my $self = bless {}, 'main';
    $sub->()->($self, 1,2);
    scalar $sub->()->($self, 3, 4);
    map { $_ } $sub->()->($self, 5,6);

    is_deeply(\@foo, [['void', $self],
                      ['scalar', $self],
                      ['list', $self],
                  ]);

}


done_testing;

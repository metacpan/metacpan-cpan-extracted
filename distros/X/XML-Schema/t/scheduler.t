#============================================================= -*-perl-*-
#
# t/schedule.t
#
# Test the XML::Schema::Scheduler module.
#
# Written by Andy Wardley <abw@kfs.org>
#
# Copyright (C) 2001 Canon Research Centre Europe Ltd.
# All Rights Reserved.
#
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: scheduler.t,v 1.1.1.1 2001/08/29 14:30:17 abw Exp $
#
#========================================================================

use strict;
use lib qw( ./lib ../lib );
use XML::Schema::Test;
use XML::Schema::Scheduler;
$^W = 1;

ntests(13);

use vars qw( $foo $DEBUG );
$foo = 0;
$DEBUG = 0;
$XML::Schema::Scheduler::DEBUG = $DEBUG;

my $pkg = 'XML::Schema::Scheduler';
my $schedule = $pkg->new({
    schedule_before => \&before,
    schedule_after  => [ \&after1, \&after2 ],
});

my $info = $schedule->activate_before();
ok( $info );
match( $info->{ before }, 'been here' );

ok( ! $info->{ after1 } );
$schedule->activate_after($info );
ok( $info );
match( $info->{ before }, 'been here' );
match( $info->{ after1 }, 'and here' );
match( $info->{ after2 }, 'here too' );


sub before {
    my ($node, $infoset) = @_;
    $infoset->{ before } = 'been here';
}

sub after1 {
    my ($node, $infoset) = @_;
    $infoset->{ after1 } = 'and here';
}

sub after2 {
    my ($node, $infoset) = @_;
    $infoset->{ after2 } = 'here too';
}

#------------------------------------------------------------------------
package My::Scheduler;
use base qw( XML::Schema::Scheduler );
use vars qw( @SCHEDULES );
@SCHEDULES = qw( foo bar baz );

package main;
my ($foo, $bar, $baz) = (0) x 3;

$pkg = 'My::Scheduler';
$schedule = $pkg->new({
    foo => sub { $foo++ },
    bar => [ sub { $bar++ }, sub { $baz++ } ],
});

$schedule = $pkg->new({
    foo => sub { $foo++ },
    bar => [ sub { $bar++ }, sub { $baz++ } ],
});


#------------------------------------------------------------------------
package main;

package My::Other::Scheduler;
use base qw( XML::Schema::Scheduler );
use vars qw( @SCHEDULES @SCHEDULE_foo );
@SCHEDULES = qw( foo );
@SCHEDULE_foo = ( \&main::up_foo );


#$XML::Schema::Scheduler::DEBUG = 1;

package main;

$pkg = 'My::Other::Scheduler';
$schedule = $pkg->new({
    schedule_foo => \&up_foo_again,
});

$schedule->activate_foo();
match( $foo, 2 );

$schedule->activate_foo();
match( $foo, 4 );

$schedule->schedule_foo(\&up_foo_more);
$schedule->activate_foo();
match( $foo, 16 );

# add to head of schedule list (1)
$schedule->schedule_foo(\&foo_no_more, 1);
$schedule->activate_foo();
match( $foo, 12 );


sub up_foo {
    print STDERR "up_foo($foo++)\n" if $main::DEBUG;
    $foo++;
}

sub up_foo_again {
    print STDERR "up_foo_again($foo++)\n" if $DEBUG;
    $foo++;
}

sub up_foo_more {
    print STDERR "up_foo_more($foo += 10)\n" if $DEBUG;
    $foo += 10;
}

sub foo_no_more {
    print STDERR "no_more_foo(0)\n" if $DEBUG;
    $foo = 0;
}

#------------------------------------------------------------------------
use XML::Schema::Type::Builtin;

#$XML::Schema::Schedule::DEBUG = 1;
$pkg = 'XML::Schema::Type::boolean';
my $bool = $pkg->new();

ok( $bool, $pkg->error()  );
match( $bool->instance('true')->{ result }, 'true' );


#------------------------------------------------------------------------
package X;
use base qw( XML::Schema::Base );

sub new {
    my ($class, $val) = @_;
    $val ||= 0;
    bless { value => $val }, $class;
}

sub bar {
    my ($self, $type, $infoset, $pi, $e) = @_;
    $self->DEBUG("$self($self->{ value })->bar($type, $infoset, $pi, $e)")
	if $main::DEBUG;
}

package My::Third::Scheduler;
use base qw( XML::Schema::Scheduler );
use vars qw( @SCHEDULES );
@SCHEDULES = qw( foo );

package main;
my $x = X->new(32);

$schedule = My::Third::Scheduler->new();
$schedule->schedule_foo([ $x, 'bar', 3.14, 2.718 ]);
$schedule->activate_foo();







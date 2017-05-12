#!/usr/bin/perl -w

# Copyright 2010 Kevin Ryde

# This file is part of Time-Duration-Locale.
#
# Time-Duration-Locale is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Time-Duration-Locale is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Time-Duration-Locale.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;

{
  package Base;
  sub foo {
    my ($self) = @_;
    print "foo() in Base\n";
  }
}

{
  package Derived;
  our @ISA = ('Base');
  use Carp;
  use vars '$AUTOLOAD';
  sub new {
    my ($class) = @_;
    return bless {}, $class;
  }
  sub can {
    my ($self, $name) = @_;
    print "can() Derived $name\n";
    if ($name eq 'foo') {
      return _make_foo();
    } else {
      return undef;
    }
  }
  sub AUTOLOAD {
    my $name = $AUTOLOAD;
    print "AUTOLOAD() Derived $name\n";
    $name =~ s/.*://;
    if ($name eq 'foo') {
      my $code = _make_foo();
      goto $code;
    } else {
      print "AUTOLOAD() croak\n";
      croak "No such function $name()";
    }
  }
  sub _make_foo {
    my $code = sub {
      print "foo() in Derived\n";
    };
    no warnings 'once';
    *foo = $code;
    return $code;
  }
}

my $obj = Derived->new;
$obj->foo;
exit 0;

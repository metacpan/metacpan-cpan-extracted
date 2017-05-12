#!/usr/bin/perl -w

# Copyright 2009, 2010 Kevin Ryde

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

use 5.010;
use strict;
use warnings;
use Data::Dumper;
use Devel::Peek;

package Foo;
use base 'Exporter';
our @EXPORT = ('foo');
use vars qw($AUTOLOAD);

sub can {
  my ($class, $name) = @_;
  my $can = $class->SUPER::can($name);
  say "SUPER::can ", $can // 'undef';
  return $can;
}

sub AUTOLOAD {
  print "autoload $AUTOLOAD\n";
}

CHECK { say "keys ", keys %Foo::; }
say "UNIVERSAL::can ", Foo->UNIVERSAL::can('foo') // 'undef';
say "Foo::can ", Foo->can('foo') // 'undef';
say "defined ", defined &Foo::foo;
say Data::Dumper::Dumper(\*Foo::foo);
say Devel::Peek::Dump(*Foo::foo);
BEGIN { say "keys ", keys %Foo::; }

package main;
# say Foo->can('foo') // 'undef';
# say "exists ", exists $Foo::{'foo'};
# say defined &Foo::foo;
# 

print "\nafter import\n";
# Foo->import;
# my $code = \&Foo::foo;

say Devel::Peek::Dump(*Foo::foo);
say "UNIVERSAL::can ", Foo->UNIVERSAL::can('foo') // 'undef';
say "Foo::can ", Foo->can('foo') // 'undef';
say "defined ", defined &Foo::foo;

exit 0;

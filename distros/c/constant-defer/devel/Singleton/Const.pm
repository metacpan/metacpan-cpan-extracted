# This was an idea to have a Class::Singleton form with the inherited
# ->instance installing a constant sub as the class ->instance, on the first
# call.
#
# The difference is thus in holding the instance in a constant sub as
# opposed to the way Class::Singleton does it in a package variable.  It has
# to build and lookup that variable each time, whereas a constant sub would
# be hit directly by the method lookup.  On the whole very little between
# the two in either time or space ...



# Copyright 2008, 2009 Kevin Ryde

# This file is part of constant-defer.
#
# constant-defer is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation; either version 3, or (at your option) any later
# version.
#
# constant-defer is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with constant-defer.  If not, see <http://www.gnu.org/licenses/>.

package Class::Singleton::Const;
use strict;
use warnings;
use Carp;

sub instance {
  my ($class) = @_;
  my $instance = $class->_new_instance;

  my $funcname = "${class}::instance";
  { no strict 'refs';
    no warnings;
    *$funcname = sub () { $instance };
  }

  # constant.pm optimizes to save a typeglob, but it doesn't allow a
  # particular package to be given, only the caller() package
  #   require constant;
  #   constant->import ("${class}::instance", $instance);
  require constant;
  $_ = $instance;
  eval "package \Q$class\E; use constant instance => \$_; 1"
    or die $@;

  return $instance;
}

sub _new_instance {
  my ($class) = @_;
  croak "Singleton: $class->_new_instance() not defined";
}

1;
__END__

# BEGIN {
#   print $xyz;
#   eval "no strict";
#   print $xyz;
# }
# package x\;y;


package MyClass;
our @ISA = ('Class::Singleton::Const');
sub new {
  my ($class) = @_;
  return bless {}, $class;
}
*_new_instance = \&new;

package main;
print exists(&MyClass::instance),"\n";
print MyClass->instance,"\n";
print exists(&MyClass::instance),"\n";

1;
__END__


our $x = [ 'x' ];

  print "$funcname\n";
  my $y = $x;
#   use Data::Dumper;
#   print Dumper(\*$funcname),"\n";


  require Scalar::Util;
  Scalar::Util::weaken ($x);

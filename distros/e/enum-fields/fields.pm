package enum::fields;

use 5.00503;
use strict;
no strict 'refs';
use vars qw($VERSION %class_info %final);

use Carp;

$VERSION = '1.0';

%class_info = ();
%final = ();

sub define_constant {

    my $pkg = shift;
    my $const = shift;
    my $val = shift;
    
    # Stolen from base.pm, but hey, that's what code's for
    
    my $glob;
    
    if (defined($glob = ${"$pkg\::"}{$const}) and *{$glob}{CODE}) {
        croak "Redefined constant $const";
    }
    
    eval "*$pkg\::$const = sub () { $val }";
}

sub import {

    shift;
    
    my $class = caller();
    
    # Who needs exporter
    
    if ($class =~ /^enum::fields::/) {
        *{"$class\::class_info"} = \%class_info;
        *{"$class\::define_constant"} = \&define_constant;
        *{"$class\::final"} = \%final;
    }
    
    return unless (@_);
    
    croak "Cannot add fields to class that has been inherited"
        if exists($final{$class});
    
    $class_info{$class} = [] unless exists($class_info{$class});
    
    my $idx = ~~@{$class_info{$class}};
    
    for my $fld (@_) {
        define_constant($class, $fld, $idx++);
        if ($@) {
            croak();
        }
        push @{$class_info{$class}}, $fld;
    }
}

1;

=pod

=head1 NAME

enum::fields - Perl extension for defining constants for use
in Array-based objects

=head1 SYNOPSIS

  package Foo;
  
  use enum::fields qw{
      FIELD_ONE
      FIELD_TWO
  };
  
  package Bar;
  
  use base 'Foo';
  
  use enum::fields::extending Foo => qw{
      BAR_FIELD_ONE
      BAR_FIELD_TWO
  };

=head1 DESCRIPTION

This module allows you to define constants that can be
inherited and extended by child classes.  It is used
much like a simple form of L<enum> to define constants, 
with the exception that you can inherit a list of constants
from a parent class using the "extending" form of the pragma.

This module was designed to allow an object-oriented programmer
to use an array to store instance data for object classes.

Since I'm a lousy doc writer I'll get right to the examples.

=head2 Example 1 - Parent Class

  package Employee;
  
  use enum::fields qw{NAME PHONE SALARY};
  
  sub new {
      my $class = shift;
      my $self = bless [], $class;

      $self->[NAME] = shift;
      $self->[PHONE] = shift;
      $self->[SALARY] = shift;
  }
  
  sub salary {
      my $self = shift;
      $self->[SALARY] = shift if (@_);
      $self->[SALARY];
  }

This example shows a simple employee object.  It holds the
employee's name, phone, and salary information.  The constructor
for this class, aptly named 'new', creates a new employee and
assigns the three arguments passed in to the NAME, PHONE, and
SALARY fields (whose values, not-so-coincidentally, are 0, 1,
and 2).  Since this is actually an array storage, it is nice
and fast.

=head2 Example 2 - Subclassing without adding fields

  package Employee::CoffeeBoy;
  
  use Carp;
  
  use base 'Employee';
  use enum::fields::extending 'Employee';

  sub salary {
      my $self = shift;
      if (@_) {
          $salary = shift;
          if ($salary > 8_000.00) {
              croak "Attept to overpay coffee boy";
          }
          $self->[SALARY] = $salary;
      }
      $self->[SALARY];
  }

This example shows a subclass that inherits from Employee.
Using the L<enum::fields::extending> pragma causes the fields
from the parent class to be brought into the child class.
Therefore we are able to override the I<salary> method.

=head2 Example 3 - Subclassing with adding fields

  package Employee::CEO;
  
  use base 'Employee';
  use enum::fields::extending Employee => qw{
      NUMBER_OF_BOATS
  };
  
  sub boats {
      my $self = shift;
      $self->[NUMBER_OF_BOATS] = shift if (@_);
      $self->[NUMBER_OF_BOATS];
  }

This class shows that we can inherit the fields from a
parent, and then add another field onto the end of the
list.  Behind the scenes, the new field is numbered
after those from the parent class, so that the inherited
fields and the new fields will not collide.

=head1 CAVEATS

You cannot add fields to a class after another class has
inherited its fields.  Attempting to do so will result in
a compile-time error.

Trying to extend fields from more than one class (ala 
multiple inheritance) will not work.  For a different
(arguably better) solution, see L<Class::Delegate>.

=head1 SEE ALSO

L<enum>, L<fields>.

=head1 AUTHOR

David M. Lloyd E<lt>dmlloyd@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002 by David M. Lloyd

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

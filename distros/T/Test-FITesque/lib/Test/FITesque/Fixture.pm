package Test::FITesque::Fixture;

use strict;
use warnings;

use attributes;
use base qw(Class::Data::Inheritable);

__PACKAGE__->mk_classdata(__ATTR_MAP => {});

=pod

=head1 NAME

Test::FITesque::Fixture - Abstract calls for fixtures

=head1 SYNOPSIS

  package Buddha::Fixture;

  use strict;
  use warnings;
  use base qw(Test::FITesque::Fixture);
  use Test::More qw();

  sub click_on_button : Test {
    my ($self, @args) = @_;
    ...
    ok(1);
  }

  sub open_window : Test : Plan(3) {
    my ($self, @args) = @_;
    ...
    ok(1);
    ok(2);
    ok(3);
  }

=head1 DESCRIPTION

This module provides the base class for FITesque fixtures. It provides methods
for the 'Test' and 'Plan' attributes along with some utility functions for
L<Test::FITesque::Fixture>.

All methods for use as FITesque test methods must be marked with the 'Test'
attribute.

The 'Plan' attribute states how many L<Test::More> functions the FITesque test
method expects to run. If a method does not have the 'Plan' attribute set, it
is implied that the test method will execute one L<Test::More> functions.

  # Execute 10 Test::More functions
  sub test_method : Test : Plan(10) {
    ...  
  }

  # Just one this time
  sub test_method : Test {
    ...
  }

  # not a test method
  sub normal_method {
    ...
  }

There are also 2 methods which may require overriding. The parse_method_string
method returns a coderef of the method that relates to the method string
used as the first element of a FITesque test row.

  # get coderef for the 'click_on_buton' method of the fixture class
  my $coderef = $fixture->parse_method_string('click on button');

The other method, 'parse_arguments' provides a hook in point to allow
preprocessing on arguments to FITesque fixture test methods. This might be
useful in case you want to design a domain specific langauge into your
arguments. By default, this method just returns the arguments as is.

=head1 METHODS

=head2 new

  my $fixture = Buddha::Fixture->new();

Simple constructor

=cut

sub new {
  my ($class, $args) = @_;
  $args ||= {};
  my $self = bless $args, $class;
  return $self;
}

=head2 method_test_count

 my $count = $fixture->method_test_count('foo');

This returns the planned test count associated with the passed
method name.

=cut

sub method_test_count {
  my ($self, $string) = @_;
  my $coderef = $self->parse_method_string($string);

  return undef if !$coderef;

  # use test methods first
  for my $meth (values %{ __PACKAGE__->__ATTR_MAP}){
    if($coderef == $meth->{coderef}){
      return $meth->{count} || 1;
    }
  }

  return undef;
}

=head2 parse_method_string 

  my $coderef = $fixture->parse_method_string('click on button');

This method takes a string of text and attempts to return a coderef
of a method within the fixture class.

=cut

sub parse_method_string {
  my ($self, $method_string) = @_;
  (my $method_name = $method_string) =~ s/\s+/_/g;
  
  my $coderef = $self->can($method_name);
  return $coderef;
}

=head2 parse_arguments

  my @arguments = $fixture->parse_arguments(qw(one two three));

This method provides a way to preprocess arguments for methods before
they are run.

=cut

sub parse_arguments {
  my $self = shift;
  return @_;
}

sub MODIFY_CODE_ATTRIBUTES {
  my ($package, $coderef, @attrs) = @_;

  my $attr_info = { package => $package, coderef => $coderef };
  my @not_recognised = (); 
  while (my $attr = shift @attrs){
    next if $attr eq 'Test';
    if(my ($count) = $attr =~ /^Plan\((\d+)\)$/){
      if($count > 0){
        $attr_info->{count} = $count;
        next;
      }
    }
    push @not_recognised, $attr;
  }
  
  __PACKAGE__->__ATTR_MAP->{"$coderef"} = $attr_info;
  
  return @not_recognised;
}

=head1 AUTHORS

Scott McWhirter, C<< <konobi@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Scott McWhirter, all rights reserved.

This program is released under the following license: BSD. Please see the
LICENSE file included in this distribution for details.

=cut

1;

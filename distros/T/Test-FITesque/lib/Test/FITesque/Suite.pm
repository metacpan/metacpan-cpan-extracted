package Test::FITesque::Suite;

use strict;
use warnings;

use Test::Builder;

our $TEST_BUILDER;

=head1 NAME

Test::FITesque::Suite - FITesque test suite runner

=head1 SYNOPSIS

  my $suite   = Test::FITesque::Suite->new();

  my $test    = Test::FITesque::Test->new();
  my $suite2  = Test::FITesque::Suite->new();

    ...

  $suite->add($test, $suite2, ...);

  my $test_count = $suite->test_count();
  $suite->run_tests();

=head1 DESCRIPTION

This package provides a way of running a suite of tests. It also allowd you to
run suites of suites in whatever hierarchy you see fit.

=head1 METHODS

=head2 new

  my $suite = Test::FITesque::Suite->new();

This method is a simple constructor, but can take a single parameter within a
hashref:

=over

=item data

This takes a simple arrayref of tests or suites.

=back

=cut

sub new {
  my ($class, $args) = @_;
  $args ||= {};
  my $self = bless $args, $class;
  return $self;
}

=head2 add

  $suite->add($test, $suite2, ...);

This method allows you to add tests or suites to the current suite object.

=cut

sub add {
  my ($self, @tests) = @_;
  $self->{data} ||= [];
  my $data = $self->{data};
  for my $test (@tests){
    die "Attempted to add a test that was not a FITesque test" 
      if !($test->isa(q{Test::FITesque::Test}) || $test->isa(q{Test::FITesque::Suite}));
  }
  push @$data, @tests;
}

=head2 test_count

  my $count = $suite->test_count();

This method returns the test count for all tests within the suite.

=cut

sub test_count {
  my ($self) = @_;

  my $count = 0;
  for my $test (@{ $self->{data} }){
    $count += $test->test_count();
  }

  return $count;
}

=head2 run_tests 

  $suite->run_tests();

This method will run all tests within a suite.

=cut

sub run_tests {
  my ($self) = @_;

  my $data = $self->{data} || [];

  die "Attempting to run a suite with no tests" if !@$data;
  
  my ($pkg) = caller();
  if(!$pkg->isa('Test::FITesque::Suite')){
    my $Builder = $TEST_BUILDER ? $TEST_BUILDER : Test::Builder->new();
    $Builder->exported_to(__PACKAGE__);
    if ( $Builder->isa('Test::FakeBuilder') || !$Builder->has_plan) {
        if( my $count = $self->test_count() ){
          $Builder->expected_tests($count);
        } else {
          $Builder->no_plan();
        }
    }
  }
  
  for my $test (@$data){
    $test->run_tests();
  }
}

=head1 AUTHOR

Scott McWhirter, C<< <konobi@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Scott McWhirter, all rights reserved.

This program is released under the following license: BSD. Please see the
LICENSE file included in this distribution for details.

=cut

1;

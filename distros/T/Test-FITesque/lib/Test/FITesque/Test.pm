package Test::FITesque::Test;

use strict;
use warnings;

use Module::Load;
use Test::Builder;

our $TEST_BUILDER;
our $METHOD_DETAIL_VERBOSE;


=head1 NAME

Test::FITesque::Test - A FITesque test

=head1 SYNOPSIS

  my $test = Test::FITesque::Test->new();

  # add test rows
  $test->add( ... );
  $test->add( ... );

  # return number of TAP tests
  $test->test_count();

  $test->run_tests();

=head1 DESCRIPTION

=head1 METHODS

=head2 new

  my $test = Test::FITesque::Test->new();

This is a simple constructor. It takes a hashref of options:

=over

=item data

This is an arrayref of arrayrefs for the FITesque run.

=back

Please note that the first test row that is added must be the FITesque fixture
class name, followed by the arguments to be passed to its constructor.

=cut

sub new {
  my ($class, $args) = @_;
  $args ||= {};
  my $self = bless $args, $class;
  return $self;
}

=head2 add

  $test->add(qw(Foo::Fixture some constructor args));
  $test->add('click button', 'search');

This method allows you to add FITesque test rows individually. As with the data
option in the constructor, the first row added must be the Fixture class name
and its constructor arguments.

=cut

sub add {
  my ($self, @args) = @_;
  $self->{data} ||= [];

  push @{ $self->{data} }, [@args];
}

=head2 test_count

  my $count = $test->test_count();

This method returns the number of TAP tests expected to be run during the
test run.

=cut

sub test_count {
  my ($self) = @_;
  my $data = $self->{data} || [];
  
  if(@$data){
    my ($fixture_class) = $self->_load_fixture_class();
    
    my $count = 0;
    for my $test_row ( @$data[ 1..( scalar(@$data) -1) ]){
      my $method_string = $test_row->[0];
      my $test_count = $fixture_class->method_test_count($method_string) || 0;
      $count += $test_count; 
    }

    return $count;
  }
  
  return 0;
}

=head2 run_tests

  $test->run_tests();

This method will run the FITesque test based upon the data supplied.

=cut

sub run_tests {
  my ($self) = @_;
  my $data = $self->{data} || [];
  
  if(@$data){
    my ($fixture_class, @fixture_args) = $self->_load_fixture_class();

    my $fixture_object;
    if(!defined $self->{__test_has_run__}){
      @fixture_args   = $fixture_class->parse_arguments(@fixture_args);
      $fixture_object = $fixture_class->new(@fixture_args);
      $self->{__test_has_run__} = 1;
    } else {
      die q{Attempted to run test more than once};
    }

    # Deal with being called directly or as part of a suite
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
   
    # early bail out in case of unavailable methods
    # - We do this as a seperate step as the method called could take a long
    #   time, which would mean that you'd only fail halfway through a long
    #   test run.
    for my $test_row (@$data[ 1..(scalar(@$data) -1) ]){
      my $method_string = $test_row->[0];
      if( !$fixture_object->parse_method_string($method_string) ){
        die qq{Unable to run tests, no method available for action "$method_string"} 
      }
    }

    for my $test_row ( @$data[ 1..( scalar(@$data) -1) ]){
      my $Builder = $TEST_BUILDER ? $TEST_BUILDER : Test::Builder->new();
      my ($method_string, @args) = @$test_row;
      my $method = $fixture_object->parse_method_string($method_string);
      die "No method exists for '$method_string'" if !defined $method;

      my $test_count = $fixture_object->method_test_count($method_string) || 0;
      my $msg = "running '$method_string' in class '$fixture_class' ($test_count tests)";
      $Builder->diag( $msg ) if $METHOD_DETAIL_VERBOSE;

      @args = $fixture_object->parse_arguments(@args);
      $fixture_object->$method(@args);
    }

  }else{
    die "Attempted to run empty test";
  }
 
}

sub _load_fixture_class {
  my ($self) = @_;
  my $data = $self->{data};
  my ($class,@args) = @{ $data->[0] };
    
  eval {
    load $class;
  };
  die qq{Could not load '$class' fixture: $@} if $@;
  die qq{Fixture class '$class' is not a FITesque fixture} 
    if !$class->isa(q{Test::FITesque::Fixture});

  return ($class, @args);
}

=head1 AUTHOR

Scott McWhirter, C<< <konobi@cpan.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2007 Scott McWhirter, all rights reserved.

This program is released under the following license: BSD. Please see the
LICENSE file included in this distribution for details.

=cut

1;

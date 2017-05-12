#!/usr/bin/perl -w

package State;
use VSO;
#use Mouse;
#use Mouse::Util::TypeConstraints;
#use Moose;
#use Moose::Util::TypeConstraints;

subtype 'State::Name' => 
  as      'Str',
  where   { length($_) > 0 },
  message { "Must have a length greater than zero - [$_] is invalid." };

subtype 'State::Population' =>
  as      'Int',
  where   { $_ > 0 },
  message { "Population must be greater than zero" };

#subtype 'State::FuncRef'  =>
#  as      'CodeRef',
#  where   sub { 1 };

#coerce 'State::FuncRef' =>
#  from  'Str',
#  via   sub { my $val = $_; return sub { $val } };

#coerce 'State::FuncRef' =>
#  from  'CodeRef',
#  via   { $_ };

has 'name' => (
  is        => 'ro',
  isa       => 'State::Name',
  required  => 1,
#  'where'     => sub { m{Colorado} }
);

has 'capital' => (
  is        => 'rw',
  isa       => 'Str',
  required  => 1,
);

has 'population' => (
  is        => 'rw',
  isa       => 'State::Population',
  required  => 1,
);


has 'foo' => (
  is        => 'ro',
  isa       => 'HashRef[Foo]',
  required  => 1,
) if 0;

has 'func' => (
  is        => 'ro',
  isa       => 'State::FuncRef',
  required  => 1,
  coerce    => 1,
) if 0;

before 'population' => sub {
  my ($s, $new_value, $old_value) = @_;
  
#  warn "About to change population from '$old_value' to '$new_value'\n";
};

after 'population' => sub {
  my ($s, $new_value, $old_value) = @_;
  
#  warn "Changed population from '$old_value' to '$new_value'\n";
};

sub greet
{
  my $s = shift;
  
  warn "Greetings from ", $s->name, "!\n";
  return wantarray ? ( 1..10 ) : 1;
}# end greet()

before 'greet' => sub {
  my $s = shift;
  
  warn "About to greet you (first-defined, second-run)...\n";
};

before 'greet' => sub {
  my $s = shift;
  
  warn "About to greet you (second-defined, first-run)...\n";
};

after 'greet' => sub {
  my $s = shift;
  
  warn "After greeting you (first-defined, first-run)...\n";
};

after 'greet' => sub {
  my $s = shift;
  
  warn "After greeting you (second-defined, second-run)...\n";
};

#__PACKAGE__->meta->make_immutable();

package main;

use strict;
use warnings 'all';

for( 1..10000 )
{
  my $state = State->new(
    name        => 'Colorado',
    capital     => 'Denver',
    population  => 5_000_000,
#    foo         => { bar => bless {}, 'Foo' },
#    func        => sub { }
  );
  $state->capital('Boulder');
  $state->population( 75_000 );
}# end for()



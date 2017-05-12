package Test::Proto::TestCase;
use 5.008;
use strict;
use warnings;
use Moo;
with('Test::Proto::Role::Tagged');
use Test::Proto::Common ();

=head1 NAME

Test::Proto::TestCase - an individual test case

=head1 SYNOPSIS

Holds attributes to describe the test - the name of the test, the parameters (data) and the code to be executed. 

All the attributes are chainable when used as setters (they return the TestCase). 

In addition to those documented below, the TestCase can have tags - see L<Test::Proto::Role::Tagged> for details.

=cut

=head2 ATTRIBUTES

=cut

=head3 name

Returns the name of the test.

=cut

has 'name' => default => sub { '[Anonymous Test Case]' },
	is     => 'rw';

=head3 code

Returns the code.

=cut

has 'code' => is => 'rw';

=head3 data

Returns the data.

=cut

has 'data'  => is  => 'rw',
	default => sub { {}; };

around qw(name code data) => \&Test::Proto::Common::chainable;

1;

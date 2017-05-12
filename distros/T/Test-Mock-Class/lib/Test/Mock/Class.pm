#!/usr/bin/perl -c

package Test::Mock::Class;

=head1 NAME

Test::Mock::Class - Simulating other classes

=head1 SYNOPSIS

  use Test::Mock::Class ':all';
  require Net::FTP;

  # concrete mocked class
  mock_class 'Net::FTP' => 'Net::FTP::Mock';
  my $mock_object = Net::FTP::Mock->new;

  # anonymous mocked class
  my $metamock = mock_anon_class 'Net::FTP';
  my $mock_object = $metamock->new_object;

  # anonymous class with role applied
  my $metamock = Test::Mock::Class->create_anon_class(
      roles => [ 'My::Handler::Role' ],
  );
  my $mock_object = $metamock->new_object;

=head1 DESCRIPTION

In a unit test, mock objects can simulate the behavior of complex, real
(non-mock) objects and are therefore useful when a real object is impractical
or impossible to incorporate into a unit test.

The unique features of C<Test::Mock::Class>:

=over 2

=item *

Its API is inspired by PHP SimpleTest framework.

=item *

It isn't tied with L<Test::Builder> so it can be used standalone or with any
xUnit-like framework, i.e. L<Test::Unit::Lite>.  Look for
L<Test::Builder::Mock::Class> if you want to use it with L<Test::Builder>
(L<Test::More> or L<Test::Simple>).

=item *

The API for creating mock classes is based on L<Moose> and L<Class::MOP> so it
doesn't clash with API of original class and is easy expandable.

=item *

The methods for defining mock object's behavior are prefixed with C<mock_>
string so they shouldn't clash with original object's methods.

=item *

Mocks as actors: The mock version of a class has all the methods of the
original class.  The return value will be C<undef>, but it can be changed with
C<mock_returns> method.

=item *

Mocks as critics: The method of mock version of a class can check its calling
arguments and throws an exception if arguments don't match (C<mock_expect>
method).  An exception also can be thrown if the method wasn't called at all
(C<mock_expect_once> method).

=back

=for readme stop

=cut

use 5.006;

use strict;
use warnings;

our $VERSION = '0.0303';

use Moose 0.90;
use Class::MOP 0.93;


=head1 INHERITANCE

=over 2

=item *

extends L<Moose::Meta::Class>

=cut

extends 'Moose::Meta::Class';

=item *

with L<Test::Mock::Class::Role::Meta::Class>

=back

=cut

with 'Test::Mock::Class::Role::Meta::Class';


use namespace::clean -except => 'meta';


=head1 FUNCTIONS

=over

=cut

BEGIN {
    my %exports = ();

=item B<mock_class>( I<class> : Str, I<mock_class> : Str = undef ) : Moose::Meta::Class

Creates the concrete mock class based on original I<class>.  If the name of
I<mock_class> is undefined, its name is created based on name of original
I<class> with added C<::Mock> suffix.

The original I<class> is loaded with C<L<Class::MOP>::load_class> function
which behaves wrongly for some packages, i.e. I<IO::File>.  It is much safer
to require original class explicitly.

The function returns the metaclass object of new I<mock_class>.

=cut

    $exports{mock_class} = sub {
        sub ($;$) {
            return __PACKAGE__->create_mock_class(
                defined $_[1] ? $_[1] : $_[0] . '::Mock',
                class => $_[0],
            );
        };
    };

=item B<mock_anon_class>( I<class> : Str = undef ) : Moose::Meta::Class

Creates an anonymous mock class based on original I<class>.  The name of this
class is automatically generated.  If I<class> argument not defined, the empty
mock class is created.

The function returns the metaobject of new mock class.

=back

=cut

    $exports{mock_anon_class} = sub {
        sub (;$) {
            return __PACKAGE__->create_mock_anon_class(
                defined $_[0] ? (class => $_[0]) : (),
            );
        };
    };

=head1 IMPORTS

=over

=cut

    my %groups = ();

=item Test::Mock::Class ':all';

Imports all functions into caller's namespace.

=back

=cut

    $groups{all} = [ keys %exports ];

    require Sub::Exporter;
    Sub::Exporter->import(
        -setup => {
            exports => [ %exports ],
            groups => \%groups,
        },
    );
};


1;


=begin umlwiki

= Class Diagram =

[                                 Test::Mock::Class
 ----------------------------------------------------------------------------------
 ----------------------------------------------------------------------------------
 <<utility>> mock_class(class : Str, mock_class : Str = undef) : Moose::Meta::Class
 <<utility>> mock_anon_class(class : Str) : Moose::Meta::Class
                                                                                   ]

[Test::Mock::Class] ---|> [Moose::Meta::Class] [<<role>> Test::Mock::Class::Role::Meta::Class]

=end umlwiki

=head1 EXAMPLE

The C<Test::Mock::Class> fits perfectly to L<Test::Unit::Lite> tests.  It
throws an exception immediately if some problem is occurred.  It means that
the test unit is failed if i.e. the mock method is called with wrong
arguments.

Example code:

  package My::ExampleTest;

  use Test::Unit::Lite;

  use Moose;
  extends 'Test::Unit::TestCase';

  use Test::Assert ':all';
  use Test::Mock::Class ':all';

  require IO::File;

  sub test_mock_class {
      my ($self) = @_;

      my $mock = mock_anon_class 'IO::File';
      my $io = $mock->new_object;
      $io->mock_return( open => 1, args => [qr//, 'r'] );

      assert_true( $io->open('/etc/passwd', 'r') );

      $io->mock_tally;
  };

=head1 SEE ALSO

Mock metaclass API: L<Test::Mock::Class::Role::Meta::Class>,
L<Moose::Meta::Class>.

Mock object methods: L<Test::Mock::Class::Role::Object>.

xUnit-like testing: L<Test::Unit::Lite>.

Mock classes for L<Test::Builder>: L<Test::Builder::Mock::Class>.

Other implementations: L<Test::MockObject>, L<Test::MockClass>.

=for readme continue

=head1 BUGS

The API is not stable yet and can be changed in future.

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Based on SimpleTest, an open source unit test framework for the PHP
programming language, created by Marcus Baker, Jason Sweat, Travis Swicegood,
Perrick Penet and Edward Z. Yang.

Copyright (c) 2009, 2010 Piotr Roszatycki <dexter@cpan.org>.

This program is free software; you can redistribute it and/or modify it
under GNU Lesser General Public License.

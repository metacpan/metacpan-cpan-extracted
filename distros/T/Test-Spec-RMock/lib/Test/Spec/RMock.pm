package Test::Spec::RMock;
# ABSTRACT: a mocking library for Test::Spec

use warnings;
use strict;

use Exporter qw(import);

use Test::Spec::RMock::AnyConstraint;
use Test::Spec::RMock::AtLeastConstraint;
use Test::Spec::RMock::ExactlyConstraint;
use Test::Spec::RMock::MessageExpectation;
use Test::Spec::RMock::MockObject;

our @EXPORT = qw(rmock);

sub rmock {
    my ($name) = @_;
    Test::Spec::RMock::MockObject->new($name);
}

1;

__END__

=pod

=head1 NAME

Test::Spec::RMock - a mocking library for Test::Spec

=head1 VERSION

version 0.006

=head1 SYNOPSIS

  use Test::Spec;
  use Test::Spec::RMock;

  describe "Something" => sub {
      it "should do something" => {
          my $foo = rmock('Foo');
          $foo->should_receive('bar')->twice->and_return('baz');
          Something->new->do_something_with($foo);
      };
  };

  runtests unless caller;

=encoding utf-8

=head1 EXPORTED METHODS

=over 4

=item rmock($name)

Creates a mock object with the given name.

C<$name> is used in error messages. Often a good choice is the name of
the class or role you are mocking.

=back

=head1 USING MOCK OBJECTS

=head2 Method stubs

You want to use method stubs on all messages that you don't care to
set expectations on. Any interactions that don't are important for the
test you are writing.

=over 4

=item $mock->stub(%spec)

This creates method stubs for each message defined in %spec.

  $mock->stub(
      message1 => 'foo',
      message2 => 'bar',
  );
  $mock->message1; # 'foo'
  $mock->message2; # 'bar'

=item $mock->stub_chain(@method_names)

Creates a chain of two or more method stubs in one statement. 

  $mock->stub_chain(qw(one two three))->and_return('four');
  $mock->one->two->three; # 'four'

=back

=head2 Method mocks

Mocking methods allows you to set expectations on the messages that
the mocked object should receive. 

=over 4

=item $mock->should_receive($name)

=item $mock->should_not_receive($name)

=back

=head2 Null objects

Use a null object when you don't care about the object's behavior or
interaction, and don't want to explicitly stub everything out that's needed.

=over 4

=item $mock->as_null_object()

=back

=head2 Message expectations

All return $self so that you can chain them.

=over 4

=item $expectation->and_return(...)

=item $expectation->and_raise($exception)

=item $expectation->with(...)

=item $expectation->any_number_of_times()

=item $expectation->at_least_once()

=item $expectation->at_least($n)

    $expectation->at_least(4)->times

=item $expectation->once()

=item $expectation->exactly($n)

    $expectation->exactly(4)->times

=item $expectation->times

Noop

=back

=head1 SEE ALSO

=over 4

=item *

L<Test::Spec>

=item *

L<Test::Spec::Mock>

=back

=head1 AUTHOR

Kjell-Magne Øierud <kjellm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Kjell-Magne Øierud.

This is free software, licensed under:

  The MIT (X11) License

=cut

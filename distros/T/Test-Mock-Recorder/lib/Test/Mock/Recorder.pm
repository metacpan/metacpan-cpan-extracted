package Test::Mock::Recorder;
use strict;
use warnings;
use base qw(Class::Accessor::Fast);
__PACKAGE__->mk_ro_accessors(qw(_mock _expectations));
use Test::MockObject;
use Test::Mock::Recorder::Expectation;
use Test::Builder;
use UNIVERSAL::isa;

our $VERSION = '0.01';

=head1 NAME

Test::Mock::Recorder - Record-and-verify style mocking library.

=head1 SYNOPSIS

  my $rec = Test::Mock::Recorder->new;
  $rec->expects('print')->with('hello');
  
  $rec->verify_ok(
    sub { my $io = shift; $io->print('hello'); }
  );
  
  # If you don't like callback-style interface...
  my $io = $rec->replay;
  $io->print('hello');
  $rec->verify_ok($io);

=head1 DESCRIPTION

Test::Mock::Recorder is a record-and-verify style mocking library.

It wraps Test::MockObject and provides functionality of
testing a sequence of method calls.

=head1 CLASS METHODS

=head2 new()

Constructor.

=cut

sub new {
    my ($class) = @_;
    return $class->SUPER::new({
        _expectations => [],
    });
}

=head1 INSTANCE METHODS

=head2 expects($method)

Append exceptation of calling method named $method and
returns new Test::Mock::Recorder::Expectation instance.

=cut

sub _expects_one {
    my ($self, $method) = @_;

    my $result = Test::Mock::Recorder::Expectation->new({ method => $method });
    push @{ $self->_expectations }, $result;

    return $result;
}

=head2 expects($method1 => $ret1, $method2 => $ret2, ...)

Short-form of one-argument "expects" method.

=cut

sub _slice {
    my ($n, @src) = @_;

    my $max = scalar @src / $n - 1;
    my @result;
    for my $i (0...$max) {
        push @result, [ map { $src[$i * $n + $_] } 0...$n ];
    }
    return @result;
}

sub expects {
    my $self = shift;

    if (scalar @_ == 1) {
        return $self->_expects_one(@_);
    }

    for (_slice(2, @_)) {
        my ($method, $return) = @{ $_ };
        $self->_expects_one($method)->returns($return);
    }
}

=head2 replay(), replay($callback)

Creates new mock object and pass it.

Without $callback, the method returns new mock object.

With $callback, the method pass a new mock to $callback and verify,
returns the result of verification.

=cut

sub replay {
    my ($self, $callback) = @_;

    my $mock = $self->_replay;

    if ($callback) {
        $callback->($mock);
        return $self->verify($mock);
    } else {
        return $mock;
    }
}

sub _nth {
    my ($n) = @_;

    [ qw(first second third) ]->[ $n-1 ] || "${n}nd";
}

sub _create_mock_method {
    my ($self, $expectation, $index_ref) = @_;

    return sub {
        my $where =
            sprintf('%s invocation of the mock', _nth($$index_ref + 1));
        my $e = $self->_expectations->[ $$index_ref ];
        $$index_ref++;
        if (! $e) {
            die sprintf(
                'The %s is "%s" but not expected',
                $where,
                $expectation->method,
            );
        }

        my $ret;
        eval {
            $ret = $e->verify(@_);
        };
        if ($@) {
            if ($@->isa('Test::Mock::Recorder::InvalidArguments')) {
                die sprintf(
                    'Called "%s" with invalid arguments at the %s',
                    $@->method,
                    $where,
                );
            } else {
                die $@;
            }
        } else {
            return $ret;
        }
    };
}

sub _replay {
    my ($self) = @_;

    my $result = Test::MockObject->new;
    my $called = 0;

    for my $e (@{ $self->_expectations }) {
        $result->mock(
            $e->method => $self->_create_mock_method($e, \$called)
        );
    }

    return $result;
}

=head2 verify($mock)

Verify $mock and returns true when success.

=cut

sub verify {
    my ($self, $mock) = @_;

    my $i = 1;
    for my $expectation (@{ $self->_expectations }) {
        my $where =
            sprintf('%s invocation of the mock', _nth($i));

        my @actual = $mock->next_call;
        if (! $actual[0]) {
            die sprintf(
                q{The %s is "%s" but not called},
                $where, $expectation->method
            );
        }
        if ($actual[0] && $actual[0] eq $expectation->method) {
            ;
        } else {
            die sprintf(
                q{The %s should be "%s" but called method was "%s"},
                $where, $expectation->method, $actual[0]
            );
        }
        $i++;
    }

    return 1;
}

=head2 verify_ok($callback), verify_ok($mock)

Verify and call Test::Builder's ok.

With $callback (code reference),
the method calls $callback with new mock object.

With $mock (not code reference), the method just verify $mock.

=cut

my $Test = Test::Builder->new;

sub verify_ok {
    my ($self, $arg, $test_name) = @_;

    $test_name ||= $self->default_test_name;

    if (ref $arg eq 'CODE') {
        $Test->ok($self->replay($arg), $test_name);
    } else {
        $Test->ok($self->verify($arg), $test_name);
    }
}

sub default_test_name {
    my ($self) = @_;

    my @methods = map {
        sprintf(q{'%s'}, $_->method);
    } @{ $self->_expectations };

    if (scalar @methods > 1) {
        my $last = pop @methods;
        return 'called ' . (join ', ', @methods) . ' and ' . $last;
    } else {
        return 'called ' . (join ', ', @methods);
    }
}

1;
__END__

=head1 DESIGN

Test::Mock::Recorder is heavily inspired from other language's mock library
especially Mox (Python) and Mocha (Ruby).

But it has a little different interface.

=head2 Need to call "replay" method but it returns object

Mocha don't need to call "replay" method.
But the interface need to reserve some method name such as "expects".

Mox need to call "replay" but it switch pre-created instances.
The interface is not straightforward.

=head2 Need to call "excepts", not AUTOLOAD hack

Mox has AUTOLOAD-style interface.
But the interface need to reserve some method name too.
And "Comparator" is difficult to learn I think.
L<http://code.google.com/p/pymox/wiki/MoxDocumentation#Comparators>

=head1 AUTHOR

Kato Kazuyoshi E<lt>kato.kazuyoshi@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=head2 Test::Expectation

L<http://search.cpan.org/dist/Test-Expectation/>

Test::Expectation provides record style interface
(expects, with, to_return, ...)
but it provides RSpec like interface (it_is_a, it_should, ...) too.

=head2 Test::Mock::Class

L<http://search.cpan.org/dist/Test-Mock-Class/>

Test::Mock::Class provides record style interface
(mock_invoke, mock_return, ...) but it depends Moose!

=head2 Mox

L<http://code.google.com/p/pymox/>

=head2 Mocha

L<http://mocha.rubyforge.org/>

=head2 Test Double

L<http://xunitpatterns.com/Test%20Double.html>

=cut

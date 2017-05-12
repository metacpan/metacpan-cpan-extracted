package Test::EasyMock::MockControl;
use strict;
use warnings;

=head1 NAME

Test::EasyMock::MockControl - Control behavior of the mock object.

=cut
use Data::Dump qw(pp);
use Data::Util qw(is_instance);
use List::Util qw(first);
use Scalar::Util qw(blessed);
use Test::Builder;
use Test::EasyMock::ArgumentsMatcher;
use Test::EasyMock::Expectation;
use Test::EasyMock::ExpectationSetters;
use Test::EasyMock::MockObject;

my $tb = Test::Builder->new();

=head1 CLASS METHODS

=head2 create_control

Create a default control instance.

=cut
sub create_control {
    my $class = shift;
    return $class->new(@_);
}

=head1 CONSTRUCTORS

=head2 new([$module|$object])

Create a instance.

=cut
sub new {
    my ($class, $module_or_object) = @_;
    my $blessed = blessed $module_or_object;
    return bless {
        _module => $blessed || $module_or_object,
        _object => $blessed && $module_or_object,
    }, $class;
}

=head1 INSTANCE METHODS

=head2 create_mock

Create a mock instance.

=cut
sub create_mock {
    my ($self) = @_;
    return bless {
        _control => $self,
    }, 'Test::EasyMock::MockObject';
}

=head2 process_method_invocation($mock, $method, @args)

Process method invocation.
Dispatch to replay or record method.

=cut
sub process_method_invocation {
    my ($self, $mock, $method, @args) = @_;
    return $self->{_is_replay_mode}
        ? $self->replay_method_invocation($mock, $method, @args)
        : $self->record_method_invocation($mock, $method, @args);
}

=head2 replay_method_invocation($mock, $method, @args)

Replay the method invocation.

=cut
sub replay_method_invocation {
    my ($self, $mock, $method, @args) = @_;
    my $expectation = $self->find_expectation({
        mock => $mock,
        method => $method,
        args => \@args,
    });
    my $object = $self->{_object};

    my $method_detail = "(method: $method, args: " . pp(@args) . ')';

    if ($expectation) {
        $tb->ok(1, 'Expected mock method invoked.'.$method_detail);
        return $expectation->retrieve_result();
    }
    elsif ($object && $object->can($method)) {
        return $object->$method(@args);
    }
    else {
        $tb->ok(0, 'Unexpected mock method invoked.'.$method_detail);
        return;
    }
}

=head2 record_method_invocation($mock, $method, @args)

Record the method invocation.

=cut
sub record_method_invocation {
    my ($self, $mock, $method, @args) = @_;
    my $expectation = Test::EasyMock::Expectation->new({
        method => $method,
        args => is_instance($args[0], 'Test::EasyMock::ArgumentsMatcher')
            ? $args[0]
            : Test::EasyMock::ArgumentsMatcher->new(\@args),
    });
    return ($mock, $expectation);
}

=head2 find_expectation($args)

Find the expectation by arguments.

=cut
sub find_expectation {
    my ($self, $args) = @_;
    my @expectations = grep { $_->matches($args) }
                            @{$self->{_expectations}};

    my $result = first { $_->has_result } @expectations;
    return $result || first { $_->has_stub_result } @expectations;
}

=head2 expect($expectation)

Record the expectation of the mock method invocation.

=cut
sub expect {
    my ($self, $mock, $expectation) = @_;
    push @{$self->{_expectations}}, $expectation;
    return Test::EasyMock::ExpectationSetters->new($expectation);
}

=head2 replay

Change to I<replay> mode.

=cut
sub replay {
  my ($self) = @_;
  $self->{_is_replay_mode} = 1;
}

=head2 reset

Clear expectations and change to I<record> mode.

=cut
sub reset {
    my ($self) = @_;
    $self->{_is_replay_mode} = 0;
    $self->{_expectations} = [];
}

=head2 verify

Verify the mock method invocations.

=cut
sub verify {
  my ($self) = @_;
  my $unsatisfied_message =
    join "\n", map { $_->unsatisfied_message }
              grep { !$_->is_satisfied }
                   @{$self->{_expectations}};
  $tb->is_eq($unsatisfied_message, '', 'verify mock invocations.');
}

1;

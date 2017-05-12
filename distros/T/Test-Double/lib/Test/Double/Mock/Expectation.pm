package Test::Double::Mock::Expectation;

use strict;
use warnings;
use List::MoreUtils qw(each_array);
use Test::Deep qw(cmp_details);
use Test::More;

sub new {
    my ($class, %args) = @_;
    bless {
        behavior   => sub {},
        %args,
        called     => 0,
    }, $class;
}

sub with {
    my ($self, @args) = @_;
    $self->{with_args} = \@args;
    $self;
}

sub at_least {
    my ($self, $at_least) = @_;
    $self->{at_least} = $at_least;
    return $self;
}

sub at_most {
    my ($self, $at_most) = @_;
    $self->{at_most} = $at_most;
    return $self;
}

sub times {
    my ($self, $times) = @_;
    $self->{times} = $times;
    return $self;
}

sub returns {
    my ($self, $behavior) = @_;
    if (defined $behavior) {
        $self->{behavior} = ref($behavior) eq 'CODE' ? $behavior : sub { $behavior };
    }
    $self;
}

sub behavior {
    my $self = shift;
    return sub {
        my ($instance, @args) = @_;
        $self->{called}++;
        if ($self->{with_args}) {
            $self->_check_with($self->{called}, @args)
        }
        return $self->{behavior}->();
    };
}

sub _check_with {
    my ($self, $counter, @args) = @_;
    if (scalar @args != scalar @{$self->{with_args}}) {
        $self->{with}->{$counter} = 0;
        return;
    }
    my $ea = each_array(@{$self->{with_args}}, @args);
    while (my ($with_arg, $arg) = $ea->())  {
        my ($ok, $stack) = cmp_details($arg, $with_arg);
        if ($ok) {
            $self->{with}->{$counter} = 1;
        } else {
            $self->{with}->{$counter} = 0;
            return;
        }
    }
}

sub _check_at_least {
    my $self = shift;
    return $self->{called} < $self->{at_least} ? 0 : 1;
}

sub _check_at_most {
    my $self = shift;
    return $self->{called} > $self->{at_most} ? 0 : 1;
}

sub _check_at_times {
    my $self = shift;
    return $self->{called} != $self->{times} ? 0 : 1;
}

sub verify_result {
    my $self = shift;

    if ($self->{at_least}) {
        $self->{result}->{at_least} = $self->_check_at_least;
    }
    if ($self->{at_most}) {
        $self->{result}->{at_most} = $self->_check_at_most;
    }
    if ($self->{times}) {
        $self->{result}->{times} = $self->_check_at_times;
    }
    for (keys %{$self->{with}}) {
        $self->{result}->{with}->{$_} = $self->{with}->{$_};
    }

    return $self->{result};

}

sub verify {
    my $self = shift;

    $self->verify_result;
    if ($self->{at_least}) {
        ok $self->{result}->{at_least},
          "Expected method must be called at least " . $self->{at_least};
    }
    if ($self->{at_most}) {
        ok $self->{result}->{at_most},
          "Expected method must be called at most " . $self->{at_most};
    }
    if ($self->{times}) {
        ok $self->{result}->{times},
          "Expected method must be called " . $self->{times} . " times";
    }
    for (keys %{$self->{with}}) {
        ok $self->{result}->{with}->{$_},
          "Expected method must be called with "
          . join " ", map { ref $_ ? ref $_ : $_ } @{$self->{with_args}};
    }
}

1;
__END__

=encoding utf-8

=for stopwords

=head1 NAME

Test::Double::Mock::Expectation - Mock expectation object

=head1 METHODS

=over 4

=item at_least

Modifies expectation so that the expected method must be called at least a minimum number of times.

=item at_most

Modifies expectation so that the expected method must be called at most a maximum number of times.

=item times

Modifies expectation so that the number of calls to the expected method must be within a specific range.

=item with(@args)

Assigns expected callee arguments.

=item returns($expected_value_or_subref)

Assigns expected returning value or subroutine reference.

=item verify_result

Return verified result hash.

=item verify

Verify how many times does method get called, and what parameters passed to method. Setting expectations that how many calling method by at_least() or at_most() or times() and what parameters passed by with().

=back

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::Double>, L<Test::Double::Mock>, L<Test::Deep>, L<Test::More>

=cut

package Test::Spec::RMock::MockObject;

sub new {
    my ($class, $name) = @_;
    my $self = {
        _name           => $name,
        _messages       => {},
        _problems_found => [],
        _canceled       => 0,
        _is_null_object => 0,
    };
    bless $self, $class;
    my $context = Test::Spec->current_context
        || Carp::croak "Test::Spec::RMocks only works in conjunction with Test::Spec";
    $context->on_leave(sub { $self->__teardown });
    $self;
}

sub should_receive {
    my ($self, $message) = @_;
    my $expectation = Test::Spec::RMock::MessageExpectation->new($message);
    $self->__register_expectation($message, $expectation);
    $expectation;
}

sub should_not_receive {
    my ($self, $message) = @_;
    $self->should_receive($message)->exactly(0)->times;
}

sub stub {
    my ($self, %spec) = @_;
    my $last_double;
    while (my ($method_name, $return_value) = each %spec) {
        $last_double = $self->should_receive($method_name)->and_return($return_value)->any_number_of_times;
    }
    $last_double;
}

sub stub_chain {
    my ($self, @chain) = @_;
    my $name = shift @chain;
    if (@chain) {
        my $next = __PACKAGE__->new('StubChainMockObject');
        $self->stub($name => $next);
        return $next->stub_chain(@chain);
    }
    $self->stub($name => undef);
}

sub as_null_object {
    my ($self) = @_;
    $self->{_is_null_object} = 1;
    $self;
}

sub __cancel {
    my ($self) = @_;
    $self->{_canceled} = 1;
    $self;
}

sub __register_expectation {
    my ($self, $message, $expectation) = @_;
    $self->{_messages}{$message} ||= [];
    push @{$self->{_messages}{$message}}, $expectation;
}


sub __teardown {
    my ($self) = @_;
    my $report = $self->__check;
    die $report if !$self->{_canceled} && $report;
    return 1;
}

sub __check {
    my ($self) = @_;
    for my $ms (values %{$self->{_messages}}) {
        for my $m (@$ms) { 
            push @{$self->{_problems_found}}, $m->call_contraint_error_message($self->{_name}) unless $m->is_call_constrint_satisfied;
        }
    }
    join("\n", @{$self->{_problems_found}});
}

sub __find_method_proxy {
    my ($self, $expectations, @args) = @_;
    for my $e (@$expectations) {
        return $e if $e->is_all_conditions_satisfied(@args);
    }
    for my $e (@$expectations) {
        return $e if $e->does_arguments_match(@args);
    }
    for my $e (@$expectations) {
        push @{$self->{_problems_found}}, $e->argument_matching_error_message(@args);
    }
    return $expectations->[0];
}

our $AUTOLOAD;
sub AUTOLOAD {
    my ($self, @args) = @_;
    my $message_name = $self->__get_message_name;
    my $expectations = $self->{_messages}{$message_name};
    unless ($expectations) {
        return $self if $self->{_is_null_object};
        push @{$self->{_problems_found}},
            sprintf("Unmocked method '%s' called on '%s' with (%s)", 
                    $message_name, 
                    $self->{_name},
                    join(', ', map {"'$_'"} @args));
        return;
    }
    my $proxy = $self->__find_method_proxy($expectations, @args);
    return $proxy->call(@args);
}

sub __get_message_name {
    my $name = $AUTOLOAD;
    $name =~ s/.*:://;
    $name;
}

1;

__END__

=pod

=head1 NAME

Test::Spec::RMock::MockObject

=head1 VERSION

version 0.006

=head1 AUTHOR

Kjell-Magne Øierud <kjellm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 by Kjell-Magne Øierud.

This is free software, licensed under:

  The MIT (X11) License

=cut

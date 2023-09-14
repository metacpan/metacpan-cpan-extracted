package
    Test::YA::CLI::Example::Something;
use Moo;
use namespace::autoclean;

with 'YA::CLI::ActionRole';

sub action    { 'something' }
sub usage_pod { 1 }

has foo => (
    is        => 'ro',
    predicate => 'has_foo',
);

sub cli_options {
    return qw(foo=s foobar=s);
}

sub run {
    my $self = shift;
    if ($self->has_foo) {
        return sprintf("You called me with foo=%s", $self->foo);
    }
    elsif ($self->_cli_args->{foobar}) {
        return
          sprintf("You called me with foobar=%s", $self->_cli_args->{foobar});
    }
    else {
        return "Called me with no args";
    }
}

__PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

This is the C<something> sub command

=head1 SYNOPSIS

    example.pl subcommand --foo

=head2 OPTIONS

=over

=item --foo

You can call me with --foo

=back

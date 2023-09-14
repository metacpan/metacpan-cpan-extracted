package
    Test::YA::CLI::Example::Something::Else;
use Moo;
use namespace::autoclean;

with 'YA::CLI::ActionRole';

sub action    { 'something' }
sub subaction { 'else' }
sub usage_pod { 1 }

has this => (
    is        => 'ro',
    predicate => 'has_this',
);

sub cli_options {
    return qw(this=s that=s);
}

sub run {
    my $self = shift;
    if ($self->has_this) {
        return sprintf("You called me with this=%s", $self->this);
    }
    elsif ($self->_cli_args->{that}) {
        return
          sprintf("You called me with that=%s", $self->_cli_args->{that});
    }
    else {
        return "Called me with no args";
    }
}

__PACKAGE__->meta->make_immutable;

=head1 DESCRIPTION

This is the C<something else> sub command

=head1 SYNOPSIS

    example.pl subcommand else --this

=head2 OPTIONS

=over

=item --this

You can call me with --this

=back

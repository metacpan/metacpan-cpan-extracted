package
    YA::CLI::Example::Something;
use Moo;
use namespace::autoclean;

with 'YA::CLI::ActionRole';

sub action    { 'something' }
sub usage_pod { 1 }

sub run {
    my $self = shift;
    printf("I'm running the sub command %s", $self->action);
    print $/;
    return;
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 DESCRIPTION

This is the C<something> sub command

=head1 SYNOPSIS

    example.pl subcommand --foo

=head2 OPTIONS

=over

=item --foo

You can call me with --foo

=back

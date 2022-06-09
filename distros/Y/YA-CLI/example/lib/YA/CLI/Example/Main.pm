package YA::CLI::Example::Main;
use Moo;
use namespace::autoclean;

# ABSTRACT: The handler of the 'main' action of the example app

with 'YA::CLI::ActionRole';

sub action    { 'main' }
sub usage_pod { 0 }

sub run {
    my $self = shift;
    my $h = $self->as_help(1);
    return $h->run;
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 DESCRIPTION

This action handler is the main action handler of your application. In this
example it just runs the help.

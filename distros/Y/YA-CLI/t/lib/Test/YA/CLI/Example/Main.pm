package
    Test::YA::CLI::Example::Main;
use Moo;
use namespace::autoclean;

# ABSTRACT: The main handler of the test suite

with 'YA::CLI::ActionRole';

sub action    { 'main' }
sub usage_pod { return }

sub run {
    my $self = shift;
    my $h = $self->as_help(1);
    return $h->run;
}

__PACKAGE__->meta->make_immutable;

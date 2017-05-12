package Test::EasyMock::ArgumentsMatcher;
use strict;
use warnings;

=head1 NAME

Test::EasyMock::ArgumentsMatcher - Arguments matcher.

=cut
use Test::Deep::NoTest qw(eq_deeply);

=head1 CONSTRUCTORS

=head2 new($args)

Create a instance.

=cut
sub new {
    my ($class, $args) = @_;
    return bless { _args => $args }, $class;
}

=head1 METHODS

=head2 matches($args)

It is tested whether the specified argument matches.

=cut
sub matches {
    my ($self, $args) = @_;
    return eq_deeply($args, $self->{_args});
}

1;

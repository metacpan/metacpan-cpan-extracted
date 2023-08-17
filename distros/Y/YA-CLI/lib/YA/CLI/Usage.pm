package YA::CLI::Usage;
our $VERSION = '0.003';
use Moo;
use namespace::autoclean;

# ABSTRACT: Class that handles usage and man page generation for action handlers

use Carp qw(croak);
use List::Util qw(first);
use Pod::Find qw(pod_where);
use Pod::Usage qw(pod2usage);

has verbose => (
    is      => 'ro',
    default => 1,
);

has rc => (
    is      => 'ro',
    default => 0,
);

has message => (
    is        => 'ro',
    predicate => 'has_message',
);

has pod_file => (
    is        => 'ro',
    predicate => 'has_pod_file'
);

sub run {
    my $self = shift;

    my $pod_where = $self->_pod_where;

    $self->_pod2usage(
        $self->has_message ? (-message => $self->message) : (),
        -verbose => $self->verbose,
        -exitval => $self->rc,
        $pod_where ? ('-input' => $pod_where) : (),
    );
}

sub _pod_where {
  my $self = shift;
  return unless $self->has_pod_file;
  return pod_where({ -inc => 1 }, $self->pod_file);
}

sub _pod2usage {
    my $self = shift;
    pod2usage(@_);
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

YA::CLI::Usage - Class that handles usage and man page generation for action handlers

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use YA::CLI::Usage;
    my $usage = YA::CLI::Usage->new(
        verbose  => 1,
        rc       => 1,
        message  => 'Foo',
        pod_file => '/path/to/pod',
    );

    $usage->run();

=head1 DESCRIPTION

This module takes care of the pod2usage invocations done by the action
handlers.

=for Pod::Coverage has_message has_pod_file

=head1 ATTRIBUTES

=head2 verbose

Defaults to 1. Maps to C<-verbose> of L<Pod::Usage/pod2usage>.

=head2 rc

The return value/code, defaults to 0. Maps to C<-exitval> of
L<Pod::Usage/pod2usage>.

=head2 message

An optional message. Maps to C<-message> of L<Pod::Usage/pod2usage>.

=head2 pod_file

Specifies the path to the pod file that is used if supplied.

=head1 METHODS

=head2 run

Display the usage to your user.

=head1 AUTHOR

Wesley Schwengle <waterkip@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2022 by Wesley Schwengle.

This is free software, licensed under:

  The (three-clause) BSD License

=cut

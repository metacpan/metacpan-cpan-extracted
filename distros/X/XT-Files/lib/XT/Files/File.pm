package XT::Files::File;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.002';

use Class::Tiny 1 qw(name);

use overload (
    q{""}    => sub    { shift->name },
    bool     => sub () { return 1 },
    fallback => 1,
);

use Carp ();

sub BUILD {
    my ( $self, $args ) = @_;

    Carp::croak 'name attribute required' if !defined $self->name;

    $self->{_module} = $args->{is_module} ? 1 : q{};
    $self->{_pod}    = $args->{is_pod}    ? 1 : q{};
    $self->{_script} = $args->{is_script} ? 1 : q{};
    $self->{_test}   = $args->{is_test}   ? 1 : q{};

    return;
}

sub is_module {
    my ($self) = @_;

    return $self->{_module} ? 1 : q{};
}

sub is_pod {
    my ($self) = @_;

    return $self->{_pod} ? 1 : q{};
}

sub is_script {
    my ($self) = @_;

    return $self->{_script} ? 1 : q{};
}

sub is_test {
    my ($self) = @_;

    return $self->{_test} ? 1 : q{};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

XT::Files::File - file object for XT::Files

=head1 VERSION

Version 0.002

=head1 SYNOPSIS

    use XT::Files::File;
    my $file = XT::Files::File->new( name => 'lib/Local/Module.pm', is_module => 1 );

    $file->is_module();  # returns 1
    $file->is_pod();     # returns empty string
    $file->is_script();  # returns empty string
    $file->is_test();    # returns empty string

=head1 DESCRIPTION

The C<XT::Files::File> object is used by L<XT::Files> to represent files that
should be tested.

=head1 USAGE

=head2 new( name => NAME, is_X => 1 )

Returns a new C<XT::Files::File> object. C<new> takes a hash or hash ref
with its arguments.

The C<name> argument is the name of the file and is required.

The arguments C<is_module>, C<is_pod>, C<is_script> and C<is_test> are
optional and default to false. They specify what kind of file it is.

=head1 SEE ALSO

L<Test::XTFiles>, L<XT::Files>

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/skirmess/XT-Files/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/skirmess/XT-Files>

  git clone https://github.com/skirmess/XT-Files.git

=head1 AUTHOR

Sven Kirmess <sven.kirmess@kzone.ch>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2019 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl

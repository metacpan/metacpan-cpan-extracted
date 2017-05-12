package Test::TempDir::Handle;
# ABSTRACT: A handle for managing a temporary directory root

our $VERSION = '0.10';

use Moose;
use MooseX::Types::Path::Class qw(Dir);
use Moose::Util::TypeConstraints;

use namespace::autoclean 0.08;

has dir => (
    isa => Dir,
    is  => "ro",
    handles => [qw(file subdir rmtree)],
);

has lock => (
    isa => "File::NFSLock",
    is  => "ro",
    predicate => "has_lock",
    clearer   => "clear_lock",
);

has cleanup_policy => (
    isa => enum([ qw(success always never) ]),
    is  => "rw",
    default => "success",
);

has test_builder => (
    isa => "Test::Builder",
    is  => "rw",
    lazy_build => 1,
    handles => { test_summary => "summary" },
);

sub _build_test_builder {
    require Test::Builder;
    Test::Builder->new;
}

sub failing_tests {
    my $self = shift;
    grep { !$_ } $self->test_summary;
}

sub empty {
    my $self = shift;
    return unless -d $self->dir;
    $self->rmtree({ keep_root => 1 });
}

sub delete {
    my $self = shift;
    return unless -d $self->dir;
    $self->rmtree({ keep_root => 0 });
    $self->dir->parent->remove; # rmdir, safe, and we don't care about errors
}

sub release_lock {
    my $self = shift;

    $self->clear_lock;

    # FIXME always unlock? or allow people to keep the locks around by enrefing them?

    #if ( $self->has_lock ) {
    #    $self->lock->unlock;
    #    $self->clear_lock;
    #}
}

sub DEMOLISH {
    my $self = shift;
    $self->cleanup;
}

sub cleanup {
    my ( $self, @args ) = @_;

    $self->release_lock;

    my $policy = "cleanup_policy_" . $self->cleanup_policy;

    $self->can($policy) or die "Unknown cleanup policy " . $self->cleanup_policy;

    $self->$policy(@args);
}

sub cleanup_policy_never {}

sub cleanup_policy_always {
    my ( $self, @args ) = @_;

    $self->delete;
}

sub cleanup_policy_success {
    my ( $self, @args ) = @_;

    if ( $self->failing_tests ) {
        $self->test_builder->diag("Leaving temporary directory '" . $self->dir . "' due to test fails");
    } else {
        $self->cleanup_policy_always(@args);
    }
}

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

Test::TempDir::Handle - A handle for managing a temporary directory root

=head1 VERSION

version 0.10

=head1 SYNOPSIS

    use Test::TempDir::Handle;

    my $h = Test::TempDir::Handle->new( dir => dir("t/tmp") );

    $h->empty;

    # ...

    $h->cleanup; # will delete on success by default

=head1 DESCRIPTION

This class manages a temporary directory.

=head1 ATTRIBUTES

=head2 C<dir>

The L<Path::Class::Dir> that is being managed.

=head2 C<lock>

An optional lock object (L<File::NFSLock>). Just kept around for reference counting.

=head2 C<cleanup_policy>

One of C<success>, C<always> or C<never>.

C<success> means that C<cleanup> deletes only if C<test_builder> says the tests
have passed.

=head2 C<test_builder>

The L<Test::Builder> singleton.

=head1 METHODS

=head2 C<empty>

Cleans out the directory but doesn't delete it.

=head2 C<delete>

Cleans out the directory and removes it.

=head2 C<cleanup>

Calls C<delete> if the C<cleanup_policy> dictates to do so.

This is normally called automatically at destruction.

=head1 AUTHOR

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by יובל קוג'מן (Yuval Kogman).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

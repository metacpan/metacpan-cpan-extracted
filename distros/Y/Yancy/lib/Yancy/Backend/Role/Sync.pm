package Yancy::Backend::Role::Sync;
our $VERSION = '1.033';
# ABSTRACT: A role to give a synchronous backend useful Promises methods

#pod =head1 SYNOPSIS
#pod
#pod     package Yancy::Backend::SyncOnly;
#pod     with 'Yancy::Backend::Role::Sync';
#pod
#pod     package main;
#pod     my $be = Yancy::Backend::SyncOnly->new;
#pod     my $promise = $be->create_p( \%item );
#pod
#pod =head1 DESCRIPTION
#pod
#pod This role implements C<list_p>, C<get_p>, C<set_p>, C<delete_p>, and
#pod C<create_p> methods that return L<Mojo::Promise> objects for synchronous
#pod backends. This does not make the backend asynchronous: The original,
#pod synchronous method is called and a promise object created from the
#pod result. The promise is then returned already fulfilled.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Yancy::Backend>
#pod
#pod =cut

use Mojo::Base '-role';
use Mojo::Promise;

sub _call_with_promise {
    my ( $self, $method, @args ) = @_;
    my @return = $self->$method( @args );
    my $promise = Mojo::Promise->new;
    $promise->resolve( @return );
}

sub list_p { return _call_with_promise( shift, list => @_ ) }
sub get_p { return _call_with_promise( shift, get => @_ ) }
sub set_p { return _call_with_promise( shift, set => @_ ) }
sub delete_p { return _call_with_promise( shift, delete => @_ ) }
sub create_p { return _call_with_promise( shift, create => @_ ) }

1;

__END__

=pod

=head1 NAME

Yancy::Backend::Role::Sync - A role to give a synchronous backend useful Promises methods

=head1 VERSION

version 1.033

=head1 SYNOPSIS

    package Yancy::Backend::SyncOnly;
    with 'Yancy::Backend::Role::Sync';

    package main;
    my $be = Yancy::Backend::SyncOnly->new;
    my $promise = $be->create_p( \%item );

=head1 DESCRIPTION

This role implements C<list_p>, C<get_p>, C<set_p>, C<delete_p>, and
C<create_p> methods that return L<Mojo::Promise> objects for synchronous
backends. This does not make the backend asynchronous: The original,
synchronous method is called and a promise object created from the
result. The promise is then returned already fulfilled.

=head1 SEE ALSO

L<Yancy::Backend>

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

package Test::Mock::Signature::Meta;

use strict;
use warnings;

use Test::Mock::Signature;
use Test::Mock::Signature::Dispatcher;

sub new {
    my ($class, %params) = @_;

    return bless(\%params, $class);
}

sub callback {
    my $self       = shift;
    my $callback   = shift;

    return $self->{'callback'} unless defined $callback;

    my $real_class = $self->{'class'};
    my $mock       = Test::Mock::Signature->new($real_class);

    $self->{'callback'}  = $callback;

    my $dispatcher = $mock->dispatcher($self->{'method'});
    $dispatcher->add($self);
    $dispatcher->compile;
}

sub params {
    my $self = shift;

    return $self->{'params'};
}

42;

__END__

=head1 NAME

Test::Mock::Signature::Meta - meta class. Used as a signature container.

=head1 SYNOPSIS

Create meta container module:

    my $meta = Test::Mock::Signature::Meta->new(
        class  => 'My::Real::Class',
        method => 'do_something',
        params => [ 1, 2, 3 ]
    );

=head1 DESCRIPTION

Module for storing meta information of the signature. Used internally to
iterate between meta clases in L<Test::Mock::Signature::Dispatcher>.

=head1 METHODS

=head2 new()

Takes 3 paramters (as a key value pairs).

=over 8

=item class

Name of the real class which we are mocking.

=item method

Name of the mocked method.

=item params

Array reference of the parameters.

=back

=head2 callback( [ $code_ref ] )

Set callback for the given meta information if C<$code_ref> is given or return
callback if not.

=head2 params()

Getter for the params.

=head1 AUTHOR

cono E<lt>cono@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2014 - cono

=head1 LICENSE

Artistic v2.0

=head1 SEE ALSO

L<Test::Mock::Signature>

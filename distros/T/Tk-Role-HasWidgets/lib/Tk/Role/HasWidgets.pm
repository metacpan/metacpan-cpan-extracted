#
# This file is part of Tk-Role-HasWidgets
#
# This software is copyright (c) 2010 by Jerome Quelin.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use 5.010;
use strict;
use warnings;

package Tk::Role::HasWidgets;
{
  $Tk::Role::HasWidgets::VERSION = '1.112380';
}
# ABSTRACT: keep track of your tk widgets

use Moose::Role 0.92;
use MooseX::Has::Sugar;



# a hash to store the widgets for easier reference.
has _widgets => (
    ro,
    traits  => ['Hash'],
    isa     => 'HashRef',
    default => sub { {} },
    handles => {
        _set_w   => 'set',
        _w       => 'get',
        _del_w   => 'delete',
        _clear_w => 'clear',
    },
);

no Moose::Role;
1;


=pod

=head1 NAME

Tk::Role::HasWidgets - keep track of your tk widgets

=head1 VERSION

version 1.112380

=head1 SYNOPSIS

    package Your::Tk::Window::Class;

    use Moose;
    with 'Tk::Role::HasWidgets';

    # store a button
    $self->_set_w( my_button => $button );

    # later on, in one of the methods
    $self->_w( 'my_button' )->configure( ... );

    # when no longer needed:
    $self->_del_w( 'my_button' );

=head1 DESCRIPTION

When programming L<Tk>, it's almost always a good idea to keep a
reference to the widgets that you created in the interface. Most of the
time, a simple hash is enough; but it is usually wrapped up in methods
to make the hash private to the window object. And of course, those
methods are duplicated in all modules, under a form or another.

Since duplication is bad, this module implements a L<Moose> role
implementing those methods once and forever. This implies that your
class is using L<Moose> in order to consume the role.

=head2 About the method names

The methods featured in this role begin with C<_>, that is, they are
following Perl convention of private methods. This is on purpose:
remember that this method is a role, consumed by your class. And you
don't want those methods to be available outside of the window
class, do you?

=head1 METHODS

=head2 _set_w

    $object->_set_w( $name, $widget );

Store a reference to C<$widget> and associate it to C<$name>.

=head2 _w

    my $widget = $object->_w( $name );

Get back the C<$widget> reference associated to C<$name>.

=head2 _del_w

    $object->_del_w( $name );

Delete the C<$name> reference to a widget.

=head2 _clear_w

Empty the widget references.

=head1 SEE ALSO

You can look for information on this module at:

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/Tk-Role-HasWidgets>

=item * See open / report bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Tk-Role-HasWidgets>

=item * Git repository

L<http://github.com/jquelin/tk-role-haswidgets>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Tk-Role-HasWidgets>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Tk-Role-HasWidgets>

=back

=head1 AUTHOR

Jerome Quelin

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Jerome Quelin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__


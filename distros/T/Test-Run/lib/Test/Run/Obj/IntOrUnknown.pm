package Test::Run::Obj::IntOrUnknown;

=head1 NAME

Test::Run::Obj::IntOrUnknown - an object representing a int or unknown.

=head1 DESCRIPTION

Inherits from Test::Run::Base::Struct.

=head1 METHODS

=cut

use strict;
use warnings;

use vars qw(@fields);

use Moose;

extends('Test::Run::Base::Struct');

has '_is_unknown' => (is => "rw", isa => "Bool");
has '_val' => (is => "rw", isa => "Maybe[Int]");

=head2 $class->create_unknown()

Creates an unknown value.

=cut

sub create_unknown
{
    my $class = shift;

    return $class->new({_is_unknown => 1});
}

=head2 $class->create_int($integer)

Creates an integer value.

=cut

sub create_int
{
    my $class = shift;
    my $integer = shift;

    return $class->new({_is_unknown => 0, _val => $integer});
}

=head2 zero()

A new 0 constant.

=cut

sub zero
{
    my $class = shift;

    return $class->create_int(0);
}

=head2 $class->init_from_string("??" | [Integer])

Inits a value from a string.

=cut

sub init_from_string
{
    my $class = shift;
    my $string = shift;

    return
    (
          ($string eq "??")
        ? $class->create_unknown()
        : $class->create_int(int($string))
    );
}

=head2 $self->get_string_val()

Returns "??" if the value is undefined or its numeric value otherwise.

=cut

sub get_string_val
{
    my $self = shift;

    return ($self->_is_unknown() ? "??" : $self->_val());
}

1;

__END__

=head1 SEE ALSO

L<Test::Run::Base::Struct>, L<Test::Run::Obj>, L<Test::Run::Core>

=head1 COPYRIGHT

Copyright by Shlomi Fish, 2009.

=head1 LICENSE

This file is freely distributable under the MIT X11 license.

L<http://www.opensource.org/licenses/mit-license.php>

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>.

=cut


package Test::Run::Sprintf::Named::FromAccessors;

use strict;
use warnings;

=head1 NAME

Test::Run::Sprintf::Named::FromAccessors - named sprintf according to the
values of accessors.

=head1 SYNOPSIS

    my $formatter =
        Test::Run::Sprintf::Named::FromAccessors->new(
            {
                fmt => "Hello %(name)s! Today you are %(age)d years old.",
            )
        );

    my $person1 = Person->new(name => "Larry", age => 24);

    my $msg1 = $formatter->format({args => { obj => $person1 }});

    my $person2 = Person->new(name => "Rachel", age => 30);

    my $msg2 = $formatter->format({args => { obj => $person2 }});

=head1 DESCRIPTION

This module is a sub-class of L<Text::Sprintf::Named> where the variables
inside the sprintf fields (e.g: C<%(varname)s>) are read from the accessors
(or any other function) of the current object.

=head1 METHODS

=cut

use Moose;

extends('Text::Sprintf::Named');


=head2 $formatter->calc_param()

Over-riding the behavior of the equivalent one in Text::Sprintf::Named.

=cut

sub calc_param
{
    my ($self, $args) = @_;

    my $method = $args->{name};

    return $args->{named_params}->{obj}->$method();
}

=head2 $formatter->obj_format($object, \%args)

Formats based on the accessors of the object $object. I don't think %args
is used in any way.

=cut

sub obj_format
{
    my ($self, $obj, $other_args) = @_;

    if (!$other_args)
    {
        $other_args = {};
    }

    return $self->format({args => {obj => $obj, %$other_args}});
}

1;

__END__

=head1 AUTHOR

Written by Shlomi Fish, L<http://www.shlomifish.org/>.

=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php

=head1 SEE ALSO

L<Text::Sprintf::Named> , L<Test::Run>


package Test::Run::Base::Struct;

use strict;
use warnings;

=head1 NAME

Test::Run::Base::Struct - base class for Test::Run's "structs", that are
simple classes that hold several values.

=head1 DESCRIPTION

Inherits from L<Test::Run::Base>.

=cut

use MRO::Compat;
use Moose;

# We need to put it here before the use MooseX::StrictConstructor due
# to a Moose mis-feature. Thanks to doy.
BEGIN
{
    extends('Test::Run::Base');
}

use MooseX::StrictConstructor;


sub _pre_init
{
}

use Carp;

=head2 BUILD

For Moose.

=cut

sub BUILD
{
    my $self = shift;

=begin debugging_code

    Carp::confess '$args not a hash' if (ref($args) ne "HASH");

=end debugging_code

=cut

    $self->_pre_init();

    return;
}

=head1 METHODS

=head2 $struct->inc_field($field_name)

Increment the slot $field_name by 1.

=cut

sub inc_field
{
    my ($self, $field) = @_;
    return $self->add_to_field($field, 1);
}

=head2 $struct->add_to_field($field_name, $difference)

Add $difference to the slot $field_name.

=cut

sub add_to_field
{
    my ($self, $field, $diff) = @_;
    $self->$field($self->$field()+$diff);
}

1;

__END__

=head1 SEE ALSO

L<Test::Run::Base>, L<Test::Run::Obj>, L<Test::Run::Core>

=head1 LICENSE

This file is freely distributable under the MIT X11 license.

L<http://www.opensource.org/licenses/mit-license.php>

=head1 AUTHOR

Shlomi Fish, L<http://www.shlomifish.org/>.

=cut


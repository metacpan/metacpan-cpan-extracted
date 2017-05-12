package Test::Run::Base::PlugHelpers;

use strict;
use warnings;

=head1 NAME

Test::Run::Base::PlugHelpers - base class for Test::Run's classes with
pluggable helpers.

=cut

use MRO::Compat;

use Carp;

use Moose;

extends('Test::Run::Base');


use Test::Run::Base::Plugger;

has '_plug_helpers' => (is => "rw", isa => "HashRef",
    lazy => 1, default => sub { +{} },
);

=head2 $self->register_pluggable_helper( { %args } )

Registers a pluggable helper class (commonly done during initialisation).
%args contain the following keys:

=over 4

=item * 'id'

The 'id' identifying this class type.

=item * 'base'

The base class to use as the ultimate primary class of the plugin-based class.

=item * 'collect_plugins_method'

The method from which to collect the plugins. It should be defined for every
base class in the hierarchy of the main class (that instantiates the helpers)
and is traversed there.

=back

=cut

sub register_pluggable_helper
{
    my ($self, $args) = @_;

    my %plug_helper_struct;

    foreach my $key (qw(id base collect_plugins_method))
    {
        my $value = $args->{$key}
            or confess "\"$key\" not specified for register_pluggable_helper";

        $plug_helper_struct{$key} = $value;
    }

    $self->_plug_helpers()->{$plug_helper_struct{'id'}}
        = \%plug_helper_struct;

    return;
}

=head2 $self->calc_helpers_namespace($id)

Calc the namespace to put the helper with the ID C<$id> in.

=cut

sub calc_helpers_namespace
{
    my ($self, $id) = @_;

    return
        $self->helpers_base_namespace() . "::Helpers::" . ucfirst($id)
        ;
}

=head2 $self->create_pluggable_helper_obj({ id => $id, args => $args })

Instantiates a new pluggable helper object of the ID $id and with $args
passed to the constructor.

=cut

sub create_pluggable_helper_obj
{
    my ($self, $args) = @_;

    my $id = $args->{id};

    my $plug_struct = $self->_plug_helpers()->{$id};
    if (!defined($plug_struct))
    {
        confess "Unknown Pluggable Helper ID \"$id\"!";
    }

    my $plugger = Test::Run::Base::Plugger->new(
        {
            base => $plug_struct->{base},
            into => $self->calc_helpers_namespace($id),
        }
    );

    $plugger->add_plugins(
        $self->accum_array(
            {
                method => $plug_struct->{collect_plugins_method}
            }
        )
    );

    return
        $plugger->create_new(
            $args->{args},
        );
}

=head2 $self->helpers_base_namespace()

B<TO OVERRIDE>: this method determines the base namespace used as the
base for the pluggable helpers classes.

=cut


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


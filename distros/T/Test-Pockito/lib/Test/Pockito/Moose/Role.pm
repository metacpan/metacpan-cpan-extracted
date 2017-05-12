package Test::Pockito::Moose::Role;
use Moose::Meta::Role;

=head1

Creates a package based on a Moose role.  Has only one sub:

convert( $target_package_name, $role );

Creates a package based on the role.

=cut

sub convert {
    my $role_package = shift;
    my $role = shift;

    my $meta = Moose::Meta::Role->initialize($role);

    my %dispatch = map {
        $_,
          sub { }
    } $meta->get_method_list;

    map {
        $dispatch{ $_->name } =
          sub { }
    } $meta->get_required_method_list;

    my $package = "${role_package}::${role}";
    Class::MOP::Class->create( $package, 'methods' => \%dispatch, );
}
1;

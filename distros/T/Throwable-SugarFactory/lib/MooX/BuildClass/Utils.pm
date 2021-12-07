package MooX::BuildClass::Utils;

use strictures 2;

use Module::Runtime 'module_notional_filename';

use parent 'Exporter';

our @EXPORT_OK = qw( make_variant_package_name make_variant );

our $VERSION = '0.213360'; # VERSION

# ABSTRACT: methods for MooX::BuildClass and MooX::BuildRole

#
# This file is part of Throwable-SugarFactory
#
#
# Christian Walde has dedicated the work to the Commons by waiving all of his
# or her rights to the work worldwide under copyright law and all related or
# neighboring legal rights he or she had in the work, to the extent allowable by
# law.
#
# Works under CC0 do not require attribution. When citing the work, you should
# not imply endorsement by the author.
#


sub make_variant_package_name {
    my ( undef, $name ) = @_;

    my $path = module_notional_filename $name;
    die "Won't clobber already loaded: $path => $INC{$path}" if $INC{$path};

    return $name;
}


sub make_variant {
    my ( $class, undef, undef, @args ) = @_;
    while ( @args ) {
        my ( $func, $args ) = ( shift @args, shift @args );
        $args = [$args] if ref $args ne "ARRAY";
        $class->can( $func )->( @{$args} );
    }
    return;
}

1;

__END__

=pod

=head1 NAME

MooX::BuildClass::Utils - methods for MooX::BuildClass and MooX::BuildRole

=head1 VERSION

version 0.213360

=head1 DESCRIPTION

Provides methods for L<MooX::BuildClass> and L<MooX::BuildRole>.

=head1 METHODS

=head2 make_variant_package_name

Advises Package::Variant to use the user-provided name to create the new package
in. Dies if that package has already been defined.

=head2 make_variant

Takes the arguments and executes them as function calls on the target package
to declare the package contents.

=head1 AUTHOR

Christian Walde <walde.christian@gmail.com>

=head1 COPYRIGHT AND LICENSE


Christian Walde has dedicated the work to the Commons by waiving all of his
or her rights to the work worldwide under copyright law and all related or
neighboring legal rights he or she had in the work, to the extent allowable by
law.

Works under CC0 do not require attribution. When citing the work, you should
not imply endorsement by the author.

=cut

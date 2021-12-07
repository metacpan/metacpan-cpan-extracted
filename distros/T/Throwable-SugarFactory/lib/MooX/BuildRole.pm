package MooX::BuildRole;

use strictures 2;
use Moo::Role 1.004000 ();    # required to get %INC-marking
use Package::Variant 1.003002 #
  importing => ['Moo::Role'],
  subs      => [qw(extends has with before around after requires)];

use MooX::BuildClass::Utils qw( make_variant_package_name make_variant );

our $VERSION = '0.213360'; # VERSION

# ABSTRACT: build a Moo role at runtime

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


1;

__END__

=pod

=head1 NAME

MooX::BuildRole - build a Moo role at runtime

=head1 VERSION

version 0.213360

=head1 DESCRIPTION

Sister module to L<MooX::BuildClass>, is used identically, but creates roles,
not classes.

Additional exported function is:

requires

Unsupported function is:

extends

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

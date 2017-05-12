package Throwable::SugarFactory::Hashable;

use strictures 2;
use Class::Inspector;
use Moo::Role;

our $VERSION = '0.152700'; # VERSION

# ABSTRACT: role provides a generic to_hash function for Throwable exceptions

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


sub to_hash {
    my ( $self ) = @_;
    my @base_methods = qw( error namespace description previous_exception );
    my %skip_methods = map { $_ => 1 } @base_methods,
      qw( BUILDALL BUILDARGS DEMOLISHALL DOES after around before does extends
      has meta new throw previous_exception to_hash with );
    my $methods = Class::Inspector->methods( ref $self, 'public' );
    my %data = map { $_ => $self->$_ } grep { !$skip_methods{$_} } @{$methods};
    my %out = ( data => \%data, map { $_ => $self->$_ } @base_methods );
    return \%out;
}

1;

__END__

=pod

=head1 NAME

Throwable::SugarFactory::Hashable - role provides a generic to_hash function for Throwable exceptions

=head1 VERSION

version 0.152700

=head1 METHODS

=head2 to_hash

Returns a hash reference containing the data of the exception.

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

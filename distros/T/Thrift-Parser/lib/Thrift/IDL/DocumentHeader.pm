package Thrift::IDL::DocumentHeader;

=head1 NAME

Thrift::IDL::DocumentHeader

=head1 DESCRIPTION

Inherits from L<Thrift::IDL::Base>

=cut

use strict;
use warnings;
use base qw(Thrift::IDL::Base);
__PACKAGE__->mk_accessors(qw(namespaces includes path basename));

=head1 METHODS

=head2 namespaces

=head2 includes

=head2 path

=head2 basename

Scalar accessors

=head2 namespace ($scope)

Searches through the C<namespaces> and returns the one that matches the named scope.

=cut

sub namespace {
    my ($self, $scope) = @_;

    foreach my $namespace (@{ $self->namespaces }) {
        if ($namespace->scope eq $scope || $namespace->scope eq '*') {
            my $value = $namespace->value;
            if ($scope eq 'perl') {
                $value =~ s/\./::/g;
            }
            return $value;
        }
    }
    return;
}

1;

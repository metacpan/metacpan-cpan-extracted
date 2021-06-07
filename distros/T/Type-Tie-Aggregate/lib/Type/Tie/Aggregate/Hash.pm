# ABSTRACT: class to tie hashes for Type::Tie::Aggregate

######################################################################
# Copyright (C) 2021 Asher Gordon <AsDaGo@posteo.net>                #
#                                                                    #
# This program is free software: you can redistribute it and/or      #
# modify it under the terms of the GNU General Public License as     #
# published by the Free Software Foundation, either version 3 of     #
# the License, or (at your option) any later version.                #
#                                                                    #
# This program is distributed in the hope that it will be useful,    #
# but WITHOUT ANY WARRANTY; without even the implied warranty of     #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU   #
# General Public License for more details.                           #
#                                                                    #
# You should have received a copy of the GNU General Public License  #
# along with this program. If not, see                               #
# <http://www.gnu.org/licenses/>.                                    #
######################################################################

package Type::Tie::Aggregate::Hash;
$Type::Tie::Aggregate::Hash::VERSION = '0.001';
#pod =head1 DESCRIPTION
#pod
#pod This class is used to tie hashes. This class is internal to
#pod L<Type::Tie::Aggregate|Type::Tie::Aggregate>.
#pod
#pod =cut

use v5.6.0;
use strict;
use warnings;
use namespace::autoclean;
use Carp;
use parent 'Type::Tie::Aggregate::Base';

sub _create_ref {
    shift;
    if (@_ % 2) {
	carp 'Odd number of elements in hash initialization';
	push @_, undef;
    }
    +{ @_ };
}

sub _check_value {
    my (undef, $value) = @_;
    return 'Not a HASH reference' unless ref $value eq 'HASH';
    return;
}

sub TIEHASH { my $class = shift; $class->_new(@_) }

__PACKAGE__->_install_methods(
    { mutates => 1 },
    STORE	=> '$ref->{$_[0]} = $_[1]',
    DELETE	=> 'delete $ref->{$_[0]}',
    CLEAR	=> '%$ref = ()',
);

__PACKAGE__->_install_methods(
    { mutates => 0 },
    FETCH	=> '$ref->{$_[0]}',
    FIRSTKEY	=> 'scalar keys %$ref; each %$ref',
    NEXTKEY	=> 'each %$ref',
    EXISTS	=> 'exists $ref->{$_[0]}',
    SCALAR	=> 'scalar %$ref',
);

#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod * L<Type::Tie::Aggregate>
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Type::Tie::Aggregate::Hash - class to tie hashes for Type::Tie::Aggregate

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This class is used to tie hashes. This class is internal to
L<Type::Tie::Aggregate|Type::Tie::Aggregate>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Type-Tie-Aggregate>
or by email to
L<bug-Type-Tie-Aggregate@rt.cpan.org|mailto:bug-Type-Tie-Aggregate@rt.cpan.org>.

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=over 4

=item *

L<Type::Tie::Aggregate>

=back

=head1 AUTHOR

Asher Gordon <AsDaGo@posteo.net>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2021 Asher Gordon <AsDaGo@posteo.net>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or (at
your option) any later version.

This program is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.

=cut

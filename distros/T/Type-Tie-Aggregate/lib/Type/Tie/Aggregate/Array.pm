# ABSTRACT: class to tie arrays for Type::Tie::Aggregate

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

package Type::Tie::Aggregate::Array;
$Type::Tie::Aggregate::Array::VERSION = '0.001';
#pod =head1 DESCRIPTION
#pod
#pod This class is used to tie arrays. This class is internal to
#pod L<Type::Tie::Aggregate|Type::Tie::Aggregate>.
#pod
#pod =cut

use v5.6.0;
use strict;
use warnings;
use namespace::autoclean;
use parent 'Type::Tie::Aggregate::Base';

sub _create_ref { shift; \@_ }

sub _check_value {
    my (undef, $value) = @_;
    return 'Not an ARRAY reference' unless ref $value eq 'ARRAY';
    return;
}

sub TIEARRAY { my $class = shift; $class->_new(@_) }

__PACKAGE__->_install_methods(
    { mutates => 1 },
    STORESIZE	=> '$#$ref = $_[0] - 1',
    STORE	=> '$ref->[$_[0]] = $_[1]',
    CLEAR	=> '@$ref = ()',
    POP		=> 'pop @$ref',
    PUSH	=> 'push @$ref, @_',
    SHIFT	=> 'shift @$ref',
    UNSHIFT	=> 'unshift @$ref, @_',
    SPLICE	=> '&CORE::splice($ref, @_)',
    DELETE	=> 'delete $ref->[$_[1]]',
);

__PACKAGE__->_install_methods(
    { mutates => 0 },
    FETCHSIZE	=> '@$ref',
    FETCH	=> '$ref->[$_[0]]',
    EXISTS	=> 'exists $ref->[$_[0]]',
    EXTEND	=> sub {},
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

Type::Tie::Aggregate::Array - class to tie arrays for Type::Tie::Aggregate

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This class is used to tie arrays. This class is internal to
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

package Sympatic::Role;
require Sympatic;

sub import { Sympatic->import( to => (scalar caller), -class ); }

1;

=encoding utf8

=head1 NAME

Sympatic::Role - A Moo::Role with all the Sympatic magic.

=head1 STATUS

=for HTML
<a href="http://travis-ci.org/sympa-community/p5-sympatic/">
<img src="https://travis-ci.org/sympa-community/p5-sympatic.svg?branch=master">
</a>

=head1 DESCRIPTION

you can write this

    use Sympatic::Role;

instead of this

    use Sympatic -class;

so writing a Sympatic role C<Flyable> is just like

    package Flyable;
    use Sympatic::Role;

    method fly () { $self->altitude += 10 }
    1;

and use it in your C<Pet> class

    package Pet;
    use Sympatic;
    with 'Flyable';

    has qw( altitude is rw
        lvalue   1
        default  0
    );

    has qw( name is rw );

    1;


=head1 LICENSE AND COPYRIGHT

Copyright 2018 Sympa community <F<sympa-developpers@listes.renater.fr>>

This package is free software and is provided "as is" without express
or implied warranty.  you can redistribute it and/or modify it under the
same terms as the Perl 5 programming language system itself.

=head1 LICENCE

    Copyright (C) 2017,2018 Sympa Community

    Sympatic is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License as
    published by the Free Software Foundation; either version 2 of the
    License, or (at your option) any later version.

    Sympatic is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, see <http://www.gnu.org/licenses/>.

=cut

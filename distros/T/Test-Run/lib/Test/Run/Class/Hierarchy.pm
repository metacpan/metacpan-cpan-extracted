package Test::Run::Class::Hierarchy;

use strict;
use warnings;

=head1 NAME

Test::Run::Class::Hierarchy - returns a list of super-classes in topological
order.

=head1 SYNPOSIS

    use Test::Run::Class::Hierarchy;

    my $base_classes = hierarchy_of("MyClass::Sub::Sub::Sub");

    my $base_classes_rev = rev_hierarchy_of("MyClass::Sub::Sub::Sub");

=head1 DESCRIPTION

Returns a list of classes in the current namespace. Note that it caches
the results.

=head1 EXPORTS

=cut

use Moose;

extends('Exporter');

use List::MoreUtils (qw(uniq));

our @EXPORT_OK = (qw(hierarchy_of rev_hierarchy_of));

our %_hierarchy_of = ();

=head2 my [@list] = hierarchy_of($class)

Returns a list of the classes in the hierarchy of the class, from bottom to
top.

=cut

sub hierarchy_of
{
    my $class = shift;

    if (exists($_hierarchy_of{$class}))
    {
        return $_hierarchy_of{$class};
    }

    no strict 'refs';

    my @hierarchy = $class;
    my @parents = @{$class. '::ISA'};

    while (my $p = shift(@parents))
    {
        push @hierarchy, $p;
        push @parents, @{$p. '::ISA'};
    }

    my @unique = uniq(@hierarchy);

    return $_hierarchy_of{$class} =
        [
            sort
            {
                  $a->isa($b) ? -1
                : $b->isa($a) ? +1
                :               0
            }
            @unique
        ];
}

our %_rev_hierarchy_of = ();

=head2 my [@list] = rev_hierarchy_of($class)

Returns the classes from top to bottom.

=cut

sub rev_hierarchy_of
{
    my $class = shift;

    if (exists($_rev_hierarchy_of{$class}))
    {
        return $_rev_hierarchy_of{$class};
    }

    return $_rev_hierarchy_of{$class} = [reverse @{hierarchy_of($class)}];
}

1;

=head1 LICENSE

This file is licensed under the MIT X11 License:

http://www.opensource.org/licenses/mit-license.php

=head1 CREDITS

The code was inspired by the code from Damian Conway's L<Class::Std>, but
is not inclusive of it.

Written by Shlomi Fish: L<http://www.shlomifish.org/>.

=head1 SEE ALSO

L<Class::Std>, L<Test::Run>

=cut


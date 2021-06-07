# ABSTRACT: used to deeply tie variables

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

package Type::Tie::Aggregate::Deep;
$Type::Tie::Aggregate::Deep::VERSION = '0.001';
#pod =head1 DESCRIPTION
#pod
#pod This package contains the C<deep_tie> function, used to deeply tie
#pod references. It also contains several other packages used to tie
#pod deeply.
#pod
#pod =cut

use v5.18.0;
use strict;
use warnings;
use feature 'lexical_subs';
no warnings 'experimental::lexical_subs';
use namespace::autoclean;
use Carp;
use Scalar::Util qw(blessed);
# For _check_ref_type() and _tied_types().
use parent 'Type::Tie::Aggregate';

our @CARP_NOT = qw(Type::Tie::Aggregate::Base);

sub reftype ($) {
    my $type = Scalar::Util::reftype $_[0];
    return 'SCALAR' if defined $type && $type eq 'REF';
    return $type;
}

my %get_children = (
    SCALAR	=> sub { $$_ },
    ARRAY	=> sub { @$_ },
    HASH	=> sub { values %$_ },
);

# TODO: Handle circular references correctly.
my sub children {
    map {
	my $type = reftype $_;
	my $get = $get_children{$type}
	    or confess "Invalid reference type: $type";
	$get->($_)
    } @_;
}

my $package_name = sub {
    my ($class, $type, $tied) = @_;
    $class .= '::Tied' if $tied;
    $class .= '::' . ucfirst lc $type;
    return $class;
};

my sub tie_deeply;
sub tie_deeply {
    my $obj = shift;
    # Don't tie blessed refs, because we want to preserve
    # encapsulation.
    my @refs = grep { ref ne '' && ! defined blessed $_ } @_;

    foreach my $ref (@refs) {
	my $type = __PACKAGE__->_check_ref_type($ref) or next;
	my $tied = &CORE::tied($ref);
	my $tied_type = blessed $tied if $tied;

	my $pkg = __PACKAGE__;

	# Don't tie deeply if it's already tied deeply.
	if (defined $tied_type && $tied_type =~ /^\Q$pkg\E::/) {
	    if ($tied->object != $obj) {
		my ($old, $new) =
		    map $_->_type, $tied->object, $obj;
		croak "Cannot tie $ref to $new; already tied to $old";
	    }
	}
	else {
	    $pkg = __PACKAGE__->$package_name($type, $tied);

	    my @args = (
		$type eq 'SCALAR'	? $$ref :
		$type eq 'ARRAY'	? @$ref :
		$type eq 'HASH'		? %$ref :
		die "Invalid type: $type",
	    );

	    my %params = (object => $obj);
	    $params{ref} = $tied if $tied;
	    &CORE::tie($ref, $pkg, \%params, @args);
	}

	tie_deeply $obj, children $ref;
    }
}

#pod =func deep_tie
#pod
#pod     deep_tie $obj, $ref;
#pod
#pod Tie C<$ref> to C<$obj> deeply, so that whenever C<$ref> changes,
#pod C<< $obj->_check >> will be called. If C<$ref> is not defined, it
#pod defaults to C<< $obj->_ref >>.
#pod
#pod Currently this does not handle circular references correctly. See
#pod L<Type::Tie::Aggregate/CAVEATS>.
#pod
#pod =cut

sub deep_tie {
    my ($obj, $ref) = @_;
    $ref //= $obj->_ref;
    tie_deeply $obj, children $ref;
}

# How to initialize objects which tie various types.
my %tie_initializers = (
    SCALAR	=> sub { $_[0]->STORE($_[1]) },
    ARRAY	=> sub { my $s = shift; $s->CLEAR; $s->PUSH(@_) },
    HASH	=> sub {
	my $self = shift;
	carp 'Odd number of elements in hash initialization'
	    if @_ % 2;
	$self->CLEAR;
	while (my ($key, $value) = splice @_, 0, 2) {
	    $self->STORE($key => $value);
	}
    }
);

# Initialize the packages.
foreach my $type (__PACKAGE__->_tied_types) {
    my @parents = (Type::Tie::Aggregate->$package_name($type));
    require s|::|/|gr . '.pm' foreach @parents;

    foreach my $tied (0, 1) {
	my $class = __PACKAGE__->$package_name($type, $tied);

	my %pkg_globs = (
	    VERSION	=> our $VERSION,
	    ISA		=> [
		__PACKAGE__->$package_name('Base', $tied), @parents,
	    ],
	);

	if ($tied) {
	    # Make the constructor initialize elements on the
	    # underlying tied object.
	    my $initialize = $tie_initializers{$type}
		or die "Invalid type: $type";
	    $pkg_globs{_initialize} = sub {
		my $self = shift;
		$self->_ref->$initialize(@_);
	    };
	}

	while (my ($name, $value) = each %pkg_globs) {
	    $name = "$class\::$name";
	    no strict 'refs';
	    (ref $value eq '' ? $$name : *$name) = $value;
	}
    }
}

package Type::Tie::Aggregate::Deep::Base {
$Type::Tie::Aggregate::Deep::Base::VERSION = '0.001';
use parent 'Type::Tie::Aggregate::Base';

    sub _new {
	my $class = shift;
	my %params = %{+shift};
	my $self = bless \%params, $class;
	$self->_initialize(@_);
	return $self;
    }

    # The user should never see this class anyway, so no need to name
    # the accessor _object().
    sub object {
	my $self = shift;
	return $self->{object} unless @_;
	($self->{object}) = @_;
    }

    sub _check_and_retie {
	my $self = shift;
	$self->object->_check_and_retie(@_);
    }
}

package Type::Tie::Aggregate::Deep::Tied::Base {
$Type::Tie::Aggregate::Deep::Tied::Base::VERSION = '0.001';
use parent -norequire => 'Type::Tie::Aggregate::Deep::Base';

    # This class provides methods which fall back to the tied object
    # in $ref.

    # Methods to install.
    my @install_methods = (
	[
	    { mutates => 1 }, qw(
		STORESIZE STORE DELETE CLEAR POP PUSH SHIFT UNSHIFT
	    ),
	],
	[
	    { mutates => 0 }, qw(
		FETCHSIZE FETCH FIRSTKEY NEXTKEY EXISTS SCALAR
	    ),
	],
    );

    foreach my $methods (@install_methods) {
	my ($params, @methods) = @$methods;
	@$methods = (
	    $params, map { $_ => "\$ref->$_(\@_)" } @methods,
	);
    }

    __PACKAGE__->_install_methods(@$_) foreach @install_methods;
}

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

Type::Tie::Aggregate::Deep - used to deeply tie variables

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This package contains the C<deep_tie> function, used to deeply tie
references. It also contains several other packages used to tie
deeply.

=head1 FUNCTIONS

=head2 deep_tie

    deep_tie $obj, $ref;

Tie C<$ref> to C<$obj> deeply, so that whenever C<$ref> changes,
C<< $obj->_check >> will be called. If C<$ref> is not defined, it
defaults to C<< $obj->_ref >>.

Currently this does not handle circular references correctly. See
L<Type::Tie::Aggregate/CAVEATS>.

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

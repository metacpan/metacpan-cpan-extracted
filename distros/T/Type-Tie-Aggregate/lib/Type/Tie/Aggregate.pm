# ABSTRACT: like Type::Tie, but slower and more flexible

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

package Type::Tie::Aggregate;
$Type::Tie::Aggregate::VERSION = '0.001';
#pod =head1 SYNOPSIS
#pod
#pod     use Type::Tie::Aggregate;
#pod     use Types::Standard qw(Dict Optional Num Str);
#pod
#pod     ttie my %hash, Dict[name => Str, age => Optional[Num]], (
#pod         name	=> 'John Doe',
#pod 	age	=> 42,
#pod     );
#pod
#pod     $hash{name} = 'Jane Doe';	# ok
#pod     $hash{age}++;		# ok
#pod     $hash{age} = 'forty-two;	# dies
#pod     delete $hash{name};		# dies ('name' is mandatory)
#pod
#pod     # Unfortunately this does not work, because the hash is
#pod     # momentarily cleared and will no longer pass the type constraint
#pod     # (which requires a 'name' key).
#pod     %hash = (name => 'J. Random Hacker');
#pod
#pod     # Use this instead (also more efficient).
#pod     (tied %hash)->initialize(name => 'J. Random Hacker');
#pod
#pod =head1 DESCRIPTION
#pod
#pod Like L<Type::Tie|Type::Tie>, this module exports a single function:
#pod C<ttie>. Also like L<Type::Tie|Type::Tie>, C<ttie> ties a variable to
#pod a type constraint (coercions will be honored).
#pod
#pod However, unlike L<Type::Tie|Type::Tie>, when an assignment happens on
#pod a variable tied with C<ttie>, the I<entire> variable will be
#pod re-checked, not just the value that was added. This is much more
#pod expensive, of course, but can be very useful for structured types such
#pod as C<Dict> from L<Types::Standard|Types::Standard> as show in the
#pod L</SYNOPSIS>.
#pod
#pod Any type constraints supporting the L<Type::API|Type::API> interface
#pod should work, not just L<Type::Tiny|Type::Tiny> types. However, in the
#pod examples that follow, all type constraints are from
#pod L<Types::Standard|Types::Standard> unless specified otherwise.
#pod
#pod =head2 Initialization and Re-initialization
#pod
#pod Since some types don't allow empty values (see the L</SYNOPSIS>),
#pod values may need to be given when initializing the type. For example,
#pod this is invalid:
#pod
#pod     ttie my %hash, Dict[name => Str]; # dies
#pod
#pod No values were given to initialize C<%hash>, so C<%hash> failed the
#pod type constraint C<Dict[name => Str]> (which requires a C<name>
#pod key). Instead, this should be done:
#pod
#pod     ttie my %hash, Dict[name => Str], (name => 'My Name');
#pod
#pod This initializes C<%hash> with the value C<< (name => 'My Name') >>
#pod before any type checking is performed, so, at the end of the day,
#pod C<%hash> passes the type constraint.
#pod
#pod Another important thing to note is that when a variable is
#pod re-initialized, it is temporarily emptied. So the following is
#pod invalid:
#pod
#pod     ttie my %hash, Dict[name => Str], (name => 'My Name');
#pod     %hash = (name => 'Other Name'); # dies
#pod
#pod Instead, the C<initialize> method should be used on the tied object,
#pod like so:
#pod
#pod     ttie my %hash, Dict[name => Str], (name => 'My Name');
#pod     (tied %hash)->initialize(name => 'Other Name'); # ok
#pod
#pod This is also more efficient than the previous method.
#pod
#pod =head2 Deep Tying
#pod
#pod C<ttie> ties variables deeply, meaning that if any references
#pod contained within the variable are changed, the entire variable is
#pod rechecked against the type constraint. Blessed objects are not deeply
#pod tied, but tied references are and the functionality of these tied
#pod references is preserved.
#pod
#pod For example, the following Does The Right Thing(TM):
#pod
#pod     ttie my %hash, HashRef[ArrayRef[Int]];
#pod     $hash{foo} = [1, 2, 3];	# ok
#pod     $hash{foo}[0] = 'one';	# dies
#pod     $hash{bar} = [3, 2, 1];	# ok
#pod     push @{$hash{bar}}, 'zero';	# dies
#pod
#pod This also works:
#pod
#pod     use List::Util qw(all);
#pod     use Tie::RefHash;
#pod
#pod     ttie my @array, ArrayRef[HashRef[Int]];
#pod
#pod     my $scalar_key = 'scalar';
#pod     my @array_key = (1, 2, 3);
#pod     tie my %refhash, 'Tie::RefHash', (
#pod         \$scalar_key    => 1,
#pod         \@array_key     => 2,
#pod     );
#pod
#pod     push @array, \%refhash;
#pod
#pod     $array[0]{\$scalar_key} = 'foo';	# dies
#pod     $array[0]{\@array_key} = 42;	# ok
#pod     all { ref ne '' } keys %{$array[0]}; # true
#pod
#pod Currently, circular references are not handled correctly (see
#pod L</Circular References>).
#pod
#pod =head1 CAVEATS
#pod
#pod =head2 Re-initialization
#pod
#pod Re-initialization of tied variables using C<@array = @init> or
#pod C<%hash = %init> does not always work. Use
#pod C<< (tied @array)->initialize(@init) >> and
#pod C<< (tied %hash)->initialize(%init) >> instead. See
#pod L</Initialization and Re-initialization> for more information.
#pod
#pod =head2 Retying References
#pod
#pod If a variable tied to a type contains a reference, then that reference
#pod cannot be contained by any other variable tied to a type. For example,
#pod the following will die:
#pod
#pod     my $arrayref = [42];
#pod     ttie my @num_array, ArrayRef[ArrayRef[Num]], ($arrayref);
#pod     ttie my @str_array, ArrayRef[ArrayRef[Str]], ($arrayref);
#pod
#pod If this were allowed, it would not be clear whether
#pod C<push @$arrayref, 'foo'> should die or not. This behavior may be
#pod changed in a later release, but you probably should not be doing this
#pod regardless.
#pod
#pod =head2 Circular References
#pod
#pod Circular references are not handled correctly. Hopefully this will be
#pod fixed in a future release.
#pod
#pod =cut

use v5.13.2;
use strict;
use warnings;
use namespace::autoclean;
use Carp;
use Scalar::Util qw(reftype);
use parent 'Exporter';

our @EXPORT = qw(ttie);

# Used by Type::Tie::Aggregate::Deep;
sub _tied_types { qw(SCALAR ARRAY HASH) }

{
    my %tied_types = map { $_ => 1 } _tied_types;

    # Used also by Type::Tie::Aggregate::Deep. Returns the type of the
    # reference.
    sub _check_ref_type {
	my ($class, $ref) = @_;
	my $type = reftype $ref // croak 'Not a reference';
	$type = 'SCALAR' if $type eq 'REF';
	return unless $tied_types{$type};
	return $type;
    }
}

#pod =func ttie
#pod
#pod     ttie my $scalar, TYPE, $init_val;
#pod     ttie my @array, TYPE, @init_val;
#pod     ttie my %hash, TYPE, %init_val;
#pod
#pod Tie C<$scalar>, C<@array>, or C<%hash> to C<TYPE> and initialize with
#pod C<$init_val>, C<@init_val>, or C<%init_val>.
#pod
#pod =cut

sub ttie (\[$@%]@) {
    my ($ref, $type, @args) = @_;

    my $ref_type;
    $ref_type = __PACKAGE__->_check_ref_type($ref) //
	croak "Cannot tie variable of type $ref_type";

    my $pkg = __PACKAGE__ . '::' . ucfirst lc $ref_type;
    require $pkg =~ s|::|/|gr . '.pm';

    &CORE::tie($ref, $pkg, $type, @args);
    return $ref;
}

#pod =method initialize
#pod
#pod     (tied $scalar)->initialize($init_val);
#pod     (tied @array)->initialize(@init_val);
#pod     (tied %hash)->initialize(%init_val);
#pod
#pod Re-initialize C<$scalar>, C<@array>, or C<%hash>. This is necessary
#pod because some types don't allow an empty value, and the variable will
#pod temporarily be emptied (except for scalars) if initialized the usual
#pod way (e.g., C<@array = qw(foo bar baz)>). This is also more efficient
#pod than conventional initialization.
#pod
#pod See L</Initialization and Re-initialization> for more info.
#pod
#pod =method type
#pod
#pod     my $type = (tied VAR)->type;
#pod
#pod Return the type constraint for C<VAR>. Note that the type cannot
#pod currently be set, only read.
#pod
#pod =cut

#pod =head1 SEE ALSO
#pod
#pod =for :list
#pod * L<Type::Tie>
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Type::Tie::Aggregate - like Type::Tie, but slower and more flexible

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use Type::Tie::Aggregate;
    use Types::Standard qw(Dict Optional Num Str);

    ttie my %hash, Dict[name => Str, age => Optional[Num]], (
        name	=> 'John Doe',
	age	=> 42,
    );

    $hash{name} = 'Jane Doe';	# ok
    $hash{age}++;		# ok
    $hash{age} = 'forty-two;	# dies
    delete $hash{name};		# dies ('name' is mandatory)

    # Unfortunately this does not work, because the hash is
    # momentarily cleared and will no longer pass the type constraint
    # (which requires a 'name' key).
    %hash = (name => 'J. Random Hacker');

    # Use this instead (also more efficient).
    (tied %hash)->initialize(name => 'J. Random Hacker');

=head1 DESCRIPTION

Like L<Type::Tie|Type::Tie>, this module exports a single function:
C<ttie>. Also like L<Type::Tie|Type::Tie>, C<ttie> ties a variable to
a type constraint (coercions will be honored).

However, unlike L<Type::Tie|Type::Tie>, when an assignment happens on
a variable tied with C<ttie>, the I<entire> variable will be
re-checked, not just the value that was added. This is much more
expensive, of course, but can be very useful for structured types such
as C<Dict> from L<Types::Standard|Types::Standard> as show in the
L</SYNOPSIS>.

Any type constraints supporting the L<Type::API|Type::API> interface
should work, not just L<Type::Tiny|Type::Tiny> types. However, in the
examples that follow, all type constraints are from
L<Types::Standard|Types::Standard> unless specified otherwise.

=head2 Initialization and Re-initialization

Since some types don't allow empty values (see the L</SYNOPSIS>),
values may need to be given when initializing the type. For example,
this is invalid:

    ttie my %hash, Dict[name => Str]; # dies

No values were given to initialize C<%hash>, so C<%hash> failed the
type constraint C<Dict[name => Str]> (which requires a C<name>
key). Instead, this should be done:

    ttie my %hash, Dict[name => Str], (name => 'My Name');

This initializes C<%hash> with the value C<< (name => 'My Name') >>
before any type checking is performed, so, at the end of the day,
C<%hash> passes the type constraint.

Another important thing to note is that when a variable is
re-initialized, it is temporarily emptied. So the following is
invalid:

    ttie my %hash, Dict[name => Str], (name => 'My Name');
    %hash = (name => 'Other Name'); # dies

Instead, the C<initialize> method should be used on the tied object,
like so:

    ttie my %hash, Dict[name => Str], (name => 'My Name');
    (tied %hash)->initialize(name => 'Other Name'); # ok

This is also more efficient than the previous method.

=head2 Deep Tying

C<ttie> ties variables deeply, meaning that if any references
contained within the variable are changed, the entire variable is
rechecked against the type constraint. Blessed objects are not deeply
tied, but tied references are and the functionality of these tied
references is preserved.

For example, the following Does The Right Thing(TM):

    ttie my %hash, HashRef[ArrayRef[Int]];
    $hash{foo} = [1, 2, 3];	# ok
    $hash{foo}[0] = 'one';	# dies
    $hash{bar} = [3, 2, 1];	# ok
    push @{$hash{bar}}, 'zero';	# dies

This also works:

    use List::Util qw(all);
    use Tie::RefHash;

    ttie my @array, ArrayRef[HashRef[Int]];

    my $scalar_key = 'scalar';
    my @array_key = (1, 2, 3);
    tie my %refhash, 'Tie::RefHash', (
        \$scalar_key    => 1,
        \@array_key     => 2,
    );

    push @array, \%refhash;

    $array[0]{\$scalar_key} = 'foo';	# dies
    $array[0]{\@array_key} = 42;	# ok
    all { ref ne '' } keys %{$array[0]}; # true

Currently, circular references are not handled correctly (see
L</Circular References>).

=head1 FUNCTIONS

=head2 ttie

    ttie my $scalar, TYPE, $init_val;
    ttie my @array, TYPE, @init_val;
    ttie my %hash, TYPE, %init_val;

Tie C<$scalar>, C<@array>, or C<%hash> to C<TYPE> and initialize with
C<$init_val>, C<@init_val>, or C<%init_val>.

=head1 METHODS

=head2 initialize

    (tied $scalar)->initialize($init_val);
    (tied @array)->initialize(@init_val);
    (tied %hash)->initialize(%init_val);

Re-initialize C<$scalar>, C<@array>, or C<%hash>. This is necessary
because some types don't allow an empty value, and the variable will
temporarily be emptied (except for scalars) if initialized the usual
way (e.g., C<@array = qw(foo bar baz)>). This is also more efficient
than conventional initialization.

See L</Initialization and Re-initialization> for more info.

=head2 type

    my $type = (tied VAR)->type;

Return the type constraint for C<VAR>. Note that the type cannot
currently be set, only read.

=head1 CAVEATS

=head2 Re-initialization

Re-initialization of tied variables using C<@array = @init> or
C<%hash = %init> does not always work. Use
C<< (tied @array)->initialize(@init) >> and
C<< (tied %hash)->initialize(%init) >> instead. See
L</Initialization and Re-initialization> for more information.

=head2 Retying References

If a variable tied to a type contains a reference, then that reference
cannot be contained by any other variable tied to a type. For example,
the following will die:

    my $arrayref = [42];
    ttie my @num_array, ArrayRef[ArrayRef[Num]], ($arrayref);
    ttie my @str_array, ArrayRef[ArrayRef[Str]], ($arrayref);

If this were allowed, it would not be clear whether
C<push @$arrayref, 'foo'> should die or not. This behavior may be
changed in a later release, but you probably should not be doing this
regardless.

=head2 Circular References

Circular references are not handled correctly. Hopefully this will be
fixed in a future release.

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

L<Type::Tie>

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

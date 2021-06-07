# ABSTRACT: base class for tying variables

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

package Type::Tie::Aggregate::Base;
$Type::Tie::Aggregate::Base::VERSION = '0.001';
#pod =head1 DESCRIPTION
#pod
#pod This class is inherited by the classes used to tie variables to
#pod types. This class is internal to
#pod L<Type::Tie::Aggregate|Type::Tie::Aggregate>.
#pod
#pod The methods below are described in more detail in
#pod L<Type::Tie::Aggregate>.
#pod
#pod =cut

use v5.10.0;
use strict;
use warnings;
use namespace::autoclean;
use Carp;

require Type::Tie::Aggregate::Deep;
*_deep_tie = \&Type::Tie::Aggregate::Deep::deep_tie;

our @CARP_NOT = qw(Type::Tie::Aggregate);

sub _new {
    my ($class, $type, @init) = @_;
    my $self = bless {}, $class;

    $self->_type($type);

    my $check;
    if ($type->can('compiled_check')) {
	$check = $type->compiled_check;
	ref $check eq 'CODE' or croak 'Compiled check for ' .
	    "$type is not a CODE ref: $check";
    }
    elsif (my $check_method = $type->can('check')) {
	$check = sub { $type->$check_method(@_) };
    }
    else {
	croak "Type $type is not a valid type constraint";
    }
    $self->_compiled_check($check);

    # If there's no has_coercion() method, assume that it does have aq
    # coercion.
    my $has_coercion = $type->can('has_coercion');
    my $coercion;
    if (! $has_coercion || $type->$has_coercion) {
	if ($type->can('coercion')) {
	    my $coercion_obj = $type->coercion;
	    if ($coercion_obj->can('compiled_coercion')) {
		$coercion = $coercion_obj->compiled_coercion;
		ref $coercion eq 'CODE'
		    or croak "Compiled coercion for $coercion_obj " .
		    "(type: $type) is not a CODE ref: $coercion";
	    }
	    elsif (my $coerce_method = $coercion_obj->can('coerce')) {
		$coercion = sub { $coercion_obj->$coerce_method(@_) };
	    }
	    else {
		carp "Type $type provides a coercion object " .
		    "$coercion_obj, but it cannot coerce";
	    }
	}
	unless (defined $coercion) {
	    if (my $coerce_method = $type->can('coerce')) {
		$coercion = sub { $type->$coerce_method(@_) };
	    }
	    elsif ($has_coercion) {
		carp "Type $type falsely reports that it can coerce";
	    }
	}
    }
    $self->_compiled_coercion($coercion);

    my $get_message;
    if ($type->can('message') &&
	ref (my $message = $type->message) eq 'CODE') {
	$get_message = $message;
    }
    elsif (my $get_message_method = $type->can('get_message')) {
	$get_message = sub { $type->$get_message_method(@_) };
    }
    else {
	my $type_name = "$type";
	$get_message = sub {
	    my ($value) = @_;
	    "$value did not pass type constraint $type";
	};
    }
    $self->_message($get_message);

    $self->initialize(@init);
    return $self;
}

#pod =method initialize
#pod
#pod     $obj->initialize(@init);
#pod
#pod Initialize C<$obj> from C<@init>.
#pod
#pod =cut

sub initialize {
    my $self = shift;
    $self->_initialize(@_);
    $self->_check_and_retie;
    return $self;
}

sub _initialize {
    # It is important that we use a copy for @init (rather than
    # shifting and using @_), because we don't want to modify the
    # original value(s) passed to _initialize().
    my ($self, @init) = @_;
    $self->_ref($self->_create_ref(@init));
}

#pod =method type
#pod
#pod     my $type = $obj->type;
#pod
#pod Return the type constraint associated with C<$obj>.
#pod
#pod =cut

sub type {
    my $self = shift;
    croak 'The type constraint can only be read, not set' if @_;
    $self->_type;
}

# Install accessors for the following attributes, prefixed with an
# underscore. The '_value' accessor, which defaults to the same as
# '_ref', is overridden by Type::Tie::Aggregate::Scalar.
foreach (qw(type compiled_check compiled_coercion message),
	 [ref => 'value']) {
    my ($key, @aliases) = ref eq 'ARRAY' ? @$_ : $_;
    my $code = sub {
	my $self = shift;
	return $self->{$key} unless @_;
	($self->{$key}) = @_;
    };
    foreach ($key, @aliases) {
	no strict 'refs';
	*{"_$_"} = $code;
    }
}

# This is used to check values after coercion. It doesn't do any
# checking by default, but can be overridden by subclasses. It should
# return an error string on error, or undef on success.
sub _check_value { }

# Perform a type check on the type, croaking on error.
sub _check_and_retie {
    my ($self) = @_;
    my ($value, $check, $coerce) = map $self->$_, qw(
	_value _compiled_check _compiled_coercion
    );

    if (defined $coerce) {
	$value = $coerce->($value);
	my $err = $self->_check_value($value);
	croak "Coerced to invalid value: $err" if defined $err;
	$self->_value($value);
    }

    $check->($value) or croak $self->_message->($value);

    $self->_deep_tie;

    return $value;
}

# Install methods, and also make the methods retie and recheck the
# object if $opts->{mutates}.
sub _install_methods {
    my ($class, $opts, @methods) = @_;

    my $mutates = $opts->{mutates};
    require Type::Tie::Aggregate::Deep if $mutates;

    while (my ($method, $code) = splice @methods, 0, 2) {
	my $callback;
	my $statement; # $code in a single statement
	if (ref $code eq 'CODE') {
	    $callback = $code;
	    $statement = $code = '$self->$callback(@_)';
	}
	else {
	    $statement = "do { $code }";
	}

	if ($callback && ! $mutates) {
	    # Optimize this case.
	    $code = $callback;
	}
	else {
	    $code = q{
		my $self = shift;
	    } . (
		! $callback || $mutates ? q{
		    my $ref = $self->_ref;
		} : '',
	    ) . (
		$mutates ? qq{
		    wantarray ? my \@ret = $statement :
			defined wantarray ? my \$ret = $statement :
			$statement;
		} . q{
		    $self->_check_and_retie;
		    return wantarray ? @ret : $ret;
		} : $code,
	    );

	    $code = eval "sub { $code }" or die;
	}

	no strict 'refs';
	*{"$class\::$method"} = $code;
    }
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

Type::Tie::Aggregate::Base - base class for tying variables

=head1 VERSION

version 0.001

=head1 DESCRIPTION

This class is inherited by the classes used to tie variables to
types. This class is internal to
L<Type::Tie::Aggregate|Type::Tie::Aggregate>.

The methods below are described in more detail in
L<Type::Tie::Aggregate>.

=head1 METHODS

=head2 initialize

    $obj->initialize(@init);

Initialize C<$obj> from C<@init>.

=head2 type

    my $type = $obj->type;

Return the type constraint associated with C<$obj>.

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

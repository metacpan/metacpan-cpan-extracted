package Mojo::Util::Collection::Comparator;
use Mojo::Base -base;

our $VERSION = '0.0.13';

use List::Util qw(all any none);

has 'specials' => sub {{
    '=='            => 'eq',
    '>'         => 'gt',
    '>='        => 'ge',
    '<'         => 'lt',
    '<='        => 'le',
    '!='        => 'ne',
    'not_like'  => 'notLike',
    'not_match' => 'notMatch'
}};

=head2 between

Check if search between given values

Returns:
C<Int> 1/0

=cut

sub between {
    my ($self, $search, $values) = @_;

    if (scalar(@$values) != 2) {
        warn "between requires 2 values";

        return 0;
    }

    my ($min, $max) = @$values;

    return $self->gt($search, $min) && $self->lt($search, $max) ? 1 : 0;
}

=head2 eq

Check if a is equal to b

Returns:
C<Int> 1/0

=cut

sub eq {
    my ($self, $a, $b) = @_;

    return 0 if ($self->__both_undefined($a, $b));

    return ($a == $b) ? 1 : 0;
}

=head2 gt

Check if a is greater than b

Returns:
C<Int> 1/0

=cut

sub gt {
    my ($self, $a, $b) = @_;

    return 0 if ($self->__both_undefined($a, $b));

    return ($a > $b) ? 1 : 0;
}

=head2 ge

Check if a is greater than or equal to b

Returns:
C<Int> 1/0

=cut

sub ge {
    my ($self, $a, $b) = @_;

    return 0 if ($self->__both_undefined($a, $b));

    return ($a >= $b) ? 1 : 0;
}

=head2 in

Check if search is in array

Returns:
C<Int> 1/0

=cut

sub in {
    my ($self, $search, $array) = @_;

    return any { $search eq $_ } @$array;
}

=head2 like

Alias for match

Returns:
C<Int> 1/0

=cut

sub like {
    return shift->match(@_);
}

=head2 lt

Check if a is less than b

Returns:
C<Int> 1/0

=cut

sub lt {
    my ($self, $a, $b) = @_;

    return 0 if ($self->__both_undefined($a, $b));

    return ($a < $b) ? 1 : 0;
}

=head2 le

Check if a is less than or equal to b

Returns:
C<Int> 1/0

=cut

sub le {
    my ($self, $a, $b) = @_;

    return 0 if ($self->__both_undefined($a, $b));

    return ($a <= $b) ? 1 : 0;
}

=head2 match

Check if search match pattern

Returns:
C<Int> 1/0

=cut

sub match {
    my ($self, $search, $pattern) = @_;

    return $search =~ m/$pattern/ ? 1 : 0;
}

=head2 ne

Check if a is not equal to b

Returns:
C<Int> 1/0

=cut

sub ne {
    my ($self, $a, $b) = @_;

    return 0 if ($self->__both_undefined($a, $b));

    return ($a != $b) ? 1 : 0;
}

=head2 notLike

Alias for notMatch

Returns:
C<Int> 1/0

=cut

sub notLike {
    return shift->notMatch(@_);
}

=head2 notMatch

Check if search does not match pattern

Returns:
C<Int> 1/0

=cut

sub notMatch {
    my ($self, $search, $pattern) = @_;

    return $search !~ m/$pattern/ ? 1 : 0;
}

=head2 verify

Check if a matches the conditions from b

Returns:
C<Int> 1/0

=cut

sub verify {
    my ($self, $a, $b) = @_;

    return 0 if ($self->__both_undefined($a, $b));
    
    # Special method comparison
    if (ref($b) eq 'HASH') {
        my @keys = keys(%$b);

        if (scalar(@keys) > 1) {
            return all { $self->verify($a, { $_ => $b->{ $_ } }) } @keys;
        }

        my $method = $keys[0];
        my $comparator = $method;

        if (! $self->can($method) && $self->specials->{$method}) {
            $comparator = $self->specials->{$method};
        }

        if (! $self->can($comparator)) {
            warn "$method is not defined";

            return 0;
        }

        return $self->$comparator($a, $b->{ $method });
    }

    if (ref($b) eq 'ARRAY') {
        return $self->in($a, $b);
    }

    # String comparison
    return (($a || '') eq ($b || '')) ? 1 : 0;
}

=head2 __both_undefined

Check if both values are undefined

Returns:
C<Int> 1/0

=cut

sub __both_undefined {
    my ($self, $a, $b) = @_;

    return (!defined($a) && !defined($b)) ? 1 : 0;
}

1;

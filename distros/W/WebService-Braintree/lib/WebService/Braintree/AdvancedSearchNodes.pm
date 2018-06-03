# vim: sw=4 ts=4 ft=perl

{
    package WebService::Braintree::AdvancedSearchNodes;
$WebService::Braintree::AdvancedSearchNodes::VERSION = '1.4';
use 5.010_001;
    use strictures 1;

    use Moose;
}

{
    package WebService::Braintree::SearchNode;
$WebService::Braintree::SearchNode::VERSION = '1.4';
use 5.010_001;
    use strictures 1;

    use Moose;

    has searcher => (is => 'ro');
    has name => (is => 'ro');

    has criteria => (is => 'rw', default => sub {shift->default_criteria()});

    sub default_criteria {
        return {};
    }

    sub active {
        my $self = shift;
        return %{$self->criteria};
    }

    sub add_node {
        my ($self, $operator, $operand) = @_;
        $self->criteria->{$operator} = $operand;
        return $self->searcher;
    }

    __PACKAGE__->meta->make_immutable;
}

{
    package WebService::Braintree::IsNode;
$WebService::Braintree::IsNode::VERSION = '1.4';
use 5.010_001;
    use strictures 1;

    use Moose;
    extends 'WebService::Braintree::SearchNode';

    sub is {
        my ($self, $operand) = @_;
        return $self->add_node(is => $operand);
    }

    __PACKAGE__->meta->make_immutable;
}

{
    package WebService::Braintree::EqualityNode;
$WebService::Braintree::EqualityNode::VERSION = '1.4';
use 5.010_001;
    use strictures 1;

    use Moose;
    extends 'WebService::Braintree::IsNode';

    sub is_not {
        my ($self, $operand) = @_;
        return $self->add_node(is_not => $operand);
    }

    __PACKAGE__->meta->make_immutable;
}

{
    package WebService::Braintree::KeyValueNode;
$WebService::Braintree::KeyValueNode::VERSION = '1.4';
use 5.010_001;
    use strictures 1;

    use Moose;
    extends 'WebService::Braintree::SearchNode';

    sub default_criteria {
        return '';
    }

    sub active {
        my $self = shift;
        return $self->criteria;
    }

    sub is {
        my ($self, $operand) = @_;
        $self->criteria($operand);
        return $self->searcher;
    }

    __PACKAGE__->meta->make_immutable;
}

{
    package WebService::Braintree::PartialMatchNode;
$WebService::Braintree::PartialMatchNode::VERSION = '1.4';
use 5.010_001;
    use strictures 1;

    use Moose;
    extends 'WebService::Braintree::EqualityNode';

    sub starts_with {
        my ($self, $operand) = @_;
        return $self->add_node(starts_with => $operand);
    }

    sub ends_with {
        my ($self, $operand) = @_;
        return $self->add_node(ends_with => $operand);
    }

    __PACKAGE__->meta->make_immutable;
}

{
    package WebService::Braintree::TextNode;
$WebService::Braintree::TextNode::VERSION = '1.4';
use 5.010_001;
    use strictures 1;

    use Moose;
    extends 'WebService::Braintree::PartialMatchNode';

    sub contains {
        my ($self, $operand) = @_;
        return $self->add_node(contains => $operand);
    }

    __PACKAGE__->meta->make_immutable;
}

{
    package WebService::Braintree::RangeNode;
$WebService::Braintree::RangeNode::VERSION = '1.4';
use 5.010_001;
    use strictures 1;

    use Moose;
    extends 'WebService::Braintree::EqualityNode';

    use overload ( '>=' => 'min', '<=' => 'max');

    sub min {
        my ($self, $operand) = @_;
        return $self->add_node(min => $operand);
    }

    sub max {
        my ($self, $operand) = @_;
        return $self->add_node(max => $operand);
    }

    sub between {
        my ($self, $min, $max) = @_;
        $self->min($min);
        $self->max($max);
    }

    __PACKAGE__->meta->make_immutable;
}

{
    package WebService::Braintree::MultipleValuesNode;
$WebService::Braintree::MultipleValuesNode::VERSION = '1.4';
use 5.010_001;
    use strictures 1;

    use Carp;
    use Moose;
    use WebService::Braintree::Util qw(is_arrayref);
    extends 'WebService::Braintree::SearchNode';

    has allowed_values => (is => 'ro');

    sub difference_arrays {
        my ($array1, $array2) = @_;
        my @diff;
        foreach my $element (@$array1) {
            push(@diff, $element) unless grep { $element eq $_ } @$array2;
        }
        return \@diff;
    }

    sub default_criteria {
        return [];
    }

    sub active {
        my $self = shift;
        return @{$self->criteria};
    }

    sub is {
        shift->in(@_);
    }

    sub _args_to_array {
        my $self = shift;
        my @args;
        if (is_arrayref($_[0])) {
            @args = @{$_[0]};
        } else {
            @args = @_;
        }
        return @args;
    }

    sub in {
        my $self = shift;
        my @values = $self->_args_to_array(@_);

        my $bad_values = difference_arrays(\@values, $self->allowed_values);

        if (@$bad_values && $self->allowed_values) {
            croak 'Invalid Argument(s) for ' . $self->name . ': ' . join(', ', @$bad_values);
        }

        @{$self->criteria} = @values;
        return $self->searcher;
    }

    __PACKAGE__->meta->make_immutable;
}

1;
__END__

=head1 NAME

WebService::Braintree::AdvancedSearchNodes

=head1 PURPOSE

This class represents the various field types a search can have.

=head1 FIELDS

=head2 Text Field

Text fields support the following operators:

=over 4

=item is(scalar)

=item is_not(scalar)

=item starts_with(scalar)

=item ends_with(scalar)

=item contains(scalar)

=back

=head2 Multiple Value Field

Multiple Value fields support the following operators:

=over 4

=item is(scalar)

=item in(list)

=back

=head2 Range Field

Range fields support the following operators:

=over 4

=item is(scalar)

=item min(scalar)

=item max(scalar)

=item between(scalar1, scalar2)

This is a shortcut for C<< min(scalar1); max(scalar2) >>.

=back

=head2 Equality Field

Equality fields support the following operators:

=over 4

=item is(scalar)

=item is_not(scalar)

=back

=head2 Partial Match Field

Partial Match fields support the following operators:

=over 4

=item is(scalar)

=item is_not(scalar)

=item starts_with(scalar)

=item ends_with(scalar)

=back

=head2 Is Field

Is fields support the following operators:

=over 4

=item is(scalar)

=back

=cut

=head2 Key Value Field

Key Value fields support the following operators:

=over 4

=item is(scalar)

=back

Key value fields are different from Is fields and Equality fields in that they
do not allow for multiple criteria.

=cut

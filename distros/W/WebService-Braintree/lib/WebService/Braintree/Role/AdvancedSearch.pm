# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::Role::AdvancedSearch;

use 5.010_001;
use strictures 1;

use Moose::Role;

use WebService::Braintree::AdvancedSearchNodes;
use WebService::Braintree::Util qw(is_arrayref);

sub field {
    my $class = shift;
    my ($proto, $name) = @_;

    push @{$class->FIELDS}, $name;

    my $default;
    if (ref $proto) {
        $default = $proto
    }
    else {
        my $node_class = "WebService::Braintree::${proto}";
        $default = sub {
            return $node_class->new(
                searcher => shift,
                name => $name,
            );
        };
    }

    $class->can('has')->($name => (
        is => 'rw',
        default => $default,
    ));

    return;
}

sub equality_field { shift->field(EqualityNode => @_) }
sub is_field { shift->field(IsNode => @_) }
sub key_value_field { shift->field(KeyValueNode => @_) }
sub partial_match_field { shift->field(PartialMatchNode => @_) }
sub range_field { shift->field(RangeNode => @_) }
sub text_field { shift->field(TextNode => @_) }

sub multiple_values_field {
    my ($class, $name, @allowed_values) = @_;
    @allowed_values = map {
        is_arrayref($_) ? @$_ : $_
    } @allowed_values;

    my $node = sub {
        return WebService::Braintree::MultipleValuesNode->new(
            searcher => shift,
            name => $name,
            allowed_values => @allowed_values ? [@allowed_values] : undef,
        );
    };
    $class->field($node => $name);
}

sub to_hash {
    my ($self) = @_;
    my $class = ref($self);

    my %hash = map {
        $_ => $self->$_->criteria
    } grep {
        $self->$_->active
    } @{$class->FIELDS};

    return \%hash;
}

1;
__END__

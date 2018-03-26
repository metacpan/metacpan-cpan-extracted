# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::AdvancedSearch;

use 5.010_001;
use strictures 1;

use Moose;

sub to_hash {
    my ($self) = @_;

    my $hash = {};
    for my $attribute ($self->meta()->get_all_attributes) {
        my $field = $attribute->name;
        if ($self->$field->active()) {
            $hash->{$field} = $self->$field->criteria;
        }
    }

    return $hash;
}

__PACKAGE__->meta->make_immutable;

1;
__END__

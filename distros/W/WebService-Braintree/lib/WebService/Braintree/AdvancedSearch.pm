package WebService::Braintree::AdvancedSearch;
$WebService::Braintree::AdvancedSearch::VERSION = '1.1';
use 5.010_001;
use strictures 1;

sub search_to_hash {
    my ($self, $search) = @_;

    my $hash = {};
    for my $attribute ($search->meta()->get_all_attributes) {
        my $field = $attribute->name;
        if ($search->$field->active()) {
            $hash->{$field} = $search->$field->criteria;
        }
    }

    return $hash;
}

1;
__END__

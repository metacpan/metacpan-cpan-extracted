package WebService::Braintree::GenericSearch;
$WebService::Braintree::GenericSearch::VERSION = '1.0';
use 5.010_001;
use strictures 1;

use Moose;
use WebService::Braintree::AdvancedSearch;

my $field = WebService::Braintree::AdvancedSearchFields->new(metaclass => __PACKAGE__->meta);

$field->text("id");
$field->multiple_values("ids");

sub to_hash {
    WebService::Braintree::AdvancedSearch->search_to_hash(shift);
}

__PACKAGE__->meta->make_immutable;

1;
__END__

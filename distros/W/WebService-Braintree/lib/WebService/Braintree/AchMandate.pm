package WebService::Braintree::AchMandate;
$WebService::Braintree::AchMandate::VERSION = '1.1';
use 5.010_001;
use strictures 1;

use Moose;
extends 'WebService::Braintree::ResultObject';

use Scalar::Util qw(blessed);
use DateTime;

sub BUILD {
    my ($self, $attributes) = @_;
    $self->set_attributes_from_hash($self, $attributes);

    # Need to take braintree::util::datetime_parse->parse_datetime() from
    # the Python SDK and bring it into here.
    #$self->{accepted_at} = DateTime->parse($self->{accepted_at})
    #    unless (blessed($self->{accepted_at}) // '') eq 'DateTime';
}

__PACKAGE__->meta->make_immutable;

1;
__END__

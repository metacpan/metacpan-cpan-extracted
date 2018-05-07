# vim: sw=4 ts=4 ft=perl

package # hide from pause
    WebService::Braintree::MerchantAccountGateway;

use 5.010_001;
use strictures 1;

use Moose;
with 'WebService::Braintree::Role::MakeRequest';
with 'WebService::Braintree::Role::CollectionBuilder';

use Carp qw(confess);

use WebService::Braintree::Util qw(validate_id is_hashref);
use WebService::Braintree::Validations qw(verify_params);

use WebService::Braintree::_::MerchantAccount;

sub create {
    my ($self, $params) = @_;
    confess "ArgumentError" unless verify_params($params, _detect_signature($params));
    $self->_make_request("/merchant_accounts/create_via_api", "post", {merchant_account => $params});
}

sub update {
    my ($self, $merchant_account_id, $params) = @_;
    confess "NotFoundError" unless validate_id($merchant_account_id);
    confess "ArgumentError" unless verify_params($params, _update_signature());
    $self->_make_request("/merchant_accounts/${merchant_account_id}/update_via_api", "put", {merchant_account => $params});
}

sub find {
    my ($self, $id) = @_;
    confess "NotFoundError" unless validate_id($id);
    my $result = $self->_make_request("/merchant_accounts/$id", "get", undef)->merchant_account;
}

sub all {
    my $self = shift;

    return $self->paginated_collection({
        url => "/merchant_accounts",
        inflate => [qw/merchant_accounts merchant_account _::MerchantAccount/],
    });
}

sub _detect_signature {
    my ($params) = @_;
    if (is_hashref($params->{applicant_details})) {
        warnings::warnif("deprecated", "[DEPRECATED] Passing applicant_details to create is deprecated. Please use individual, business, and funding.");
        return _deprecated_create_signature();
    } else {
        return _create_signature();
    }
}

sub _deprecated_create_signature{
    return {
        applicant_details => {
            company_name => ".",
            first_name => ".",
            last_name => ".",
            email => ".",
            phone => ".",
            date_of_birth => ".",
            ssn => ".",
            tax_id => ".",
            routing_number => ".",
            account_number => ".",
            address => {
                street_address => ".",
                postal_code => ".",
                locality => ".",
                region => ".",
            }
        },
        tos_accepted => ".",
        master_merchant_account_id => ".",
        id => "."
    };
}

sub _create_signature{
    return {
        individual => {
            first_name => ".",
            last_name => ".",
            email => ".",
            phone => ".",
            date_of_birth => ".",
            ssn => ".",
            address => {
                street_address => ".",
                postal_code => ".",
                locality => ".",
                region => ".",
            }
        },
        business => {
            legal_name => ".",
            dba_name => ".",
            tax_id => ".",
            address => {
                street_address => ".",
                postal_code => ".",
                locality => ".",
                region => ".",
            }
        },
        funding => {
            destination => ".",
            email => ".",
            mobile_phone => ".",
            routing_number => ".",
            account_number => ".",
            descriptor => ".",
        },
        tos_accepted => ".",
        master_merchant_account_id => ".",
        id => "."
    };
}

sub _update_signature{
    return {
        individual => {
            first_name => ".",
            last_name => ".",
            email => ".",
            phone => ".",
            date_of_birth => ".",
            ssn => ".",
            address => {
                street_address => ".",
                postal_code => ".",
                locality => ".",
                region => ".",
            }
        },
        business => {
            legal_name => ".",
            dba_name => ".",
            tax_id => ".",
            address => {
                street_address => ".",
                postal_code => ".",
                locality => ".",
                region => ".",
            }
        },
        funding => {
            destination => ".",
            email => ".",
            mobile_phone => ".",
            routing_number => ".",
            account_number => ".",
            descriptor => ".",
        },
        master_merchant_account_id => ".",
        id => "."
    };
}

__PACKAGE__->meta->make_immutable;

1;
__END__

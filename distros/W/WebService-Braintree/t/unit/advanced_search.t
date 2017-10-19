# vim: sw=4 ts=4 ft=perl

use 5.010_001;
use strictures 1;

use Test::More;

use lib qw(lib t/lib);

use WebService::Braintree::TestHelper;

{
    package WebService::Braintree::AdvancedSearchTest;
    use Moose;
    use WebService::Braintree::AdvancedSearch;

    my $field = WebService::Braintree::AdvancedSearchFields->new(metaclass => __PACKAGE__->meta);
    $field->text("billing_company");
    $field->equality("credit_card_expiration_date");
    $field->range("amount");
    $field->text("order_id");
    $field->multiple_values("created_using", "full_information", "token");
    $field->multiple_values("ids");
    $field->key_value("refund");

    __PACKAGE__->meta->make_immutable;;
    1;
}

subtest "search_to_hash" => sub {
    subtest "empty if search is empty" => sub {
        my $search = WebService::Braintree::AdvancedSearchTest->new;
        is_deeply(WebService::Braintree::AdvancedSearch->search_to_hash($search), {});
    };

    subtest "is method" => sub {
        my $search = WebService::Braintree::AdvancedSearchTest->new;
        $search->credit_card_expiration_date->is("foo");
        is_deeply(WebService::Braintree::AdvancedSearch->search_to_hash($search), {credit_card_expiration_date => {is => "foo"}});
    };
};

subtest "Equality Nodes" => sub {
    {
        my $search = WebService::Braintree::AdvancedSearchTest->new;
        $search->order_id->is("2132");
        my $result_hash = WebService::Braintree::AdvancedSearch->search_to_hash($search);
        is $result_hash->{'order_id'}->{'is'}, "2132";
    }

    {
        my $search = WebService::Braintree::AdvancedSearchTest->new;
        $search->credit_card_expiration_date->is_not("12/11");
        my $result_hash = WebService::Braintree::AdvancedSearch->search_to_hash($search);
        is $result_hash->{'credit_card_expiration_date'}->{'is_not'}, "12/11";
    }

    {
        my $search = WebService::Braintree::AdvancedSearchTest->new;
        should_throw("Can't locate object method \"starts_with\"", sub {
            $search->credit_card_expiration_date->starts_with("12");
        });
    }

    subtest "Overrides is with new value" => sub {
        my $search = WebService::Braintree::AdvancedSearchTest->new;
        $search->order_id->is("2132");
        $search->order_id->is("4376");
        my $result_hash = WebService::Braintree::AdvancedSearch->search_to_hash($search);
        is $result_hash->{'order_id'}->{'is'}, "4376";
    };
};

subtest "Partial Matches" => sub {
    my $search = WebService::Braintree::AdvancedSearchTest->new;
    $search->billing_company->starts_with("Brain");
    my $result_hash = WebService::Braintree::AdvancedSearch->search_to_hash($search);
    is $result_hash->{'billing_company'}->{'starts_with'}, "Brain";
};

subtest "Text" => sub {
    my $search = WebService::Braintree::AdvancedSearchTest->new;
    $search->billing_company->contains("12345");
    my $result_hash = WebService::Braintree::AdvancedSearch->search_to_hash($search);
    is $result_hash->{'billing_company'}->{'contains'}, "12345";
};

subtest "Range Nodes" => sub {
    {
        my $search = WebService::Braintree::AdvancedSearchTest->new;
        $search->amount->min("10.01");
        my $result_hash = WebService::Braintree::AdvancedSearch->search_to_hash($search);
        is $result_hash->{'amount'}->{'min'}, "10.01", "Minimum"
    }

    {
        my $search = WebService::Braintree::AdvancedSearchTest->new;
        $search->amount->max("10.01");
        my $result_hash = WebService::Braintree::AdvancedSearch->search_to_hash($search);
        is $result_hash->{'amount'}->{'max'}, "10.01", "Maximum";
    }

    {
        my $search = WebService::Braintree::AdvancedSearchTest->new;
        $search->amount->between("10.00", "10.02");
        my $result_hash = WebService::Braintree::AdvancedSearch->search_to_hash($search);
        is $result_hash->{'amount'}->{'min'}, "10.00", "Between Min";
        is $result_hash->{'amount'}->{'max'}, "10.02", "Between Max";
    }
};

subtest "Key Value Nodes" => sub {
    my $search = WebService::Braintree::AdvancedSearchTest->new;
    $search->refund->is("10.00");;
    my $result_hash = WebService::Braintree::AdvancedSearch->search_to_hash($search);
    is $result_hash->{'refund'}, "10.00";
};

subtest "Multiple Values Nodes" => sub {
    {
        my $search = WebService::Braintree::AdvancedSearchTest->new;
        $search->created_using->is("token");
        my $result_hash = WebService::Braintree::AdvancedSearch->search_to_hash($search);
        is_deeply $result_hash->{'created_using'}, ["token"];
    }

    {
        my $ids = [1, 2, 3];
        my $search = WebService::Braintree::AdvancedSearchTest->new;
        $search->ids->in($ids);
        my $result_hash = WebService::Braintree::AdvancedSearch->search_to_hash($search);
        is_deeply $result_hash->{'ids'}, [1, 2, 3];
    }

    {
        my $search = WebService::Braintree::AdvancedSearchTest->new;
        $search->created_using->in("token", "full_information");
        my $result_hash = WebService::Braintree::AdvancedSearch->search_to_hash($search);
        is_deeply $result_hash->{'created_using'}, ["token", "full_information"];
    }

    {
        my $search = WebService::Braintree::AdvancedSearchTest->new;
        should_throw "Invalid Argument\\(s\\) for created_using: invalid value", sub {
            $search->created_using->in("token", "invalid value");
        };
    }

    {
        my $search = WebService::Braintree::AdvancedSearchTest->new;
        should_throw "Invalid Argument\\(s\\) for created_using: invalid value, foobar", sub {
            $search->created_using->is("invalid value", "foobar");
        };
    }
};

done_testing();

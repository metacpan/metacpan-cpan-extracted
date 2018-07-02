package WWW::YNAB::MockUA;
use Moose;

extends 'HTTP::Tiny';

our $VERSION = 1;

our %responses = (
    'https://api.youneedabudget.com/v1/budgets' => <<'EOF',
{
  "data": {
    "budgets": [
      {
        "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
        "name": "My Budget",
        "last_modified_on": "2018-06-23T17:04:12+00:00",
        "date_format": {
          "format": "YYYY-MM-DD"
        },
        "currency_format": {
          "iso_code": "USD",
          "example_format": "123,456.78",
          "decimal_digits": 2,
          "decimal_separator": ".",
          "symbol_first": true,
          "group_separator": ",",
          "currency_symbol": "$",
          "display_symbol": true
        },
        "first_month": "2016-06-01",
        "last_month": "2018-07-01"
      }
    ]
  }
}
EOF
    'https://api.youneedabudget.com/v1/user' => <<'EOF',
{
  "data": {
    "user": {
      "id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
    }
  }
}
EOF
    'https://api.youneedabudget.com/v1/budgets/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa' => <<'EOF',
{
  "data": {
    "budget": {
      "id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
      "name": "My Budget",
      "last_modified_on": "2018-06-23T17:04:12+00:00",
      "date_format": {
        "format": "YYYY-MM-DD"
      },
      "currency_format": {
        "iso_code": "USD",
        "example_format": "123,456.78",
        "decimal_digits": 2,
        "decimal_separator": ".",
        "symbol_first": true,
        "group_separator": ",",
        "currency_symbol": "$",
        "display_symbol": true
      },
      "first_month": "2018-06-01",
      "last_month": "2018-07-01",
      "accounts": [
        {
          "id": "00000000-0000-0000-0000-000000000000",
          "name": "Savings Account",
          "type": "savings",
          "on_budget": true,
          "closed": false,
          "note": null,
          "balance": 12345670,
          "cleared_balance": 12345670,
          "uncleared_balance": 0,
          "deleted": false
        },
        {
          "id": "00000000-0000-0000-0000-111111111111",
          "name": "Checking Account",
          "type": "checking",
          "on_budget": true,
          "closed": false,
          "note": null,
          "balance": 2345670,
          "cleared_balance": 2345670,
          "uncleared_balance": 0,
          "deleted": false
        },
        {
          "id": "00000000-0000-0000-0000-222222222222",
          "name": "Credit Card",
          "type": "creditCard",
          "on_budget": true,
          "closed": false,
          "note": null,
          "balance": -6543210,
          "cleared_balance": -5432100,
          "uncleared_balance": -1111110,
          "deleted": false
        }
      ],
      "payees": [
        {
          "id": "11111111-1111-1111-1111-111111111111",
          "name": "a restaurant",
          "transfer_account_id": null,
          "deleted": false
        },
        {
          "id": "11111111-1111-1111-1111-222222222222",
          "name": "the power company",
          "transfer_account_id": null,
          "deleted": false
        },
        {
          "id": "11111111-1111-1111-1111-333333333333",
          "name": "candy shop",
          "transfer_account_id": null,
          "deleted": false
        }
      ],
      "payee_locations": [],
      "category_groups": [
        {
          "id": "22222222-2222-2222-2222-222222222222",
          "name": "Home",
          "hidden": false,
          "deleted": false
        },
        {
          "id": "22222222-2222-2222-2222-333333333333",
          "name": "Food",
          "hidden": false,
          "deleted": false
        }
      ],
      "categories": [
        {
          "id": "33333333-3333-3333-3333-333333333333",
          "category_group_id": "22222222-2222-2222-2222-333333333333",
          "name": "Restaurants",
          "hidden": false,
          "note": null,
          "budgeted": 234560,
          "activity": -34560,
          "balance": 200000,
          "deleted": false
        },
        {
          "id": "33333333-3333-3333-3333-444444444444",
          "category_group_id": "22222222-2222-2222-2222-222222222222",
          "name": "Utilities",
          "hidden": false,
          "note": null,
          "budgeted": 123450,
          "activity": -123450,
          "balance": 0,
          "deleted": false
        },
        {
          "id": "33333333-3333-3333-3333-555555555555",
          "category_group_id": "22222222-2222-2222-2222-333333333333",
          "name": "Groceries",
          "hidden": false,
          "note": null,
          "budgeted": 345670,
          "activity": -123450,
          "balance": 222220,
          "deleted": false
        }
      ],
      "months": [
        {
          "month": "2018-08-01",
          "note": null,
          "to_be_budgeted": 0,
          "age_of_money": 88,
          "categories": [
            {
              "id": "33333333-3333-3333-3333-444444444444",
              "category_group_id": "22222222-2222-2222-2222-222222222222",
              "name": "Utilities",
              "hidden": false,
              "note": null,
              "budgeted": 0,
              "activity": 0,
              "balance": 123450,
              "deleted": false
            },
            {
              "id": "33333333-3333-3333-3333-555555555555",
              "category_group_id": "22222222-2222-2222-2222-333333333333",
              "name": "Groceries",
              "hidden": false,
              "note": null,
              "budgeted": 0,
              "activity": 0,
              "balance": 234560,
              "deleted": false
            },
            {
              "id": "33333333-3333-3333-3333-333333333333",
              "category_group_id": "22222222-2222-2222-2222-333333333333",
              "name": "Restaurants",
              "hidden": false,
              "note": null,
              "budgeted": 0,
              "activity": 0,
              "balance": 567890,
              "deleted": false
            }
          ]
        },
        {
          "month": "2018-07-01",
          "note": null,
          "to_be_budgeted": 0,
          "age_of_money": 88,
          "categories": [
            {
              "id": "33333333-3333-3333-3333-444444444444",
              "category_group_id": "22222222-2222-2222-2222-222222222222",
              "name": "Utilities",
              "hidden": false,
              "note": null,
              "budgeted": 132450,
              "activity": 0,
              "balance": 132450,
              "deleted": false
            },
            {
              "id": "33333333-3333-3333-3333-555555555555",
              "category_group_id": "22222222-2222-2222-2222-333333333333",
              "name": "Groceries",
              "hidden": false,
              "note": null,
              "budgeted": 212130,
              "activity": 0,
              "balance": 345210,
              "deleted": false
            },
            {
              "id": "33333333-3333-3333-3333-333333333333",
              "category_group_id": "22222222-2222-2222-2222-333333333333",
              "name": "Restaurants",
              "hidden": false,
              "note": null,
              "budgeted": 152430,
              "activity": 0,
              "balance": 215340,
              "deleted": false
            }
          ]
        },
        {
          "month": "2018-06-01",
          "note": null,
          "to_be_budgeted": 19279540,
          "age_of_money": 88,
          "categories": [
            {
              "id": "33333333-3333-3333-3333-444444444444",
              "category_group_id": "22222222-2222-2222-2222-222222222222",
              "name": "Utilities",
              "hidden": false,
              "note": null,
              "budgeted": 98760,
              "activity": -98760,
              "balance": 0,
              "deleted": false
            },
            {
              "id": "33333333-3333-3333-3333-555555555555",
              "category_group_id": "22222222-2222-2222-2222-333333333333",
              "name": "Groceries",
              "hidden": false,
              "note": null,
              "budgeted": 167890,
              "activity": -134560,
              "balance": 33330,
              "deleted": false
            },
            {
              "id": "33333333-3333-3333-3333-333333333333",
              "category_group_id": "22222222-2222-2222-2222-333333333333",
              "name": "Restaurants",
              "hidden": false,
              "note": null,
              "budgeted": 456780,
              "activity": -54320,
              "balance": 402460,
              "deleted": false
            }
          ]
        }
      ],
      "transactions": [
        {
          "id": "44444444-4444-4444-4444-444444444444",
          "date": "2018-06-18",
          "amount": -98760,
          "memo": null,
          "cleared": "cleared",
          "approved": true,
          "flag_color": null,
          "account_id": "00000000-0000-0000-0000-111111111111",
          "payee_id": "11111111-1111-1111-1111-222222222222",
          "category_id": "33333333-3333-3333-3333-444444444444",
          "transfer_account_id": null,
          "import_id": "YNAB:-98760:2018-06-18:1",
          "deleted": false
        },
        {
          "id": "44444444-4444-4444-4444-555555555555",
          "date": "2018-06-17",
          "amount": -5000,
          "memo": null,
          "cleared": "cleared",
          "approved": true,
          "flag_color": null,
          "account_id": "00000000-0000-0000-0000-222222222222",
          "payee_id": "11111111-1111-1111-1111-333333333333",
          "category_id": "33333333-3333-3333-3333-555555555555",
          "transfer_account_id": null,
          "import_id": "YNAB:-5000:2018-06-18:1",
          "deleted": false
        },
        {
          "id": "44444444-4444-4444-4444-666666666666",
          "date": "2018-06-02",
          "amount": -200000,
          "memo": null,
          "cleared": "cleared",
          "approved": true,
          "flag_color": null,
          "account_id": "00000000-0000-0000-0000-222222222222",
          "payee_id": "11111111-1111-1111-1111-111111111111",
          "category_id": "33333333-3333-3333-3333-666666666666",
          "transfer_account_id": null,
          "import_id": "YNAB:-200000:2018-05-31:1",
          "deleted": false
        }
      ],
      "subtransactions": [
        {
          "id": "55555555-5555-5555-5555-555555555555",
          "transaction_id": "44444444-4444-4444-4444-666666666666",
          "amount": -100000,
          "memo": null,
          "payee_id": null,
          "category_id": "33333333-3333-3333-3333-444444444444",
          "transfer_account_id": null,
          "deleted": false
        },
        {
          "id": "55555555-5555-5555-5555-666666666666",
          "transaction_id": "44444444-4444-4444-4444-666666666666",
          "amount": -50000,
          "memo": null,
          "payee_id": null,
          "category_id": "33333333-3333-3333-3333-555555555555",
          "transfer_account_id": null,
          "deleted": false
        },
        {
          "id": "55555555-5555-5555-5555-777777777777",
          "transaction_id": "44444444-4444-4444-4444-666666666666",
          "amount": -50000,
          "memo": null,
          "payee_id": null,
          "category_id": "33333333-3333-3333-3333-333333333333",
          "transfer_account_id": null,
          "deleted": false
        }
      ],
      "scheduled_transactions": [
        {
          "id": "66666666-6666-6666-6666-666666666666",
          "date_first": "2018-06-05",
          "date_next": "2018-07-05",
          "frequency": "monthly",
          "amount": -100000,
          "memo": "cable",
          "flag_color": "purple",
          "account_id": "00000000-0000-0000-0000-111111111111",
          "payee_id": null,
          "category_id": "33333333-3333-3333-3333-666666666666",
          "transfer_account_id": null,
          "deleted": false
        }
      ],
      "scheduled_subtransactions": [
        {
          "id": "77777777-7777-7777-7777-777777777777",
          "scheduled_transaction_id": "66666666-6666-6666-6666-666666666666",
          "amount": -50000,
          "memo": "tv",
          "payee_id": null,
          "category_id": "33333333-3333-3333-3333-444444444444",
          "transfer_account_id": null,
          "deleted": false
        },
        {
          "id": "77777777-7777-7777-7777-888888888888",
          "scheduled_transaction_id": "66666666-6666-6666-6666-666666666666",
          "amount": -50000,
          "memo": "internet",
          "payee_id": null,
          "category_id": "33333333-3333-3333-3333-444444444444",
          "transfer_account_id": null,
          "deleted": false
        }
      ]
    },
    "server_knowledge": 1
  }
}
EOF
    'https://api.youneedabudget.com/v1/budgets/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/accounts/00000000-0000-0000-0000-222222222222' => <<'EOF',
{
  "data": {
    "account": {
      "id": "00000000-0000-0000-0000-222222222222",
      "name": "Credit Card",
      "type": "creditCard",
      "on_budget": true,
      "closed": false,
      "note": null,
      "balance": -6543210,
      "cleared_balance": -5432100,
      "uncleared_balance": -1111110,
      "deleted": false
    }
  }
}
EOF
    'https://api.youneedabudget.com/v1/budgets/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/categories/33333333-3333-3333-3333-333333333333' => <<'EOF',
{
  "data": {
    "category": {
      "id": "33333333-3333-3333-3333-333333333333",
      "category_group_id": "22222222-2222-2222-2222-333333333333",
      "name": "Restaurants",
      "hidden": false,
      "note": null,
      "budgeted": 234560,
      "activity": -34560,
      "balance": 200000,
      "deleted": false
    }
  }
}
EOF
    'https://api.youneedabudget.com/v1/budgets/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/payees/11111111-1111-1111-1111-333333333333' => <<'EOF',
{
  "data": {
    "payee": {
      "id": "11111111-1111-1111-1111-333333333333",
      "name": "candy shop",
      "transfer_account_id": null,
      "deleted": false
    }
  }
}
EOF
    'https://api.youneedabudget.com/v1/budgets/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/months/2018-07-01' => <<'EOF',
{
  "data": {
    "month": {
      "month": "2018-07-01",
      "note": null,
      "to_be_budgeted": 0,
      "age_of_money": 88,
      "categories": [
        {
          "id": "33333333-3333-3333-3333-555555555555",
          "category_group_id": "22222222-2222-2222-2222-333333333333",
          "name": "Groceries",
          "hidden": false,
          "note": null,
          "budgeted": 345670,
          "activity": -123450,
          "balance": 222220,
          "deleted": false
        },
        {
          "id": "33333333-3333-3333-3333-333333333333",
          "category_group_id": "22222222-2222-2222-2222-333333333333",
          "name": "Restaurants",
          "hidden": false,
          "note": null,
          "budgeted": 234560,
          "activity": -34560,
          "balance": 200000,
          "deleted": false
        },
        {
          "id": "33333333-3333-3333-3333-444444444444",
          "category_group_id": "22222222-2222-2222-2222-222222222222",
          "name": "Utilities",
          "hidden": false,
          "note": null,
          "budgeted": 123450,
          "activity": -123450,
          "balance": 0,
          "deleted": false
        }
      ]
    }
  }
}
EOF
    'https://api.youneedabudget.com/v1/budgets/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/transactions/44444444-4444-4444-4444-666666666666' => <<'EOF',
{
  "data": {
    "transaction": {
      "id": "44444444-4444-4444-4444-666666666666",
      "date": "2018-06-02",
      "amount": -200000,
      "memo": null,
      "cleared": "cleared",
      "approved": true,
      "flag_color": null,
      "account_id": "00000000-0000-0000-0000-222222222222",
      "account_name": "Credit Card",
      "payee_id": "11111111-1111-1111-1111-111111111111",
      "payee_name": "a restaurant",
      "category_id": "33333333-3333-3333-3333-666666666666",
      "category_name": "Split (Multiple Categories)...",
      "transfer_account_id": null,
      "import_id": "YNAB:-200000:2018-05-31:1",
      "deleted": false,
      "subtransactions": [
        {
          "id": "55555555-5555-5555-5555-555555555555",
          "transaction_id": "44444444-4444-4444-4444-666666666666",
          "amount": -100000,
          "memo": null,
          "payee_id": null,
          "category_id": "33333333-3333-3333-3333-444444444444",
          "transfer_account_id": null,
          "deleted": false
        },
        {
          "id": "55555555-5555-5555-5555-666666666666",
          "transaction_id": "44444444-4444-4444-4444-666666666666",
          "amount": -50000,
          "memo": null,
          "payee_id": null,
          "category_id": "33333333-3333-3333-3333-555555555555",
          "transfer_account_id": null,
          "deleted": false
        },
        {
          "id": "55555555-5555-5555-5555-777777777777",
          "transaction_id": "44444444-4444-4444-4444-666666666666",
          "amount": -50000,
          "memo": null,
          "payee_id": null,
          "category_id": "33333333-3333-3333-3333-333333333333",
          "transfer_account_id": null,
          "deleted": false
        }
      ]
    }
  }
}
EOF
    'https://api.youneedabudget.com/v1/budgets/aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa/scheduled_transactions/66666666-6666-6666-6666-666666666666' => <<'EOF',
{
  "data": {
    "scheduled_transaction": {
      "id": "66666666-6666-6666-6666-666666666666",
      "date_first": "2018-06-05",
      "date_next": "2018-07-05",
      "frequency": "monthly",
      "amount": -100000,
      "memo": "cable",
      "flag_color": "purple",
      "account_id": "00000000-0000-0000-0000-111111111111",
      "account_name": "Checking Account",
      "payee_id": null,
      "payee_name": null,
      "category_id": "33333333-3333-3333-3333-666666666666",
      "category_name": "Split (Multiple Categories)...",
      "transfer_account_id": null,
      "deleted": false,
      "subtransactions": [
        {
          "id": "77777777-7777-7777-7777-777777777777",
          "scheduled_transaction_id": "66666666-6666-6666-6666-666666666666",
          "amount": -50000,
          "memo": "tv",
          "payee_id": null,
          "category_id": "33333333-3333-3333-3333-444444444444",
          "transfer_account_id": null,
          "deleted": false
        },
        {
          "id": "77777777-7777-7777-7777-888888888888",
          "scheduled_transaction_id": "66666666-6666-6666-6666-666666666666",
          "amount": -50000,
          "memo": "internet",
          "payee_id": null,
          "category_id": "33333333-3333-3333-3333-444444444444",
          "transfer_account_id": null,
          "deleted": false
        }
      ]
    }
  }
}
EOF
);

sub get {
    my $self = shift;
    my ($uri, $params) = @_;

    $self->{__www_ynab_test_requests} ||= [];
    push @{ $self->{__www_ynab_test_requests} }, [$uri, $params];

    my $count = @{ $self->{__www_ynab_test_requests} };

    return {
        content => "$responses{$uri}",
        headers => {
            'x-rate-limit' => "$count/200",
        },
        success => 1,
    }
}

sub test_requests {
    my $self = shift;

    @{ $self->{__www_ynab_test_requests} || [] }
}

no Moose;

1;

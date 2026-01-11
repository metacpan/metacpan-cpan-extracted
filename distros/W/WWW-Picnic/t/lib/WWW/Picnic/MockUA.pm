package WWW::Picnic::MockUA;
# Mock LWP::UserAgent for offline testing

use strict;
use warnings;
use utf8;
use HTTP::Response;
use JSON::MaybeXS;

my $json = JSON::MaybeXS->new->utf8;

sub new {
  my ($class, %args) = @_;
  return bless {
    responses => {},
    requests  => [],
    %args,
  }, $class;
}

sub agent { shift->{agent} = shift if @_; }

sub add_response {
  my ($self, $path_pattern, $response_data, %opts) = @_;
  $self->{responses}{$path_pattern} = {
    data    => $response_data,
    status  => $opts{status} // 200,
    headers => $opts{headers} // {},
  };
}

sub request {
  my ($self, $request) = @_;
  push @{$self->{requests}}, $request;

  my $uri = $request->uri->as_string;
  my $method = $request->method;

  for my $pattern (keys %{$self->{responses}}) {
    if ($uri =~ /$pattern/) {
      my $resp_config = $self->{responses}{$pattern};
      my $response = HTTP::Response->new($resp_config->{status});
      $response->content($json->encode($resp_config->{data}));
      $response->header('Content-Type' => 'application/json');
      for my $header (keys %{$resp_config->{headers}}) {
        $response->header($header => $resp_config->{headers}{$header});
      }
      return $response;
    }
  }

  # Default: 404
  my $response = HTTP::Response->new(404);
  $response->content($json->encode({ error => 'Not found', uri => $uri }));
  return $response;
}

sub last_request {
  my ($self) = @_;
  return $self->{requests}[-1];
}

sub all_requests {
  my ($self) = @_;
  return @{$self->{requests}};
}

sub clear_requests {
  my ($self) = @_;
  $self->{requests} = [];
}

# Sample response data generators
sub sample_login_response {
  return {
    user_id => 'test-user-123',
    second_factor_authentication_required => 0,
    show_second_factor_authentication_intro => 0,
  };
}

sub sample_login_2fa_response {
  return {
    user_id => 'test-user-123',
    second_factor_authentication_required => 1,
    show_second_factor_authentication_intro => 1,
  };
}

sub sample_user_response {
  return {
    user_id       => 'test-user-123',
    firstname     => 'Max',
    lastname      => 'Mustermann',
    contact_email => 'max@example.com',
    phone         => '+49123456789',
    customer_type => 'REGULAR',
    address       => {
      street           => 'Musterstraße',
      house_number     => '42',
      house_number_ext => 'a',
      postcode         => '12345',
      city             => 'Berlin',
    },
    household_details => { adults => 2, children => 1 },
    feature_toggles   => ['feature_a', 'feature_b'],
    subscriptions     => [],
  };
}

sub sample_cart_response {
  return {
    id                   => 'shopping_cart',
    type                 => 'ORDER',
    status               => 'OPEN',
    items                => [
      {
        id    => 'product-1',
        name  => 'Haribo Goldbären',
        count => 2,
        price => 129,
      },
      {
        id    => 'product-2',
        name  => 'Milch 1L',
        count => 1,
        price => 119,
      },
    ],
    total_count          => 3,
    total_price          => 377,
    checkout_total_price => 377,
    delivery_slots       => [],
    selected_slot        => undef,
    deposit_breakdown    => [],
  };
}

sub sample_delivery_slots_response {
  return {
    delivery_slots => [
      {
        slot_id              => 'slot-1',
        hub_id               => 'hub-berlin-1',
        fc_id                => 'fc-1',
        window_start         => '2025-01-15T10:00:00Z',
        window_end           => '2025-01-15T12:00:00Z',
        cut_off_time         => '2025-01-14T22:00:00Z',
        is_available         => 1,
        minimum_order_value  => 3500,
      },
      {
        slot_id              => 'slot-2',
        hub_id               => 'hub-berlin-1',
        fc_id                => 'fc-1',
        window_start         => '2025-01-15T14:00:00Z',
        window_end           => '2025-01-15T16:00:00Z',
        cut_off_time         => '2025-01-15T08:00:00Z',
        is_available         => 0,
        unavailability_reason => 'SOLD_OUT',
        minimum_order_value  => 3500,
      },
    ],
  };
}

sub sample_search_response {
  # New nested format with sellingUnit objects
  return {
    body => {
      child => {
        analytics => {
          contexts => [
            { data => { main_entity => 'haribo' } }
          ]
        },
        children => [
          {
            child => {
              children => [
                {
                  sellingUnit => {
                    id             => 'product-1',
                    name           => 'Haribo Goldbären 200g',
                    display_price  => 129,
                    image_id       => 'img-1',
                    unit_quantity  => '200g',
                    max_count      => 10,
                    decorators     => [],
                  }
                },
                {
                  sellingUnit => {
                    id             => 'product-2',
                    name           => 'Haribo Color-Rado 200g',
                    display_price  => 149,
                    image_id       => 'img-2',
                    unit_quantity  => '200g',
                    max_count      => 10,
                    decorators     => [],
                  }
                },
              ],
            },
          },
        ],
      },
    },
  };
}

sub sample_article_response {
  return {
    id                 => 'product-1',
    name               => 'Haribo Goldbären 200g',
    description        => 'Die beliebten Gummibärchen von Haribo.',
    type               => 'ARTICLE',
    images             => ['img-1-large'],
    image_ids          => ['img-1'],
    price_info         => {
      price           => 129,
      original_price  => 149,
      deposit         => 0,
      base_price_text => '0,65 € / 100g',
    },
    unit_quantity      => '200g',
    max_order_quantity => 10,
    labels             => ['vegetarian'],
    allergies          => {
      allergy_contains => ['glucose'],
      allergy_text     => 'Kann Spuren von Nüssen enthalten.',
    },
    highlights         => ['Klassiker', 'Fruchtgummi'],
    perishable         => 0,
  };
}

1;

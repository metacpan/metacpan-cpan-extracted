# WWW-Picnic

[![CPAN Version](https://img.shields.io/cpan/v/WWW-Picnic.svg)](https://metacpan.org/pod/WWW::Picnic)
[![License](https://img.shields.io/cpan/l/WWW-Picnic.svg)](https://metacpan.org/pod/WWW::Picnic)

Perl library and CLI to access the Picnic Supermarket API.

## Installation

```bash
cpanm WWW::Picnic
```

## Command Line Interface

Three CLI commands are provided:

- `picnic` - Main CLI (English default)
- `picnic-de` - German wrapper (sets PICNIC_LANG=de, PICNIC_COUNTRY=de)
- `picnic-nl` - Dutch wrapper (sets PICNIC_LANG=nl, PICNIC_COUNTRY=nl)

### Environment Variables

```bash
export PICNIC_USER='your@email.com'
export PICNIC_PASS='yourpassword'
export PICNIC_COUNTRY='de'  # de or nl
export PICNIC_LANG='en'     # en, de, or nl
```

### Commands

```bash
# Login and check authentication
picnic login

# View user profile
picnic user

# View shopping cart
picnic cart

# Clear shopping cart
picnic clear-cart

# View available delivery slots
picnic slots

# Search for products
picnic search haribo

# View product details
picnic article s1234567

# Add product to cart (by ID or name)
picnic add s1234567
picnic add s1234567 3
picnic add 'Haribo Goldbären'

# Remove product from cart
picnic remove s1234567

# Browse categories
picnic categories

# Get search suggestions
picnic suggest har
```

### Options

```bash
-u, --user      Override PICNIC_USER
-p, --pass      Override PICNIC_PASS
-c, --country   Override PICNIC_COUNTRY
-r, --raw       Output raw JSON
-h, --help      Show help
```

## Library Usage

```perl
use WWW::Picnic;

my $picnic = WWW::Picnic->new(
    user    => 'user@example.com',
    pass    => 'password',
    country => 'de',
);

# Login
my $login = $picnic->login;
if ($login->requires_2fa) {
    $picnic->generate_2fa_code;
    # User receives SMS...
    $picnic->verify_2fa_code('123456');
}

# Get user info
my $user = $picnic->get_user;
say $user->firstname, ' ', $user->lastname;
say $user->address->{street}, ' ', $user->address->{house_number};

# Search products
my $results = $picnic->search('Milch');
for my $item ($results->all_items) {
    printf "%s: %s (%.2f EUR)\n",
        $item->id, $item->name, $item->display_price / 100;
}

# Get product details
my $article = $picnic->get_article('s1234567');
say $article->name;
say $article->description;

# Shopping cart
my $cart = $picnic->get_cart;
say "Items: ", $cart->total_count;
say "Total: ", sprintf("%.2f", $cart->total_price / 100), " EUR";

$picnic->add_to_cart('s1234567', 2);
$picnic->remove_from_cart('s1234567', 1);
$picnic->clear_cart;

# Delivery slots
my $slots = $picnic->get_delivery_slots;
for my $slot ($slots->available_slots) {
    say $slot->window_start, ' - ', $slot->window_end;
}
```

## Result Classes

All API methods return typed result objects:

- `WWW::Picnic::Result::Login` - Authentication result
- `WWW::Picnic::Result::User` - User profile
- `WWW::Picnic::Result::Cart` - Shopping cart
- `WWW::Picnic::Result::DeliverySlots` - Container for delivery slots
- `WWW::Picnic::Result::DeliverySlot` - Individual slot
- `WWW::Picnic::Result::Search` - Search results
- `WWW::Picnic::Result::SearchResult` - Individual search item
- `WWW::Picnic::Result::Article` - Product details

All result objects provide a `raw` method to access the underlying API response.

## Testing

```bash
# Offline tests (using MockUA)
prove -l t/

# Live API tests (requires credentials)
TEST_WWW_PICNIC_USER='your@email.com' \
TEST_WWW_PICNIC_PASS='password' \
TEST_WWW_PICNIC_COUNTRY='de' \
prove -l t/basic.t
```

## License

This is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

## Author

Torsten Raudssus <torsten@raudssus.de> ([GETTY](https://metacpan.org/author/GETTY))

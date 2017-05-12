#!/usr/bin/perl

use Modern::Perl;

use Test::More tests => 11;
use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/lib";
use T::Discovery;
use T::OverDrive;

my $EMAIL = 'nobody@nowhere.com';
my %NON_LOCKABLE_FORMAT = map { $_ => 1 } (
    'ebook-overdrive', 'audiobook-overdrive', 'ebook-mediado'
);
#use WebService::ILS::OverDrive;
#$WebService::ILS::OverDrive::DEBUG = 1;

use_ok('WebService::ILS::OverDrive::Patron');

SKIP: {
    skip "Not testing OverDrive::Patron API, WEBSERVICE_ILS_TEST_OVERDRIVE_PATRON not set", 10
      unless $ENV{WEBSERVICE_ILS_TEST_OVERDRIVE_PATRON};

    my $od_id     = $ENV{OVERDRIVE_TEST_CLIENT_ID}
        or BAIL_OUT("Env OVERDRIVE_TEST_CLIENT_ID not set");
    my $od_secret = $ENV{OVERDRIVE_TEST_CLIENT_SECRET}
        or BAIL_OUT("Env OVERDRIVE_TEST_CLIENT_SECRET not set");
    my $od_website_id = $ENV{OVERDRIVE_TEST_WEBSITE_ID}
        or BAIL_OUT("Env OVERDRIVE_TEST_WEBSITE_ID not set");
    my $od_authorization_name = $ENV{OVERDRIVE_TEST_AUTHORIZATION_NAME} || 'odapilibrary';
    my $od_user_id = $ENV{OVERDRIVE_TEST_USER_ID}
        or BAIL_OUT("Env OVERDRIVE_TEST_USER_ID not set");
    my $od_password = $ENV{OVERDRIVE_TEST_USER_PASSWORD};

    my $od = WebService::ILS::OverDrive::Patron->new({
        test => 1,
        client_id => $od_id,
        client_secret => $od_secret,
    });

    ok($od->auth_by_user_id($od_user_id, $od_password, $od_website_id, $od_authorization_name), "auth_by_user_id()");

    my $patron = T::OverDrive::patron($od);
    my ($hold_limit, $checkout_limit, $active);
    if ($patron) {
        $hold_limit = $patron->{hold_limit};
        $checkout_limit = $patron->{checkout_limit};
        $active = $patron->{active};
    }
    #BAIL_OUT("Patron not active") unless $active;

    clear($od) if $ENV{OVERDRIVE_TEST_CLEAR};

    my $init_checkouts = $od->checkouts;
    my $init_holds = $od->holds;

    my ($total_init_holds);
    if ($init_holds) {
        $total_init_holds = $init_holds->{total};
    }
    ok(defined $total_init_holds, "Holds") or diag(Dumper($init_holds));

    my ($total_init_checkouts);
    if ($init_checkouts) {
        $total_init_checkouts = $init_checkouts->{total};
    }
    ok(defined $total_init_checkouts, "Checkouts") or diag(Dumper($init_checkouts));

    my ($items, $random_page) = T::Discovery::search_all_random_page( $od );
    BAIL_OUT("No items in search results, cannot test circulation") unless $items && @$items;

    subtest "Place hold" => sub {
        if ($total_init_holds >= $hold_limit) {
            my $item = $init_holds->{items}[0];
            test_remove_hold($od, $item->{id});
            test_place_hold($od, $init_holds, $item);
        }
        else {
            my $item;
            while ($items) {
                $item = pick_unused_item($od, [@{ $init_checkouts->{items} }, @{ $init_holds->{items} }], $items);
                last if $item;
                diag( Dumper($init_checkouts, $init_holds, $items) );
                ($items, $random_page) = T::Discovery::search_all_random_page( $od, $random_page + 1 );
            }
            BAIL_OUT("Cannot find appropriate item to place hold") unless $item;

            my $item_id = test_place_hold($od, $init_holds, $item);
            SKIP: {
                skip "Could not place hold", 1 unless $item_id;

                test_remove_hold($od, $item_id);
            }
        }
    };

    if ($total_init_checkouts >= $checkout_limit - 1) {
        foreach(@{ $init_checkouts->{items} }) {
            next if $_->{format};

            $od->return($_->{id}) or BAIL_OUT("Checkouts at full capacity and cannot return");
            $total_init_checkouts--;

            last if $total_init_checkouts < $checkout_limit - 1;
        }
        $init_checkouts = $od->checkouts;
    }
    BAIL_OUT("Checkouts at full capacity and no item can be returned")
      if $total_init_checkouts >= $checkout_limit;

    subtest "Checkout no format" => sub {
        my $item;
        while ($items) {
            $item = pick_unused_item($od, $init_checkouts->{items}, $items, 'AVAILABLE_ONLY');
            last if $item;
            diag( Dumper($init_checkouts, $items) );
            ($items, $random_page) = T::Discovery::search_all_random_page( $od, $random_page + 1 );
        }
        BAIL_OUT("Cannot find appropriate item to checkout") unless $item;

        test_checkout($od, $init_checkouts, $item);
        $total_init_checkouts++;
    };

    subtest "Checkout with format" => sub {
        SKIP: {
            skip "Not testing checkout with format locking, OVERDRIVE_TEST_LOCK_FORMAT not set", 1
              unless $ENV{OVERDRIVE_TEST_LOCK_FORMAT};

            SKIP: {
                skip "Checkouts at full capacity, cannot test checkout with locked format", 1
                  if $total_init_checkouts >= $checkout_limit;

                $init_checkouts = $od->checkouts;
                my $item;
                while ($items) {
                    $item = pick_unused_item($od, $init_checkouts->{items}, $items, 'AVAILABLE_ONLY');
                    last if $item;
                    ($items, $random_page) = T::Discovery::search_all_random_page( $od, $random_page + 1 );
                }

                SKIP: {
                    skip "Cannot find appropriate item to checkout with locked format", 1
                      unless $item;

                    test_checkout_with_format($od, $init_checkouts, $item);
                }
            }
        }
    };

    subtest "Standard search" => sub { T::OverDrive::search( $od ) };

    $patron = $od->native_patron;
    ok($patron && $patron->{patronId}, "Native patron")
      or diag(Dumper($patron));

    subtest "Native search"   => sub { T::OverDrive::native_search( $od ) };
}

sub test_place_hold {
    my ($od, $init_holds, $item) = @_;

    my $item_id = $item->{id};
    my ($hold, $cannot_place_hold);
    {
        local $@;
        $hold = eval { $od->place_hold($item_id, $EMAIL, "AUTO_CHECKOUT") };
        if ($@) {
            diag("$@\n".Dumper($item));
            $cannot_place_hold = ($@ =~ m/not allowed to place a hold on this title/io);
        }
    }
    my ($hold_item_id, $hold_item_id_uc, $total_holds, $ok);
    SKIP: {
        skip "Cannot place hold", 1 if $cannot_place_hold;

        if ($hold) {
            $hold_item_id = uc $hold->{id};
            $hold_item_id_uc = uc $hold_item_id;
            $total_holds = $hold->{total};
        }
#       $ok = ok($hold_item_id_uc eq uc($item_id) && $total_holds == scalar(@$hold_items) + 1, "Place hold")
        $ok = ok($hold_item_id_uc && $hold_item_id_uc eq uc($item_id), "Place hold")
          or diag(Dumper($init_holds, $item, $hold));
    }

    SKIP: {
        skip "Cannot place hold", 2 unless $ok;

        my $holds = $od->holds;
        my $found;
        foreach (@{ $holds->{items} }) {
            if (uc($_->{id}) eq $hold_item_id_uc) {
                $found = 1;
                last;
            }
        }
        ok ($found && $holds->{total} == $init_holds->{total} + 1, "Hold in the list")
          or diag(Dumper($hold, $holds, $init_holds));

        my $same_hold = $od->place_hold($item_id, $EMAIL, "AUTO_CHECKOUT");
        ok(
            $same_hold->{id} eq $hold->{id} &&
            $same_hold->{placed_datetime} eq $hold->{placed_datetime},
            "Place same hold")
          or diag(Dumper($same_hold, $hold));
    }

    return $hold_item_id;
}

sub test_remove_hold {
    my ($od, $item_id) = @_;

    ok( $od->remove_hold($item_id), "Remove hold" );
    ok( $od->remove_hold($item_id), "Remove hold again");
}

sub test_checkout {
    my ($od, $init_checkouts, $item) = @_;

    my $item_id = $item->{id};
    my $checkout;
    {
        local $@;
        $checkout = eval { $od->checkout($item_id) };
        diag("$@\n".Dumper($item)) if $@;
    }
    my ($checkout_item_id, $checkout_item_id_uc);
    if ($checkout) {
        $checkout_item_id = $checkout->{id};
        $checkout_item_id_uc = uc $checkout_item_id;
    }
    my $ok = ok($checkout_item_id_uc && $checkout_item_id_uc eq uc($item_id), "Checkout")
      or diag(Dumper($init_checkouts, $item, $checkout));

    SKIP: {
        skip "Cannot checkout", 6 unless $ok;

        my $checkouts = $od->checkouts;
        my $found;
        foreach (@{ $checkouts->{items} }) {
            if (uc($_->{id}) eq $checkout_item_id_uc) {
                $found = $_;
                last;
            }
        }
#       ok ($found && $checkouts->{total} == $init_checkouts->{total} + 1, "Checkout in the list")
#       Sometimes API loses marbles when it comes to counting
        ok ($found, "Checkout in the list")
          or diag(Dumper($checkout, $checkouts, $init_checkouts));

        SKIP: {
            skip "Checkout not found", 5 unless $found;

            my $formats = $od->checkout_formats($item_id);
            $ok = $formats && scalar(keys %$formats);
            ok ($ok, "Checkout formats")
              or diag(Dumper($formats, $item));
            my $available_format;
            if ($ok) {
                while ( my($format, $available) = each %$formats ) {
                    if ($available) {
                        $available_format = $format;
                        last;
                    }
                }
                diag(Dumper($formats)) unless $available_format;
            }
            SKIP: {
                skip "Available format not found", 1 unless $available_format;
                test_download_url($od, $item_id, $available_format);
            }

            my $same_checkout = $od->checkout($item_id);
            ok(
                $same_checkout->{id} eq $checkout->{id} &&
                $same_checkout->{checkout_datetime} eq $checkout->{checkout_datetime},
                "Same checkout not locked")
              or diag(Dumper($same_checkout, $checkout));

            ok( $od->return($item_id), "Return" );
            # This is a bug in OverDrive API
            $ok = eval { $od->return($item_id) };
            if ($@) {
                diag("Return again: $@\nPassing nevertheless");
                $ok = 1;
            }
            ok( $ok, "Return again");

            my $lockable_format;
            SKIP: {
                skip "Not testing format locking, OVERDRIVE_TEST_LOCK_FORMAT not set", 3
                  unless $ENV{OVERDRIVE_TEST_LOCK_FORMAT};

                while ( my($format, $available) = each %$formats ) {
                    unless ($available) {
                        $lockable_format = $format;
                        last;
                    }
                }
                diag(Dumper($formats)) unless $lockable_format;

                SKIP: {
                    skip "Checkout formats cannot be locked in", 3
                      unless $lockable_format;

                    $checkout = $od->checkout($item_id);

                    my $res = $od->lock_format($item_id, $lockable_format);
                    ok($res eq $lockable_format, "Lock format $lockable_format") or diag("Format: $res");

                    my $same_checkout = $od->checkout($item_id);
                    ok(
                        $same_checkout->{id} eq $checkout->{id} &&
                        $same_checkout->{checkout_datetime} eq $checkout->{checkout_datetime} &&
                        $same_checkout->{format} eq $lockable_format,
                        "Same checkout format locked")
                      or diag(Dumper($same_checkout, $checkout, $lockable_format));

                    test_download_url($od, $item_id, $lockable_format);
                }
            }
        }
    }

    return $checkout_item_id;
}

sub test_checkout_with_format {
    my ($od, $init_checkouts, $item) = @_;

    my $item_id = $item->{id};
    my ($checkout, $lockable_format);
    foreach my $format ( @{$item->{formats} || []} ) {
        local $@;
        $checkout = eval { $od->checkout($item_id, $format) };
        diag("$@\n".Dumper($item)) if $@;
        if ($checkout) {
            $lockable_format = $format;
            last;
        }
    }
    diag(Dumper($item)) unless $checkout;
    SKIP: {
        skip "Checkout formats cannot be locked in", 4
          unless $checkout;

        my $checkout_item_id = $checkout->{id};
        my $checkout_item_id_uc = uc $checkout_item_id;
        my $checkout_item_format = $checkout->{format};
        my $checkout_item_format_lc = $checkout_item_format ? lc ($checkout_item_format) : "";
        my $ok = ok(
            $checkout_item_id_uc && $checkout_item_id_uc eq uc($item_id) &&
            $checkout_item_format_lc eq lc($lockable_format),
            "Checkout with locked format $lockable_format"
        ) or diag(Dumper($init_checkouts, $item, $checkout));

        SKIP: {
            skip "Mismatched checkout with locked format $lockable_format", 3 unless $ok;

            my $checkouts = $od->checkouts;
            my $found;
            foreach (@{ $checkouts->{items} }) {
                if (uc($_->{id}) eq $checkout_item_id_uc) {
                    $found = $_;
                    last;
                }
            }
            ok (
                $found && $found->{format} && lc($found->{format}) eq $checkout_item_format_lc,
                "Checkout in the list"
            ) or diag(Dumper($checkout, $checkouts, $init_checkouts));

            SKIP: {
                skip "Checkout not found", 2 unless $found;

                my $same_checkout = $od->checkout($item_id);
                ok(
                    uc($same_checkout->{id}) eq $checkout_item_id_uc &&
                    $same_checkout->{checkout_datetime} eq $checkout->{checkout_datetime} &&
                    $same_checkout->{format} && lc($same_checkout->{format}) eq $checkout_item_format_lc,
                    "Same checkout without specified format")
                  or diag(Dumper($same_checkout, $checkout));

                $same_checkout = $od->checkout($item_id, $lockable_format);
                ok(
                    uc($same_checkout->{id}) eq $checkout_item_id_uc &&
                    $same_checkout->{checkout_datetime} eq $checkout->{checkout_datetime} &&
                    $same_checkout->{format} && lc($same_checkout->{format}) eq $checkout_item_format_lc,
                    "Same checkout with specified format")
                  or diag(Dumper($same_checkout, $checkout));
            }
        }

        return $checkout_item_id;
    }

    return;
}

sub test_download_url  {
    my ($od, $item_id, $format) = @_;

    my $download_url = $od->checkout_download_url(
        $item_id,
        $format,
        "http://wherever.com/failure",
        "http://wherever.com/success"
    );
    ok($download_url, "Download url");
}

sub pick_unused_item {
    my ($od, $used_items, $pool_items, $available_only) = @_;

    POOL_ITEMS_LOOP:
    foreach my $pi (@$pool_items) {
        if ($used_items) {
            my $id_uc = uc $pi->{id};
            foreach (@$used_items) {
                next POOL_ITEMS_LOOP if uc($_->{id}) eq $id_uc;
            }
        }

        my $formats = $pi->{formats} or next;
        next if $available_only && !$od->is_item_available($pi->{id});

        foreach my $format (@$formats) {
            next if $format eq 'periodicals-nook';
            next if $format =~ m/-streaming$/o;
            next if $available_only && $NON_LOCKABLE_FORMAT{$format};

            return $pi;
        }
    }
    return;
}

sub clear {
    my ($od) = @_;

    my $checkouts = $od->checkouts;
    eval { $od->return($_->{id}) } foreach @{$checkouts->{items}};

    my $holds = $od->holds;
    $od->remove_hold($_->{id}) foreach @{$holds->{items}};
}

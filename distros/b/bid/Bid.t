#!/usr/bin/perl -w

#-------------------------------------------------------------------------
#
# Tests:      Auction::Bid
#
#-------------------------------------------------------------------------
#
# Modification History
#
# Auth     Date       Description
# -------  ---------  ----------------------------------------------------
# mwk      17 Oct 01  Wrote this  
#-------------------------------------------------------------------------

=head1 NAME

Auction/Bid.t - Tests Bid.pm

=head1 DESCRIPTION

Tests Auction::Bid

=head1 BUGS

None known

=head1 TODO

Nothing known

=cut

#-------------------------------------------------------------------------
# Set up our standard testing environment
#-------------------------------------------------------------------------

use strict;

# initialise the number of tests to be done
use Test::More tests => 26;

BEGIN {
  $| = 1;
  $^W = 1;
  for ( qw(Auction::Bid
           Auction::Lot
           Date::Simple
          ) ) {
    use_ok( $_ );
  }
}
if (Auction::Bid->can("make_bid")) {

  #-------------------------------------------------------------------------
  # Tests on new
  #-------------------------------------------------------------------------

  ok(! defined Auction::Bid->new, 
    "can't new with no parameters");
  ok(! defined Auction::Bid->new("deaf and taxed"),
    "can't new with rubbish");

  #-------------------------------------------------------------------------
  # Tests on for_item
  #-------------------------------------------------------------------------

  #-------------------------------------------------------------------------
  # Make a new auction item.
  #-------------------------------------------------------------------------
  my $reserve = int rand(100) + 1;
  my $then = Date::Simple->new + 10;
  my $expires = "$then 12:13:14";
  my $desc = "An interesting old pot dated $$ BC";
  my $a_item = Auction::Lot->create({ description => $desc,
                                      reserve     => $reserve,
                                      expiry_date => $expires });

  eval { Auction::Bid->for_item; 1; };
  like($@, qr/Need an/, "Can't for_item with no parameters");

  eval { Auction::Bid->for_item("deaf and taxed"); 1; };
  like($@, qr/Need an Auction /, "Can't for_item with rubbish");

  eval { Auction::Bid->for_item($then) ); 1; };
  like($@, qr/Need a/, "Can't for_item with wrong object");
  is(Auction::Bid->for_item($a_item), "", "No bid means no object");

  #-------------------------------------------------------------------------
  # Tests on make_bid
  #-------------------------------------------------------------------------
  ok(! defined Auction::Bid->make_bid,
    "can't make_bid with no parameters");
  ok(! defined Auction::Bid->make_bid("partridge amongst the pigeons"),
    "can't make_bid with rubbish");
  ok(! defined Auction::Bid->make_bid({ item => $then }),
    "can't make_bid without a proper auction_item");

  ok(! defined Auction::Bid->make_bid({ item     => $a_item, }),
    "can't make_bid without a customerid");
  my $customerid = $$;
  ok(! defined Auction::Bid->make_bid({ item     => $a_item,
                                        customer => $customerid, 
                                        bid      => "a pony"}),
    "can't make_bid with a non-numeric bid");

  ok(! defined Auction::Bid->make_bid({ item     => $a_item,
                                        customer => $customerid,
                                        bid      => 9.75}),
    "can't make_bid with a non-whole number");

  my $today = Date::Simple->new;
  my $bid = 9999;
  my $a_bid = Auction::Bid->make_bid({ item     => $a_item,
                                       customer => $customerid,
                                       bid      => $bid, });

  isa_ok($a_bid, "Auction::Bid");
  $a_bid = Auction::Bid->new($a_bid->id);
  isa_ok($a_bid, "Auction::Bid");
  isa_ok($a_bid->item, "Auction::Lot");
  is($a_bid->item->id, $a_item->id, "Same auction item");
  is($a_bid->customerid, $customerid, "Same customer");
  is($a_bid->bid, $bid, "Correct bid");
  isa_ok($a_bid->date, "Date::Simple");
  is($a_bid->date->format, "$today", "bid made on right day"); 
  like($a_bid->time, qr/^\d{2}\:\d{2}\:\d{2}/, "time alright");
}

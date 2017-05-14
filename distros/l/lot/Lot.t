#!/usr/bin/perl -w

#-------------------------------------------------------------------------
#
# Tests:      Auction::Lot
#
#-------------------------------------------------------------------------
#
# Modification History
#
# Auth     Date       Description
# -------  ---------  ----------------------------------------------------
# mwk      17 Oct 01  Created this
#-------------------------------------------------------------------------

=head1 NAME

Auction/Lot.t - Test Lot.pm

=head1 DESCRIPTION

Tests Auction::Lot

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
use Test::More tests => 15;

BEGIN {
  $| = 1;
  $^W = 1;
  for ( qw(Auction::Lot
           Date::Simple) ) {
    use_ok( $_ );
  }
}

if (Auction::Lot->can("new")) {
  #-------------------------------------------------------------------------
  # Tests on new. (Create is undocumented, and used only for testing!!)
  #-------------------------------------------------------------------------
  ok(! defined Auction::Lot->new,
    "can't new with no parameters");
  ok(! defined Auction::Lot->new("wibble"),
    "can't new with rubbish");

  my $desc = "An interesting old coin dated $$ BC";
  my $reserve = int rand(100) + 1;
  my $then = Date::Simple->new + 10;
  my $expires = "$then 12:13:14";
  my $a_item = Auction::Lot->create({ description => $desc,
                                      reserve     => $reserve,
                                      expiry_date => $expires });
  my $itemid = $a_item->id;
  isa_ok($a_item, "Auction::Lot");
  $a_item = Auction::Lot->new($itemid);
  isa_ok($a_item, "Auction::Lot");
  ok(! defined Auction::Lot->new($itemid + 100),
    "can't new with imaginary itemid");

  #-------------------------------------------------------------------------
  # Tests on description, reserve, itemid, expiry_day, expiry_time and
  # is_active
  #-------------------------------------------------------------------------

  is($a_item->itemid, $itemid, "itemid correct");
  is($a_item->reserve, $reserve, "reserve correct");
  is($a_item->description, $desc, "description correct");
  isa_ok($a_item->expiry_day, "Date::Simple");
  my $day = $a_item->expiry_day;
  is("$day", "$then", "day of expiry alright");
  is($a_item->expiry_time, "12:13:14", "expiry time alright");
  
  is($a_item->is_active, 1, "The auction has time remaining");
  $then = Date::Simple->new - 10;
  $expires = "$then 12:13:14";
  $a_item->set_expiry_date($expires);
  $a_item = Auction::Lot->new($a_item->id);
  is($a_item->is_active, 0, "The auction is closed");
}

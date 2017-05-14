package Auction::Bid;

#------------------------------------------------------------------------------
#
# Modification History
#
# Auth    Date       Description
# ------  ---------  ----------------------------------------------------------
# mwk     17 Oct 01  Wrote this.
#------------------------------------------------------------------------------


=head1 NAME

Auction::Bid - Information on an auction bid

=head1 SYNOPSIS

  my $a_bid = Auction::Bid->new($bidid);

  my $bidid = $a_bid->bid_id; 
  my $id = $a_bid->id;

  my $customerid = $a_bid->customerid;

  my $item = $a_bid->item;

  my $bid = $a_bid->bid;

  my $date = $a_bid->date;
  my $time = $a_bid->time; 

  my @bids = Auction::Bid->for_item($a_item);

  my $a_bid = Auction::Bid->make_bid({ item       => $a_item,
                                       customerid => $customerid,
                                       bid        => $bid, });

=head1 DESCRIPTION

This module provides information on an auction bid.

YOU HAVE TO GET YOURSELF A DATABASE HANDLE!! I don't know how you connect
to your database, so I leave that for an exercise for the reader.   

=cut

use strict;
use Date::Simple;
use vars qw($VERSION);
$VERSION = 1.00;     
use base ('Class::DBI');
 
__PACKAGE__->table('auction_bid');
__PACKAGE__->columns(Primary   => 'bid_id');
__PACKAGE__->columns(Essential => qw/itemid bid bid_date bid_time customerid/);
__PACKAGE__->autocommit(1);               

=head1 FACTORY METHODS

=head2 new

  my $a_bid = Auction::Bid->new($bidid);  

Make a new auction bid object.

=head2 for_item

  my @bids = Auction::Bid->for_item($a_item);

This will return a list of Bid objects for the auction item.

=cut

sub for_item {
  my $class = shift;
  my $item = shift();
  die "Need an Auction_item object" unless ($item->isa("Auction::Item");
  return $class->search("itemid", $item->itemid);
}

=head2 make_bid

  my $a_bid = Auction::Bid->make_bid({ item       => $a_item,
                                       customerid => $customerid,
                                       bid        => $bid, });

This will make a bid on the auction item.

=cut

sub make_bid {
  my $class = shift;
   my $ref = shift;
  unless ( ref $ref eq 'HASH' ) { return; }
  unless ( defined $ref->{customerid} and $ref->{customerid}=~ /^\d+$/) {
    return;
  }
  unless ( defined $ref->{item} and $ref->{item}->isa("Auction::Lot")) {
    return;
  }   
  unless (defined $ref->{bid} and $ref->{bid} =~ /^\d+$/) { return; }
  my $time = Date::Simple->new;
  my $bid = $class->SUPER::create({ itemid     => $ref->{item}->id,
                                    bid        => $ref->{bid},
                                    bid_date   => $time->format("%Y-%m-%d"),
                                    bid_time   => $time->format("%H:%M:%S"),
                                    customerid => $ref->{customerid},
                                  });
  return $bid;            
}

=head1 INSTANCE METHODS

=head2 bid_id

  my $bidid = $a_bid->bid_id;

This will return the bid id.

=head2 id

  my $id = $a_bid->id;

This is synonomous with bid_id.

=head2 customerid

  my $customer = $a_bid->customer;

This will return the customerid of who made the bid.

=head2 item

  my $item = $a_bid->item;

This will return the auction item.

=head2 bid

  my $bid = $a_bid->bid;

This will return the bid for that bid id.

=head2 date

  my $date = $a_bid->date;

This will return the Date::Simple of the bid

NOTE: This does not include the time of the bid.

=head2 time

  my $time = $a_bid->time;

This will return the time of the bid on the day it was made.

=cut

sub id { return $_[0]->bid_id }

sub item { 
  my $self = shift;
  require Auction::Lot;
  return Auction::Lot->new($self->itemid);
}

sub date {
  my $self = shift;
  my @bits = split /-/, $self->bid_date;
  return Date::Simple->new(@bits);
}

sub time { $_[0]->bid_time; }

=head1 BUGS

None known

=head1 TODO

Nothing known

=head1 COPYRIGHT

Copyright (C) 2001 mwk. All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

MWKerr, <coder@stray-toaster.co.uk>   

=cut

return qw/I asked for juice
          You bring me poison/;

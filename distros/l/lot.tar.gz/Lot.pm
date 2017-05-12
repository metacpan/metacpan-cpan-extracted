package Auction::Lot;

#------------------------------------------------------------------------------
#
# Modification History
#
# Auth    Date       Description
# ------  ---------  ----------------------------------------------------------
# mwk     17 Oct 01  Wrote this
#------------------------------------------------------------------------------


=head1 NAME

Auction::Lot - Information on an item in an auction

=head1 SYNOPSIS

  my $a_item = Auction::Lot->new($itemid);

  my $itemid      = $a_item->itemid;
  my $id          = $a_item->id;
  my $reserve     = $a_item->reserve;
  my $description = $a_item->description;
  my $expiry_day  = $a_item->expiry_day;
  my $expiry_time = $a_item->expiry_time;
  my @time_left   = $a_item->time_remaining;

=head1 DESCRIPTION

This provides information on an item in an auction

YOU HAVE TO GET YOURSELF A DATABASE HANDLE!! I don't know how you connect 
to your database, so I leave that for an exercise for the reader.

Oh, alright, here is an example...
Auction::Lot->set_db('Main', 'dbi:mysql', 'me', 'noneofyourgoddamnedbusiness',
                      {AutoCommit => 1});  
my @handles = Auction::Lot->db_handles;
my $dbh = $handles[0];

=cut

use strict;
use Date::Simple;
use vars qw($VERSION);
$VERSION = 1.00;
use base ('Class::DBI');

__PACKAGE__->table('auction_item');
__PACKAGE__->columns(Primary   => 'itemid');
__PACKAGE__->columns(Essential => qw/description reserve expiry_date/);
__PACKAGE__->autocommit(1);

my $DATABASE_HANDLE = "Get yourself a database handle";

=head1 FACTORY METHODS

=head2 new

  my $a_item = Auction::Lot->new($itemid);

Make a new auction item object

=head1 INSTANCE METHODS

=head2 itemid

  my $itemid = $a_item->itemid;

This will return the itemid

=head2 description

  my $description = $a_item->description;

This will return the item's description

=head2 reserve

  my $reserve = $a_item->reserve

This will return the item's reserve.

=head2 id

  my $id = $a_item->id;

This is synomous with itemid

=cut

sub id { return $_[0]->itemid }

=head2 expiry_day

  my $expiry_day = $a_item->expiry_day;

This will return the day of expiry as a Date::Simple;

=head2 expiry_time

  my $expiry_time = $a_item->expiry_time;

This will return the time of expiry of the auction (on the expiry_date)

=cut

sub expiry_day {
  my $self = shift;
  my @bits = split /-/, substr($self->expiry_date, 0, 10);
  return Date::Simple->new(@bits);     
}

sub expiry_time {
  my $self = shift;
  return substr($self->expiry_date, 11, 8);   
}

=head2 time_remaining

  my @time_remaining = $a_item->time_remaining.

This will return a list (days, hours, minutes, seconds) of the time remaining
until the end of the auction.

=cut

sub time_remaining {
  my $self = shift;
  my $dbh = $DATABASE_HANDLE;
  my $q_remain = qq{ # Q-Auction_Lot-001
    SELECT SEC_TO_TIME(UNIX_TIMESTAMP(?) - UNIX_TIMESTAMP(NOW()) )
  };  
  my $remaining = $dbh->selectrow_array($q_remain, undef, $self->expiry_date);
  return (0) if ($remaining =~ m/\-/);
  my @bits = split /:/, $remaining;
  my $days = int($bits[0] / 24);
  my $hours = $bits[0] % 24;
  my @dhms = ($days, $hours, $bits[1], $bits[2]);
  return @dhms;
}

=head2 is_active

  my $is_active = $a_item->is_active;

This will be true is the item is still auctionable, that is, that the expiry
date of the auction hasn't passed.

=cut

sub is_active {
  my $self = shift;
  my $dbh = $DATABASE_HANDLE;    
  my $q_remain = qq{ # Q-Auction_Lot-002
    SELECT NOW() < ?
  };
  return $dbh->selectrow_array($q_remain, undef, $self->expiry_date);
}

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

return qw/Everybody in the funhouse says they want out
          But we're taking our time, cause we're in love with time/;

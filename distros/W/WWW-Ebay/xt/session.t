
# $Id: session.t,v 1.12 2014-09-09 03:09:10 Martin Exp $

use strict;
use warnings;

use Test::More 'no_plan';

my $sPkg;

BEGIN
  {
  use ExtUtils::testlib;
  $sPkg = 'WWW::Ebay::Session';
  use_ok($sPkg);
  } # end of BEGIN block

SKIP:
  {
  # See if ebay userid is in environment variable:
  my $sUserID = $ENV{EBAY_USERID} || '';
  my $sPassword = $ENV{EBAY_PASSWORD} || '';
  if (($sUserID eq '') || ($sPassword eq ''))
    {
    diag("In order to fully test this module, set environment variables EBAY_USERID and EBAY_PASSWORD.");
    } # if
  skip "eBay userid/password not supplied", 11 if (($sUserID   eq '') ||
                                                   ($sPassword eq ''));
  my $oSession = new $sPkg($sUserID, $sPassword);
  isa_ok($oSession, $sPkg);
  diag("Trying to sign in as $sUserID, with password from env.var EBAY_PASSWORD...");
  my $s = $oSession->signin;
  if (! isnt($s, 'FAILED', 'signed-in'))
    {
    skip q{Can not sign in; no point trying any more tests}, 9;
    } # if

  diag("Fetching $sUserID\'s current auctions...");
  my @aoListings = $oSession->selling_auctions(); # 'Pages/selling.html');
  my $iAnyError = $oSession->any_error;
  diag($oSession->error) if $oSession->error;
 SKIP:
    {
    skip sprintf("because %s has no auctions on-line", $oSession->{_user}), 1 if (@aoListings == 0);
    diag($oSession->error);
    # ok(! $iAnyError);
    diag(sprintf(q{The following auctions were found on %s's ebay selling page:}, $oSession->{_user}));
 LISTING:
    foreach my $oListing (@aoListings)
      {
      # diag(sprintf("  %s: %s", $oListing->id, $oListing->status->as_text));
      diag($oListing->as_string);
      ok($oListing->status->listed);
      ok(! $oListing->status->ended);
      like($oListing->id, qr{\A\d+\Z}, 'id is an integer');
      isnt($oListing->title, '', 'title is not empty');
      like($oListing->bidcount, qr{\A\d+\Z}, 'bidcount is an integer');
      like($oListing->bidmax, qr{\A\d+\Z}, 'bidmax is an integer');
      # like($oListing->datestart, qr{\A\d+\Z}, 'datestart is an integer');
      } # foreach LISTING
    } # end of SKIP block

  diag("Fetching $sUserID\'s ended auctions, sold items...");
  @aoListings = $oSession->sold_auctions(); # 'Pages/selling.html');
  $iAnyError = $oSession->any_error;
  diag($oSession->error) if $oSession->error;
 SKIP:
    {
    skip sprintf("because %s has no sold auctions on-line", $oSession->{_user}), 1 if (@aoListings == 0);
    diag($oSession->error);
    # ok(! $iAnyError);
    diag(sprintf(q{The following ended, sold auctions were found on %s's ebay selling page:}, $oSession->{_user}));
 LISTING:
    foreach my $oListing (@aoListings)
      {
      # diag(sprintf("  %s: %s", $oListing->id, $oListing->status->as_text));
      diag($oListing->as_string);
      ok($oListing->status->ended, 'auction has ended');
      like($oListing->id, qr{\A\d+\Z}, 'id is an integer');
      isnt($oListing->title, '', 'title is not empty');
      isnt($oListing->winnerid, '', 'winnerid is not empty');
      like($oListing->bidmax, qr{\A\d+\Z}, 'bidmax is an integer');
      like($oListing->shipping, qr{\A(\d+|unknown)\Z}, 'shipping looks ok');
      } # foreach LISTING
    } # end of SKIP block

  diag("Fetching $sUserID\'s ended auctions, unsold items...");
  @aoListings = $oSession->unsold_auctions(); # 'Pages/selling.html');
  $iAnyError = $oSession->any_error;
  diag($oSession->error) if $oSession->error;
 SKIP:
    {
    skip sprintf("because %s has no unsold auctions on-line", $oSession->{_user}), 1 if (@aoListings == 0);
    diag($oSession->error);
    # ok(! $iAnyError);
    diag(sprintf(q{The following ended, unsold auctions were found on %s's ebay selling page:}, $oSession->{_user}));
 LISTING:
    foreach my $oListing (@aoListings)
      {
      # diag(sprintf("  %s: %s", $oListing->id, $oListing->status->as_text));
      diag($oListing->as_string);
      ok($oListing->status->ended, 'auction has ended');
      like($oListing->id, qr{\A\d+\Z}, 'id is an integer');
      isnt($oListing->title, '', 'title is not empty');
      is($oListing->bidcount, 0, 'bidcount is zero');
      like($oListing->bidmax, qr{\A\d+\Z}, 'bidmax is an integer');
      like($oListing->shipping, qr{\A(\d+|unknown)\Z}, 'shipping looks ok');
      like($oListing->datestart, qr{\A\d+\Z}, 'datestart is an integer');
      } # foreach LISTING
    } # end of SKIP block
  } # end of SKIP block

exit 0;

__END__


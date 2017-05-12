
use ExtUtils::testlib;

use Test::More;

my $sMod;
BEGIN {
  $sMod = 'WWW::Ebay::Session';
  } # end of BEGIN block

use strict;

use_ok($sMod);

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
  diag("Trying to sign in as $sUserID, with password from env.var EBAY_PASSWORD...");
  my $oSession = new $sMod($sUserID, $sPassword);
  isa_ok($oSession, $sMod);
  my $s = $oSession->signin;
  isnt($s, 'FAILED', 'sign-in');
  diag("Fetching $sUserID\'s watchlist...");
  my @aoListings = $oSession->watchlist_auctions('Pages/watchlist.html');
  my $iAnyError = $oSession->any_error;
  diag($oSession->error);
 SKIP:
    {
    skip sprintf("because %s has no auctions in watchlist", $oSession->{_user}), 1 if (@aoListings == 0);
    ok(! $iAnyError);
    diag(sprintf(q{The following auctions were found on %s's ebay watchlist:}, $oSession->{_user}));
 LISTING:
    foreach my $oListing (@aoListings)
      {
      diag($oListing->title);
      # like($oListing->question_count, qr{\A\d+\Z}, 'question_count is an integer');
      # like($oListing->watcher_count, qr{\A\d+\Z}, 'watcher_count is an integer');
      like($oListing->bid_count, qr{\A\d+\Z}, 'bid_count is an integer');
      isnt($oListing->end_date, '', 'end_date is not empty');
      # like($oListing->bid_amount, qr{\A\d+\Z}, 'bid_amount is an integer');
      isnt($oListing->seller, '', 'seller is not empty');
      if ($oListing->bid_count)
        {
        isnt($oListing->bidder, '', 'bidder is not empty');
        } # if
      } # foreach LISTING
    } # end of SKIP block
  } # end of SKIP block

done_testing();

exit 0;

__END__


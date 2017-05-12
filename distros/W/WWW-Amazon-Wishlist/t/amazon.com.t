
use strict;
use warnings;

my $VERSION = 2.31;

use blib;
use Data::Dumper;
use Test::More 'no_plan';

our $iDebug = 0;

BEGIN
  {
  use_ok('WWW::Amazon::Wishlist', qw(get_list COM));
  } # end of BEGIN block

use vars qw/ $sCode @arh $iCount /;

# This is an empty wishlist:
$sCode = '3MGZN132X8XV1';
@arh = get_list($sCode, COM);
$iCount = scalar(@arh);
diag(qq{$sCode\'s wishlist at .COM has $iCount items});
is($iCount, 0, 'is an empty list');

# I think this is Simon's, it has at least 18 pages!!!:
$sCode = '2EAJG83WS7YZM';
# This is Martin's, it has two pages:
$sCode = '2O4B95NPM1W3L';
# This is Richard Soderberg's which has at least 3 pages:
# $sCode = '6JX9XSIN6VL5';
# This is a small one, just 2 or 3 items:
# $sCode = q{XXP43C2PHSCK};
# ok(get_list ($sCode, COM, 1), "Got any items from .com");
@arh = get_list($sCode, COM, $iDebug);
$iCount = scalar(@arh);
diag(qq{$sCode\'s wishlist at .COM has $iCount items});
# exit 89;
ok($iCount, 'not an empty list');
cmp_ok(25, q{<}, $iCount, q{got at least 2 pages}); # }); # Emacs bug
if (0)
  {
  print STDERR Dumper(\@arh);
  } # if
# Gather up all the unique priorities we found:
my %hsi;
foreach my $rh (@arh)
  {
  $hsi{$rh->{priority}}++;
  } # foreach
foreach my $sRank (qw( highest high medium ))
  {
  # As of 2011-10 (probably much earlier), the HTML page does not show priorities.
  ok($hsi{$sRank}, qq{got at least one $sRank priority item});
  } # foreach
# Make sure all items have an ASIN:
foreach my $rh (@arh)
  {
  if ($rh->{asin} eq q{})
    {
    fail("there's an item with no ASIN");
    } # if
  } # foreach
# Make sure no items are repeated in the list:
my %hsiASIN;
foreach my $rh (@arh)
  {
  if ($hsiASIN{$rh->{asin}})
    {
    fail("item $rh->{asin} is repeated");
    last;
    } # if
  $hsiASIN{$rh->{asin}}++;
  } # foreach

pass('all done');

__END__

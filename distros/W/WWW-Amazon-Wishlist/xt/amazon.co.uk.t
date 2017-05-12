
# $Id: amazon.co.uk.t,v 1.1 2015-09-23 23:06:54 Martin Exp $

use strict;
use warnings;

use blib;
use Test::More 'no_plan';

BEGIN
  {
  use_ok('WWW::Amazon::Wishlist', qw(get_list UK));
  }

my $iDebug = 0;

my $sCode = '108ACFCI5OK8I';
$sCode = 'A1NU8UVEIOGXZ';
# ok(get_list ($sCode, UK, 1), "Got any items from .co.uk");
my @arh = get_list($sCode, UK, $iDebug);
my $iCount = scalar(@arh);
diag(qq{$sCode\'s wishlist at .UK has $iCount items});
ok($iCount, 'not an empty list');
if (0)
  {
  use Data::Dumper;
  print STDERR Dumper(\@arh);
  } # if

pass('all done');

__END__

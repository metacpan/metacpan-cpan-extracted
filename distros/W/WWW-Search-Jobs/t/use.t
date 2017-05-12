
# $Id: use.t,v 1.4 2007/06/10 00:51:44 Daddy Exp $

use strict;
use ExtUtils::testlib;
use Test::More;
use WWW::Search;

use vars qw( @as );

open MAN, "<MANIFEST" or die " --- can not open MANIFEST for read: $!";
$/ = "\n";
my @as = <MAN>;
close MAN or warn " --- can not close MANIFEST after read: $!";
# This is an OS-independent chomp:
map { tr/\r\n//d } @as;
local $" = ',';
# print STDERR " + read from MANIFEST (@as)\n";
@as = grep {/lib/} @as;
# print STDERR " + after grep (@as)\n";
my $iNum = scalar(@as);
plan tests => $iNum;

foreach my $sEngine (@as)
  {
  my $o;
  # print STDERR " +   trying engine $sEngine ";
  $sEngine =~ s!\.pm!!;
  $sEngine =~ s!lib/WWW/Search/!!;
  $sEngine =~ s!/!::!g;
  # diag "($sEngine)...";
  $o = new WWW::Search($sEngine);
  isa_ok($o, qq"WWW::Search::$sEngine");
  } # foreach

exit 0;

# Now make sure we get *some* results from *some* engine:
my $o = new WWW::Search('Monster');
$o->maximum_to_retrieve(1);
# $o->{debug} = 9;
$o->native_query('perl',
                   # {search_debug => 2, },
                );
ok(0 < scalar($o->results()));

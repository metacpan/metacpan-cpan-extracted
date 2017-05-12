# -*- perl -*-

use strict;
use Test;
use WWW::Search;

use vars qw( @as );

open MAN, "<MANIFEST" or die " --- can not open MANIFEST for read: $!";
$/ = "\n";
my @as = <MAN>;
close MAN or warn " --- can not close MANIFEST after read: $!";
chomp @as;
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
    # print STDERR "($sEngine)...\n";
    eval { $o = new WWW::Search($sEngine) };
    ok(ref($o));
  } # foreach

exit 0;

# Now make sure we get some results:
my $o = new WWW::Search('Jobserve');
$o->maximum_to_retrieve(1);
# $o->{debug} = 9;
$o->native_query('perl',
                   # {search_debug => 2, },
                );
ok(0 < scalar($o->results()));
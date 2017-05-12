use Test::More tests => 21;

BEGIN { use_ok 'Webalizer::Hist'; }

use strict;
use warnings;

## The incoming data
my @source = ( \"1 2006 978 621 142 2734 1 31 689 473
2 2006 376 276 68 554 1 5 272 162
12 2005 761 421 93 1219 8 31 587 357", 
"t/data/testfile.data"
);

## The returned hashrefs
my @months = ( [
  { 'month' => 2, 'firstday' => 1, 'totalhits' => 376, 'totalvisits' => 162,
    'totalfiles' => 276, 'avgkbytes' => '110.80', 'totalsites' => 68,
    'avghits' => '75.20', 'totalpages' => 272, 'lastday' => 5, 'avgfiles' => '55.20',
    'avgsites' => '13.60', 'totalkbytes' => 554, 'avgpages' => '54.40', 'year' => 2006,
    'avgvisits' => '32.40' },
  { 'month' => 1, 'firstday' => 1, 'totalhits' => 978,'totalvisits' => 473,
    'totalfiles' => 621, 'avgkbytes' => '88.19', 'totalsites' => 142, 'avghits' => '31.55',
    'totalpages' => 689, 'lastday' => 31, 'avgfiles' => '20.03', 'avgsites' => '4.58',
    'totalkbytes' => 2734, 'avgpages' => '22.23', 'year' => 2006, 'avgvisits' => '15.26'  },
  { 'month' => 12, 'firstday' => 8, 'totalhits' => 761,'totalvisits' => 357,
    'totalfiles' => 421, 'avgkbytes' => '50.79', 'totalsites' => 93,'avghits' => '31.71',
    'totalpages' => 587, 'lastday' => 31, 'avgfiles' => '17.54', 'avgsites' => '3.88',
    'totalkbytes' => 1219, 'avgpages' => '24.46', 'year' => 2005, 'avgvisits' => '14.88' }
], [
  { 'month' => 10, 'firstday' => 1, 'totalhits' => 4338182, 'totalvisits' => 153261, 'totalfiles' => 2834408,
    'avgkbytes' => '269351.35',  'totalsites' => 73148,  'avghits' => '139941.35', 'totalpages' => 1206931,
    'lastday' => 31, 'avgfiles' => '91432.52', 'avgsites' => '2359.61', 'totalkbytes' => 8349892,
    'avgpages' => '38933.26', 'year' => 2005, 'avgvisits' => '4943.90'  },
  { 'month' => 9, 'firstday' => 1, 'totalhits' => 3535470, 'totalvisits' => 126022, 'totalfiles' => 2264993,
    'avgkbytes' => '219543.40', 'totalsites' => 61124, 'avghits' => '117849.00', 'totalpages' => 905294,
    'lastday' => 30, 'avgfiles' => '75499.77', 'avgsites' => '2037.47', 'totalkbytes' => 6586302,
    'avgpages' => '30176.47', 'year' => 2005, 'avgvisits' => '4200.73' },
  { 'month' => 8, 'firstday' => 1,'totalhits' => 4156089, 'totalvisits' => 152399, 'totalfiles' => 2717191,
    'avgkbytes' => '245489.94', 'totalsites' => 83034, 'avghits' => '134067.39', 'totalpages' => 983036,
    'lastday' => 31, 'avgfiles' => '87651.32','avgsites' => '2678.52','totalkbytes' => 7610188,
    'avgpages' => '31710.84', 'year' => 2005, 'avgvisits' => '4916.10' },
]);
my @totals = (
 { 'visits' => 992, 'sites' => 303, 'hits' => 2115, 'kbytes' => 4507, 'files' => 1318, 'pages' => 1548 },
 { 'visits' => 431682, 'sites' => 217306, 'hits' => 12029741, 'kbytes' => 22546382, 'files' => 7816592, 'pages' => 3095261 }
);

foreach my $t (0, 1) {
  my $src = $t ? "filesource" : "refsource";
  my $dwh = Webalizer::Hist->new(source => $source[$t]);
  my $dwhd = Webalizer::Hist->new(source => $source[$t], desc => 0);
  isa_ok($dwh, 'Webalizer::Hist', "$src, obj, ascending");
  isa_ok($dwhd, 'Webalizer::Hist', "$src, obj, descending");
  my $month;
  foreach $month (@{$months[$t]}) {
    is_deeply($month, $dwh->month(), "$src, month $$month{month}, descending");
  }
  foreach $month (reverse @{$months[$t]}) {
    is_deeply($month, $dwhd->month(), "$src, month $$month{month}, ascending");
  }
  is_deeply($totals[$t], $dwh->totals(), "$src, totals, descending");
  is_deeply($totals[$t], $dwhd->totals(), "$src, totals, ascending");
}

1;

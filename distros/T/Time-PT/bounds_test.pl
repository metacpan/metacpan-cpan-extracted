#!/usr/bin/perl -w

use Time::PT;
my @ptst = ('pt', # '37M', '37N', '37O', '37P', '37Q', '37R', '37S', '37T',
            'e',  # '0'  , '012', '013', '014', '015', '016', '017', '018',
  '0', '00', '01', '0z', '0C', 
  '_', '_0', '_1', '_z', '_C', 
  '0D', '0O', 
  '_D', '_O', 
  '0P', '0a', 
  '_P', '_a', 
  '0b', '0m', 
  '_b', '_m', 
  '0n', '0y', 
  '_n', '_y', 
  '010O', '0C0O',
  '_10O', '_C0O',
  '0D0O', '0O0O',
  '_D0O', '_O0O',
  '0P0O', '0a0O',
  '_P0O', '_a0O',
  '0b0O', '0m0O',
  '_b0O', '_m0O',
  '0n0O', '0y0O',
  '_n0O', '_y0O',
  '0',   '00W', '01W', '0zW', '0CW', 
  '10W', '_0W', '_1W', '_zW', '_CW', 
  '0OW', '0DW', 
  '_OW', '_DW', 
  '0aW', '0PW', 
  '_aW', '_PW', 
  '0mW', '0bW', 
  '_mW', '_bW', 
  '0yW', '0nW', 
  '_yW', '_nW', 
  '0CWO', '01WO',
  '_CWO', '_1WO',
  '0OWO', '0DWO',
  '_OWO', '_DWO',
  '0aWO', '0PWO',
  '_aWO', '_PWO',
  '0mWO', '0bWO',
  '_mWO', '_bWO',
  '0yWO', '0nWO',
  '_yWO', '_nWO',
);
#printf("ptst:%7s -> %s\n", $_, pt($_)) foreach(@ptst);
for(my $i=0; $i<@ptst; $i+=2) {
  printf("%-7s -> %27s, %-7s -> %27s\n", $ptst[$i], pt($ptst[$i]), $ptst[$i+1], pt($ptst[$i+1]));
  my $p = Time::PT->new($ptst[$i]);
  my $q = Time::PT->new($ptst[$i+1]);
  printf("%-7s -> %27s, %-7s -> %27s\n", $ptst[$i], $p->expand(), $ptst[$i+1], $q->expand());
}

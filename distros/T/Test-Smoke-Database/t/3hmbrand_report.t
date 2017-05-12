# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 3hmbrand.t'


use Test::More;
use Test::Smoke::Database::Parsing;
use Data::Dumper;
use File::Basename qw(basename dirname);

use strict;

#chdir(dirname($0));
my ($rep,$tt);

if ($ARGV[0]) {
  foreach (glob("t/rpt/*.hm.rpt.*")) { s!^t/!!; $$rep{$_}=1; }
  $tt=1;
} else {
  # Count how many test
  my $d = "cat t/result_hm";
  $rep = eval `$d`;
  $tt = 0;
  foreach my $f (keys %$rep) {
    $tt+= $#{$$rep{$f}}+1;
  }
}

plan tests => $tt+2;

my $t = { opts => { } };

# no file return undef
ok(!Test::Smoke::Database::Parsing::parse_hm_brand_rpt(undef), 
   'Test::Smoke::Database::Parsing::parse_hm_brand_rpt without file');
# no existent file return undef
ok(!Test::Smoke::Database::Parsing::parse_hm_brand_rpt('t/mlkmlkmlk'),
   'Test::Smoke::Database::Parsing::parse_hm_brand_rpt with non existent file');

my %res;
foreach my $f (keys %$rep) {
  my @lr = Test::Smoke::Database::Parsing::parse_hm_brand_rpt('t/'.$f);
  if ($ARGV[0]) { $res{$f}=\@lr; next; }
  else {
    my $nb=0;
    foreach (@lr) { 
       ok(eq_hash($_, $$rep{$f}->[$nb]), "Parse HM Brand report as model") 
          or diag("Find ". Data::Dumper->Dump([ $_ ]).
                  " and want ".Data::Dumper->Dump([ $$rep{$f}->[$nb] ]));
       $nb++;
    }
  }
}
print Data::Dumper->Dump([ \%res], ['rep']),"\n" if ($ARGV[0]);

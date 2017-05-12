#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 11;
use File::Basename;
my $dir=dirname $0;

chdir $dir;

use Util::Properties;
#$Util::Properties::VERBOSE=2;


my $prop=Util::Properties->new;
ok($prop, "Util::Properties object / default constructor");
ok($prop->isEmpty, "new prop is empty");
$prop->prop_set('prop_a', -1);
is($prop->prop_get('prop_a'), -1, "ok prop value");
ok(!$prop->isEmpty, "filled prop is not empty anymore");

$prop= Util::Properties->new(properties=>{prop_a=>1, prop_b=>'atchoum'});
ok($prop, "Util::Properties object / from hash constructor");

is($prop->prop_get('prop_a'), 1, "ok prop value");
is($prop->prop_get('prop_b'), 'atchoum', "ok prop value");

$prop->prop_set('prop_a', 2);
is($prop->prop_get('prop_a'), 2, "ok changed prop value");

my $prop2=Util::Properties->new(copy=>$prop);
ok($prop2, "Util::Properties object / copy constructor");
is($prop2->prop_get('prop_a'), 2, "ok prop value");


use File::Temp qw /tempdir tempfile/;

my (undef, $fname)=tempfile(DIR=>File::Spec->tmpdir, UNLINK=>$ENV{DO_NOT_REMOVE_TEMP_FILES}, SUFFIX=>".properties");
$prop2->file_name($fname);
$prop2->save();

#print $prop2->dump(1);

my @props;
my $n=5;
foreach my $i(1..$n){
  my $p=  Util::Properties->new(file=>$fname);
  $p->name("prop-$i");
  push @props,$p;
}
my $m=3;
foreach (1..$m){
  foreach my $p (@props){
    $p->prop_set('prop_a', $p->prop_get('prop_a')+1);
#    print "----\n$_+++++\n";;
  }
}

my $prop3=Util::Properties->new({file=>$fname});
is($prop3->prop_get('prop_a')+0, 2+$n*$m, "prop value after ($n x $m) concurent setting");

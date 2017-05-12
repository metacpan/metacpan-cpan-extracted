#! /usr/bin/perl

use strict;
use warnings;

use Test::More;

my $taintness = substr($0,0,0)."";

# check whether taint mode is enabled.
eval
{
  local($SIG{__WARN__}) = sub{ die shift };
  my $ret = `echo test$taintness 2>&1`;
};
if( $@ !~ /Insecure/ )
{
  plan skip_all => "taint check is not enabled";
}

plan tests => 2;

require Tripletail;
Tripletail->import("/dev/null");
our $TL;

&test;

sub test
{
  my $tmpl = $TL->newTemplate()->setTemplate("<form></form>".$taintness);
  eval{
  $tmpl->addHiddenForm({a=>1});
  };
  is($@, '', "addHiddenForm works.");
  is($tmpl->toStr, qq{<form><input type="hidden" name="a" value="1"></form>}, "result of it");
}

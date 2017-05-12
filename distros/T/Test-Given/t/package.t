package MyPackage;
use Test::Given;
use strict;
use warnings;

our ($subject);

describe 'Package Test' => sub {
  Given subject => sub { 'subject' };
  When subject => sub { 'result' };
  Then sub { $subject eq 'result' };
};

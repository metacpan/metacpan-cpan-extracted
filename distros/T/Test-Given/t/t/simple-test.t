use Test::Given;
use strict;
use warnings;

our ($subject);

describe 'Simple Test' => sub {
  Given subject => sub { 'subject' };
  When subject => sub { 'result' };
  Then sub { $subject eq 'result' };
  And  sub { $subject ne 'subject' };
};

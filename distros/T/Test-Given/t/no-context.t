use Test::Given;
use strict;
use warnings;

our ($subject);

Given subject => sub { 'subject' };
When subject => sub { 'result' };
Then sub { $subject eq 'result' };

#!/usr/bin/perl 

use strict;
use warnings;

use Test::Most qw{no_plan};
use Data::Dumper;
#use Carp::Always;

BEGIN {
  require_ok('Tool::Bench::Item');
};

my $items = {
                ls  => sub{qx{ls}},
                die => sub{die},
            };

for my $name ( keys %$items ) {
  ok my $i  = Tool::Bench::Item->new(name => $name, code => $items->{$name} ), qq{[$name] build item};
  ok $i->run, qq{[$name] running};
  ok $i->run(3), qq{[$name] running with built in looping};
  is $i->total_runs, 4, q{run count is correct};

  is $i->name, $name, "name = $name";

  is scalar(@{$i->times}), 4, 'got the right number of times';
  is scalar(grep{$_<=0} @{$i->times}), 0, 'all times are non-negative';

  # should we have 4 empty error strings, or no errors?
  is scalar(@{$i->errors}),   4, 'got the right number of errors';
  is scalar( @{$i->results}), 4, 'got the right number of results';
}

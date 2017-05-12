#!/usr/bin/perl -w

=head1 NAME

  test.pl - tests Test::Inspector

=head1 SYNOPSIS

  perl -w test.pl

=head1 DESCRIPTION

This uses Test::Inspector to make sure this script calls every method in
Test::Inspector.

=cut

use strict;
use warnings;

use Test::More tests => 3;

use_ok 'Test::Inspector';

isa_ok my $inspector = Test::Inspector->setup({
  modules => [ 'Test::Inspector', 'Test::Foo' ],
  dirs    => [ 't'                            ],
  ignore  => [ 'find', 'finddepth',           ],
  private => 1,
}) => 'Test::Inspector';

$inspector->pretty_report;

isa_ok $inspector = Test::Inspector->setup({
  modules => [ 'Test::Inspector', 'Test::Foo' ],
  dirs    => [ 't'                            ],
}) => 'Test::Inspector';

#$inspector->pretty_report;

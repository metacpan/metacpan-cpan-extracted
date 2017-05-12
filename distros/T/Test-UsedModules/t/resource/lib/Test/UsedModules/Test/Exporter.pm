package Test::UsedModules::Test::Exporter;
use strict;
use warnings;
use utf8;

sub import {
  my $class = shift;
  return unless my $flag = shift;
  no strict 'refs';

  if ($flag eq '-base') {
    $flag = $class;
    my $caller = caller;
    push @{"${caller}::ISA"}, $flag;
    *{"${caller}::dummy"} = sub { return 1 };
  }
}
1;

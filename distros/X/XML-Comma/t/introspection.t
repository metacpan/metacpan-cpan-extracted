use strict;

use lib ".test/lib/";

use XML::Comma;

use Test::More 'no_plan';

my $def = XML::Comma::Def->_test_introspection;
ok($def);

#what to expect
my $expected = {
  ignore_for_hash => { map { $_ => 1 } qw ( test_bool test_ts ) },
  plural => { map { $_ => 1 } qw ( test_plain ) },
  required => { map { $_ => 1 } qw ( test_enum test_bool ) },

  blob => { map { $_ => 1 } qw ( test_blob ) },
  nested => { map { $_ => 1 } qw ( test_nest ) },
  
  boolean => { map { $_ => 1 } qw ( test_bool ) },
  enum => { map { $_ => 1 } qw ( test_enum ) },
  range => { map { $_ => 1 } qw ( test_range ) },
  timestamp => { map { $_ => 1 } qw ( test_ts created last_modified ) },
  timestamp_created => { map { $_ => 1 } qw ( created ) },
  timestamp_last_modified => { map { $_ => 1 } qw ( last_modified ) },
};

#nxor is a fancy name for the truth value matching
#note this isn't the same as eq or ==
sub nxor {
  my ($x, $y) = @_;
  return ($x && $y) || (!$x && !$y);
}

foreach my $el ($def->def_sub_elements()) {
  my $el_name = $el->name();
  my $el_def  = $def->def_by_name($el_name);

  ok(nxor($def->is_ignore_for_hash($el_name), $expected->{ignore_for_hash}->{$el_name}));
  ok(nxor($def->is_plural($el_name), $expected->{plural}->{$el_name}));
  ok(nxor($def->is_required($el_name), $expected->{required}->{$el_name}));

  ok(nxor($el_def->is_blob(), $expected->{blob}->{$el_name}));
  ok(nxor($el_def->is_nested(), $expected->{nested}->{$el_name}));

  my %macros = map { $_ => 1 } $el_def->applied_macros();
  ok(nxor($macros{boolean}, $expected->{boolean}->{$el_name}));
  ok(nxor($macros{enum}, $expected->{enum}->{$el_name}));
  ok(nxor($macros{range}, $expected->{range}->{$el_name}));
  ok(nxor($macros{timestamp}, $expected->{timestamp}->{$el_name}));
  ok(nxor($macros{timestamp_created}, $expected->{timestamp_created}->{$el_name}));
  ok(nxor($macros{timestamp_last_modified}, $expected->{timestamp_last_modified}->{$el_name}));
}

#TODO: the same, but on test_nest


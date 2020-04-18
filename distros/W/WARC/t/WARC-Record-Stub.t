# Unit tests for WARC::Record::Stub module			# -*- CPerl -*-

use strict;
use warnings;

use if $ENV{AUTOMATED_TESTING}, Carp => 'verbose';

use FindBin qw($Bin);

use Test::More tests => 2 + 2 + 4;

BEGIN { use_ok('WARC::Record::Stub')
	  or BAIL_OUT "WARC::Record::Stub failed to load" }

BEGIN {
  my $fail = 0;
  eval q{use WARC::Record::Stub v9999.1.2.3; $fail = 1};
  ok($fail == 0
     && $@ =~ m/WARC.* version v9999.*required--this is only version/,
     'WARC::Record::Stub version check')
}

use File::Spec;

# Construction edge case tests
{
  my $volume = mount WARC::Volume
    (File::Spec->catfile($Bin, 'test-file-1.warc'));

  {
    my $fail = 0;
    eval {new WARC::Record::Stub ($volume, 0, 'bogus'); $fail = 1;};
    ok($fail == 0 && $@ =~ m/unbalanced.*pairs/,
       'bogus extended stub construction fails');
  }

  my $stub = new WARC::Record::Stub ($volume, 0, foo => 'bar');
  is($stub->{foo}, 'bar', 'extra option to stub constructor appears in stub');
}

# Record loading due to method call tests

my %Method_results =
  # TODO: replay and open_payload currently raise "not implemented" exceptions
  ( fields =>
    [1, sub {is((shift)->{WARC_Type}, 'warcinfo',
		'stub loads warcinfo record')} ],
    open_block =>
    [1, sub {isa_ok(tied *{(shift)}, 'WARC::Record::Block',
		    'tied block handle opened via stub')}],
    #open_payload => [0, sub {}],
    protocol =>
    [1, sub {is((shift), 'WARC/1.0',
		'stub loads WARC version')}],
    #replay => [0, sub{}],
    next =>
    [1, sub {isa_ok((shift), 'WARC::Record',
		    'next record loaded via stub')}],
  );

sub test_stub_load_method ($$$) {
  my $volume = shift;
  my $method = shift;
  my $check = shift;

  my $record_stub = new WARC::Record::Stub ($volume, 0);

  plan tests => 3 + $check->[0] + 3;

  isa_ok($record_stub, 'WARC::Record::Stub', 'stub record object');
  isa_ok($record_stub, 'WARC::Record::FromVolume', 'stub record object');
  isa_ok($record_stub, 'WARC::Record', 'stub record object');

  my $result = $record_stub->$method;

  $check->[1]->($result);

  ok((not $record_stub->isa('WARC::Record::Stub')),
    'record object is no longer a stub');
  isa_ok($record_stub, 'WARC::Record::FromVolume', 'record object');
  isa_ok($record_stub, 'WARC::Record', 'record object');
}

{
  my $volume = mount WARC::Volume
    (File::Spec->catfile($Bin, 'test-file-1.warc'));

  subtest "record stub loads record if '$_' called"
    => sub { test_stub_load_method $volume, $_, $Method_results{$_} }
      for sort keys %Method_results;
}

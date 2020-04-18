# Unit tests for WARC::Index::Builder module			# -*- CPerl -*-

use strict;
use warnings;

use if $ENV{AUTOMATED_TESTING}, Carp => 'verbose';

use FindBin qw($Bin);

use Test::More tests => 2 + 8;

BEGIN {
  my $have_test_differences = 0;
  eval q{use Test::Differences; unified_diff; $have_test_differences = 1};
  *eq_or_diff = \&is_deeply unless $have_test_differences;
}

BEGIN { use_ok('WARC::Index::Builder')
	  or BAIL_OUT "WARC::Index::Builder failed to load" }

BEGIN {
  my $fail = 0;
  eval q{use WARC::Index::Builder v9999.1.2.3; $fail = 1};
  ok($fail == 0
     && $@ =~ m/WARC.* version v9999.*required--this is only version/,
     'WARC::Index::Builder version check')
}

use File::Spec;

my %Volume = ();	# map:	tag => volume file name

$Volume{raw1}	= File::Spec->catfile($Bin, 'test-file-1.warc');
$Volume{raw2}	= File::Spec->catfile($Bin, 'test-file-2.warc');

require WARC::Date;

{
  package WARC::Index::_TestMock;

  our @ISA = qw(WARC::Index);

  sub new { bless [], shift }

  sub first_entry {
    my $self = shift;
    bless [$self, 0], 'WARC::Index::Entry::_TestMock'
  }

  sub _contents { @{(shift)} }

  sub _clear { splice @{(shift)} }	# returns previous contents
}

{
  package WARC::Index::Entry::_TestMock;

  our @ISA = qw(WARC::Index::Entry);

  sub record { $_[0]->[0]->[$_[0]->[1]] }
  sub next { bless [$_[0]->[0], 1 + $_[0]->[1]], ref $_[0]
	       if defined $_[0]->[0][1 + $_[0]->[1]] }
}

{
  package WARC::Index::Builder::_TestMock;

  our @ISA = qw(WARC::Index::Builder);

  sub _new_for {
    my $class = shift;
    my $index = shift;

    bless \$index, $class
  }

  sub _add_record { my $self = shift; push @{$$self}, shift }
}

note('*' x 60);

# item adding tests
{
  my $index1 = new WARC::Index::_TestMock;
  my $builder1 = WARC::Index::Builder::_TestMock->_new_for($index1);
  my $index2 = new WARC::Index::_TestMock;
  my $builder2 = WARC::Index::Builder::_TestMock->_new_for($index2);

  {
    my $fail = 0;
    eval {$builder1->add(WARC::Date->now()); $fail = 1};
    ok($fail == 0 && $@ =~ m/unrecognized object/,
       'reject adding bogus object to index');

    # for code coverage:
    $builder1->flush;
  }

  {
    my $pass = 0;
    eval {$builder1->add($Volume{raw1}); $pass = 1};
    ok($pass, 'add test volume by file name') or diag $@;

    $pass = 0;
    eval {$builder2->add($index1); $pass = 1};
    ok($pass, 'add copy of test index 1 to index 2') or diag $@;

    my $vol = mount WARC::Volume ($Volume{raw1});
    $pass = 0;
    eval {$builder1->add($vol); $pass = 1};
    ok($pass, 'add test volume as object') or diag $@;

    $pass = 0;
    eval {$builder2->add($index1->first_entry); $pass = 1};
    ok($pass, 'add entry from index 1 to index 2');

    $pass = 0;
    eval {$builder2->add($vol->first_record); $pass = 1};
    ok($pass, 'add record from volume to index 2');
  }

  eq_or_diff([map $_->id, sort $index1->_clear],
	     [sort ((map '<urn:test:file-1:record-'.$_.'>', qw/0 1 2 N/) x 2)],
	     'test volume correctly added to index 1 twice');

  eq_or_diff([map $_->id, sort $index2->_clear],
	     [sort (map '<urn:test:file-1:record-'.$_.'>', qw/0 0 0 1 2 N/)],
	     'test entries correctly added to index 2');
}

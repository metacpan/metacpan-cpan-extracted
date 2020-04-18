# Unit tests for WARC::Index::File::CDX::Builder module		# -*- CPerl -*-

use strict;
use warnings;

use if $ENV{AUTOMATED_TESTING}, Carp => 'verbose';

use FindBin qw($Bin);

use Test::More tests =>
     3	# loading tests
  +  7;	# basic tests


BEGIN {
  my $have_text_diff = 0;
  eval q{use Text::Diff; $have_text_diff = 1};
  *diff = sub {} unless $have_text_diff;
}

BEGIN { use_ok('WARC::Index::File::CDX::Builder')
	  or BAIL_OUT "WARC::Index::File::CDX::Builder failed to load" }

BEGIN {
  my $fail = 0;
  eval q{use WARC::Index::File::CDX::Builder v9999.1.2.3; $fail = 1};
  ok($fail == 0
     && $@ =~ m/WARC.* version v9999.*required--this is only version/,
     'WARC::Index::File::CDX::Builder version check')
}

isa_ok('WARC::Index::File::CDX::Builder', 'WARC::Index::Builder');

use File::Copy qw/copy/;
use File::Spec;

my @Cleanup = (); my $KeepTemps = 0;
END { if ($KeepTemps) { diag "temporary files from PID $$ not removed" }
      else { unlink @Cleanup } }

sub prep_cdx_test_file ($$) {
  my $which = shift;
  my $what = shift;

  my $filename = File::Spec->catfile($Bin, "test-file-$which.$what.$$.cdx");
  my $src_file = File::Spec->catfile($Bin, "test-file-$which.$what.in.cdx");
  ($filename) = $filename =~ m/^(.*)$/; # untaint -- do not do in production!
  ($src_file) = $src_file =~ m/^(.*)$/; # untaint -- do not do in production!
  copy($src_file, $filename) if -r $src_file;
  push @Cleanup, $filename;

  return $filename;
}

sub check_cdx_result ($$) {
  my $which = shift;
  my $what = shift;

  my $out_file = File::Spec->catfile($Bin, "test-file-$which.$what.$$.cdx");
  my $ref_file = File::Spec->catfile($Bin, "test-file-$which.$what.ref.cdx");

  open my $out, '<', $out_file or BAIL_OUT "$out_file: $!";
  open my $ref, '<', $ref_file or BAIL_OUT "$ref_file: $!";

  {
    local $/ = undef;		# slurp
    my $output = <$out>; my $reference = <$ref>;

    unless (ok($output eq $reference,
	       "CDX output $which:$what matches reference")) {
      print diff \$reference, \$output,
	{ FILENAME_A => 'reference', FILENAME_B => 'result' };
      $KeepTemps = 1;
    }
  }

  close $out; close $ref;
}

note('*' x 60);

# basic tests
{
  {
    my $builder;
    my $fail = 0;
    eval { $builder = _new WARC::Index::File::CDX::Builder (); $fail = 1};
    ok(!defined $builder && $fail == 0 && $@ =~ m/required parameter.*into/,
       'reject construction without destination filename') or diag $@;

    $fail = 0;
    my $filename = prep_cdx_test_file 2, 'bad-header';
    eval { $builder = _new WARC::Index::File::CDX::Builder (into => $filename);
	     $fail = 1};
    ok(!defined $builder && $fail == 0 && $@ =~ m/CDX header/,
       'reject extending bogus file (1)') or diag $@;

    $fail = 0;
    $filename = prep_cdx_test_file 2, 'null-header';
    eval { $builder = _new WARC::Index::File::CDX::Builder (into => $filename);
	     $fail = 1};
    ok(!defined $builder && $fail == 0 && $@ =~ m/CDX header/,
       'reject extending bogus file (2)') or diag $@;
  }

  my $filename = prep_cdx_test_file 1, 'build-vgu';
  my $builder = _new WARC::Index::File::CDX::Builder
    (into => $filename, fields => [qw/v g u/]);
  $builder->add(File::Spec->catfile($Bin, 'test-file-1.warc'));
  $builder->flush;
  check_cdx_result 1, 'build-vgu';

  $filename = prep_cdx_test_file 1, 'buildx-Vgu';
  $builder = _new WARC::Index::File::CDX::Builder
    (into => $filename, fields => [qw/N X u a/]);
  # fields option overidden from existing file header
  $builder->add(File::Spec->catfile($Bin, 'test-file-1.warc.gz'));
  $builder->flush;
  check_cdx_result 1, 'buildx-Vgu';

  $filename = prep_cdx_test_file 1, 'build-default';
  $builder = _new WARC::Index::File::CDX::Builder (into => $filename);
  $builder->add(File::Spec->catfile($Bin, 'test-file-1.warc.gz'));
  $builder->flush;
  check_cdx_result 1, 'build-default';

  $filename = prep_cdx_test_file 2, 'build-default';
  $builder = _new WARC::Index::File::CDX::Builder (into => $filename);
  $builder->add(File::Spec->catfile($Bin, 'test-file-2.warc'));
  $builder->flush;
  check_cdx_result 2, 'build-default';
}

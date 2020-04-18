# Unit tests for WARC::Record::Logical::Heuristics module	# -*- CPerl -*-

use strict;
use warnings;

use if $ENV{AUTOMATED_TESTING}, Carp => 'verbose';

use FindBin qw($Bin);

use Test::More tests =>
     2	# Loading tests
  +  6	# Internal helper function:  _split_digit_spans
  +  4	# Internal helper function:  _find_nearby_files
  +  6	# Internal helper function:  _scan_directory_for_axes
  +  4	# Internal helper function:  _find_similar_files
  + 16	# Internal helper function:  _scan_volume
  +  7	# Searches in same volume
  +  8	# Spanning volumes (simple)
  + 12;	# Spanning volumes (directory scan)

BEGIN {
  my $have_test_differences = 0;
  eval q{use Test::Differences; unified_diff; $have_test_differences = 1};
  *eq_or_diff = \&is_deeply unless $have_test_differences;
}

BEGIN { $INC{'WARC/Volume.pm'} = 'mocked in test driver' }

BEGIN { use_ok('WARC::Record::Logical::Heuristics')
	  or BAIL_OUT "WARC::Record::Logical::Heuristics failed to load" }

BEGIN {
  my $fail = 0;
  eval q{use WARC::Record::Logical::Heuristics v9999.1.2.3; $fail = 1};
  ok($fail == 0
     && $@ =~ m/ version v9999.*required--this is only version/,
     'WARC::Record::Logical::Heuristics version check')
}

use File::Spec;
use Storable qw/dclone/;
require WARC::Record::FromVolume;

my $HF_TestDir = File::Spec->catdir($Bin, 'heuristics_files');
BAIL_OUT 'heuristics test directory missing' unless -d $HF_TestDir;
my @HF_TestFiles =
  (qw( abc122-533-def056-ad-56334.emv abc122-543-def056-ad-56334.emv
       abc123-533-def056-ad-56334.emv abc123-543-def047-ad-56334.emv
       abc123-543-def056-ad-56330.emv abc123-543-def056-ad-56332.emv
       abc123-543-def056-ad-56333.emv abc123-543-def056-ad-56334.emv
       abc123-543-def056-ad-56335.emv abc123-543-def056-ad-56336.emv
       abc123-543-def056-ad-56338.emv abc123-543-def057-ad-56334.emv ),
   qw( def456-789-abc042-zc-82440.emv ), # another "island" volume
   # the following are adapted from a sample found at the Internet Archive
   qw( NEWS-20100913192819505-00056-10413~ia360914.us.archive.org~9443.emv
       NEWS-20100913193701387-00058-10413~ia360914.us.archive.org~9443.emv
       NEWS-20100913195201346-00060-10413~ia360914.us.archive.org~9443.emv
       NEWS-20100913200316661-00062-10413~ia360914.us.archive.org~9443.emv
       NEWS-20100913201909556-00064-10413~ia360914.us.archive.org~9443.emv
       NEWS-20100913203413308-00066-10413~ia360914.us.archive.org~9443.emv
       NEWS-20100913204603775-00068-10413~ia360914.us.archive.org~9443.emv
       NEWS-20100913205911958-00070-10413~ia360914.us.archive.org~9443.emv
       NEWS-20100913210939238-00072-10413~ia360914.us.archive.org~9443.emv
       NEWS-20100913211911044-00074-10413~ia360914.us.archive.org~9443.emv ),
   # further adapted for test code coverage
   qw( NEWS-00060-20100913195201346-10413~ia360914.us.archive.org~9443.emv
       NEWS-00062-20100913200316661-10413~ia360914.us.archive.org~9443.emv
       NEWS-00064-20100913201909556-10413~ia360914.us.archive.org~9443.emv
       NEWS-00066-20100913203413308-10413~ia360914.us.archive.org~9443.emv ));
foreach my $file (@HF_TestFiles) {
  BAIL_OUT 'heuristics test file missing'
    unless -f File::Spec->catfile($HF_TestDir, $file);
  BAIL_OUT 'heuristics test file not empty mock volume'
    unless -z File::Spec->catfile($HF_TestDir, $file);
}
BAIL_OUT 'heuristics test directory has unexpected contents'
  unless (join('',sort map {File::Spec->catfile($HF_TestDir,$_)} @HF_TestFiles)
	  eq join('',sort glob File::Spec->catfile($HF_TestDir, '*.emv')));

my %Mock_Volume_Contents =
  ( 'abc122-533-def056-ad-56334.emv'
    => [[WARC_Type => 'warcinfo',	# offset 0
	 Content_Length => 5,
	 WARC_Record_ID => '<urn:test:fhash-34d4:record-0>',
	 WARC_Filename => 'abc122-533-def056-ad-56334.emv'],
	[WARC_Type => 'resource',	# offset 1
	 WARC_Segment_Number => 1, Content_Length => 100,
	 WARC_Record_ID => '<urn:test:fhash-34d4:record-1>'],
	[WARC_Type => 'resource',	# offset 2
	 Content_Length => 20,
	 WARC_Record_ID => '<urn:test:fhash-34d4:record-2>'],
	[WARC_Type => 'resource',	# offset 3
	 Content_Length => 50, X_Mock_Compression => 'gzip',
	 WARC_Record_ID => '<urn:test:fhash-34d4:record-3>'],
	[WARC_Type => 'continuation',	# offset 4
	 WARC_Record_ID => '<urn:test:fhash-34d4:record-4>',
	 WARC_Segment_Number => 2, Content_Length => 100,
	 WARC_Segment_Origin_ID => '<urn:test:fhash-34d4:record-1>'],
	[WARC_Type => 'resource',	# offset 5
	 Content_Length => 30, X_Mock_Compression => 'gzip',
	 WARC_Record_ID => '<urn:test:fhash-34d4:record-5>'],
	[WARC_Type => 'continuation',	# offset 6
	 WARC_Record_ID => '<urn:test:fhash-34d4:record-6>',
	 WARC_Segment_Number => 3, Content_Length => 100,
	 X_Mock_Compression => 'gzip',
	 WARC_Segment_Origin_ID => '<urn:test:fhash-34d4:record-1>'],
	[WARC_Type => 'continuation',	# offset 7
	 WARC_Record_ID => '<urn:test:fhash-34d4:record-7>',
	 WARC_Segment_Number => 4, Content_Length => 100,
	 X_Mock_Compression => 'gzip-sl',
	 WARC_Segment_Origin_ID => '<urn:test:fhash-34d4:record-1>'],
	[WARC_Type => 'continuation',	# offset 8
	 WARC_Record_ID => '<urn:test:fhash-34d4:record-8>',
	 WARC_Segment_Number => 5, Content_Length => 100,
	 WARC_Segment_Total_Length => 500, X_Mock_Compression => 'gzip-sl',
	 WARC_Segment_Origin_ID => '<urn:test:fhash-34d4:record-1>'],
	[WARC_Type => 'continuation',	# offset 9
	 WARC_Segment_Number => 2, Content_Length => 40,
	 WARC_Segment_Total_Length => 100,
	 WARC_Segment_Origin_ID => '<urn:test:fhash-7f75:record-1>',
	 WARC_Record_ID => '<urn:test:fhash-34d4:record-9>']],

    'abc122-543-def056-ad-56334.emv'
    => [[WARC_Type => 'warcinfo',	# offset 0
	 WARC_Record_ID => '<urn:test:fhash-7f75:record-0>',
	 WARC_Filename => 'abc122-543-def056-ad-56334.emv'],
	[WARC_Type => 'resource',	# offset 1
	 WARC_Segment_Number => 1, Content_Length => 60,
	 WARC_Record_ID => '<urn:test:fhash-7f75:record-1>'],
	[WARC_Type => 'resource',	# offset 2
	 WARC_Record_ID => '<urn:test:fhash-7f75:record-2>'],
	[WARC_Type => 'resource',	# offset 3
	 WARC_Record_ID => '<urn:test:fhash-7f75:record-3>'],
	[WARC_Type => 'resource',	# offset 4
	 WARC_Record_ID => '<urn:test:fhash-7f75:record-4>'],
	[WARC_Type => 'resource',	# offset 5
	 WARC_Record_ID => '<urn:test:fhash-7f75:record-5>'],
	[WARC_Type => 'resource',	# offset 6
	 WARC_Record_ID => '<urn:test:fhash-7f75:record-6>'],
	[WARC_Type => 'resource',	# offset 7
	 WARC_Record_ID => '<urn:test:fhash-7f75:record-7>'],
	[WARC_Type => 'resource',	# offset 8
	 WARC_Record_ID => '<urn:test:fhash-7f75:record-8>'],
	[WARC_Type => 'resource',	# offset 9
	 WARC_Record_ID => '<urn:test:fhash-7f75:record-9>']],

    'abc123-533-def056-ad-56334.emv'
    => [[WARC_Type => 'warcinfo',	# offset 0
	 WARC_Record_ID => '<urn:test:fhash-87d5:record-0>',
	 WARC_Filename => 'abc123-533-def056-ad-56334.emv'],
	[WARC_Type => 'resource',	# offset 1
	 WARC_Record_ID => '<urn:test:fhash-87d5:record-1>'],
	[WARC_Type => 'resource',	# offset 2
	 WARC_Record_ID => '<urn:test:fhash-87d5:record-2>'],
	[WARC_Type => 'resource',	# offset 3
	 WARC_Record_ID => '<urn:test:fhash-87d5:record-3>'],
	[WARC_Type => 'resource',	# offset 4
	 WARC_Record_ID => '<urn:test:fhash-87d5:record-4>'],
	[WARC_Type => 'resource',	# offset 5
	 WARC_Record_ID => '<urn:test:fhash-87d5:record-5>'],
	[WARC_Type => 'resource',	# offset 6
	 WARC_Record_ID => '<urn:test:fhash-87d5:record-6>'],
	[WARC_Type => 'resource',	# offset 7
	 WARC_Record_ID => '<urn:test:fhash-87d5:record-7>'],
	[WARC_Type => 'resource',	# offset 8
	 WARC_Record_ID => '<urn:test:fhash-87d5:record-8>'],
	[WARC_Type => 'resource',	# offset 9
	 WARC_Record_ID => '<urn:test:fhash-87d5:record-9>']],

    'abc123-543-def047-ad-56334.emv'
    => [[WARC_Type => 'warcinfo',	# offset 0
	 WARC_Record_ID => '<urn:test:fhash-9e56:record-0>',
	 WARC_Filename => 'abc123-543-def047-ad-56334.emv'],
	[WARC_Type => 'resource',	# offset 1
	 WARC_Record_ID => '<urn:test:fhash-9e56:record-1>'],
	[WARC_Type => 'resource',	# offset 2
	 WARC_Record_ID => '<urn:test:fhash-9e56:record-2>'],
	[WARC_Type => 'resource',	# offset 3
	 WARC_Record_ID => '<urn:test:fhash-9e56:record-3>'],
	[WARC_Type => 'resource',	# offset 4
	 WARC_Record_ID => '<urn:test:fhash-9e56:record-4>'],
	[WARC_Type => 'resource',	# offset 5
	 WARC_Record_ID => '<urn:test:fhash-9e56:record-5>'],
	[WARC_Type => 'resource',	# offset 6
	 WARC_Record_ID => '<urn:test:fhash-9e56:record-6>'],
	[WARC_Type => 'resource',	# offset 7
	 WARC_Record_ID => '<urn:test:fhash-9e56:record-7>'],
	[WARC_Type => 'resource',	# offset 8
	 WARC_Record_ID => '<urn:test:fhash-9e56:record-8>'],
	[WARC_Type => 'resource',	# offset 9
	 WARC_Record_ID => '<urn:test:fhash-9e56:record-9>']],

    # Note that the arrangements of the segments in these volumes does not
    # conform to the WARC specification at all, but is possible if WARC
    # volumes are combined after being initially written using tools that
    # preserve segmentation as the records were initially written.

    'abc123-543-def056-ad-56330.emv'
    => [[WARC_Type => 'warcinfo',	# offset 0
	 WARC_Record_ID => '<urn:test:fhash-7072:record-0>',
	 WARC_Filename => 'abc123-543-def056-ad-56330.emv'],
	[WARC_Type => 'resource',	# offset 1
	 WARC_Segment_Number => 1, Content_Length => 10,
	 WARC_Record_ID => '<urn:test:fhash-7072:record-1>'],
	[WARC_Type => 'resource',	# offset 2
	 WARC_Record_ID => '<urn:test:fhash-7072:record-2>'],
	[WARC_Type => 'resource',	# offset 3
	 WARC_Record_ID => '<urn:test:fhash-7072:record-3>'],
	[WARC_Type => 'resource',	# offset 4
	 WARC_Record_ID => '<urn:test:fhash-7072:record-4>'],
	[WARC_Type => 'resource',	# offset 5
	 WARC_Record_ID => '<urn:test:fhash-7072:record-5>'],
	[WARC_Type => 'resource',	# offset 6
	 WARC_Record_ID => '<urn:test:fhash-7072:record-6>'],
	[WARC_Type => 'resource',	# offset 7
	 WARC_Record_ID => '<urn:test:fhash-7072:record-7>'],
	[WARC_Type => 'resource',	# offset 8
	 WARC_Record_ID => '<urn:test:fhash-7072:record-8>'],
	[WARC_Type => 'resource',	# offset 9
	 WARC_Record_ID => '<urn:test:fhash-7072:record-9>']],

    # skip 'abc123-543-def056-ad-56331.emv' -- the simple sequence search
    # will stop there but the directory scan will still find the above

    'abc123-543-def056-ad-56332.emv'
    => [[WARC_Type => 'warcinfo',	# offset 0
	 WARC_Record_ID => '<urn:test:fhash-a174:record-0>',
	 WARC_Filename => 'abc123-543-def056-ad-56332.emv'],
	[WARC_Type => 'continuation',	# offset 1
	 WARC_Segment_Number => 2, Content_Length => 10,
	 WARC_Segment_Origin_ID => '<urn:test:fhash-7072:record-1>',
	 WARC_Record_ID => '<urn:test:fhash-a174:record-1>'],
	[WARC_Type => 'resource',	# offset 2
	 WARC_Segment_Number => 1, Content_Length => 10,
	 WARC_Record_ID => '<urn:test:fhash-a174:record-2>'],
	[WARC_Type => 'resource',	# offset 3
	 WARC_Record_ID => '<urn:test:fhash-a174:record-3>'],
	[WARC_Type => 'resource',	# offset 4
	 WARC_Record_ID => '<urn:test:fhash-a174:record-4>'],
	[WARC_Type => 'continuation',	# offset 5
	 WARC_Segment_Number => 2, Content_Length => 10,
	 WARC_Segment_Origin_ID => '<urn:test:fhash-a174:record-2>',
	 WARC_Record_ID => '<urn:test:fhash-a174:record-5>'],
	[WARC_Type => 'resource',	# offset 6
	 WARC_Record_ID => '<urn:test:fhash-a174:record-6>'],
	[WARC_Type => 'resource',	# offset 7
	 WARC_Segment_Number => 1, Content_Length => 10,
	 WARC_Record_ID => '<urn:test:fhash-a174:record-7>'],
	[WARC_Type => 'resource',	# offset 8
	 WARC_Record_ID => '<urn:test:fhash-a174:record-8>'],
	[WARC_Type => 'resource',	# offset 9
	 WARC_Record_ID => '<urn:test:fhash-a174:record-9>']],

    'abc123-543-def056-ad-56333.emv'
    => [[WARC_Type => 'warcinfo',	# offset 0
	 WARC_Record_ID => '<urn:test:fhash-b9f5:record-0>',
	 WARC_Filename => 'abc123-543-def056-ad-56333.emv'],
	[WARC_Type => 'resource',	# offset 1
	 WARC_Record_ID => '<urn:test:fhash-b9f5:record-1>'],
	[WARC_Type => 'continuation',	# offset 2
	 WARC_Segment_Number => 3, Content_Length => 10,
	 WARC_Segment_Origin_ID => '<urn:test:fhash-7072:record-1>',
	 WARC_Record_ID => '<urn:test:fhash-b9f5:record-2>'],
	[WARC_Type => 'resource',	# offset 3
	 WARC_Record_ID => '<urn:test:fhash-b9f5:record-3>'],
	[WARC_Type => 'resource',	# offset 4
	 WARC_Record_ID => '<urn:test:fhash-b9f5:record-4>'],
	[WARC_Type => 'resource',	# offset 5
	 WARC_Record_ID => '<urn:test:fhash-b9f5:record-5>'],
	[WARC_Type => 'resource',	# offset 6
	 WARC_Record_ID => '<urn:test:fhash-b9f5:record-6>'],
	[WARC_Type => 'resource',	# offset 7
	 WARC_Record_ID => '<urn:test:fhash-b9f5:record-7>'],
	[WARC_Type => 'resource',	# offset 8
	 WARC_Record_ID => '<urn:test:fhash-b9f5:record-8>'],
	[WARC_Type => 'resource',	# offset 9
	 WARC_Record_ID => '<urn:test:fhash-b9f5:record-9>']],

    'abc123-543-def056-ad-56334.emv'	# central point file <========>
    => [[WARC_Type => 'warcinfo',	# offset 0
	 WARC_Record_ID => '<urn:test:fhash-7cac:record-0>',
	 WARC_Filename => 'abc123-543-def056-ad-56334.emv'],
	[WARC_Type => 'resource',	# offset 1
	 WARC_Segment_Number => 1, Content_Length => 10,
	 WARC_Record_ID => '<urn:test:fhash-7cac:record-1>'],
	[WARC_Type => 'continuation',	# offset 2
	 WARC_Segment_Number => 2, Content_Length => 10,
	 WARC_Segment_Origin_ID => '<urn:test:fhash-7cac:record-1>',
	 WARC_Record_ID => '<urn:test:fhash-7cac:record-2>'],
	[WARC_Type => 'continuation',	# offset 3
	 WARC_Segment_Number => 3, Content_Length => 10,
	 WARC_Segment_Total_Length => 30,
	 WARC_Segment_Origin_ID => '<urn:test:fhash-7cac:record-1>',
	 WARC_Record_ID => '<urn:test:fhash-7cac:record-3>'],
	[WARC_Type => 'continuation',	# offset 4
	 WARC_Segment_Number => 3, Content_Length => 10,
	 WARC_Segment_Origin_ID => '<urn:test:fhash-a174:record-2>',
	 WARC_Record_ID => '<urn:test:fhash-7cac:record-4>'],
	[WARC_Type => 'resource',	# offset 5
	 WARC_Record_ID => '<urn:test:fhash-7cac:record-5>'],
	[WARC_Type => 'continuation',	# offset 6
	 WARC_Segment_Number => 4, Content_Length => 10,
	 WARC_Segment_Origin_ID => '<urn:test:fhash-7072:record-1>',
	 WARC_Record_ID => '<urn:test:fhash-7cac:record-6>'],
	[WARC_Type => 'resource',	# offset 7
	 WARC_Record_ID => '<urn:test:fhash-7cac:record-7>'],
	[WARC_Type => 'resource',	# offset 8
	 WARC_Segment_Number => 1, Content_Length => 10,
	 WARC_Record_ID => '<urn:test:fhash-7cac:record-8>'],
	[WARC_Type => 'continuation',	# offset 9
	 WARC_Segment_Number => 2, Content_Length => 10,
	 WARC_Segment_Origin_ID => '<urn:test:fhash-7cac:record-8>',
	 WARC_Record_ID => '<urn:test:fhash-7cac:record-9>']],

    'abc123-543-def056-ad-56335.emv'
    => [[WARC_Type => 'warcinfo',	# offset 0
	 WARC_Record_ID => '<urn:test:fhash-eaf7:record-0>',
	 WARC_Filename => 'abc123-543-def056-ad-56335.emv'],
	[WARC_Type => 'resource',	# offset 1
	 WARC_Record_ID => '<urn:test:fhash-eaf7:record-1>'],
	[WARC_Type => 'resource',	# offset 2
	 WARC_Record_ID => '<urn:test:fhash-eaf7:record-2>'],
	[WARC_Type => 'resource',	# offset 3
	 WARC_Record_ID => '<urn:test:fhash-eaf7:record-3>'],
	[WARC_Type => 'continuation',	# offset 4
	 WARC_Segment_Number => 4, Content_Length => 10,
	 WARC_Segment_Origin_ID => '<urn:test:fhash-a174:record-2>',
	 WARC_Record_ID => '<urn:test:fhash-eaf7:record-4>'],
	[WARC_Type => 'resource',	# offset 5
	 WARC_Record_ID => '<urn:test:fhash-eaf7:record-5>'],
	[WARC_Type => 'resource',	# offset 6
	 WARC_Record_ID => '<urn:test:fhash-eaf7:record-6>'],
	[WARC_Type => 'resource',	# offset 7
	 WARC_Record_ID => '<urn:test:fhash-eaf7:record-7>'],
	[WARC_Type => 'resource',	# offset 8
	 WARC_Record_ID => '<urn:test:fhash-eaf7:record-8>'],
	[WARC_Type => 'resource',	# offset 9
	 WARC_Record_ID => '<urn:test:fhash-eaf7:record-9>']],

    'abc123-543-def056-ad-56336.emv'
    => [[WARC_Type => 'warcinfo',	# offset 0
	 WARC_Record_ID => '<urn:test:fhash-0378:record-0>',
	 WARC_Filename => 'abc123-543-def056-ad-56336.emv'],
	[WARC_Type => 'resource',	# offset 1
	 WARC_Record_ID => '<urn:test:fhash-0378:record-1>'],
	[WARC_Type => 'continuation',	# offset 2
	 WARC_Segment_Number => 5, Content_Length => 10,
	 WARC_Segment_Total_Length => 50,
	 WARC_Segment_Origin_ID => '<urn:test:fhash-a174:record-2>',
	 WARC_Record_ID => '<urn:test:fhash-0378:record-2>'],
	[WARC_Type => 'continuation',	# offset 3
	 WARC_Segment_Number => 2, Content_Length => 10,
	 WARC_Segment_Total_Length => 20,
	 WARC_Segment_Origin_ID => '<urn:test:fhash-a174:record-7>',
	 WARC_Record_ID => '<urn:test:fhash-0378:record-3>'],
	[WARC_Type => 'resource',	# offset 4
	 WARC_Record_ID => '<urn:test:fhash-0378:record-4>'],
	[WARC_Type => 'continuation',	# offset 5
	 WARC_Segment_Number => 5, Content_Length => 10,
	 WARC_Segment_Origin_ID => '<urn:test:fhash-7072:record-1>',
	 WARC_Record_ID => '<urn:test:fhash-0378:record-5>'],
	[WARC_Type => 'continuation',	# offset 6
	 WARC_Segment_Number => 3, Content_Length => 10,
	 WARC_Segment_Origin_ID => '<urn:test:fhash-7cac:record-8>',
	 WARC_Record_ID => '<urn:test:fhash-0378:record-6>'],
	[WARC_Type => 'resource',	# offset 7
	 WARC_Record_ID => '<urn:test:fhash-0378:record-7>'],
	[WARC_Type => 'resource',	# offset 8
	 WARC_Record_ID => '<urn:test:fhash-0378:record-8>'],
	[WARC_Type => 'resource',	# offset 9
	 WARC_Record_ID => '<urn:test:fhash-0378:record-9>']],

    # skip 'abc123-543-def056-ad-56337.emv' -- the simple sequence search
    # will stop there but the directory scan will still find the following

    'abc123-543-def056-ad-56338.emv'
    => [[WARC_Type => 'warcinfo',	# offset 0
	 WARC_Record_ID => '<urn:test:fhash-347a:record-0>',
	 WARC_Filename => 'abc123-543-def056-ad-56338.emv'],
	[WARC_Type => 'resource',	# offset 1
	 WARC_Record_ID => '<urn:test:fhash-347a:record-1>'],
	[WARC_Type => 'resource',	# offset 2
	 WARC_Record_ID => '<urn:test:fhash-347a:record-2>'],
	[WARC_Type => 'continuation',	# offset 3
	 WARC_Segment_Number => 6, Content_Length => 10,
	 WARC_Segment_Total_Length => 60,
	 WARC_Segment_Origin_ID => '<urn:test:fhash-7072:record-1>',
	 WARC_Record_ID => '<urn:test:fhash-347a:record-3>'],
	[WARC_Type => 'resource',	# offset 4
	 WARC_Record_ID => '<urn:test:fhash-347a:record-4>'],
	[WARC_Type => 'continuation',	# offset 5
	 WARC_Segment_Number => 5, Content_Length => 10,
	 WARC_Segment_Total_Length => 50,
	 # note that segment number 4 of this item is missing...
	 WARC_Segment_Origin_ID => '<urn:test:fhash-7cac:record-8>',
	 WARC_Record_ID => '<urn:test:fhash-347a:record-5>'],
	[WARC_Type => 'resource',	# offset 6
	 WARC_Record_ID => '<urn:test:fhash-347a:record-6>'],
	[WARC_Type => 'resource',	# offset 7
	 WARC_Record_ID => '<urn:test:fhash-347a:record-7>'],
	[WARC_Type => 'resource',	# offset 8
	 WARC_Record_ID => '<urn:test:fhash-347a:record-8>'],
	[WARC_Type => 'resource',	# offset 9
	 WARC_Record_ID => '<urn:test:fhash-347a:record-9>']],

    'abc123-543-def057-ad-56334.emv'
    => [[WARC_Type => 'warcinfo',	# offset 0
	 WARC_Record_ID => '<urn:test:fhash-0c17:record-0>',
	 WARC_Filename => 'abc123-543-def057-ad-56334.emv'],
	[WARC_Type => 'resource',	# offset 1
	 WARC_Record_ID => '<urn:test:fhash-0c17:record-1>'],
	[WARC_Type => 'resource',	# offset 2
	 WARC_Record_ID => '<urn:test:fhash-0c17:record-2>'],
	[WARC_Type => 'resource',	# offset 3
	 WARC_Record_ID => '<urn:test:fhash-0c17:record-3>'],
	[WARC_Type => 'resource',	# offset 4
	 WARC_Record_ID => '<urn:test:fhash-0c17:record-4>'],
	[WARC_Type => 'resource',	# offset 5
	 WARC_Record_ID => '<urn:test:fhash-0c17:record-5>'],
	[WARC_Type => 'resource',	# offset 6
	 WARC_Record_ID => '<urn:test:fhash-0c17:record-6>'],
	[WARC_Type => 'resource',	# offset 7
	 WARC_Record_ID => '<urn:test:fhash-0c17:record-7>'],
	[WARC_Type => 'resource',	# offset 8
	 WARC_Record_ID => '<urn:test:fhash-0c17:record-8>'],
	[WARC_Type => 'resource',	# offset 9
	 WARC_Record_ID => '<urn:test:fhash-0c17:record-9>']],

    # This volume is an island, even in directory scan;
    # included to tie up loose ends in code coverage analysis.
    'def456-789-abc042-zc-82440.emv'
    => [[WARC_Type => 'warcinfo',	# offset 0
	 WARC_Record_ID => '<urn:test:fhash-1ddb:record-0>',
	 WARC_Filename => 'def456-789-abc042-zc-82440.emv'],
	[WARC_Type => 'continuation',	# offset 1
	 WARC_Segment_Number => 2, Content_Length => 10,
	 # note that segment number 1 of this item is missing...
	 WARC_Segment_Origin_ID => '<urn:test:bogus:record-1>',
	 WARC_Record_ID => '<urn:test:fhash-1ddb:record-1>'],
	[WARC_Type => 'continuation',	# offset 2
	 WARC_Segment_Number => 3, Content_Length => 10,
	 WARC_Segment_Total_Length => 30,
	 # note that segment number 1 of this item is missing...
	 WARC_Segment_Origin_ID => '<urn:test:bogus:record-1>',
	 WARC_Record_ID => '<urn:test:fhash-1ddb:record-2>']],

    # sample from Internet Archive
    'NEWS-20100913192819505-00056-10413~ia360914.us.archive.org~9443.emv' => [],
    'NEWS-20100913193701387-00058-10413~ia360914.us.archive.org~9443.emv' => [],
    'NEWS-20100913195201346-00060-10413~ia360914.us.archive.org~9443.emv' => [],
    'NEWS-20100913200316661-00062-10413~ia360914.us.archive.org~9443.emv' => [],
    'NEWS-20100913201909556-00064-10413~ia360914.us.archive.org~9443.emv' => [],
    'NEWS-20100913203413308-00066-10413~ia360914.us.archive.org~9443.emv' => [],
    'NEWS-20100913204603775-00068-10413~ia360914.us.archive.org~9443.emv' => [],
    'NEWS-20100913205911958-00070-10413~ia360914.us.archive.org~9443.emv' => [],
    'NEWS-20100913210939238-00072-10413~ia360914.us.archive.org~9443.emv' => [],
    'NEWS-20100913211911044-00074-10413~ia360914.us.archive.org~9443.emv' => [],

    # further adapted for code coverage
    'NEWS-00060-20100913195201346-10413~ia360914.us.archive.org~9443.emv' => [],
    'NEWS-00062-20100913200316661-10413~ia360914.us.archive.org~9443.emv' => [],
    'NEWS-00064-20100913201909556-10413~ia360914.us.archive.org~9443.emv' => [],
    'NEWS-00066-20100913203413308-10413~ia360914.us.archive.org~9443.emv' => [],

  );
BAIL_OUT 'mock volume table does not match file list'
  unless (join('', sort @HF_TestFiles)
	  eq join('', sort keys %Mock_Volume_Contents));

foreach my $volname (keys %Mock_Volume_Contents) {
  for (@{$Mock_Volume_Contents{$volname}}) {
    $_ = new WARC::Fields (@$_);
    $_->set_readonly;
    my $is_later_segment = (defined $_->field('WARC-Segment-Number')
			    && $_->field('WARC-Segment-Number') > 1);
    my $is_continuation = $_->field('WARC-Type') eq 'continuation';
    BAIL_OUT 'bad record '.$_->field('WARC-Record-ID').' in '.$volname
      if ($is_later_segment xor $is_continuation);
  }
}


{
  package WARC::Record::_TestMock;

  our @ISA = qw(WARC::Record::FromVolume);

  use Carp;

  sub new {
    my $class = shift;
    my $volume = shift;
    my $offset = shift;

    my $ob = {volume => $volume, offset => $offset};
    $ob->{compression} = ''
      if $Mock_Volume_Contents{$$volume}[$offset]->field('X-Mock-Compression');
    $ob->{sl_packed_size} = 0
      if $Mock_Volume_Contents{$$volume}[$offset]->field('X-Mock-Compression')
	&& $Mock_Volume_Contents{$$volume}[$offset]->field('X-Mock-Compression')
	  =~ m/sl$/;

    bless $ob, $class
  }

  sub _read		{ croak "cannot read from mock volume" }
  sub logical		{ croak "do not ask for trouble like that" }
  sub open_block	{ croak "mock record has no block" }
  sub replay		{ croak "mock record is empty" }
  sub open_payload	{ croak "mock record has no payload" }

  sub protocol { 'MOCK' }
  sub volume { (shift)->{volume} }
  sub offset { (shift)->{offset} }
  sub fields {
    my $self = shift;
    return $Mock_Volume_Contents{${$self->{volume}}}[$self->{offset}];
  }
  sub next {
    my $self = shift;

    return undef
      unless defined $Mock_Volume_Contents{${$self->{volume}}}[1+$self->{offset}];
    return new WARC::Record::_TestMock ($self->{volume}, 1+$self->{offset});
  }
}
{
  package WARC::Volume;

  use Test::More;

  sub mount {
    my $class = shift;
    my $name = (File::Spec->splitpath(shift))[2];

    BAIL_OUT "unknown name '$name' in mock WARC::Volume::mount"
      unless defined $Mock_Volume_Contents{$name};

    bless \$name, $class
  }

  sub filename { File::Spec->catfile( $HF_TestDir, ${(shift)}) }
  sub first_record { new WARC::Record::_TestMock ((shift), 0) }
  sub record_at { new WARC::Record::_TestMock (@_) }

  sub _file_tag { (shift)->filename }
}

# convert WARC::Record objects to record ID values, sort as text, and
# remove duplicates
sub as_id_set (@) {
  my @ids = sort map {$_->id} @_;
  for (my $i = 0; $i < @ids; $i++)
    { splice @ids, 1+$i, 1 while defined $ids[1+$i] && $ids[$i] eq $ids[1+$i] }
  return @ids;
}

note('*' x 60);

# Internal helper function:  _split_digit_spans
{
  eq_or_diff([WARC::Record::Logical::Heuristics::_split_digit_spans
	      'abc-123-543-def056-ad-56334-end'],
	     [['abc-', '123', '-543-def056-ad-56334-end'],
	      ['abc-123-', '543', '-def056-ad-56334-end'],
	      ['abc-123-543-def', '056', '-ad-56334-end'],
	      ['abc-123-543-def056-ad-', '56334', '-end']],
	     'split digits from test string (1)');
  eq_or_diff([WARC::Record::Logical::Heuristics::_split_digit_spans
	      '1abc-123-543-def056-ad-56334-end'],
	     [['', '1', 'abc-123-543-def056-ad-56334-end'],
	      ['1abc-', '123', '-543-def056-ad-56334-end'],
	      ['1abc-123-', '543', '-def056-ad-56334-end'],
	      ['1abc-123-543-def', '056', '-ad-56334-end'],
	      ['1abc-123-543-def056-ad-', '56334', '-end']],
	     'split digits from test string (2)');
  eq_or_diff([WARC::Record::Logical::Heuristics::_split_digit_spans
	      'abc-123-543-def056-ad-56334-end-4'],
	     [['abc-', '123', '-543-def056-ad-56334-end-4'],
	      ['abc-123-', '543', '-def056-ad-56334-end-4'],
	      ['abc-123-543-def', '056', '-ad-56334-end-4'],
	      ['abc-123-543-def056-ad-', '56334', '-end-4'],
	      ['abc-123-543-def056-ad-56334-end-', '4', '']],
	     'split digits from test string (3)');
  eq_or_diff([WARC::Record::Logical::Heuristics::_split_digit_spans
	      '1abc-123-543-def056-ad-56334-end-4'],
	     [['', '1', 'abc-123-543-def056-ad-56334-end-4'],
	      ['1abc-', '123', '-543-def056-ad-56334-end-4'],
	      ['1abc-123-', '543', '-def056-ad-56334-end-4'],
	      ['1abc-123-543-def', '056', '-ad-56334-end-4'],
	      ['1abc-123-543-def056-ad-', '56334', '-end-4'],
	      ['1abc-123-543-def056-ad-56334-end-', '4', '']],
	     'split digits from test string (4)');

  eq_or_diff([WARC::Record::Logical::Heuristics::_split_digit_spans
	      'abc-123456789-12345678-1234-end'],
	     [['abc-123456789-', '12345678', '-1234-end'],
	      ['abc-123456789-12345678-', '1234', '-end']],
	     'splitting digits skips long spans (1)');
  eq_or_diff([WARC::Record::Logical::Heuristics::_split_digit_spans
	      'abc123-123456789-123456789-12345-123456789-end'],
	     [['abc', '123', '-123456789-123456789-12345-123456789-end'],
	      ['abc123-123456789-123456789-', '12345', '-123456789-end']],
	     'splitting digits skips long spans (2)');
}

note('*' x 60);

# Internal helper function:  _find_nearby_files
sub sieve_testdir (@) {
  # This sub removes results from directories other than $HF_TestDir.

  #  While finding files anywhere on the system sufficiently near the
  #   starting point *is* the intended and correct behavior for the library
  #   code tested here, some CPAN smoke test machines unpack multiple
  #   copies of the distribution into adjacent directories with a counter
  #   appended to the distribution directory.  The heuristics code finds
  #   spurious hits from the other copies and these tests incorrectly fail.

  my $vol; my $dir; my $file; my $v; my $d; my $f;
  my $testdir = File::Spec->catfile($HF_TestDir, 'bogus');
  ($vol, $dir, $file) = File::Spec->splitpath($testdir);
  BAIL_OUT "\$HF_TestDir $HF_TestDir did not parse properly"
    unless $file eq 'bogus';

  foreach my $axis (@_) {
    foreach my $item (@$axis) {
      ($v, $d, $f) = File::Spec->splitpath($item);
      $item = undef unless $v eq $vol && $d eq $dir;
    }
    @$axis = grep defined, @$axis;
  }
  return grep {scalar @$_} @_;
}
{
  my $file = File::Spec->catfile($HF_TestDir, 'abc123-543-def056-ad-56334.emv');
  my @axes = WARC::Record::Logical::Heuristics::_split_digit_spans $file;
  eq_or_diff([sieve_testdir
	      WARC::Record::Logical::Heuristics::_find_nearby_files  +1, @axes],
	     [[map {File::Spec->catfile($HF_TestDir, $_)}
	       'abc123-543-def057-ad-56334.emv'],
	      [map {File::Spec->catfile($HF_TestDir, $_)}
	       'abc123-543-def056-ad-56335.emv',
	       'abc123-543-def056-ad-56336.emv']],
	     'find nearby files (+1: later)');
  eq_or_diff([sieve_testdir
	      WARC::Record::Logical::Heuristics::_find_nearby_files  -1, @axes],
	     [[map {File::Spec->catfile($HF_TestDir, $_)}
	       'abc122-543-def056-ad-56334.emv'],
	      [map {File::Spec->catfile($HF_TestDir, $_)}
	       'abc123-543-def056-ad-56333.emv',
	       'abc123-543-def056-ad-56332.emv']],
	     'find nearby files (-1: earlier)');
  eq_or_diff([sieve_testdir
	      WARC::Record::Logical::Heuristics::_find_nearby_files -10, @axes],
	     [[map {File::Spec->catfile($HF_TestDir, $_)}
	       'abc123-533-def056-ad-56334.emv']],
	     'find nearby files (-10: skip earlier)');
  eq_or_diff([sieve_testdir
	      WARC::Record::Logical::Heuristics::_find_nearby_files  +2, @axes],
	     [[map {File::Spec->catfile($HF_TestDir, $_)}
	       'abc123-543-def056-ad-56336.emv',
	       'abc123-543-def056-ad-56338.emv']],
	     'find nearby files (2: skip later)');
}

note('*' x 60);

# Internal helper function:  _scan_directory_for_axes
{
  local $WARC::Record::Logical::Heuristics::Effort = 0;
  local $WARC::Record::Logical::Heuristics::Effort{readdir_files_per_tick} = 1;
  my $file = 'abc123-543-def056-ad-56334.emv';
  my @axes = WARC::Record::Logical::Heuristics::_split_digit_spans $file;

  {
    my $fail = 0;
    eval {WARC::Record::Logical::Heuristics::_scan_directory_for_axes
	$HF_TestDir.'-not-there', (); $fail = 1;};
    ok($fail == 0 && $@ =~ m/-not-there/,
       'scanning non-existent directory croaks');
    is($WARC::Record::Logical::Heuristics::Effort, 0, '... with no I/O');
  }

  eq_or_diff([map {[sort @$_]}
	      WARC::Record::Logical::Heuristics::_scan_directory_for_axes
	      $HF_TestDir, @axes],
	     [['abc122-543-def056-ad-56334.emv',
	       'abc123-543-def056-ad-56334.emv'],
	      ['abc123-533-def056-ad-56334.emv',
	       'abc123-543-def056-ad-56334.emv'],
	      ['abc123-543-def047-ad-56334.emv',
	       'abc123-543-def056-ad-56334.emv',
	       'abc123-543-def057-ad-56334.emv'],
	      ['abc123-543-def056-ad-56330.emv',
	       'abc123-543-def056-ad-56332.emv',
	       'abc123-543-def056-ad-56333.emv',
	       'abc123-543-def056-ad-56334.emv',
	       'abc123-543-def056-ad-56335.emv',
	       'abc123-543-def056-ad-56336.emv',
	       'abc123-543-def056-ad-56338.emv']],
	     'scan directory (constant digit spans)');

  $file = 'NEWS-20100913201909556-00064-10413~ia360914.us.archive.org~9443.emv';
  @axes = WARC::Record::Logical::Heuristics::_split_digit_spans $file;
  eq_or_diff
    ([map {[sort @$_]}
      WARC::Record::Logical::Heuristics::_scan_directory_for_axes
      $HF_TestDir, @axes],
     [['NEWS-20100913192819505-00056-10413~ia360914.us.archive.org~9443.emv',
       'NEWS-20100913193701387-00058-10413~ia360914.us.archive.org~9443.emv',
       'NEWS-20100913195201346-00060-10413~ia360914.us.archive.org~9443.emv',
       'NEWS-20100913200316661-00062-10413~ia360914.us.archive.org~9443.emv',
       'NEWS-20100913201909556-00064-10413~ia360914.us.archive.org~9443.emv',
       'NEWS-20100913203413308-00066-10413~ia360914.us.archive.org~9443.emv',
       'NEWS-20100913204603775-00068-10413~ia360914.us.archive.org~9443.emv',
       'NEWS-20100913205911958-00070-10413~ia360914.us.archive.org~9443.emv',
       'NEWS-20100913210939238-00072-10413~ia360914.us.archive.org~9443.emv',
       'NEWS-20100913211911044-00074-10413~ia360914.us.archive.org~9443.emv'],
      ['NEWS-20100913201909556-00064-10413~ia360914.us.archive.org~9443.emv'],
      ['NEWS-20100913201909556-00064-10413~ia360914.us.archive.org~9443.emv'],
      ['NEWS-20100913201909556-00064-10413~ia360914.us.archive.org~9443.emv']],
     'scan directory (variable timestamps)');

  $file = 'NEWS-00064-20100913201909556-10413~ia360914.us.archive.org~9443.emv';
  @axes = WARC::Record::Logical::Heuristics::_split_digit_spans $file;
  eq_or_diff
    ([map {[sort @$_]}
      WARC::Record::Logical::Heuristics::_scan_directory_for_axes
      $HF_TestDir, @axes],
     [['NEWS-00060-20100913195201346-10413~ia360914.us.archive.org~9443.emv',
       'NEWS-00062-20100913200316661-10413~ia360914.us.archive.org~9443.emv',
       'NEWS-00064-20100913201909556-10413~ia360914.us.archive.org~9443.emv',
       'NEWS-00066-20100913203413308-10413~ia360914.us.archive.org~9443.emv'],
      ['NEWS-00064-20100913201909556-10413~ia360914.us.archive.org~9443.emv'],
      ['NEWS-00064-20100913201909556-10413~ia360914.us.archive.org~9443.emv'],
      ['NEWS-00064-20100913201909556-10413~ia360914.us.archive.org~9443.emv']],
     'scan directory (variable timestamps postfix)');
  cmp_ok($WARC::Record::Logical::Heuristics::Effort,
	 '>=', 3 * scalar @HF_TestFiles, 'each test read entire directory');
}

note('*' x 60);

# Internal helper function:  _find_similar_files
{
  local $WARC::Record::Logical::Heuristics::Effort = 0;
  local $WARC::Record::Logical::Heuristics::Effort{readdir_files_per_tick} = 1;

  my $file = File::Spec->catfile($HF_TestDir, 'abc123-543-def056-ad-56334.emv');
  eq_or_diff([WARC::Record::Logical::Heuristics::_find_similar_files $file],
	     [[[map {File::Spec->catfile($HF_TestDir, $_)}
		'abc122-543-def056-ad-56334.emv'],[]],
	      [[map {File::Spec->catfile($HF_TestDir, $_)}
		'abc123-533-def056-ad-56334.emv'],[]],
	      [[map {File::Spec->catfile($HF_TestDir, $_)}
		'abc123-543-def047-ad-56334.emv'],
	       [map {File::Spec->catfile($HF_TestDir, $_)}
		'abc123-543-def057-ad-56334.emv']],
	      [[map {File::Spec->catfile($HF_TestDir, $_)}
		'abc123-543-def056-ad-56330.emv',
		'abc123-543-def056-ad-56332.emv',
		'abc123-543-def056-ad-56333.emv'],
	       [map {File::Spec->catfile($HF_TestDir, $_)}
		'abc123-543-def056-ad-56335.emv',
		'abc123-543-def056-ad-56336.emv',
		'abc123-543-def056-ad-56338.emv']]],
	     'find similar files (simple)');

  $file = File::Spec->catfile
    ($HF_TestDir,
     'NEWS-20100913201909556-00064-10413~ia360914.us.archive.org~9443.emv');
  eq_or_diff
    ([WARC::Record::Logical::Heuristics::_find_similar_files $file],
     [[[map {File::Spec->catfile($HF_TestDir, $_)}
	'NEWS-20100913192819505-00056-10413~ia360914.us.archive.org~9443.emv',
	'NEWS-20100913193701387-00058-10413~ia360914.us.archive.org~9443.emv',
	'NEWS-20100913195201346-00060-10413~ia360914.us.archive.org~9443.emv',
	'NEWS-20100913200316661-00062-10413~ia360914.us.archive.org~9443.emv'],
       [map {File::Spec->catfile($HF_TestDir, $_)}
	'NEWS-20100913203413308-00066-10413~ia360914.us.archive.org~9443.emv',
	'NEWS-20100913204603775-00068-10413~ia360914.us.archive.org~9443.emv',
	'NEWS-20100913205911958-00070-10413~ia360914.us.archive.org~9443.emv',
	'NEWS-20100913210939238-00072-10413~ia360914.us.archive.org~9443.emv',
	'NEWS-20100913211911044-00074-10413~ia360914.us.archive.org~9443.emv']]
     ],
    'find similar files (timestamps)');

  $file = File::Spec->catfile
    ($HF_TestDir,
     'NEWS-00064-20100913201909556-10413~ia360914.us.archive.org~9443.emv');
  eq_or_diff
    ([WARC::Record::Logical::Heuristics::_find_similar_files $file],
     [[[map {File::Spec->catfile($HF_TestDir, $_)}
	'NEWS-00060-20100913195201346-10413~ia360914.us.archive.org~9443.emv',
	'NEWS-00062-20100913200316661-10413~ia360914.us.archive.org~9443.emv'],
       [map {File::Spec->catfile($HF_TestDir, $_)}
	'NEWS-00066-20100913203413308-10413~ia360914.us.archive.org~9443.emv']]
     ],
     'find similar files (timestamps postfix)');
  cmp_ok($WARC::Record::Logical::Heuristics::Effort,
	 '>=', 3 * scalar @HF_TestFiles, 'each test read entire directory');
}

note('*' x 60);

# Internal helper function:  _scan_volume
sub test_scan_volume ($$$@) {
  map {defined $_ ? $_->id : undef}
    &WARC::Record::Logical::Heuristics::_scan_volume(@_);
}
{
  local $WARC::Record::Logical::Heuristics::Effort = 0;
  local $WARC::Record::Logical::Heuristics::Effort{read_record} = 70;
  local $WARC::Record::Logical::Heuristics::Effort{gzread_data_per_tick} = 10;
  my $volume = mount WARC::Volume ('abc122-533-def056-ad-56334.emv');

  eq_or_diff([test_scan_volume $volume, 0, undef,
	      [WARC_Record_ID => '<urn:test:bogus>']],
	     [undef],
	     'search for bogus record returns empty list');
  is($WARC::Record::Logical::Heuristics::Effort, 718,
     '... and entire volume was searched');
  $WARC::Record::Logical::Heuristics::Effort = 0;
  eq_or_diff([test_scan_volume $volume, 2, undef,
	      [WARC_Record_ID => '<urn:test:fhash-34d4:record-1>']],
	     [undef],
	     'search starting after record returns nothing');
  is($WARC::Record::Logical::Heuristics::Effort, 578,
     '... after searching the rest of the volume');
  $WARC::Record::Logical::Heuristics::Effort = 0;
  eq_or_diff([test_scan_volume $volume, 0, 7,
	      [WARC_Record_ID => '<urn:test:fhash-34d4:record-8>']],
	     ['<urn:test:fhash-34d4:record-8>'],
	     'search ending before record returns nothing');
  is($WARC::Record::Logical::Heuristics::Effort, 578,
     '... after searching most of the volume');
  $WARC::Record::Logical::Heuristics::Effort = 0;
  eq_or_diff([test_scan_volume $volume, 8, undef,
	      [WARC_Record_ID => '<urn:test:fhash-34d4:record-8>']],
	     [undef,
	      '<urn:test:fhash-34d4:record-8>'],
	     'search to end finds record near end');
  is($WARC::Record::Logical::Heuristics::Effort, 140,
     '... and searches the rest of the volume');
  $WARC::Record::Logical::Heuristics::Effort = 0;
  eq_or_diff([test_scan_volume $volume, 0, 6,
	      [WARC_Record_ID => '<urn:test:fhash-34d4:record-1>']],
	     ['<urn:test:fhash-34d4:record-7>',
	      '<urn:test:fhash-34d4:record-1>'],
	     'search to middle finds record near start');
  is($WARC::Record::Logical::Heuristics::Effort, 508,
     '... and searches part of the volume');
  $WARC::Record::Logical::Heuristics::Effort = 0;

  eq_or_diff([test_scan_volume $volume, 0, 7,
	      [WARC_Record_ID => '<urn:test:fhash-34d4:record-1>']],
	     ['<urn:test:fhash-34d4:record-8>',
	      '<urn:test:fhash-34d4:record-1>'],
	     'search for origin record');
  is($WARC::Record::Logical::Heuristics::Effort, 578,
     '... spans most of the volume');
  $WARC::Record::Logical::Heuristics::Effort = 0;
  eq_or_diff([test_scan_volume $volume, 7, undef,
	      [WARC_Segment_Origin_ID => '<urn:test:fhash-34d4:record-1>']],
	     [undef,
	      '<urn:test:fhash-34d4:record-7>', '<urn:test:fhash-34d4:record-8>'],
	     'search for continuation records (1)');
  is($WARC::Record::Logical::Heuristics::Effort, 210,
     '... spans the rest of the volume with overlap');
  $WARC::Record::Logical::Heuristics::Effort = 0;
  eq_or_diff([test_scan_volume $volume, 0, 7,
	      [WARC_Segment_Origin_ID => '<urn:test:fhash-34d4:record-1>']],
	     ['<urn:test:fhash-34d4:record-8>',
	      '<urn:test:fhash-34d4:record-4>', '<urn:test:fhash-34d4:record-6>',
	      '<urn:test:fhash-34d4:record-7>'],
	     'search for continuation records (2)');
  is($WARC::Record::Logical::Heuristics::Effort, 578,
     '... spans most of the volume');
}

note('*' x 60);

# Search tests within volume
{
  local $WARC::Record::Logical::Heuristics::Effort{read_record} = 1;
  local $WARC::Record::Logical::Heuristics::Effort{readdir_files_per_tick} = 1;

  my $volume = mount WARC::Volume ('abc123-543-def056-ad-56334.emv');
  my $initial = $volume->record_at(2);
  my $first_segment; my @clues; my @rest;

  {
    my $fail = 0;
    ($first_segment, @clues) = eval
      { my $r = $volume->record_at(0);
	WARC::Record::Logical::Heuristics::find_first_segment($r);
	$fail = 1;};
    ok($fail == 0 && !defined($first_segment) && $@ =~ m/unsegmented/,
       'croak on bogus search for segments');

    $fail = 0;
    @rest = eval
      {my $r = $initial;
       WARC::Record::Logical::Heuristics::find_continuation $r, undef;
       $fail = 1;};
    ok($fail == 0 && $@ =~ m/unrecognized clue/,
       'croak on continuation search with bogus clue');

    $fail = 0;
    @rest = eval
      {my $r = $initial;
       WARC::Record::Logical::Heuristics::find_continuation $r, [BOGUS => 1];
       $fail = 1;};
    ok($fail == 0 && $@ =~ m/unrecognized hint/,
       'croak on continuation search with bogus hint clue');
  }

  ($first_segment, @clues) =
    WARC::Record::Logical::Heuristics::find_first_segment($initial);

  is($first_segment->id, '<urn:test:fhash-7cac:record-1>',
				'find first segment in same volume (1)');

  @rest = WARC::Record::Logical::Heuristics::find_continuation
    ($first_segment, @clues);
  eq_or_diff([as_id_set @rest],
	     ['<urn:test:fhash-7cac:record-2>',
	      '<urn:test:fhash-7cac:record-3>'],
				'find continuations in same volume (1)');

  $initial = $volume->record_at(3);
  ($first_segment, @clues) =
    WARC::Record::Logical::Heuristics::find_first_segment($initial);

  is($first_segment->id, '<urn:test:fhash-7cac:record-1>',
				'find first segment in same volume (2)');

  @rest = WARC::Record::Logical::Heuristics::find_continuation
    ($first_segment, @clues);
  eq_or_diff([as_id_set @rest],
	     ['<urn:test:fhash-7cac:record-2>',
	      '<urn:test:fhash-7cac:record-3>'],
				'find continuations in same volume (2)');
}

note('*' x 60);

# Search tests spanning volumes (simple)
{
  local $WARC::Record::Logical::Heuristics::Effort{read_record} = 1;
  local $WARC::Record::Logical::Heuristics::Effort{readdir_files_per_tick} = 1;

  my $volume = mount WARC::Volume ('abc123-543-def056-ad-56334.emv');
  my $initial = $volume->record_at(4);
  my $first_segment; my @clues; my @rest;

  {
    local $WARC::Record::Logical::Heuristics::Patience = 0;
    ($first_segment, @clues) =
      WARC::Record::Logical::Heuristics::find_first_segment($initial);
    ok((not defined $first_segment),
				'no patience can mean no results');
  }

  ($first_segment, @clues) =
    WARC::Record::Logical::Heuristics::find_first_segment($initial);

  is($first_segment->id, '<urn:test:fhash-a174:record-2>',
				'find first segment in earlier volume');

  {
    local $WARC::Record::Logical::Heuristics::Patience = 7;
    my $f; my @c;
    ($f, @c) = WARC::Record::Logical::Heuristics::find_first_segment($initial);
    ok((not defined $f),	'... but only with sufficient patience');
  }

  @rest = WARC::Record::Logical::Heuristics::find_continuation
    ($first_segment, map {dclone($_)} @clues);
  eq_or_diff([as_id_set @rest],
	     [sort
	      '<urn:test:fhash-a174:record-5>',
	      '<urn:test:fhash-7cac:record-4>',
	      '<urn:test:fhash-eaf7:record-4>',
	      '<urn:test:fhash-0378:record-2>'],
				'find continuations in other volumes');

  {
    local $WARC::Record::Logical::Heuristics::Patience = 4;
    @rest = WARC::Record::Logical::Heuristics::find_continuation
      ($first_segment, map {dclone($_)} @clues);
    eq_or_diff([as_id_set @rest],
	       [sort
		'<urn:test:fhash-a174:record-5>',
		'<urn:test:fhash-7cac:record-4>'],
				'... but only with sufficient patience');
  }

  @rest = WARC::Record::Logical::Heuristics::find_continuation
    ($first_segment, ());
  eq_or_diff([as_id_set @rest],
	     [sort
	      '<urn:test:fhash-a174:record-5>',
	      '<urn:test:fhash-7cac:record-4>',
	      '<urn:test:fhash-eaf7:record-4>',
	      '<urn:test:fhash-0378:record-2>'],
	     'find continuations in other volumes even without clues');

  $volume = mount WARC::Volume ('abc123-543-def056-ad-56332.emv');
  $first_segment = $volume->record_at(7); @clues = ();
  @rest = WARC::Record::Logical::Heuristics::find_continuation
    ($first_segment, ());
  eq_or_diff([as_id_set @rest],
	     ['<urn:test:fhash-0378:record-3>'],
	     'find continuation across long sequence search');
  {
    local $WARC::Record::Logical::Heuristics::Patience = 15;
    @rest = WARC::Record::Logical::Heuristics::find_continuation
      ($first_segment, ());
    eq_or_diff(\@rest, [],	'... but only with sufficient patience');
  }
}

note('*' x 60);

# Search tests spanning volumes (directory scan)
{
  local $WARC::Record::Logical::Heuristics::Effort{read_record} = 1;
  local $WARC::Record::Logical::Heuristics::Effort{readdir_files_per_tick} = 1;

  my $volume = mount WARC::Volume ('abc123-543-def056-ad-56334.emv');
  my $initial = $volume->record_at(6);
  my $first_segment; my @clues; my @rest;

  ($first_segment, @clues) =
    WARC::Record::Logical::Heuristics::find_first_segment($initial);

  is($first_segment->id, '<urn:test:fhash-7072:record-1>',
				'find first segment in earlier volume by scan');

  @rest = WARC::Record::Logical::Heuristics::find_continuation
    ($first_segment, @clues);
  eq_or_diff([as_id_set @rest],
	     [sort
	      '<urn:test:fhash-a174:record-1>',
	      '<urn:test:fhash-b9f5:record-2>',
	      '<urn:test:fhash-7cac:record-6>',
	      '<urn:test:fhash-0378:record-5>',
	      '<urn:test:fhash-347a:record-3>'],
				'find continuations in other volumes by scan');

  @rest = WARC::Record::Logical::Heuristics::find_continuation
    ($first_segment, ());
  eq_or_diff([as_id_set @rest],
	     [sort
	      '<urn:test:fhash-a174:record-1>',
	      '<urn:test:fhash-b9f5:record-2>',
	      '<urn:test:fhash-7cac:record-6>',
	      '<urn:test:fhash-0378:record-5>',
	      '<urn:test:fhash-347a:record-3>'],
	     'find continuations in other volumes by scan even without clues');

  $initial = $volume->record_at(9);

  ($first_segment, @clues) =
    WARC::Record::Logical::Heuristics::find_first_segment($initial);

  is($first_segment->id, '<urn:test:fhash-7cac:record-8>',
     'find first segment starting with last record in volume');

  @rest = WARC::Record::Logical::Heuristics::find_continuation
    ($first_segment, @clues);
  eq_or_diff([as_id_set @rest],
	     [sort
	      '<urn:test:fhash-7cac:record-9>',
	      '<urn:test:fhash-0378:record-6>',
	      # segment number 4 is missing for this item
	      '<urn:test:fhash-347a:record-5>'],
	     'find continuations after starting with last record in volume');

  @rest = WARC::Record::Logical::Heuristics::find_continuation
    ($first_segment, ());
  eq_or_diff([as_id_set @rest],
	     [sort
	      '<urn:test:fhash-7cac:record-9>',
	      '<urn:test:fhash-0378:record-6>',
	      # segment number 4 is missing for this item
	      '<urn:test:fhash-347a:record-5>'],
	     '... even without clues');

  $volume = mount WARC::Volume ('abc122-533-def056-ad-56334.emv');
  $initial = $volume->record_at(9);

  ($first_segment, @clues) =
    WARC::Record::Logical::Heuristics::find_first_segment($initial);

  is($first_segment->id, '<urn:test:fhash-7f75:record-1>',
				'find first segment across islands');

  {
    local $WARC::Record::Logical::Heuristics::Patience = 20;
    my $f; my @c;
    ($f, @c) = WARC::Record::Logical::Heuristics::find_first_segment($initial);
    ok((not defined $f),	'... but only with sufficient patience');
  }

  @rest = WARC::Record::Logical::Heuristics::find_continuation
    ($first_segment, @clues);
  eq_or_diff([as_id_set @rest],
	     ['<urn:test:fhash-34d4:record-9>'],
				'find continuation across islands');

  @rest = WARC::Record::Logical::Heuristics::find_continuation
    ($first_segment, ());
  eq_or_diff([as_id_set @rest],
	     ['<urn:test:fhash-34d4:record-9>'],
	     'find continuation across islands even without clues');
  {
    local $WARC::Record::Logical::Heuristics::Patience = 50;
    @rest = WARC::Record::Logical::Heuristics::find_continuation
      ($first_segment, ());
    eq_or_diff(\@rest, [],	'... but only with sufficient patience');
  }

  $volume = mount WARC::Volume ('def456-789-abc042-zc-82440.emv');
  $initial = $volume->record_at(1);

  ($first_segment, @clues) =
    WARC::Record::Logical::Heuristics::find_first_segment($initial);

  ok((not defined $first_segment),
     'return undefined when first segment is not present');
}

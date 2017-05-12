#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Time::Tzfile' }

subtest raw_one => sub {
  ok my $tzfile = Time::Tzfile->parse_raw({
      filename => 't/London',use_version_one => 1}), 'parse_raw tzfile v1';

  # validate header
  cmp_ok $tzfile->[0][0], 'eq','TZif','Intro is TZif';
  cmp_ok $tzfile->[0][1], '==',   2, 'Version matches';
  cmp_ok $tzfile->[0][2], '==',   8, 'GMT count matches';
  cmp_ok $tzfile->[0][3], '==',   8, 'STD count matches';
  cmp_ok $tzfile->[0][4], '==',   0, 'Leap count matches';
  cmp_ok $tzfile->[0][5], '==', 243, 'Time count matches';
  cmp_ok $tzfile->[0][6], '==',   8, 'Type count matches';
  cmp_ok $tzfile->[0][7], '==',  17, 'Char count matches';

  # validate body
  cmp_ok @{$tzfile->[1]}, '==',243, 'GMT entry count matches';
  cmp_ok @{$tzfile->[2]}, '==',243, 'GMT entry count matches';
  cmp_ok @{$tzfile->[3]}, '==',  8, 'ttinfo entry count matches';
  cmp_ok @{$tzfile->[4]}, '==',  1, 'ttinfo entry count matches';
  cmp_ok @{$tzfile->[5]}, '==',  0, 'leap entry count matches';
  cmp_ok @{$tzfile->[6]}, '==',  8, 'GMT entry count matches';
  cmp_ok @{$tzfile->[7]}, '==',  8, 'STD entry count matches';
};

subtest raw_two => sub {
  ok my $tzfile = Time::Tzfile->parse_raw({filename => 't/London'}), 'parse_raw tzfile v2';

  # validate header
  cmp_ok $tzfile->[0][0], 'eq','TZif','Intro is TZif';
  cmp_ok $tzfile->[0][1], '==',   2, 'Version matches';
  cmp_ok $tzfile->[0][2], '==',   8, 'GMT count matches';
  cmp_ok $tzfile->[0][3], '==',   8, 'STD count matches';
  cmp_ok $tzfile->[0][4], '==',   0, 'Leap count matches';
  cmp_ok $tzfile->[0][5], '==', 244, 'Time count matches';
  cmp_ok $tzfile->[0][6], '==',   8, 'Type count matches';
  cmp_ok $tzfile->[0][7], '==',  17, 'Char count matches';

  # validate body
  cmp_ok @{$tzfile->[1]}, '==',244, 'GMT entry count matches';
  cmp_ok @{$tzfile->[2]}, '==',244, 'GMT entry count matches';
  cmp_ok @{$tzfile->[3]}, '==',  8, 'ttinfo entry count matches';
  cmp_ok @{$tzfile->[4]}, '==',  1, 'ttinfo entry count matches';
  cmp_ok @{$tzfile->[5]}, '==',  0, 'leap entry count matches';
  cmp_ok @{$tzfile->[6]}, '==',  8, 'GMT entry count matches';
  cmp_ok @{$tzfile->[7]}, '==',  8, 'STD entry count matches';
};

subtest parse_one => sub {
  ok my $tzfile = Time::Tzfile->parse_raw({
      filename => 't/London',use_version_one => 1}), 'parse tzfile v1';

  ok my $data = Time::Tzfile->parse({
      filename => 't/London',use_version_one => 1}), 'parse tzfile v1';

  cmp_ok @$data, '==', @{$tzfile->[1]}, 'one entry for each transition';
};

subtest parse_two => sub {
  ok my $tzfile = Time::Tzfile->parse_raw({filename => 't/London',}), 'parse tzfile v2';
  ok my $data   = Time::Tzfile->parse({filename => 't/London',}), 'parse tzfile v2';

  cmp_ok @$data, '==', @{$tzfile->[1]}, 'one entry for each transition';
};

done_testing;

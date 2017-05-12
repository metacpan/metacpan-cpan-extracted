#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;

BEGIN {
    use_ok('Text::SuDocs');
}

my @accurate_strings = (
    {original=>'ep 1.23: 998',
     sortable=>'EP_00000001.00000023:00000998',
     normal=>'EP 1.23:998', stem=>'EP 1.23',
     agency=>'EP', subagency=>'1', series=>'23',
     relatedseries=>undef, document=>'998'},

    {original=>'EP 1.23: 998',
     sortable=>'EP_00000001.00000023:00000998',
     normal=>'EP 1.23:998', stem=>'EP 1.23',
     agency=>'EP', subagency=>'1', series=>'23',
     relatedseries=>undef, document=>'998'},

    {original=>'EP 1.23: 91-44',
     sortable=>'EP_00000001.00000023:00000091-00000044',
     normal=>'EP 1.23:91-44', stem=>'EP 1.23',
     agency=>'EP', subagency=>'1', series=>'23',
     relatedseries=>undef, document=>'91-44'},

    {original=>'C 51. 11:  EN 8/995',
     sortable=>'C_00000051.00000011:EN_00000008/00000995',
     normal=>'C 51.11:EN 8/995', stem=>'C 51.11',
     agency=>'C', subagency=>'51', series=>'11',
     relatedseries=>undef, document=>'EN 8/995'},

    {original=>'C 51. 11: 23',
     sortable=>'C_00000051.00000011:00000023',
     normal=>'C 51.11:23', stem=>'C 51.11',
     agency=>'C', subagency=>'51', series=>'11',
     relatedseries=>undef, document=>'23'},

    {original=>'T 63.209/8-3:994/1     ',
     sortable=>'T_00000063.00000209/00000008-00000003:00000994/00000001',
     normal=>'T 63.209/8-3:994/1', stem=>'T 63.209/8-3',
     agency=>'T', subagency=>'63', series=>'209',
     relatedseries=>'8-3', document=>'994/1'},

    {original=>'T63.209/8-3:994/1',
     sortable=>'T_00000063.00000209/00000008-00000003:00000994/00000001',
     normal=>'T 63.209/8-3:994/1', stem=>'T 63.209/8-3',
     agency=>'T', subagency=>'63', series=>'209',
     relatedseries=>'8-3', document=>'994/1'},

    {original=>'T63.209/8-3 : 994/1',
     sortable=>'T_00000063.00000209/00000008-00000003:00000994/00000001',
     normal=>'T 63.209/8-3:994/1', stem=>'T 63.209/8-3',
     agency=>'T', subagency=>'63', series=>'209',
     relatedseries=>'8-3', document=>'994/1'},

    {original=>'T63.209/8-3 :994/1',
     sortable=>'T_00000063.00000209/00000008-00000003:00000994/00000001',
     normal=>'T 63.209/8-3:994/1', stem=>'T 63.209/8-3',
     agency=>'T', subagency=>'63', series=>'209',
     relatedseries=>'8-3', document=>'994/1'},

    {original=>'T63 .209/8-3:994/1',
     sortable=>'T_00000063.00000209/00000008-00000003:00000994/00000001',
     normal=>'T 63.209/8-3:994/1', stem=>'T 63.209/8-3',
     agency=>'T', subagency=>'63', series=>'209',
     relatedseries=>'8-3', document=>'994/1'},

    {original=>'Y 3.EQ 2:1/',
     sortable=>'Y_00000003.EQ_00000002:00000001/',
     normal=>'Y 3.EQ 2:1/', stem=>'Y 3.EQ 2',
     agency=>'Y', subagency=>'3', committee=>'EQ', series=>'2',
     relatedseries=>undef, document=>'1/'},

    {original=>'Y 3.EQ 2:a1/4a',
     sortable=>'Y_00000003.EQ_00000002:A1/4A',
     normal=>'Y 3.EQ 2:A1/4A', stem=>'Y 3.EQ 2',
     agency=>'Y', subagency=>'3', committee=>'EQ', series=>'2',
     relatedseries=>undef, document=>'A1/4A'},

    {original=>'Y 3.F 31/21-3:2 In 8',
     sortable=>'Y_00000003.F_00000031/00000021-00000003:00000002_IN_00000008',
     normal=>'Y 3.F 31/21-3:2 IN 8', stem=>'Y 3.F 31/21-3',
     agency=>'Y', subagency=>'3', committee=>'F', series=>'31',
     relatedseries=>'21-3', document=>'2 IN 8'},

    {original=>'HE 1. 2:AC 6/7',
     sortable=>'HE_00000001.00000002:AC_00000006/00000007',
     normal=>'HE 1.2:AC 6/7', stem=>'HE 1.2',
     agency=>'HE', subagency=>'1', series=>'2',
     relatedseries=>undef, document=>'AC 6/7'},

    {original=>'   HE    1. 2:AC     6/7   ',
     sortable=>'HE_00000001.00000002:AC_00000006/00000007',
     normal=>'HE 1.2:AC 6/7', stem=>'HE 1.2',
     agency=>'HE', subagency=>'1', series=>'2',
     relatedseries=>undef, document=>'AC 6/7'},

    {original=>'A 3.103:',
     sortable=>'A_00000003.00000103',
     normal=>'A 3.103', stem=>'A 3.103',
     agency=>'A', subagency=>'3', series=>'103',
     relatedseries=>undef, document=>undef},

    {original=>'A 3.103',
     sortable=>'A_00000003.00000103',
     normal=>'A 3.103', stem=>'A 3.103',
     agency=>'A', subagency=>'3', series=>'103',
     relatedseries=>undef, document=>undef},

    {original=>'XJH',
     sortable=>'XJH',
     normal=>'XJH', stem=>'XJH',
     agency=>'XJH', subagency=>undef, series=>undef,
     relatedseries=>undef, document=>undef},

    {original=>'XJH:',
     sortable=>'XJH',
     normal=>'XJH', stem=>'XJH',
     agency=>'XJH', subagency=>undef, series=>undef,
     relatedseries=>undef, document=>undef},

    {original=>'  XJH: ',
     sortable=>'XJH',
     normal=>'XJH', stem=>'XJH',
     agency=>'XJH', subagency=>undef, series=>undef,
     relatedseries=>undef, document=>undef},

    {original=>'   XJH    ',
     sortable=>'XJH',
     normal=>'XJH', stem=>'XJH',
     agency=>'XJH', subagency=>undef, series=>undef,
     relatedseries=>undef, document=>undef},

    {original=>'XJS',
     sortable=>'XJS',
     normal=>'XJS', stem=>'XJS',
     agency=>'XJS', subagency=>undef, series=>undef,
     relatedseries=>undef, document=>undef},

    );

subtest 'Normalization' => sub {
    for my $t (@accurate_strings) {
        subtest "Parsing $t->{original}" => sub {
            plan tests => 9;
            my $s = new_ok('Text::SuDocs' => [$t->{original}]);
            next if !$s;
            for my $f (qw(agency subagency series relatedseries document)) {
                no warnings 'uninitialized';
                is($s->$f, $t->{$f}, "$f: $t->{$f} eq ".$s->$f);
            }
            is($s->normal_string, $t->{normal}, 'normalized (full)');
            is($s->normal_string(class_stem=>1), $t->{stem}, 'normalized (stem)');
            is($s->sortable_string, $t->{sortable}, 'sortable');
        }
    }
    done_testing();
};

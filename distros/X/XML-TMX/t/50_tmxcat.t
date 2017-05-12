#!/usr/bin/perl

use strict;
use warnings;

use XML::TMX::Reader;
use Test::More tests => 4;

`$^X -Iblib scripts/tmx2tmx -cat t/writer1.xml t/writer2.xml > mycat.tmx`;

ok -f 'mycat.tmx';

my $reader = XML::TMX::Reader->new('mycat.tmx');

isa_ok $reader => 'XML::TMX::Reader';

like $reader->{header}{creationdate} => qr/^\d+T\d+Z$/;
delete $reader->{header}{creationtoolversion};
delete $reader->{header}{creationdate};

is_deeply($reader->{header},
          {
           'o-tmf' => 'plain text',
           adminlang => 'en',
           creationtool => 'XML::TMX::Writer',
           srclang => 'en',
           segtype => 'sentence',
           datatype => 'plaintext',
           '-note' => [qw.note1 note2 note3 note4 note5 note6.],
           '-prop' => {prop3 => ['val3'],
                       prop4 => ['val4'],
                       prop2 => ['val2', 'val22'],
                       prop1 => ['val1', 'val11'],
                      },
      });

#unlink 'mycat.tmx';

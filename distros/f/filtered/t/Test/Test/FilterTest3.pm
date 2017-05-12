package Test::Test::FilterTest3;

use strict;

require Exporter;
our (@ISA) = qw(Exporter);
our (@EXPORT_OK) = qw(call);

sub call
{
    return 'FOOFOOZOTZOT';
}

1;

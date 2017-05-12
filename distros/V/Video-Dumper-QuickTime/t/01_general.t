use strict;
use warnings;

use Test::More tests => 4;
my $kTestFile = 't/Sample.mov';

BEGIN {
    use lib '../lib';    # For development testing
    use_ok ('Video::Dumper::QuickTime');
}

$kTestFile = 'Sample.mov' if ! -e $kTestFile;

my $object = Video::Dumper::QuickTime->new (-filename => $kTestFile);

isa_ok ($object, 'Video::Dumper::QuickTime');

$object->Dump ();
my $str = $object->Result ();

like ($str, qr/\Q'moov' Movie container @ \E/, 'Has moov atom');
like ($str, qr/\Q'mdat' Media data @ \E/, 'Has mdat atom');
